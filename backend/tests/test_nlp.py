"""Tests for the framework-free NLP core. These also run where FastAPI is not installed.

NOTE: the probe messages below were written separately from the training templates, but the rules were
adjusted after seeing them, so treat this as a REGRESSION suite, not as an unbiased accuracy estimate.
"""
import pytest

import nlp


@pytest.fixture(scope="module")
def model():
    return nlp.load_model()


SCAMS = [
    "Hi! Your GCash account is under review. To avoid restriction please verify your identity at gcash-help.top/verify today.",
    "URGENT: Your Netflix payment failed. Update billing info within 24 hours or your membership will be cancelled: netflix-billing.online",
    "Kindly send me the OTP you just received so I can verify the item, buyer here on Marketplace.",
    "Hello, this is the HR of Shopee. You've passed our screening. Pay 1,000 for uniform and ID before start date.",
    "Mum, my phone fell in water so I'm texting from a friend's phone. Can you transfer 15k for a new one? I'll explain later",
    "Join our VIP signals group, 95% win rate, guaranteed profits. Deposit 5000 to start!",
    "Your SSS pension is on hold. Update your records at sss-benefits.info immediately.",
    "Congratulations! You have been selected to win a laptop. Pay the PHP 500 processing fee to receive your reward.",
]
NORMALS = [
    "Your GCash OTP is 482913. Never share this code with anyone. GCash will never ask for it.",
    "BDO: PHP 2,500.00 was debited from your account ending 1234 at Mercury Drug. Not you? Call the hotline on the back of your card.",
    "Hey, can you send me the PDF of the lecture slides? Thanks!",
    "Class suspended tomorrow due to Signal No. 2. Stay safe!",
    "Lunch at 12? I'll text you the restaurant name.",
    "Can you lend me your charger later? Mine broke.",
    "Your Lazada order #12345 has shipped. Track it in the Lazada app.",
    "The prize giving for the school quiz bee is on Friday at 2 PM in the gym. Congratulations to all participants!",
]


@pytest.mark.parametrize("text", SCAMS)
def test_scams_are_flagged(model, text):
    assert nlp.analyze_message(model, text)["label"] != "no_obvious_scam_indicators"


@pytest.mark.parametrize("text", NORMALS)
def test_normals_not_flagged(model, text):
    assert nlp.analyze_message(model, text)["label"] == "no_obvious_scam_indicators"


def test_response_shape(model):
    r = nlp.analyze_message(model, "Your account is blocked. Send your OTP now at bit.ly/abc123")
    for key in ["label", "label_text", "risk_score", "model_scam_probability", "rule_score", "signals", "highlights",
                "links", "scam_type", "top_terms", "advice", "notes", "model", "limitations"]:
        assert key in r
    assert 0 <= r["risk_score"] <= 100
    assert r["signals"] and r["advice"]
    assert "does not prove" in r["limitations"]
    assert r["links"][0]["verdict"] in {"high_risk", "suspicious"}


def test_highlight_spans_point_at_real_text(model):
    text = "URGENT: send your OTP at bit.ly/abc123"
    r = nlp.analyze_message(model, text)
    assert r["highlights"]
    for h in r["highlights"]:
        assert 0 <= h["start"] < h["end"] <= len(text)
    assert any("bit.ly" in text[h["start"]:h["end"]] for h in r["highlights"])


def test_negated_credential_phrase_is_not_a_request():
    signals, _, _ = nlp.find_signals("Do not share your OTP with anyone.")
    assert "credential_request" not in {s.id for s in signals}


def test_scam_type_detected(model):
    r = nlp.analyze_message(model, "You won a free iPhone! Pay the PHP 500 release fee to claim your prize now.")
    assert r["scam_type"] is not None


def test_no_scam_type_for_normal(model):
    assert nlp.analyze_message(model, "See you at dinner tonight, I'll be there at seven.")["scam_type"] is None


def test_short_text_gets_a_caveat(model):
    assert nlp.analyze_message(model, "ok sure")["notes"]


class TestLinks:
    def test_ip_address(self):
        r = nlp.analyze_url("http://192.168.4.12/verify")
        assert r.verdict == "high_risk"

    def test_brand_lookalike(self):
        r = nlp.analyze_url("https://gcash-verify.top/login")
        assert r.verdict == "high_risk"
        assert any("Imitates GCash" in f.name for f in r.findings)

    def test_official_domain_not_flagged_as_lookalike(self):
        r = nlp.analyze_url("https://www.gcash.com/help")
        assert r.verdict == "no_obvious_issues"
        assert not any("Imitates" in f.name for f in r.findings)

    def test_gov_ph_registered_domain(self):
        assert nlp.registered_domain("www.sss.gov.ph") == "sss.gov.ph"
        assert nlp.analyze_url("https://www.sss.gov.ph/").verdict == "no_obvious_issues"

    def test_shortener(self):
        r = nlp.analyze_url("bit.ly/3xYk2P")
        assert r.verdict in {"suspicious", "high_risk"}

    def test_punycode_and_at_sign(self):
        assert nlp.analyze_url("http://xn--pypal-4ve.com").verdict == "high_risk"
        assert nlp.analyze_url("https://paypal.com@evil.example.top/").verdict == "high_risk"

    def test_unreadable(self):
        assert nlp.analyze_url("http://").verdict == "suspicious"

    def test_emails_are_not_links(self):
        assert nlp.extract_urls("write to support@gcash.com please") == []

    def test_trailing_punctuation_stripped(self):
        assert nlp.extract_urls("Visit www.example.com/a.")[0][0] == "www.example.com/a"


class TestRedaction:
    def test_masks_secrets(self):
        out = nlp.redact_sensitive("My OTP is 482913, call 0917 123 4567 or email me@mail.com. PIN: 1234")
        for secret in ["482913", "0917", "me@mail.com", "1234"]:
            assert secret not in out


EVERYDAY = [
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "youtube.com",
    "youtube",
    "Check out this video https://youtu.be/abc123 it's hilarious",
    "Watch my new video on YouTube, link in bio",
    "Here is the Google Drive link for the project: https://drive.google.com/file/d/1abc/view",
    "Meet me at https://zoom.us/j/123456 at 3pm",
    "Check this out https://www.wikipedia.org/wiki/Cat",
    "I uploaded the file to github.com/myrepo",
    "Hi",
    "Happy birthday!",
    "Reminder: submit your assignment on the school portal https://www.ateneo.edu.ph before Friday.",
]


@pytest.mark.parametrize("text", EVERYDAY)
def test_everyday_messages_and_known_sites_are_not_flagged(model, text):
    r = nlp.analyze_message(model, text)
    assert r["label"] == "no_obvious_scam_indicators", r
    assert r["risk_score"] < 25


def test_known_site_link_is_described_as_known():
    r = nlp.analyze_message(model_for_test := nlp.load_model(), "Watch this https://www.youtube.com/watch?v=abc")
    assert r["links"][0]["verdict"] == "no_obvious_issues"
    assert "youtube.com" in r["links"][0]["verdict_text"]
    assert any(s["id"] == "link_trusted" for s in r["signals"])


@pytest.mark.parametrize("url", [
    "https://youtube.com.evil-login.top/watch",
    "https://www.youtube.com@evil.example.top/",
    "https://youtube-login-verify.xyz",
    "http://gcash-verify.top/login",
])
def test_lookalikes_of_known_sites_are_still_caught(url):
    assert nlp.analyze_url(url).verdict in {"suspicious", "high_risk"}


def test_known_site_does_not_excuse_a_credential_request(model):
    r = nlp.analyze_message(model, "Send your OTP and password now, details at https://www.youtube.com/watch?v=abc")
    assert r["label"] != "no_obvious_scam_indicators"
