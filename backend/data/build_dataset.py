"""Build backend/data/messages.csv.

The dataset is SYNTHETIC / ILLUSTRATIVE: the original 61 hand-written seed rows plus
template-expanded variants. Every row has a ``group`` id (the template it came from) so that
evaluation can split by group and avoid template leakage. It is NOT a real-world sample.

Run:  python data/build_dataset.py
"""
from __future__ import annotations

import csv
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "messages.csv"
SEED_FILE = ROOT / "seed_messages.csv"  # the original 61 rows, kept for provenance
rng = random.Random(7)

BRANDS = ["GCash", "Maya", "BDO", "BPI", "Metrobank", "UnionBank", "PayPal", "Netflix", "Facebook", "Globe", "Smart", "Shopee", "Lazada"]
COURIERS = ["LBC", "J&T Express", "DHL", "Flash Express", "FedEx", "Ninja Van"]
PROBLEMS = ["suspended", "locked", "limited", "flagged for suspicious activity", "temporarily blocked"]
CREDS = ["password", "OTP", "PIN", "MPIN", "card number", "login details"]
BAD_LINKS = [
    "bit.ly/3xYk2P", "tinyurl.com/acct-check", "http://secure-{b}-verify.top/login", "www.{b}-update.xyz",
    "http://192.168.4.12/verify", "https://{b}.account-help.click", "https://{b}-support.online/confirm",
    "http://{b}-rewards.site/claim", "cutt.ly/Rk29aZ", "https://login-{b}.info/secure",
]
GOOD_LINKS = ["https://www.{b}.com", "the official {B} app"]
AMOUNTS = ["350", "1,200", "5,000", "899", "2,450", "15,000"]
MERCHANTS = ["Jollibee", "Grab", "Shopee", "SM Supermarket", "Meralco", "Globe Postpaid", "7-Eleven", "Mercury Drug"]
DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
TIMES = ["9 AM", "10:30 AM", "1 PM", "2 PM", "3:30 PM", "5 PM"]


def link(b: str) -> str:
    return rng.choice(BAD_LINKS).format(b=b.lower().replace(" ", "").replace("&", ""))


def fill(template: str) -> str:
    b = rng.choice(BRANDS)
    return template.format(
        brand=b,
        courier=rng.choice(COURIERS),
        problem=rng.choice(PROBLEMS),
        cred=rng.choice(CREDS),
        link=link(b),
        amt=rng.choice(AMOUNTS),
        merchant=rng.choice(MERCHANTS),
        day=rng.choice(DAYS),
        time=rng.choice(TIMES),
        code=rng.randint(100000, 999999),
        pct=rng.choice([20, 30, 40, 50, 100]),
        fee=rng.choice(["250", "500", "1,000", "1,500", "3,000"]),
        prize=rng.choice(["iPhone 15", "cash prize of PHP 100,000", "brand new motorcycle", "PHP 50,000 shopping voucher", "laptop"]),
        n=rng.choice([3, 5, 12, 24, 48]),
        earn=rng.choice(["1,500", "3,000", "5,000", "8,000"]),
        vid=rng.choice(["dQw4w9WgXcQ", "x7Kq2LmP9aB", "9bZkp7q19f0", "M7lc1UVf-VE", "1aB2cD3eF4g"]),
        num=rng.randint(100000000, 999999999),
        name=rng.choice(["juan.delacruz", "mariasantos", "kuyajay", "team-alpha", "studygroup", "anna.reyes"]),
        topic=rng.choice(["Philippines", "Photosynthesis", "Volcano", "Basketball", "Jose_Rizal"]),
        site=rng.choice(["juandev.com", "mariaphotos.net", "kuyajaycooks.blog", "studygroup.org"]),
    )


SCAM_TEMPLATES = {
    "phishing": [
        "{brand}: Your account has been {problem}. Verify your {cred} at {link} to avoid permanent closure.",
        "Dear customer, we detected unusual login on your {brand} account. Confirm your {cred} now: {link}",
        "{brand} ALERT: Your account will be deactivated within {n} hours unless you update your details here {link}",
        "Security notice from {brand}. Click {link} and enter your {cred} to keep your account active.",
        "We could not verify your {brand} account. Reply with your {cred} to restore access immediately.",
        "{brand} support: someone tried to log in. Send us the code we texted you so we can cancel it.",
        "Your {brand} wallet is {problem}. Log in at {link} within {n} hours to reactivate.",
        "Final notice from {brand}: your {cred} has expired. Renew it today at {link} or lose access.",
    ],
    "prize": [
        "Congratulations! You have been selected to win a {prize}. Claim it now at {link}",
        "{brand} Promo: You won a {prize}! Pay the PHP {fee} processing fee to receive your reward.",
        "You are the lucky winner of our weekly raffle. Send your {cred} and address to claim the {prize}.",
        "Congrats, you have won a {prize} from {brand}. Reply with your full name and bank details to receive it.",
        "WINNER! Your number was picked for a free {prize}. Click {link} before it expires today.",
        "Nanalo ka ng {prize}! I-click ang {link} at ilagay ang {cred} para ma-claim.",
    ],
    "advance_fee": [
        "Your {courier} parcel is on hold. Pay the PHP {fee} customs fee at {link} to release it.",
        "{courier}: delivery failed. Settle a redelivery charge of PHP {fee} today or your package will be returned.",
        "Your loan of PHP 20,000 is approved! Send a PHP {fee} processing fee first to release the funds.",
        "Inheritance fund waiting for you. Pay the PHP {fee} clearance fee to receive the transfer.",
        "You have an unclaimed refund. To receive it, deposit a PHP {fee} release fee first.",
        "May parcel ka sa {courier}. Magbayad ng PHP {fee} sa {link} para ma-release.",
        "Instant loan, no collateral. Approved na! Bayad muna ng PHP {fee} insurance fee bago i-release.",
    ],
    "investment": [
        "Invest PHP {fee} today and earn guaranteed {pct}% profit every week. Risk free!",
        "Double your money in {n} hours. Guaranteed returns. Send your deposit to our wallet now.",
        "Join our crypto trading group. Members earn PHP {earn} per day with zero risk. Message me to start.",
        "Limited slots! Forex signals with {pct}% guaranteed monthly returns. Deposit PHP {fee} to join.",
        "Passive income opportunity: put in PHP {fee} and withdraw double next week. No risk, trusted by thousands.",
        "Kumita ng PHP {earn} araw-araw sa crypto investment. Guaranteed tubo, walang risk. Send money na.",
    ],
    "job_task": [
        "Hiring! Part-time online job, earn PHP {earn} per day. Just like and share videos. Message us to start.",
        "Work from home opportunity: complete simple tasks and earn PHP {earn} daily. Pay a PHP {fee} registration fee to begin.",
        "Congratulations, your job application is approved. Send PHP {fee} for training materials before your interview.",
        "We saw your resume. Easy task job, earn PHP {earn} a day by rating products. Add us on Telegram now.",
        "Online assistant needed. Salary PHP {earn} weekly. Send your bank details so we can set up payroll.",
    ],
    "tech_support": [
        "Microsoft Support: your computer is infected with a virus. Call this number now and install AnyDesk so we can fix it.",
        "Warning! Your device has been hacked. Download the app at {link} to remove the malware immediately.",
        "Apple Support alert: your phone is compromised. Call our toll-free helpline and allow remote access.",
        "Your {brand} account was hacked. Install TeamViewer and give us the ID so our agent can secure it.",
    ],
    "emergency": [
        "Hi mom, this is my new number. I lost my phone and I'm in trouble. Please send money to this GCash number now.",
        "Hello, I'm your nephew. I'm stuck at the hospital and need PHP {fee} urgently. Don't tell anyone, please send it now.",
        "A relative of yours has been in an accident. Send PHP {fee} immediately for the hospital and do not call anyone.",
        "Hey it's me, I changed my number. Can you buy a gift card and send me the code? I'll pay you back. Keep it a secret.",
        "My dear, I love you so much. I am stranded abroad and need PHP {fee} for my ticket. Please help me.",
        "Ate, ito bagong number ko. Emergency, pwede ka magpadala ng PHP {fee} ngayon? Huwag mo sabihin kay mama.",
    ],
    "authority": [
        "This is the police cybercrime unit. A case was filed against you. Pay PHP {fee} today or you will be arrested.",
        "Final warning from the court: you have an unpaid fine. Settle PHP {fee} at {link} to avoid a warrant of arrest.",
        "BIR notice: unpaid tax detected. Pay immediately at {link} or legal action will follow.",
        "Your SIM will be blocked in {n} hours for illegal activity. Call this number and confirm your ID details.",
        "NBI advisory: your name appears in a money laundering case. Don't tell anyone and send your bank details for verification.",
        "Makukulong ka kapag hindi ka nagbayad ng PHP {fee} ngayon. Final notice ito.",
    ],
    "utility": [
        "Your electricity will be disconnected today due to unpaid bill. Pay now through {link} to avoid disconnection.",
        "Your {brand} postpaid line will be cut off in {n} hours. Settle your balance here: {link}",
        "Unpaid toll fee detected. Pay PHP {fee} at {link} to avoid penalties.",
    ],
}

NORMAL_TEMPLATES = {
    "otp_legit": [
        "Your {brand} verification code is {code}. Do not share this code with anyone, including {brand} staff. It expires in 5 minutes.",
        "{code} is your {brand} login code. Never share it. If you did not request this, ignore this message.",
        "Use {code} to confirm your {brand} sign in. {brand} will never ask for your code.",
    ],
    "txn_alert": [
        "{brand}: You paid PHP {amt} to {merchant}. If you did not make this payment, contact support using the number on your card.",
        "Your {brand} account received PHP {amt} from a transfer. Check the official app for details.",
        "{brand} receipt: PHP {amt} payment to {merchant} was successful. Thank you.",
        "Your monthly statement from {brand} is ready. Open the official app to view it.",
    ],
    "delivery_ok": [
        "Your {courier} parcel is out for delivery today. Track it in the {courier} app.",
        "Your order from {merchant} has been delivered. Thank you for shopping with us.",
        "{courier}: your package will arrive on {day} between {time}. Please have someone available to receive it.",
        "Your parcel was delivered and signed for at the front desk.",
    ],
    "appointments": [
        "Reminder: your dental appointment is on {day} at {time}. Reply C to confirm.",
        "Your clinic appointment is confirmed for {day}, {time}. Please bring a valid ID.",
        "Reminder: the team meeting is on {day} at {time} in the conference room.",
        "Hi, the class has been moved to {day} {time}. See you there.",
        "Your haircut is booked for {day} at {time}. See you!",
    ],
    "friends_family": [
        "Hey, are we still on for dinner on {day}? I'll book a table for {time}.",
        "Mom here. I sent your allowance through {brand}. Please check your app.",
        "Thanks for lunch yesterday! Next one is on me.",
        "Can you send me the notes from class? I missed the lecture.",
        "Happy birthday! Hope you have an amazing day. Let's celebrate this {day}.",
        "I'm on my way, traffic is heavy. I'll be there in {n} minutes.",
        "Don't forget to bring the documents tomorrow. Love you!",
        "Can you lend me your charger later? Mine broke.",
        "Dad paid the electricity bill already, no need to worry about it.",
    ],
    "work_school": [
        "Hi team, the deadline for the report is {day}. Please send your sections by {time}.",
        "Class is suspended on {day} due to the typhoon warning. Stay safe everyone.",
        "Your scholarship interview is on {day} at {time}. Please bring your documents.",
        "The office will be closed on the public holiday. Regular hours resume on {day}.",
        "Please review the attached agenda before the meeting. Let me know if anything is missing.",
        "Your exam schedule has been posted on the school portal. Check the official website for details.",
        "Reminder: the tuition payment window opens on {day}. Pay at the cashier or through the official school portal.",
    ],
    "promo_ok": [
        "Weekend sale! {pct}% off selected items in store. Show this message at the counter.",
        "{merchant}: thanks for your purchase! Rate your experience in the app when you have time.",
        "Our store hours are extended this {day}. Visit us until 9 PM.",
        "{brand} tip: update your app to the latest version from the official app store for new features.",
    ],
    "utility_ok": [
        "Your electricity bill for this month is ready in the app. Due date is the 20th.",
        "Scheduled water interruption in your area on {day} from 9 AM to 3 PM. Please store water.",
        "Your internet plan renewed successfully. Thank you for staying with {brand}.",
    ],
    "links_ok": [
        "Check out this video: https://www.youtube.com/watch?v={vid}",
        "Watch it here https://youtu.be/{vid} it's so funny",
        "Here is the Google Drive link for our project: https://drive.google.com/file/d/{vid}/view",
        "Meeting link: https://zoom.us/j/{num} see you at {time}",
        "My profile: https://www.facebook.com/{name} add me!",
        "Read this article for our report https://en.wikipedia.org/wiki/{topic}",
        "Our repo is at github.com/{name}/project, please check the readme.",
        "Look at this on TikTok https://www.tiktok.com/@{name}/video/{num}",
        "Here's my new playlist https://open.spotify.com/playlist/{vid}",
        "Class materials are posted at https://classroom.google.com, please check before {day}.",
        "The enrollment form is on the school portal at https://www.up.edu.ph, deadline is {day}.",
        "You can read the official advisory at https://www.pagasa.dost.gov.ph",
        "My portfolio is at {site} if you want to take a look.",
        "I wrote a new blog post: https://{site}/new-post",
        "youtube.com/watch?v={vid}",
        "https://www.youtube.com/@{name}",
        "Join our family group chat https://www.messenger.com/t/{name}",
    ],
    "social_ok": [
        "Subscribe to my YouTube channel, I post new videos every {day}!",
        "I just posted a new video on YouTube, please watch and share.",
        "Did you see the new episode on Netflix last night?",
        "I'm going live on Facebook later tonight, join me!",
        "Just posted on Instagram, go like it haha",
        "Thanks for the follow! Following you back.",
        "Add me on Facebook, I'll send the request now.",
        "Check my TikTok when you have time.",
        "youtube",
        "Hi",
        "Hello po, good morning!",
        "ok thanks",
        "lol that's so funny",
        "Congrats on your promotion! You deserve it.",
        "Good luck on your exam tomorrow, you'll do great.",
        "Nag-upload ako ng bagong video sa YouTube, panoorin mo ha.",
        "Salamat sa pag-like ng post ko!",
        "Pwede mo ba i-share yung video sa group chat?",
        "See you later!",
        "Happy birthday! Let's celebrate this {day}.",
    ],
    "taglish_ok": [
        "Kumain ka na ba? Uuwi ako mamaya, may dala akong pasalubong.",
        "Salamat sa tulong kahapon! Ako na bahala sa susunod.",
        "Pwede mo ba ipadala yung notes natin sa group chat?",
        "Ingat ka pauwi, text mo ako pag nakarating ka na.",
        "Nandito na ako sa labas ng school, saan tayo magkikita?",
        "Nabayaran ko na yung bill natin sa bahay, wag ka na mag-alala.",
    ],
}

# How many filled variants per template (hand-written templates with no slots get 1 after dedupe).
VARIANTS = 6


def expand(templates: dict[str, list[str]], label: str, prefix: str) -> list[tuple[str, str, str, str]]:
    rows = []
    for category, items in templates.items():
        for i, template in enumerate(items):
            seen = set()
            for _ in range(VARIANTS):
                text = fill(template)
                if text in seen:
                    continue
                seen.add(text)
                rows.append((text, label, f"{prefix}:{category}:{i}", category))
    return rows


def main() -> None:
    rows: list[tuple[str, str, str, str]] = []
    if SEED_FILE.exists():
        with SEED_FILE.open(newline="", encoding="utf-8") as fh:
            for i, row in enumerate(csv.DictReader(fh)):
                rows.append((row["text"].strip(), row["label"].strip(), f"seed:{i}", "seed"))
    rows += expand(SCAM_TEMPLATES, "scam", "scam")
    rows += expand(NORMAL_TEMPLATES, "normal", "normal")

    # de-duplicate on normalised text, keep first
    unique, seen = [], set()
    for text, label, group, category in rows:
        key = " ".join(text.lower().split())
        if key in seen:
            continue
        seen.add(key)
        unique.append((text, label, group, category))
    rng.shuffle(unique)

    with OUT.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(["text", "label", "group", "category"])
        writer.writerows(unique)
    scams = sum(1 for r in unique if r[1] == "scam")
    print(f"Wrote {len(unique)} rows ({scams} scam / {len(unique) - scams} normal) to {OUT}")


if __name__ == "__main__":
    main()
