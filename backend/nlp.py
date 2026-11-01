"""ScamShield NLP core: framework-independent so it can be tested without FastAPI.

Pipeline
  1. TF-IDF (word + char n-grams) + Logistic Regression  -> model probability
  2. Transparent rule signals (regex) with character spans -> rule score + highlights
  3. URL analysis (never fetches anything)                  -> link findings
  4. Blend model + rules, map to a label, pick a likely scam type, build advice

Everything here is heuristic and experimental. A low score never proves a message is safe.
"""
from __future__ import annotations

import csv
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
DATA_PATH = ROOT / "data" / "messages.csv"
MODEL_PATH = ROOT / "model.joblib"

MODEL_NAME = "TF-IDF word/char n-grams + Logistic Regression, blended with rule signals (experimental)"

# Thresholds on the blended score (0-1). Provisional; see evaluate.py for how they behave on grouped CV.
LIKELY_THRESHOLD = 0.50
SUSPICIOUS_THRESHOLD = 0.33
MODEL_INFLUENCE = 0.6  # how much a fully confident model can add on top of the rule evidence (noisy-OR)

LIMITATIONS = (
    "ScamShield is an experimental screening aid trained on a small illustrative dataset. It can miss scams "
    "or flag genuine messages. A low score does not prove a message is safe. Never share passwords or OTPs, "
    "and verify through official channels. English-first: Filipino/Taglish support is limited and unevaluated."
)

# --------------------------------------------------------------------------------------
# Model training / loading
# --------------------------------------------------------------------------------------

def build_pipeline():
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.linear_model import LogisticRegression
    from sklearn.pipeline import FeatureUnion, Pipeline

    return Pipeline([
        ("features", FeatureUnion([
            ("word", TfidfVectorizer(ngram_range=(1, 2), lowercase=True, strip_accents="unicode",
                                     max_features=12000, sublinear_tf=True)),
            ("char", TfidfVectorizer(analyzer="char_wb", ngram_range=(3, 5), lowercase=True,
                                     max_features=12000, sublinear_tf=True)),
        ])),
        ("classifier", LogisticRegression(max_iter=1000, class_weight="balanced", random_state=42)),
    ])


def load_dataset(path: Path = DATA_PATH) -> list[dict[str, str]]:
    if not path.exists():
        raise RuntimeError(f"Training data not found: {path}")
    with path.open(newline="", encoding="utf-8") as fh:
        rows = [r for r in csv.DictReader(fh) if (r.get("text") or "").strip() and (r.get("label") or "").strip()]
    if not rows:
        raise RuntimeError("Training data is empty")
    if len({r["label"] for r in rows}) < 2:
        raise RuntimeError("Training data must contain at least two classes")
    return rows


def train_model(save: bool = True):
    import joblib

    rows = load_dataset()
    model = build_pipeline()
    model.fit([normalize_for_model(r["text"]) for r in rows], [r["label"] for r in rows])
    if save:
        joblib.dump(model, MODEL_PATH)
    return model, len(rows)


def load_model():
    """Load the saved model, retraining if it is missing or was built by an incompatible library version."""
    import joblib

    if MODEL_PATH.exists():
        try:
            return joblib.load(MODEL_PATH)
        except Exception:
            pass
    model, _ = train_model(save=True)
    return model


# --------------------------------------------------------------------------------------
# Rule signals
# --------------------------------------------------------------------------------------

@dataclass(frozen=True)
class Rule:
    id: str
    name: str
    explanation: str
    weight: float
    severity: str  # high | medium | low
    pattern: re.Pattern[str]


def _r(p: str) -> re.Pattern[str]:
    return re.compile(p, re.I)


_CRED = r"(?:otp|one[- ]?time[- ](?:password|pin|code)|password|passcode|mpin|pin(?: code)?|cvv|verification code|security code|recovery code|card number|login details|bank details|account details|bank account(?: number| details)?|account number|atm (?:card|pin)|valid id|id (?:photo|picture)|log[- ]?in (?:code|details))"
_ASK = r"(?:send|share|give|tell|provide|enter|confirm|verify|reply with|reply|submit|update|renew|read out|ibigay|i-send|ilagay|ipadala)"

RULES: list[Rule] = [
    Rule("credential_request", "Asks for a code, password or account details",
         "The message asks you to send, enter or confirm a password, PIN, OTP, ID or bank details. Real banks and apps never ask for these by message or call.",
         0.40, "high", _r(rf"\b{_ASK}\b[^.!?\n]{{0,60}}?\b{_CRED}\b|\b(?:tell|read|send|give)\b[^.!?\n]{{0,30}}\bcode\b[^.!?\n]{{0,30}}\b(?:sent|texted|received)\b|\bthe code (?:we|that was) (?:sent|texted)")),
    Rule("urgency", "Pressure to act fast",
         "Scammers rush you so you do not stop and think. Watch for countdowns, 'final notice' and 'immediately'.",
         0.18, "medium", _r(r"\b(?:urgent(?:ly)?|immediately|right now|right away|act now|asap|within \d+ ?(?:hours?|hrs?|minutes?|mins?)|today only|last chance|final (?:warning|notice|reminder)|expires? today|limited (?:time|slots)|hurry|before it'?s too late|agad|ngayon na)\b")),
    Rule("account_threat", "Threat to your account",
         "The message says your account, card, SIM or service will be blocked, closed or cut off unless you act.",
         0.25, "high", _r(r"\b(?:account|card|wallet|number|service|sim|profile|access|line|postpaid|electricity|power)\b[^.!?\n]{0,40}\b(?:suspend\w*|block\w*|lock\w*|clos\w+|deactivat\w+|restrict\w*|disconnect\w*|terminat\w*|delet\w+|cut off)\b|\b(?:suspend\w*|block\w*|deactivat\w+|disconnect\w*)\b[^.!?\n]{0,15}\b(?:your|ng|ang)\b")),
    Rule("legal_threat", "Threat of arrest or legal action",
         "Genuine agencies do not demand payment by text under threat of arrest. This is a common intimidation tactic.",
         0.32, "high", _r(r"\b(?:arrest(?:ed)?|warrant|police|jail|prison|lawsuit|legal action|court|deport\w*|blacklist\w*|money laundering|cybercrime unit|makukulong|kulong|nbi|bir notice)\b")),
    Rule("advance_fee", "Asks for a fee before you get something",
         "You are asked to pay a fee (processing, release, customs, clearance…) to receive money or a parcel. Real prizes and loans do not work this way.",
         0.38, "high", _r(r"\b(?:pay|send|deposit|settle|remit|bayad(?:an)?|magbayad)\b[^.!?\n]{0,50}\b(?:fees?|charges?|tax(?:es)?|deposit)\b|\b(?:processing|release|registration|clearance|redelivery|delivery|customs|handling|insurance|application|training)\s+(?:fees?|charges?|materials)\b|\bpay\b[^.!?\n]{0,15}\d[\d,.]*k?\b[^.!?\n]{0,20}\bfor\b[^.!?\n]{0,25}\b(?:uniform|training|kit|slot|registration|requirements|application|processing|shipping|release)\b")),
    Rule("prize", "Prize, lottery or reward claim",
         "Unexpected prizes you never entered for are a classic lure. If you did not join, you did not win.",
         0.32, "high", _r(r"\byou(?:'ve| have)? (?:won|been selected|are (?:a |the )?(?:lucky )?winner)\b|\bcongrat\w*[^.!?\n]{0,50}\b(?:won|selected|winner|prize|reward|chosen)\b|\b(?:lucky winner|lottery|raffle|jackpot|cash reward|claim (?:your |the )?(?:prize|reward|gift|it))\b|\bfree (?:iphone|phone|gift|cash|laptop|load)\b|\bnanalo\b|\bpremyo\b|\bnapanalunan\b|\bWINNER\b|\bbeneficiary\b|\binheritance\b|\bnext of kin\b|\bunclaimed (?:funds?|refund|package)\b|\$\d+(?:\.\d+)?\s?(?:m|million)\b")),
    Rule("investment", "Too-good-to-be-true returns",
         "Guaranteed profit, 'risk free' or 'double your money' claims are red flags. All real investments carry risk.",
         0.38, "high", _r(r"\bguaranteed (?:returns?|profit|income|tubo)\b|\bdouble your money\b|\brisk[- ]?free\b|\bno risk\b|\bwalang risk\b|\bpassive income\b|\b\d+ ?% (?:guaranteed |profit |returns? |interest )?(?:daily|weekly|monthly|every)\b|\b(?:crypto|bitcoin|forex)\b[^.!?\n]{0,60}\b(?:earn|profit|returns?|signals?|invest)\w*|\bearn\b[^.!?\n]{0,30}\b(?:per day|daily|a day|araw-araw)\b|\bguaranteed\b[^.!?\n]{0,20}\btubo\b")),
    Rule("job_task", "Too-easy job offer",
         "Offers that pay a lot for liking videos, rating products or 'simple tasks' often lead to fees or stolen details.",
         0.30, "medium", _r(r"\b(?:part[- ]time|work from home|online (?:job|assistant)|easy (?:task )?job|hiring|job application)\b[^.!?\n]{0,80}\b(?:earn|per day|daily|a day|weekly|salary|fee|bank details|approved)\b|\blike (?:and|&) (?:share|subscribe)\b|\b(?:simple|easy) tasks?\b|\b(?:add|message) us on (?:telegram|whatsapp|viber)\b")),
    Rule("tech_support", "Fake tech-support alert",
         "Unsolicited 'your device is infected/hacked' messages push you to call a number or install remote-access software.",
         0.34, "high", _r(r"\b(?:virus|malware|infected|hacked|compromised)\b[^.!?\n]{0,60}\b(?:call|install|download|click|helpline|support|remove)\b|\b(?:anydesk|teamviewer|remote (?:access|control))\b|\b(?:microsoft|apple) support\b")),
    Rule("emergency_ask", "Urgent request for money from 'someone you know'",
         "Messages claiming a relative or friend is in trouble, has a new number or needs money fast are common impersonation scams. Call them on the number you already have.",
         0.34, "high", _r(r"\b(?:new number|lost my phone|changed my number|bagong number|(?:texting|messaging|using) (?:from )?(?:a )?(?:friend'?s|someone'?s|another) (?:phone|number)|phone (?:fell|broke|got stolen|is broken|died)|i(?:'m| am) (?:stuck|stranded|in trouble)|(?:relative|nephew|niece|cousin|son|daughter|friend)\b[^.!?\n]{0,40}\b(?:accident|hospital|trouble|arrested))\b")),
    Rule("unusual_payment", "Unusual payment method",
         "Gift cards, crypto and wire transfers are hard to reverse, which is why scammers ask for them.",
         0.28, "high", _r(r"\b(?:gift ?cards?|itunes card|google play card|steam card|bitcoin|usdt|crypto wallet|western union|moneygram|wire transfer|prepaid card)\b")),
    Rule("money_request", "Asks you to send money",
         "The message asks you to transfer or send money. Verify through a channel you already trust before paying anyone.",
         0.22, "medium", _r(r"\b(?:send|transfer|deposit) (?:me |us |the |your |some )?(?:money|cash|funds|php|₱|\d[\d,.]*k?)\b|\bsend (?:it )?to (?:this|my) (?:gcash|maya|number|account|wallet)\b|\blend me (?:some )?(?:money|cash|\d[\d,]*|php|₱)\b|\bmagpadala ng\b|\bsend money\b")),
    Rule("secrecy", "Asks you to keep it secret",
         "'Don't tell anyone' keeps you away from people who could spot the scam.",
         0.28, "high", _r(r"\b(?:don'?t|do not|never|huwag mo|wag mo) (?:tell|inform|share (?:this )?with|sabihin|call)\b[^.!?\n]{0,30}\b(?:anyone|anybody|family|bank|police|friends|mama|papa|kahit sino)\b|\bkeep (?:this|it) (?:a )?secret\b|\bdo not call anyone\b|\bwalang makakaalam\b")),
    Rule("call_number", "Pushes you to call a number",
         "Scammers often supply a phone number that connects to them. Use the number printed on your card or on the official website.",
         0.14, "low", _r(r"\bcall (?:this|our|the following) (?:number|helpline|hotline)\b|\btoll[- ]free\b|\bcall\b[^.!?\n]{0,15}\b\+?\d[\d -]{6,}")),
    Rule("pay_to_personal", "Asks you to pay to a personal number or wallet",
         "Real companies bill through their official app, website or branches, not to a personal mobile number or e-wallet.",
         0.32, "high", _r(r"\bpay(?:ing)?\b[^.!?\n]{0,35}\b(?:via|to|through|thru|using)\b[^.!?\n]{0,25}(?:\b09\d{9}\b|\+?63\d{10}|\b\d{10,11}\b)|\b(?:gcash|maya)\b[^.!?\n]{0,20}\b(?:number|no\.?)\b[^.!?\n]{0,10}\d{7,}")),
    Rule("login_alert", "Unrecognised-login alert",
         "'Someone logged in' alerts are used to scare you into calling or clicking. Check by opening the official app yourself.",
         0.14, "low", _r(r"\b(?:new device|unusual (?:log[- ]?in|sign[- ]?in|activity)|suspicious (?:log[- ]?in|sign[- ]?in|activity|transaction)|logged (?:in|into)|unauthori[sz]ed (?:access|transaction))\b")),
]

SHORTENERS = {"bit.ly", "tinyurl.com", "cutt.ly", "t.co", "goo.gl", "ow.ly", "is.gd", "rb.gy", "shorturl.at", "tiny.cc", "buff.ly", "rebrand.ly", "s.id", "t.ly", "lnkd.in", "bl.ink", "shorte.st"}
SUSPICIOUS_TLDS = {"xyz", "top", "click", "site", "online", "live", "icu", "vip", "buzz", "work", "link", "tk", "ml", "ga", "cf", "gq", "info", "support", "help", "shop", "cc", "ws", "rest", "cam", "monster"}
URL_KEYWORDS = {"login", "verify", "secure", "update", "confirm", "account", "wallet", "reward", "claim", "bonus", "refund", "unlock", "support", "helpdesk", "signin"}
SECOND_LEVEL = {"com.ph", "org.ph", "net.ph", "gov.ph", "edu.ph", "co.uk", "org.uk", "com.au", "co.jp", "co.id", "com.sg", "com.my"}

# Widely used sites. A link to one of these is not by itself a warning sign. (It is also not proof the message
# is genuine: shared files and profiles on big sites can be abused, which the UI says.)
TRUSTED_DOMAINS = {
    "youtube.com", "youtu.be", "google.com", "gstatic.com", "zoom.us", "github.com", "wikipedia.org", "facebook.com",
    "fb.com", "messenger.com", "instagram.com", "whatsapp.com", "twitter.com", "x.com", "linkedin.com", "tiktok.com",
    "spotify.com", "netflix.com", "microsoft.com", "office.com", "apple.com", "icloud.com", "amazon.com", "paypal.com",
    "gcash.com", "maya.ph", "paymaya.com", "bdo.com.ph", "bpi.com.ph", "metrobank.com.ph", "unionbankph.com",
    "landbank.com", "shopee.ph", "shopee.com", "lazada.com.ph", "lazada.com", "globe.com.ph", "smart.com.ph",
    "meralco.com.ph", "lbcexpress.com", "dhl.com", "fedex.com", "twitch.tv", "reddit.com", "wikimedia.org",
}


def is_trusted_domain(reg: str) -> bool:
    return reg in TRUSTED_DOMAINS or reg.endswith(".gov.ph") or reg.endswith(".edu.ph")


# brand keyword -> (display name, official registered domains)
BRANDS: dict[str, tuple[str, set[str]]] = {
    "gcash": ("GCash", {"gcash.com"}),
    "maya": ("Maya", {"maya.ph", "paymaya.com"}),
    "bdo": ("BDO", {"bdo.com.ph"}),
    "bpi": ("BPI", {"bpi.com.ph", "bpiexpressonline.com"}),
    "metrobank": ("Metrobank", {"metrobank.com.ph"}),
    "unionbank": ("UnionBank", {"unionbankph.com"}),
    "landbank": ("Landbank", {"landbank.com"}),
    "paypal": ("PayPal", {"paypal.com"}),
    "netflix": ("Netflix", {"netflix.com"}),
    "facebook": ("Facebook", {"facebook.com", "fb.com"}),
    "instagram": ("Instagram", {"instagram.com"}),
    "google": ("Google", {"google.com"}),
    "microsoft": ("Microsoft", {"microsoft.com"}),
    "apple": ("Apple", {"apple.com", "icloud.com"}),
    "amazon": ("Amazon", {"amazon.com"}),
    "globe": ("Globe", {"globe.com.ph"}),
    "smart": ("Smart", {"smart.com.ph"}),
    "shopee": ("Shopee", {"shopee.ph", "shopee.com"}),
    "lazada": ("Lazada", {"lazada.com.ph", "lazada.com"}),
    "lbc": ("LBC", {"lbcexpress.com"}),
    "dhl": ("DHL", {"dhl.com"}),
    "fedex": ("FedEx", {"fedex.com"}),
    "meralco": ("Meralco", {"meralco.com.ph"}),
    "sss": ("SSS", {"sss.gov.ph"}),
    "philhealth": ("PhilHealth", {"philhealth.gov.ph"}),
    "bir": ("BIR", {"bir.gov.ph"}),
}
_BRAND_WORD_RE = re.compile(r"\b(" + "|".join(sorted(BRANDS, key=len, reverse=True)) + r")\b", re.I)

URL_RE = re.compile(
    r"(?:https?://|www\.)[^\s<>\"']+"
    r"|\b(?:[a-z0-9-]+\.)+(?:com|net|org|xyz|top|click|info|site|ph|link|online|live|shop|co|me|ly|gl|cc|tk|ml|ga|cf|gq|icu|vip|buzz|work|support|help|app|ws|rest|cam|monster|gov|edu|io|ai)\b(?:/[^\s<>\"']*)?",
    re.I,
)
EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")
PROTECTIVE_RE = re.compile(r"\b(?:do not|don'?t|never) share (?:this|it|your)\b|\bwill never ask (?:for )?your\b|\bnever share\b|\bif you did not (?:request|make|do)\b|\bignore this message\b|\bnumber on (?:the back of )?your card\b|\bofficial (?:app|website)\b", re.I)


@dataclass
class Span:
    start: int
    end: int
    signal: str


@dataclass
class Signal:
    id: str
    name: str
    explanation: str
    severity: str  # high | medium | low | info
    weight: float
    spans: list[Span] = field(default_factory=list)


@dataclass
class LinkFinding:
    name: str
    explanation: str
    severity: str  # high | medium | low


@dataclass
class LinkReport:
    url: str
    host: str
    registered_domain: str
    verdict: str  # high_risk | suspicious | no_obvious_issues
    verdict_text: str
    findings: list[LinkFinding]


def registered_domain(host: str) -> str:
    host = host.lower().strip(".")
    parts = host.split(".")
    if len(parts) <= 2:
        return host
    if ".".join(parts[-2:]) in SECOND_LEVEL:
        return ".".join(parts[-3:])
    return ".".join(parts[-2:])


def _clean_url(raw: str) -> str:
    return raw.rstrip(".,;:!?)]}'\"")


def extract_urls(text: str) -> list[tuple[str, int, int]]:
    """Return (url, start, end) for URL-like substrings; email addresses are skipped."""
    email_spans = [(m.start(), m.end()) for m in EMAIL_RE.finditer(text)]
    out = []
    for m in URL_RE.finditer(text):
        if any(s <= m.start() < e for s, e in email_spans):
            continue
        url = _clean_url(m.group(0))
        if len(url) < 4:
            continue
        out.append((url, m.start(), m.start() + len(url)))
    return out


def normalize_for_model(text: str) -> str:
    """Replace links to well-known sites with a neutral token so the classifier judges the words, not the link.

    Used identically at training and prediction time. (Without it the model learned 'any link = scam'.)
    """
    out = text
    for url, start, end in sorted(extract_urls(text), key=lambda t: -t[1]):
        candidate = url if re.match(r"^[a-z][a-z0-9+.-]*://", url, re.I) else "http://" + url
        try:
            parsed = urlparse(candidate)
            host = (parsed.hostname or "").lower()
            has_userinfo = "@" in parsed.netloc
        except ValueError:
            continue
        if host and not has_userinfo and is_trusted_domain(registered_domain(host)):
            out = out[:start] + "trustedsite" + out[end:]
    return out


def analyze_url(raw: str, mentioned_brands: set[str] | None = None) -> LinkReport:
    """Static, offline analysis of a URL string. Never makes a network request."""
    url = _clean_url(raw.strip())
    candidate = url if re.match(r"^[a-z][a-z0-9+.-]*://", url, re.I) else "http://" + url
    findings: list[LinkFinding] = []
    try:
        parsed = urlparse(candidate)
        host = (parsed.hostname or "").lower()
    except ValueError:
        parsed, host = None, ""
    if not host:
        return LinkReport(url, "", "", "suspicious", "Could not read this link",
                          [LinkFinding("Unreadable link", "The link could not be parsed. Treat it with caution and do not open it.", "medium")])

    reg = registered_domain(host)
    labels = host.split(".")
    tld = labels[-1]
    path_query = ((parsed.path or "") + "?" + (parsed.query or "")).lower() if parsed else ""

    if re.fullmatch(r"\d{1,3}(?:\.\d{1,3}){3}", host):
        findings.append(LinkFinding("Raw IP address", "The link points to a numeric IP address instead of a normal website name. Real organisations almost never do this.", "high"))
    if reg in SHORTENERS or host in SHORTENERS:
        findings.append(LinkFinding("Shortened link", "Link shorteners hide the real destination. Ask the sender for the full address or look it up yourself.", "medium"))
    if "xn--" in host:
        findings.append(LinkFinding("Look-alike characters", "The domain uses encoded (punycode) characters that can imitate a real name.", "high"))
    if "@" in (parsed.netloc if parsed else ""):
        findings.append(LinkFinding("Hidden destination", "Everything before the '@' in the address is ignored by the browser. This is used to disguise the real site.", "high"))
    if tld in SUSPICIOUS_TLDS:
        findings.append(LinkFinding("Unusual domain ending", f"'.{tld}' domains are cheap and heavily abused. This alone proves nothing, but be careful.", "medium"))
    if len(labels) >= 5:
        findings.append(LinkFinding("Many sub-domains", "A long chain of sub-domains can hide the real owner of the site.", "medium"))
    if host.count("-") >= 2:
        findings.append(LinkFinding("Hyphen-heavy domain", "Domains stuffed with hyphens (e.g. secure-bank-login) are typical of fake sites.", "medium"))
    if parsed and parsed.scheme == "http":
        findings.append(LinkFinding("Not encrypted (http)", "The link does not use HTTPS, so anything you type could be seen or altered.", "low"))
    kw = sorted({k for k in URL_KEYWORDS if k in host.replace("-", " ").replace(".", " ").split() or k in path_query})
    if kw and (tld in SUSPICIOUS_TLDS or host.count("-") >= 1 or reg in SHORTENERS):
        findings.append(LinkFinding("Pressure words in the address", f"The address contains words such as {', '.join(kw[:3])}, often used to look official.", "low"))

    # brand look-alike: brand keyword in the host while the real domain is not official
    host_flat = host.replace("-", "").replace(".", "")
    lookalike = False
    for key, (display, official) in BRANDS.items():
        in_host = re.search(rf"(?:^|[.-]){key}(?:[.-]|\d|$)", host) is not None or (len(key) >= 5 and key in host_flat)
        if in_host and reg not in official:
            findings.append(LinkFinding(f"Imitates {display}", f"The address contains '{display}' but belongs to {reg}, which is not an official {display} domain.", "high"))
            lookalike = True
            break
    if not lookalike and mentioned_brands:
        for key in mentioned_brands:
            display, official = BRANDS[key]
            if reg not in official:
                findings.append(LinkFinding(f"Doesn't match {display}", f"The message talks about {display} but the link goes to {reg}. Open the official app or type the website yourself.", "medium"))
                break

    high = sum(f.severity == "high" for f in findings)
    medium = sum(f.severity == "medium" for f in findings)
    trusted = is_trusted_domain(reg) and "@" not in (parsed.netloc if parsed else "")
    if high >= 1 or medium >= 3:
        verdict, text = "high_risk", "High-risk link. Do not open it."
    elif medium >= 1:
        verdict, text = "suspicious", "Suspicious link. Verify before opening."
    elif trusted:
        verdict, text = "no_obvious_issues", f"This goes to {reg}, a well-known site."
        findings = [f for f in findings if f.severity != "low" or f.name == "Not encrypted (http)"]
        findings.append(LinkFinding("Well-known site", f"{reg} is widely used. Big sites can still host shared files or profiles that are unsafe, so this is not proof that the message is genuine.", "low"))
    elif len(findings) >= 2:
        verdict, text = "suspicious", "Suspicious link. Verify before opening."
    else:
        verdict, text = "no_obvious_issues", "No obvious problems with the address itself."
    if verdict == "no_obvious_issues" and not trusted:
        findings.append(LinkFinding("Static check only", "We only inspect the text of the address. A clean result does not mean the site is safe.", "low"))
    return LinkReport(url, host, reg, verdict, text, findings)


# --------------------------------------------------------------------------------------
# Scam types
# --------------------------------------------------------------------------------------

SCAM_TYPES: dict[str, dict[str, Any]] = {
    "phishing": {"name": "Phishing (account takeover)", "summary": "Tries to get your password, OTP or card details by pretending to be a bank, wallet or app.",
                 "signals": {"credential_request": 1.0, "account_threat": 0.9, "link_lookalike": 1.0}},
    "prize": {"name": "Fake prize or lottery", "summary": "Says you won something you never entered, then asks for details or a fee.",
              "signals": {"prize": 1.0}},
    "advance_fee": {"name": "Advance-fee / fake fee scam", "summary": "Asks you to pay a small fee first to release a parcel, loan or refund that never arrives.",
                    "signals": {"advance_fee": 1.0}},
    "investment": {"name": "Investment or crypto scam", "summary": "Promises guaranteed or very high returns with 'no risk'.",
                   "signals": {"investment": 1.0}},
    "job_task": {"name": "Job or task scam", "summary": "Offers easy money for simple tasks, then asks for fees, deposits or your bank details.",
                 "signals": {"job_task": 1.0}},
    "tech_support": {"name": "Tech-support scam", "summary": "Claims your device is infected so you install remote-access software or call a fake helpline.",
                     "signals": {"tech_support": 1.0}},
    "emergency": {"name": "Impersonation / emergency scam", "summary": "Pretends to be family or a friend in trouble and asks for money urgently and secretly.",
                  "signals": {"emergency_ask": 1.0, "secrecy": 0.5, "unusual_payment": 0.4}},
    "authority": {"name": "Fake authority / threat scam", "summary": "Threatens arrest, fines or disconnection to frighten you into paying.",
                  "signals": {"legal_threat": 1.0}},
}

ADVICE_BY_TYPE: dict[str, list[str]] = {
    "phishing": ["Open the official app or type the website address yourself; do not use the link in the message.", "If you already entered details, change your password and contact the real provider right away."],
    "prize": ["Real prizes never ask you to pay to receive them. If you did not enter, you did not win."],
    "advance_fee": ["Do not pay any 'release', 'customs' or 'processing' fee. Check parcels in the courier's own app with your tracking number."],
    "investment": ["Guaranteed returns do not exist. Check whether the company is registered with your country's securities regulator before investing."],
    "job_task": ["Legitimate employers do not charge you to start work. Research the company independently."],
    "tech_support": ["Hang up and do not install remote-access apps. Companies do not send unsolicited virus warnings."],
    "emergency": ["Call the person on the number you already have. Agree on a family 'safe word' for emergencies."],
    "authority": ["Real authorities do not demand instant payment by text. Contact the agency using its official website."],
}

# --------------------------------------------------------------------------------------
# Analysis
# --------------------------------------------------------------------------------------

def _prefix_negated(text: str, start: int) -> bool:
    return bool(re.search(r"(?:do not|don'?t|never|won'?t|will not|dont)\s*$", text[max(0, start - 18):start], re.I))


def find_signals(text: str) -> tuple[list[Signal], list[LinkReport], set[str]]:
    signals: list[Signal] = []
    for rule in RULES:
        spans = []
        for m in rule.pattern.finditer(text):
            if rule.id == "credential_request" and _prefix_negated(text, m.start()):
                continue
            spans.append(Span(m.start(), m.end(), rule.id))
        if spans:
            signals.append(Signal(rule.id, rule.name, rule.explanation, rule.severity, rule.weight, spans[:6]))

    mentioned = {m.group(1).lower() for m in _BRAND_WORD_RE.finditer(text)}
    urls = extract_urls(text)
    links = [analyze_url(u, mentioned) for u, _, _ in urls]

    if urls:
        spans = [Span(s, e, "link") for _, s, e in urls]
        worst = "high_risk" if any(l.verdict == "high_risk" for l in links) else ("suspicious" if any(l.verdict == "suspicious" for l in links) else "ok")
        all_trusted = all(is_trusted_domain(l.registered_domain) for l in links)
        if worst == "ok" and all_trusted:
            signals.append(Signal("link_trusted", "Link to a well-known site",
                                  "The link goes to a widely used site, so the link itself looks normal. That alone does not prove the message is genuine.",
                                  "info", 0.0, spans))
        elif worst == "high_risk":
            signals.append(Signal("link_risky", "Risky-looking link",
                                  "A link in this message has strong warning signs (look-alike name, raw IP, odd domain or hidden destination). Do not open it.",
                                  "high", 0.42, spans))
        elif worst == "suspicious":
            signals.append(Signal("link_suspicious", "Suspicious link",
                                  "A link in this message has some warning signs such as a shortener or unusual ending. Verify before opening.",
                                  "medium", 0.26, spans))
        else:
            signals.append(Signal("link_present", "Contains a link",
                                  "The message includes a link. Even if it looks normal, open services by typing their address or using their app.",
                                  "low", 0.08, spans))
        if any(f.name.startswith(("Imitates", "Doesn't match")) for l in links for f in l.findings):
            signals.append(Signal("link_lookalike", "Link doesn't match the sender",
                                  "The link's real domain does not belong to the organisation the message claims to be from.",
                                  "high", 0.0, spans))  # weight 0: already counted in link_risky; used for scam-type

    risk_ids = {s.id for s in signals}
    if mentioned and risk_ids & {"credential_request", "account_threat", "advance_fee", "link_risky", "link_suspicious", "prize", "legal_threat"}:
        spans = [Span(m.start(), m.end(), "impersonation") for m in _BRAND_WORD_RE.finditer(text)]
        signals.append(Signal("impersonation", "Uses a well-known name",
                              "The message uses the name of a trusted organisation alongside other warning signs. Anyone can type a brand name.",
                              "medium", 0.12, spans[:6]))

    letters = [c for c in text if c.isalpha()]
    if len(letters) >= 15 and sum(c.isupper() for c in letters) / len(letters) > 0.55 or re.search(r"[!?]{3,}", text):
        signals.append(Signal("shouting", "ALL-CAPS or lots of !!!", "Excessive capitals or exclamation marks are used to create alarm.", "low", 0.08, []))

    return signals, links, mentioned


def rule_score(signals: list[Signal]) -> float:
    """Noisy-OR combination of signal weights, so several weak signals add up without exceeding 1."""
    remaining = 1.0
    for s in signals:
        remaining *= 1.0 - s.weight
    return 1.0 - remaining


def merge_spans(signals: list[Signal]) -> list[dict[str, Any]]:
    """Merge overlapping spans for highlighting. Each merged span lists the signals that touch it."""
    items = sorted(((sp.start, sp.end, sp.signal) for s in signals for sp in s.spans), key=lambda t: (t[0], t[1]))
    merged: list[dict[str, Any]] = []
    for start, end, sid in items:
        if merged and start <= merged[-1]["end"]:
            merged[-1]["end"] = max(merged[-1]["end"], end)
            if sid not in merged[-1]["signals"]:
                merged[-1]["signals"].append(sid)
        else:
            merged.append({"start": start, "end": end, "signals": [sid]})
    return merged


def pick_scam_type(signals: list[Signal]) -> dict[str, Any] | None:
    present = {s.id: max(s.weight, 0.3) for s in signals}  # give weight-0 helper signals some voice
    best_id, best = None, 0.0
    for tid, spec in SCAM_TYPES.items():
        score = sum(present[sid] * w for sid, w in spec["signals"].items() if sid in present)
        if score > best:
            best_id, best = tid, score
    if best_id is None or best < 0.25:
        return None
    spec = SCAM_TYPES[best_id]
    return {"id": best_id, "name": spec["name"], "summary": spec["summary"]}


def top_terms(model, text: str, limit: int = 5) -> list[str]:
    """Words that pushed the model score towards 'scam' (linear model contributions; word features only)."""
    try:
        features = model.named_steps["features"]
        clf = model.named_steps["classifier"]
        word_vec = features.transformer_list[0][1]
        vector = features.transform([normalize_for_model(text)])
        n_word = len(word_vec.get_feature_names_out())
        classes = list(clf.classes_)
        sign = 1.0 if classes.index("scam") == 1 else -1.0
        coef = clf.coef_[0] * sign
        row = vector.tocsr()[0]
        contribs = []
        names = word_vec.get_feature_names_out()
        for idx, val in zip(row.indices, row.data):
            if idx < n_word:
                c = float(coef[idx] * val)
                if c > 0:
                    contribs.append((c, str(names[idx])))
        contribs.sort(reverse=True)
        out: list[str] = []
        for _, term in contribs:
            if any(term in o or o in term for o in out):
                continue
            out.append(term)
            if len(out) >= limit:
                break
        return out
    except Exception:
        return []


def model_probability(model, text: str) -> float:
    classes = list(model.classes_)
    if "scam" not in classes:
        raise RuntimeError("The trained model does not contain the required 'scam' class.")
    return float(model.predict_proba([normalize_for_model(text)])[0][classes.index("scam")])


def blend(probability: float, rules: float, protective: bool) -> float:
    if protective:
        rules *= 0.7
    # A model probability at or below 0.5 means "looks normal": it adds nothing. (Unfamiliar text sits near 0.5,
    # and treating that as suspicion made everyday messages look risky.)
    model_part = max(0.0, (probability - 0.5) / 0.5)
    score = 1.0 - (1.0 - rules) * (1.0 - MODEL_INFLUENCE * model_part)
    if rules >= 0.75:
        score = max(score, 0.75)  # several strong, independent warning signs
    if rules < 0.10:
        # The model alone is not enough evidence: without any corroborating warning sign it can at most
        # say "be careful" when it is very confident, and never "likely scam".
        score = min(score, 0.40 if probability >= 0.9 else 0.30)
    return max(0.0, min(1.0, score))


def label_for(score: float) -> tuple[str, str]:
    if score >= LIKELY_THRESHOLD:
        return "likely_scam", "Likely scam indicators"
    if score >= SUSPICIOUS_THRESHOLD:
        return "suspicious", "Needs careful checking"
    return "no_obvious_scam_indicators", "No obvious scam indicators detected"


def analyze_message(model, raw_text: str) -> dict[str, Any]:
    text = raw_text.strip()
    probability = model_probability(model, text)
    signals, links, _ = find_signals(text)
    scoring_signals = [s for s in signals]
    rules = rule_score(scoring_signals)
    risky_ids = {s.id for s in signals if s.weight > 0 and s.id not in {"link_present", "shouting"}}
    protective = bool(PROTECTIVE_RE.search(text)) and not (risky_ids & {"credential_request", "advance_fee", "money_request", "link_risky"})
    score = blend(probability, rules, protective)
    label, label_text = label_for(score)

    out_signals: list[dict[str, Any]] = [
        {"id": s.id, "name": s.name, "explanation": s.explanation, "severity": s.severity,
         "spans": [{"start": sp.start, "end": sp.end} for sp in s.spans]}
        for s in sorted(signals, key=lambda s: -s.weight) if s.weight > 0 or s.id in {"link_lookalike", "link_trusted"}
    ]
    if protective:
        out_signals.append({"id": "reassuring", "name": "Contains a standard safety notice",
                            "explanation": "The message includes wording legitimate services use (e.g. 'never share this code'). This is reassuring but not proof.",
                            "severity": "info", "spans": []})
    if not out_signals:
        out_signals.append({"id": "none", "name": "No obvious pattern found",
                            "explanation": "The simple signal checks did not find common warning patterns. This does not establish that the message is legitimate.",
                            "severity": "info", "spans": []})

    scam_type = pick_scam_type(signals) if label != "no_obvious_scam_indicators" else None
    advice: list[str] = []
    if label != "no_obvious_scam_indicators":
        if {"advance_fee", "money_request", "unusual_payment"} & {s.id for s in signals}:
            advice.append("Do not send money until you have verified the request independently.")
        if scam_type:
            advice += ADVICE_BY_TYPE.get(scam_type["id"], [])
    if label == "no_obvious_scam_indicators":
        advice += [
            "Nothing alarming stood out, but that does not guarantee the message is safe.",
            "If it ever asks for money, a code or a password, stop and check through the official app or website first.",
        ]
    else:
        advice += [
            "Do not click links or call numbers supplied in an unexpected message.",
            "Open the official app or type the organisation's known website yourself to verify the claim.",
            "Never share your OTP, PIN, password or recovery code.",
        ]
    seen: set[str] = set()
    advice = [a for a in advice if not (a in seen or seen.add(a))]

    notes = []
    if len(text.split()) < 4:
        notes.append("Very short messages give the model little to work with, so treat this result as weak.")
    if sum(c.isascii() for c in text) / max(len(text), 1) < 0.8:
        notes.append("Much of this text is non-English, which ScamShield has not been evaluated on.")

    return {
        "label": label,
        "label_text": label_text,
        "risk_score": round(score * 100),
        "model_scam_probability": round(probability, 4),
        "rule_score": round(rules, 4),
        "signals": out_signals,
        "highlights": merge_spans(signals),
        "links": [link_to_dict(l) for l in links],
        "scam_type": scam_type,
        "top_terms": top_terms(model, text),
        "advice": advice,
        "notes": notes,
        "model": MODEL_NAME,
        "limitations": LIMITATIONS,
    }


def link_to_dict(l: LinkReport) -> dict[str, Any]:
    return {"url": l.url, "host": l.host, "registered_domain": l.registered_domain, "verdict": l.verdict,
            "verdict_text": l.verdict_text,
            "findings": [{"name": f.name, "explanation": f.explanation, "severity": f.severity} for f in l.findings]}


# --------------------------------------------------------------------------------------
# Privacy helper: mask secrets before anything is stored
# --------------------------------------------------------------------------------------

def redact_sensitive(text: str) -> str:
    text = EMAIL_RE.sub("[email]", text)
    text = re.sub(r"(?<!\w)(?:\+?\d[\s-]?){10,16}(?!\w)", "[number]", text)          # phone / card-like numbers
    text = re.sub(r"\b(otp|code|pin|mpin|password)\b(\s*(?:is|:|=)?\s*)([A-Za-z0-9]{4,10})\b",
                  lambda m: f"{m.group(1)}{m.group(2)}[hidden]" if any(ch.isdigit() for ch in m.group(3)) else m.group(0),
                  text, flags=re.I)
    text = re.sub(r"\b\d{4,8}\b", "[digits]", text)
    return text
