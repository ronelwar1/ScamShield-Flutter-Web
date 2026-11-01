/// Offline reference content about how scams work. Scam type ids match the `scam_type.id` values returned by the API.
/// This is general information, not a legal or financial guide, and it makes no claims about statistics.
class ScamGuide {
  const ScamGuide({
    required this.id,
    required this.emoji,
    required this.title,
    required this.tagline,
    required this.howItWorks,
    required this.steps,
    required this.whyItWorks,
    required this.redFlags,
    required this.whatToDo,
    required this.example,
  });

  final String id;
  final String emoji;
  final String title;
  final String tagline;

  /// One short paragraph: what the scam is.
  final String howItWorks;

  /// How it usually unfolds, in order.
  final List<String> steps;

  /// The reason people fall for it.
  final String whyItWorks;
  final List<String> redFlags;
  final List<String> whatToDo;
  final String example;
}

/// The common shape behind most scams, in order.
const List<(String, String)> scamPlaybook = [
  ('The approach', 'A message, call, ad or friend request arrives unasked. It may look like it comes from a bank, courier, employer, government office or someone you know.'),
  ('The story', 'A believable reason to act: your account is locked, a parcel is held, you won something, a job is waiting, a relative is in trouble.'),
  ('The pressure', 'Fear, hurry, excitement or secrecy, so you act before you think or check with anyone.'),
  ('The ask', 'Something hard to undo: a code, a password, a payment to a personal account, ID photos, or remote access to your device.'),
  ('The aftermath', 'Once you comply, the scammer vanishes, or invents a new reason to ask for more.'),
];

/// Why these scams work, even on careful people.
const List<(String, String)> scamLevers = [
  ('Fear', 'Threats of blocked accounts, arrest or lost money make people act first and think later.'),
  ('Urgency', 'A short deadline leaves no time to check. Real organisations rarely need an answer in minutes.'),
  ('Excitement', 'A prize, a high-paying job or a "sure" investment makes people want it to be true.'),
  ('Trust', 'Logos, official wording, a familiar name or a friend\'s hacked account borrow credibility that is not theirs.'),
  ('Secrecy', 'Being told to keep it quiet cuts you off from the people who would say "that sounds wrong".'),
];

const List<ScamGuide> scamGuides = [
  ScamGuide(
    id: 'phishing',
    emoji: '🎣',
    title: 'Phishing',
    tagline: 'A fake "bank", wallet or app message that goes after your login.',
    howItWorks:
        'Phishing is a message that pretends to be from an organisation you use, such as a bank, e-wallet, courier or social '
        'network, in order to collect your login details or one-time codes.',
    steps: [
      'A text, email or chat message says your account is locked, limited or needs "verification".',
      'A link leads to a copy of the real site, or you are asked to reply with a code.',
      'Whatever you type goes straight to the scammer.',
      'They log in to the real account at once, before the code expires or you notice.',
    ],
    whyItWorks:
        'The fake pages are copied from the real ones, and the message arrives at a moment when you may really have an account '
        'with that company. Fear of losing access makes it feel like there is no time to check.',
    redFlags: [
      'Asks for your password, PIN or OTP',
      'A link that is not the organisation\'s real website',
      'Threatens to close or block your account',
      'Generic greeting like "Dear customer"',
    ],
    whatToDo: [
      'Open the official app or type the website yourself instead of tapping the link.',
      'An OTP is for you alone. Real staff never need it.',
      'If you already entered details, change your password and call the real provider.',
    ],
    example: 'GCash ALERT: Your account is limited. Verify now at gcash-verify.top',
  ),
  ScamGuide(
    id: 'prize',
    emoji: '🎁',
    title: 'Fake prizes',
    tagline: 'You "won" something you never entered for.',
    howItWorks:
        'A surprise prize, raffle or reward arrives by message. The prize does not exist; the goal is your personal details or '
        'a small "fee".',
    steps: [
      'You are told you were picked for a raffle, giveaway or loyalty reward.',
      'To "claim" it you must tap a link, fill in personal details or pay a shipping or tax fee.',
      'After the first payment, there is a second fee, or the contact disappears.',
    ],
    whyItWorks:
        'Winning feels good, and a small fee next to a big prize seems like a fair trade. The details you hand over can also '
        'be reused for other scams.',
    redFlags: [
      'You never joined any contest',
      'You must pay a fee to receive the prize',
      'A countdown or "claim today" pressure',
    ],
    whatToDo: [
      'If you did not enter, there is no prize.',
      'Real prizes do not ask you to pay to receive them.',
      'Check the contest on the company\'s official page.',
    ],
    example: 'Congratulations! You won an iPhone 15. Pay PHP 500 shipping to claim.',
  ),
  ScamGuide(
    id: 'advance_fee',
    emoji: '📦',
    title: 'Fake fee scams',
    tagline: 'Pay a "small fee" first and the parcel, loan or refund will come. It does not.',
    howItWorks:
        'The scammer claims a parcel is held, a loan is approved or a refund is waiting, and asks for a processing, customs or '
        'release fee up front.',
    steps: [
      'A message says something valuable is waiting for you: a parcel, a loan, a refund, an inheritance.',
      'One more step is needed: a processing, customs, insurance or release fee.',
      'You pay to a personal e-wallet or bank account.',
      'New fees appear, or the contact vanishes.',
    ],
    whyItWorks:
        'The fee is small compared with what is promised, and each payment makes it harder to stop, because stopping feels '
        'like losing what you already paid.',
    redFlags: [
      'Fees for releasing a parcel, loan or refund',
      'Payment to a personal e-wallet or bank account',
      'A parcel you were not expecting',
    ],
    whatToDo: [
      'Check parcels in the courier\'s own app using your tracking number.',
      'Real lenders deduct fees from the loan; they do not ask for money up front.',
      'Do not pay "just to release" anything.',
    ],
    example: 'Your parcel is on hold. Pay PHP 1,500 customs fee at bit.ly/xyz',
  ),
  ScamGuide(
    id: 'investment',
    emoji: '📈',
    title: 'Investment & crypto',
    tagline: 'Guaranteed profits with "no risk". Every real investment carries risk.',
    howItWorks:
        'You are invited to a trading group or app that shows impressive profits. The profits on screen are fake, and the money '
        'you deposit goes to the scammer.',
    steps: [
      'A stranger, a "mentor" or a group chat shows screenshots of big gains.',
      'You deposit a small amount into an app or website they point you to.',
      'The app shows growth, and a small withdrawal may even work, to build trust.',
      'You are pushed to deposit much more, or to recruit friends.',
      'When you try to cash out, the account is frozen or a "tax" or "unlock fee" is demanded.',
    ],
    whyItWorks:
        'Seeing profit on a screen feels like proof, and an early successful withdrawal makes the whole thing seem real. '
        'Fear of missing out then does the rest.',
    redFlags: [
      'Guaranteed returns or "double your money"',
      'Pressure to recruit friends or deposit quickly',
      'Contact came from a stranger or random group chat',
    ],
    whatToDo: [
      'No one can guarantee profit. Treat the promise itself as the warning.',
      'Check that the company is registered with your securities regulator.',
      'Talk to someone you trust before sending money.',
    ],
    example: 'Invest PHP 5,000 and earn 30% weekly. Guaranteed. No risk!',
  ),
  ScamGuide(
    id: 'job_task',
    emoji: '💼',
    title: 'Job & task scams',
    tagline: 'Easy money for liking videos or rating products.',
    howItWorks:
        'A "recruiter" offers high pay for simple online tasks. The real aim is to get you to pay money or hand over your ID and '
        'bank details.',
    steps: [
      'A recruiter messages you on a chat app with a high-paying, easy job.',
      'You complete a few simple tasks and receive small payouts.',
      'To unlock bigger tasks you must "top up", "deposit" or buy something first.',
      'Others ask for fees for training or a uniform, or for your ID and bank account number.',
      'Once you stop paying, the payouts stop and the contact disappears.',
    ],
    whyItWorks:
        'The first payouts are real and small, which builds trust. Money already put in makes people reluctant to walk away.',
    redFlags: [
      'High pay for very easy work',
      'You must pay for training, a uniform or a "deposit"',
      'Recruiting through chat apps only',
    ],
    whatToDo: [
      'Legitimate employers do not charge you to start working.',
      'Research the company and contact it through its official website.',
      'Hold back ID photos and bank details until you have a verified contract.',
    ],
    example: 'Earn PHP 5,000 a day just by liking videos. Message us on Telegram.',
  ),
  ScamGuide(
    id: 'tech_support',
    emoji: '🖥️',
    title: 'Tech-support scams',
    tagline: '"Your device is infected!" (It is not.)',
    howItWorks:
        'A pop-up or message claims your device has a virus and gives a phone number. The "technician" wants control of your '
        'device or your payment.',
    steps: [
      'A pop-up, text or call says your computer or account has been hacked.',
      'You are told to call a number or install a "support" tool.',
      'The tool, such as AnyDesk or TeamViewer, gives them remote control of your screen.',
      'They show you fake "proof" of an infection, then ask for payment or access your banking.',
    ],
    whyItWorks:
        'Browser pop-ups can look alarming and official, and most people cannot tell a real warning from a fake one. '
        'Once someone is guiding you step by step, it is hard to stop.',
    redFlags: [
      'Unsolicited virus warnings',
      'Asks you to install AnyDesk, TeamViewer or similar',
      'A phone number to call urgently',
    ],
    whatToDo: [
      'Close the page. Real warnings from your system do not include a phone number.',
      'Remote access gives someone full control, so only allow it to people you contacted yourself.',
      'Run a scan with security software you installed yourself.',
    ],
    example: 'Microsoft Support: your computer is infected. Call now and install AnyDesk.',
  ),
  ScamGuide(
    id: 'emergency',
    emoji: '🆘',
    title: 'Emergency & impersonation',
    tagline: '"Hi Mom, new number. Please send money." It is not your child.',
    howItWorks:
        'The scammer pretends to be a relative or friend in trouble, often from a "new number", or uses a hacked account. They ask '
        'for urgent money.',
    steps: [
      'A message arrives from an unknown number, or from a friend\'s hacked account, saying "it\'s me".',
      'There is a problem: a lost phone, an accident, a bill that must be paid today.',
      'You are asked to send money to an e-wallet or buy gift cards, and to keep it quiet.',
      'Once you send, a second emergency often follows.',
    ],
    whyItWorks:
        'It targets love and worry. In a moment of panic about someone you care for, checking feels less important than helping.',
    redFlags: [
      '"New number" or "lost my phone"',
      'Urgent money request and secrecy',
      'Asks for gift cards or e-wallet transfers',
    ],
    whatToDo: [
      'Call the person on the number you already have.',
      'Ask a question only the real person could answer.',
      'Some families agree on a "safe word" for emergencies.',
    ],
    example: 'Hi Mom, I lost my phone. Please send PHP 5,000 to this GCash. Don\'t tell Dad.',
  ),
  ScamGuide(
    id: 'authority',
    emoji: '👮',
    title: 'Fake authority threats',
    tagline: 'Threats of arrest, fines or disconnection unless you pay now.',
    howItWorks:
        'Scammers pretend to be police, courts, tax or utility staff and demand immediate payment, usually to a personal account.',
    steps: [
      'A call or text claims you owe a fine, have an unpaid bill or are linked to a crime.',
      'It threatens arrest, a warrant or a shut-off if you do not act now.',
      'You are told not to talk to anyone, and to stay on the line.',
      'You are given a personal account or e-wallet to pay.',
    ],
    whyItWorks:
        'Official-sounding language and fear of trouble with the law overrides the question "why would they text me this?".',
    redFlags: [
      'Threat of arrest or legal action by text',
      'Payment demanded immediately',
      'Told not to talk to anyone',
    ],
    whatToDo: [
      'Real agencies do not demand instant payment by message.',
      'Look up the agency\'s official contact details and call them yourself.',
      'You can hang up or stop replying at any time.',
    ],
    example: 'Final warning: pay PHP 3,000 today or a warrant of arrest will be issued.',
  ),
];

ScamGuide? guideForId(String id) {
  for (final g in scamGuides) {
    if (g.id == id) return g;
  }
  return null;
}

const List<String> dailyTips = [
  'Legit banks never ask for your OTP. Not by text, not by call, not ever.',
  'Pause for 10 seconds before you tap. Scammers need you to hurry.',
  'Type the website address yourself instead of tapping a link in a message.',
  'If a "friend" asks for money from a new number, call their old number first.',
  'Real prizes never charge a fee to claim them.',
  'Turn on two-step verification for your email and e-wallet.',
  'Shortened links hide where they go. Ask for the full address.',
  'Use a different password for every important account.',
  'Screenshots are evidence. Keep them before you delete a scam message.',
  'Talk to someone you trust before sending money to a stranger.',
  'No legit job charges you to start working.',
  'If it sounds too good to be true, it usually is.',
];

String tipOfTheDay([DateTime? now]) {
  final d = now ?? DateTime.now();
  final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
  return dailyTips[dayOfYear % dailyTips.length];
}

/// "I think I got scammed" help flows.
class RecoveryScenario {
  const RecoveryScenario({required this.id, required this.emoji, required this.title, required this.steps});
  final String id;
  final String emoji;
  final String title;
  final List<String> steps;
}

const List<RecoveryScenario> recoveryScenarios = [
  RecoveryScenario(
    id: 'shared_code',
    emoji: '🔑',
    title: 'I shared an OTP, PIN or password',
    steps: [
      'Open the real app (or type its website yourself) and change the password right now.',
      'Contact the bank or e-wallet through the official number in its app or on your card and ask them to secure or freeze the account.',
      'Check your recent transactions and report any you do not recognise.',
      'Turn on two-step verification wherever it is offered.',
      'If you reuse that password anywhere else, change it there too.',
      'Expect follow-up scam calls. Do not share anything else.',
    ],
  ),
  RecoveryScenario(
    id: 'sent_money',
    emoji: '💸',
    title: 'I sent money',
    steps: [
      'Contact your bank or e-wallet immediately and ask whether the transfer can be flagged or recalled. Speed matters.',
      'Take screenshots of the messages, account numbers, receipts and profiles involved.',
      'Stop all contact with the scammer. Do not pay any "recovery fee"; that is a second scam.',
      'Report it to the platform where it happened and to your local cybercrime or consumer-protection authority.',
      'Warn family and friends so they do not get the same message.',
    ],
  ),
  RecoveryScenario(
    id: 'clicked_link',
    emoji: '🔗',
    title: 'I clicked a link',
    steps: [
      'Close the page. Do not type anything into it.',
      'If you typed a password or code, change it immediately from the official app.',
      'Do not install anything the page asks for. If something was downloaded, delete it and run a security scan.',
      'Check your app permissions and recent logins for anything unfamiliar.',
      'Keep the link text (do not tap it again) in case you want to report it.',
    ],
  ),
  RecoveryScenario(
    id: 'remote_access',
    emoji: '🖥️',
    title: 'I gave someone remote access',
    steps: [
      'Disconnect the device from the internet (Wi-Fi off, unplug cable) right away.',
      'Uninstall the remote-access app, then run a full security scan.',
      'From a different, clean device, change your email, banking and e-wallet passwords.',
      'Call your bank using the official number and tell them your device was compromised.',
      'If you are unsure the device is clean, back up your files and reset it.',
    ],
  ),
  RecoveryScenario(
    id: 'shared_id',
    emoji: '🪪',
    title: 'I shared ID or personal details',
    steps: [
      'Note exactly what you shared (ID photo, birthdate, address, selfie).',
      'Contact the organisation that issued the ID and ask what protections are available.',
      'Watch your accounts and any credit or loan notices for activity you did not start.',
      'Change security questions and passwords that use that personal information.',
      'Be extra careful with unexpected calls or messages that mention your details.',
    ],
  ),
];

const List<String> whereToReport = [
  'Your bank or e-wallet (use the official number in its app or on your card).',
  'The platform where it happened: SMS provider, Facebook, Telegram, marketplace.',
  'Your country\'s cybercrime or consumer-protection authority. Check its official website for current contact options.',
  'Friends and family, so they can watch for the same scam.',
];
