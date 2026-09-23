-- CyberGuard 3D — MySQL schema + seed data
-- Run: mysql -u root -p < schema.sql

CREATE DATABASE IF NOT EXISTS cyberguard3d CHARACTER SET utf8mb4;
USE cyberguard3d;

DROP TABLE IF EXISTS badges;
DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS scenarios;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    trust_score INT DEFAULT 0,
    preferred_language VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scenarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    room VARCHAR(50) NOT NULL,          -- phishing_inbox | upi_otp_kiosk | fake_login_corridor | password_vault_lab | safe_browsing_street
    title VARCHAR(150) NOT NULL,
    difficulty INT DEFAULT 1,
    is_fraud BOOLEAN NOT NULL,
    red_flags TEXT,
    correct_actions VARCHAR(100) NOT NULL,  -- comma-separated action_taken values considered correct
    content TEXT                             -- room-specific rich flavor content, JSON (see below)
);

CREATE TABLE results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    scenario_id INT NOT NULL,
    action_taken VARCHAR(30) NOT NULL,
    was_correct BOOLEAN NOT NULL,
    score_delta INT NOT NULL,
    response_time_ms INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (scenario_id) REFERENCES scenarios(id)
);

CREATE TABLE badges (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    badge_code VARCHAR(50) NOT NULL,   -- e.g. phishing_inbox_expert, upi_otp_kiosk_expert
    awarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- Seed scenarios — 3 per room minimum, mixing is_fraud TRUE/FALSE.
--
-- `content` is a JSON object of room-specific flavor content shown to the player BEFORE a
-- decision (never leaks is_fraud/correct_actions/red_flags). Shape per room:
--   phishing_inbox        : {sender_display, sender_domain, body, link_text, link_url}
--   upi_otp_kiosk          : {caller_name, caller_lines: [...]}
--   fake_login_corridor    : {domain, page_heading}
--   password_vault_lab     : {hint}
--   safe_browsing_street   : {domain, storefront_name, popup_text?}
--   rapid_fire             : {statement}
--   vulnerability_hunt     : {object_label}
--
-- Action vocabulary sent by the game client as `action_taken`, per room:
--   phishing_inbox        : opened | reported | deleted | ignored
--     (opened = clicking the in-body link directly, not a menu choice)
--   upi_otp_kiosk          : shared_otp | approved | declined
--   fake_login_corridor    : enter_credentials | leave_page | check_url | confirmed_legit
--     (check_url/confirmed_legit only fire after the player zooms into the domain to inspect it)
--   password_vault_lab     : strong | weak   (derived client-side from the live strength meter)
--   safe_browsing_street   : enter_site | check_certificate | leave
--   rapid_fire             : safe | unsafe   (one quick judgment per short statement)
--   vulnerability_hunt     : flag | ignore   (one judgment per explored hotspot)
-- ---------------------------------------------------------------------

INSERT INTO scenarios (code, room, title, difficulty, is_fraud, red_flags, correct_actions, content) VALUES
-- phishing_inbox
('phishing_inbox_01', 'phishing_inbox', 'Urgent: Complete Your Bank KYC Update', 1, TRUE,
 'Sender domain does not match the bank''s real domain, urgent threatening tone ("account will be blocked"), generic greeting ("Dear Customer"), link asks for full card details',
 'reported,deleted',
 '{"sender_display": "SBI Bank Support", "sender_domain": "kyc-update-sbi.net", "body": "Dear Customer, your SBI account will be suspended within 24 hours unless you verify your KYC details immediately. Click below to avoid service interruption.", "link_text": "Verify My Account Now", "link_url": "http://kyc-update-sbi.net/verify?id=88231"}'),
('phishing_inbox_02', 'phishing_inbox', 'Shared Project Document from Colleague', 1, FALSE,
 'None — sender matches a known contact''s real address, no suspicious links or attachments, professional and specific tone',
 'opened',
 '{"sender_display": "Priya Sharma", "sender_domain": "priya.sharma@company.com", "body": "Hi, sharing the Q3 project report we discussed in today''s meeting. Let me know if you have questions before Friday''s review.", "link_text": "Q3_Project_Report.pdf", "link_url": "https://company-drive.com/files/Q3_Project_Report.pdf"}'),
('phishing_inbox_03', 'phishing_inbox', 'Congratulations! You Won UPI Cashback', 2, TRUE,
 'Too-good-to-be-true cashback amount, shortened/obfuscated link, requests your UPI PIN which no legitimate offer ever needs',
 'reported,deleted',
 '{"sender_display": "UPI Rewards Team", "sender_domain": "upi-cashback-bonus.info", "body": "Congratulations! You are eligible for a Rs 5,000 UPI cashback. Offer expires today. Enter your UPI PIN on the linked page to claim your reward instantly.", "link_text": "Claim Rs 5,000 Cashback", "link_url": "http://bit.ly/3xUp1Cash"}'),
('phishing_inbox_04', 'phishing_inbox', 'Package Delivery Failed - Pay Redelivery Fee', 1, TRUE,
 'Sender domain is not India Post''s official domain, legitimate courier services do not charge redelivery fees via email links, urgency and threat of parcel return, generic tracking reference',
 'reported,deleted',
 '{"sender_display": "IndiaPost Delivery", "sender_domain": "delivery-indiapost-track.com", "body": "Your package could not be delivered due to an incomplete address. Pay a small redelivery fee of Rs 49 within 24 hours to reschedule delivery, or your parcel will be returned to sender.", "link_text": "Pay Redelivery Fee", "link_url": "http://delivery-indiapost-track.com/pay?track=IN44821903"}'),
('phishing_inbox_05', 'phishing_inbox', 'Your Flipkart Order Has Shipped', 1, FALSE,
 'None — sender domain matches Flipkart''s real domain, order details are specific and match a real purchase, link points to the official flipkart.com domain',
 'opened',
 '{"sender_display": "Flipkart", "sender_domain": "noreply@flipkart.com", "body": "Hi, your order #OD328471905 for Wireless Mouse has shipped and is expected to arrive by Thursday. Track your shipment anytime from the Flipkart app or website.", "link_text": "Track My Order", "link_url": "https://www.flipkart.com/track/OD328471905"}'),
('phishing_inbox_06', 'phishing_inbox', 'Work From Home - Earn Rs 5000 Daily, No Experience Needed', 2, TRUE,
 'Unrealistic guaranteed daily earnings for unskilled work, legitimate employers never ask candidates to pay a "registration fee", requests bank details before any actual hiring process, sender domain is not a real company',
 'reported,deleted',
 '{"sender_display": "HR Recruitment Team", "sender_domain": "careers-homejobs-apply.info", "body": "We are hiring for a simple data entry job you can do from home. Earn Rs 5000 per day guaranteed. To secure your position, pay a refundable registration fee of Rs 999 and share your bank details for salary processing.", "link_text": "Apply Now & Pay Registration Fee", "link_url": "http://careers-homejobs-apply.info/register"}'),
('phishing_inbox_07', 'phishing_inbox', 'Re: Tomorrow''s Team Meeting', 1, FALSE,
 'None — sender is a known colleague''s real address, content is specific and expected, link points to the internal company-drive.com domain already used for legitimate files',
 'opened',
 '{"sender_display": "Arjun Mehta", "sender_domain": "arjun.mehta@company.com", "body": "Hi, just confirming we''re moving tomorrow''s 10am team meeting to the 3rd floor conference room. I''ve attached the updated agenda for reference.", "link_text": "Meeting_Agenda.pdf", "link_url": "https://company-drive.com/files/Meeting_Agenda.pdf"}'),

-- upi_otp_kiosk
('upi_otp_kiosk_01', 'upi_otp_kiosk', 'Caller Requests OTP to "Verify Your Account"', 1, TRUE,
 'Banks and UPI apps never ask for your OTP over a phone call, request is unsolicited, caller manufactures urgency to rush you',
 'declined',
 '{"caller_name": "Unknown Caller", "caller_lines": ["Hello, I''m calling from your bank''s security department.", "We''ve detected suspicious activity on your account just now.", "To verify it''s really you, please read out the OTP you just received."]}'),
('upi_otp_kiosk_02', 'upi_otp_kiosk', 'Payment Confirmation from Known Merchant', 1, FALSE,
 'None — amount matches your actual purchase, merchant name is recognized, no OTP or PIN requested outside the app',
 'approved',
 '{"caller_name": "PhonePe Payment Request", "caller_lines": ["Payment request received from Ramesh General Store.", "Amount: Rs 450.00", "This matches your recent purchase at the store."]}'),
('upi_otp_kiosk_03', 'upi_otp_kiosk', 'Incoming "Refund" Collect Request', 2, TRUE,
 'Genuine refunds are credited automatically and never require you to approve a collect/payment request, requester is unknown, pressure to approve quickly',
 'declined',
 '{"caller_name": "Incoming Collect Request", "caller_lines": ["You have an incoming refund request for Rs 2,000.", "Note: approving a collect request DEBITS money from your account, not credit it.", "Genuine refunds are credited automatically and never need your approval."]}'),
('upi_otp_kiosk_04', 'upi_otp_kiosk', 'Fake Customer Care Calls Back After Complaint', 2, TRUE,
 'You never filed a complaint, so this callback is unsolicited, no genuine customer care resolves issues by asking for your OTP, artificial urgency to "fix" a problem you didn''t report',
 'declined',
 '{"caller_name": "Bank Customer Care Callback", "caller_lines": ["Hello, this is customer care returning your recent complaint call.", "To resolve your issue immediately, please share the OTP sent to your registered mobile.", "This will help us verify and fix your account right away."]}'),
('upi_otp_kiosk_05', 'upi_otp_kiosk', 'Electricity Bill Autopay Confirmation', 1, FALSE,
 'None — amount matches your known monthly bill, biller name is recognized and already set up for autopay, no OTP or PIN requested outside the app',
 'approved',
 '{"caller_name": "Electricity Board Autopay", "caller_lines": ["Scheduled autopay request from State Electricity Board.", "Amount: Rs 1,240.00", "This matches your monthly electricity bill due today."]}'),
('upi_otp_kiosk_06', 'upi_otp_kiosk', 'You''ve Won a Lucky Draw - Claim via UPI Request', 1, TRUE,
 'Genuine prizes are never claimed by approving a payment request, "verification" collect requests are a common scam to debit money or harvest your UPI PIN, you never entered this lucky draw',
 'declined',
 '{"caller_name": "Lucky Draw Winnings", "caller_lines": ["Congratulations! You''ve been selected in our festival lucky draw.", "To receive your Rs 10,000 prize, approve the small Rs 1 verification collect request.", "Approve now before the offer window closes."]}'),
('upi_otp_kiosk_07', 'upi_otp_kiosk', 'Friend Requesting Dinner Split via UPI', 1, FALSE,
 'None — request is from a saved contact you know personally, amount is small and matches a real shared expense, no OTP or PIN requested outside the app',
 'approved',
 '{"caller_name": "Rohit Verma (Collect Request)", "caller_lines": ["Collect request from Rohit Verma, saved contact.", "Amount: Rs 350.00", "Note: For last night''s dinner split."]}'),

-- fake_login_corridor
('fake_login_corridor_01', 'fake_login_corridor', 'Bank Login Page (from SMS link)', 1, TRUE,
 'Domain is a lookalike ("secure-sbi-login.net") not the bank''s official domain, "account suspended" scare message, reached via an unsolicited SMS link',
 'check_url,leave_page',
 '{"domain": "secure-sbi-login.net", "page_heading": "SBI Net Banking - Account Suspended"}'),
('fake_login_corridor_02', 'fake_login_corridor', 'Bank Login Page (typed manually)', 1, FALSE,
 'None — domain matches the bank''s official site exactly, valid HTTPS certificate, reached by typing the address yourself',
 'enter_credentials,confirmed_legit',
 '{"domain": "www.onlinesbi.sbi", "page_heading": "SBI Net Banking - Login"}'),
('fake_login_corridor_03', 'fake_login_corridor', 'Social Media Login (from ad link)', 2, TRUE,
 'Lookalike domain with extra words ("facebook-secure-verify.com"), credentials requested on a page reached via an unsolicited ad/link, no valid certificate for the real site',
 'check_url,leave_page',
 '{"domain": "facebook-secure-verify.com", "page_heading": "Facebook - Verify Your Identity"}'),
('fake_login_corridor_04', 'fake_login_corridor', 'Email Login Page (password reset link)', 2, TRUE,
 'Domain is not google.com or accounts.google.com, page reached via an unsolicited "unusual activity" link, urgent security-scare framing designed to rush a credential entry',
 'check_url,leave_page',
 '{"domain": "gmail-account-security-check.com", "page_heading": "Google Account - Unusual Sign-In Activity"}'),
('fake_login_corridor_05', 'fake_login_corridor', 'Email Login Page (typed manually)', 1, FALSE,
 'None — domain matches Google''s official accounts domain exactly, valid HTTPS certificate, reached by typing the address yourself',
 'enter_credentials,confirmed_legit',
 '{"domain": "accounts.google.com", "page_heading": "Google - Sign in to your account"}'),
('fake_login_corridor_06', 'fake_login_corridor', 'UPI App Login Page (from SMS link)', 1, TRUE,
 'Lookalike domain with extra words not matching paytm.com, reached via an unsolicited SMS link, "complete KYC to continue" framing pressures you to log in immediately',
 'check_url,leave_page',
 '{"domain": "paytm-secure-kyc-update.net", "page_heading": "Paytm - Complete Your KYC to Continue"}'),
('fake_login_corridor_07', 'fake_login_corridor', 'Social Media Login Page (typed manually)', 1, FALSE,
 'None — domain matches Instagram''s official site exactly, valid HTTPS certificate, reached by typing the address yourself',
 'enter_credentials,confirmed_legit',
 '{"domain": "www.instagram.com", "page_heading": "Instagram - Log in"}'),

-- password_vault_lab (not fraud-based — strength evaluated client-side in real time)
('password_vault_lab_01', 'password_vault_lab', 'Set Your Vault Master Password', 1, FALSE,
 'Avoid common dictionary words and keyboard patterns, avoid reusing your name/birth year, aim for 12+ characters mixing upper/lowercase, digits, and symbols',
 'strong',
 '{"hint": "This vault protects real financial data - treat it like a bank password."}'),
('password_vault_lab_02', 'password_vault_lab', 'Create a Recovery Passphrase', 2, FALSE,
 'A long random passphrase beats a short complex one — combine unrelated words, avoid personal information, avoid reusing passwords from other sites',
 'strong',
 '{"hint": "A long random passphrase beats a short complex one."}'),
('password_vault_lab_03', 'password_vault_lab', 'Set an Admin Vault Key', 2, FALSE,
 'Admin-level credentials need the highest strength — avoid predictable substitutions like "P@ssw0rd", avoid short lengths even with symbols',
 'strong',
 '{"hint": "Admin-level credentials need the highest possible strength."}'),
('password_vault_lab_04', 'password_vault_lab', 'Set a Password for Your Email Account', 1, FALSE,
 'Avoid using the same password as other accounts, avoid dictionary words, use a mix of unrelated words or random characters with 12+ length',
 'strong',
 '{"hint": "This inbox is the recovery point for most of your other accounts - a breach here cascades everywhere."}'),
('password_vault_lab_05', 'password_vault_lab', 'Create a Wi-Fi Router Password', 1, FALSE,
 'Avoid the router''s default password, avoid simple number sequences, aim for a long unique passphrase not used anywhere else',
 'strong',
 '{"hint": "Anyone within range of your home network could try to guess a weak router password."}'),
('password_vault_lab_06', 'password_vault_lab', 'Set a Password for a New Social Media Account', 2, FALSE,
 'Avoid anything guessable from your public profile, avoid short passwords even if they feel clever, use a password manager-generated string if possible',
 'strong',
 '{"hint": "Attackers often try passwords built from your public profile info first - birthdays, pet names, hometowns."}'),
('password_vault_lab_07', 'password_vault_lab', 'Create a Shared Team Vault Password', 2, FALSE,
 'Avoid simple substitutions like "Team@123", avoid short lengths, prefer a long memorable passphrase the whole team can type reliably',
 'strong',
 '{"hint": "Multiple teammates will type this password - it should stay strong without becoming impossible to type correctly."}'),

-- safe_browsing_street
('safe_browsing_street_01', 'safe_browsing_street', 'Discount Electronics Store (HTTP only)', 1, TRUE,
 'No HTTPS/padlock on a page asking for payment details, generic unfamiliar domain, prices far below market rate',
 'leave,check_certificate',
 '{"domain": "http://mega-discount-electronics.xyz", "storefront_name": "Mega Discount Electronics"}'),
('safe_browsing_street_02', 'safe_browsing_street', 'Well-Known Retailer (HTTPS)', 1, FALSE,
 'None — valid HTTPS certificate, familiar established domain, no unusual pop-ups or urgency tactics',
 'enter_site',
 '{"domain": "https://www.amazon.in", "storefront_name": "Amazon India"}'),
('safe_browsing_street_03', 'safe_browsing_street', 'Storefront with "You''ve Won a Prize!" Popup', 2, TRUE,
 'Unsolicited prize popup interrupting checkout, urgency countdown timer, requests personal details to "claim" a prize you never entered to win',
 'leave,check_certificate',
 '{"domain": "https://trusted-shop-example.com", "storefront_name": "Trusted Shop", "popup_text": "Congratulations! You''ve Won a Free iPhone! Click Claim Now to receive your prize."}'),
('safe_browsing_street_04', 'safe_browsing_street', 'Flash Sale Furniture Store (HTTP only)', 1, TRUE,
 'No HTTPS/padlock on a page collecting payment details, unfamiliar domain with a generic "sale" name, countdown timer pressuring an immediate purchase',
 'leave,check_certificate',
 '{"domain": "http://superdeal-furniture-sale.xyz", "storefront_name": "SuperDeal Furniture Sale"}'),
('safe_browsing_street_05', 'safe_browsing_street', 'Well-Known Grocery Delivery (HTTPS)', 1, FALSE,
 'None — valid HTTPS certificate, familiar established domain, no unusual pop-ups or urgency tactics',
 'enter_site',
 '{"domain": "https://www.bigbasket.com", "storefront_name": "BigBasket"}'),
('safe_browsing_street_06', 'safe_browsing_street', 'Storefront with Fake "Browser Out of Date" Popup', 2, TRUE,
 'Legitimate sites never ask you to "update your browser" through an in-page popup, this is a common tactic to trick you into downloading malware, popup interrupts checkout with urgency',
 'leave,check_certificate',
 '{"domain": "https://deal-hub-shopping.com", "storefront_name": "Deal Hub Shopping", "popup_text": "Warning! Your browser is out of date and unsafe. Click Update Now to install the latest security patch before continuing to shop."}'),
('safe_browsing_street_07', 'safe_browsing_street', 'Well-Known Clothing Retailer (HTTPS)', 1, FALSE,
 'None — valid HTTPS certificate, familiar established domain, no unusual pop-ups or urgency tactics',
 'enter_site',
 '{"domain": "https://www.myntra.com", "storefront_name": "Myntra"}'),

-- rapid_fire: short mixed-topic statements, judged SAFE or UNSAFE under time pressure
('rapid_fire_01', 'rapid_fire', 'Unsolicited Password Verification Email', 1, TRUE,
 'Unknown email asking you to "verify" your password by clicking a link is a classic phishing pattern',
 'unsafe',
 '{"statement": "An unknown email asks you to verify your password by clicking a link."}'),
('rapid_fire_02', 'rapid_fire', 'Unexpected Executable from a Friend', 1, TRUE,
 'Unexpected executable files can carry malware even from a real contact whose account may be compromised',
 'unsafe',
 '{"statement": "A friend sends you an executable file you were not expecting."}'),
('rapid_fire_03', 'rapid_fire', 'Caller Requests Your OTP', 1, TRUE,
 'No legitimate bank or service ever asks you to read out your OTP over a call',
 'unsafe',
 '{"statement": "Someone on a phone call asks you to read out your OTP to verify your identity."}'),
('rapid_fire_04', 'rapid_fire', 'Valid HTTPS on the Official Domain', 1, FALSE,
 'A valid certificate on the real, matching domain is exactly what safe browsing looks like',
 'safe',
 '{"statement": "A website you are on shows a valid HTTPS padlock and matches the official domain."}'),
('rapid_fire_05', 'rapid_fire', 'Prize Popup Requesting Card Details', 1, TRUE,
 'Unsolicited prize claims that request payment card details are a common scam pattern',
 'unsafe',
 '{"statement": "A pop-up says you have won a prize and asks you to enter your card details to claim it."}'),
('rapid_fire_06', 'rapid_fire', 'Bank App Confirms Your Own Login', 1, FALSE,
 'A confirmation prompt for a login you actually just performed yourself is normal MFA behavior',
 'safe',
 '{"statement": "Your bank app asks you to confirm a login you just attempted yourself."}'),
('rapid_fire_07', 'rapid_fire', '10-Minute Account Suspension Threat', 2, TRUE,
 'Artificial urgency ("act within minutes or lose access") is a manipulation tactic, not how real account issues are handled',
 'unsafe',
 '{"statement": "A message urges you to act within 10 minutes or lose access to your account."}'),
('rapid_fire_08', 'rapid_fire', 'Expected Calendar Invite from a Colleague', 1, FALSE,
 'An expected invite from a real colleague for a meeting you already knew about carries no red flags',
 'safe',
 '{"statement": "You receive a calendar invite from a colleague for a meeting you already expected."}'),
('rapid_fire_09', 'rapid_fire', 'Flyer QR Code Promising Cashback', 2, TRUE,
 'Random QR codes promising cashback for scanning-and-paying are a common UPI scam vector',
 'unsafe',
 '{"statement": "A QR code on a random flyer promises cashback if you scan it and make a payment."}'),
('rapid_fire_10', 'rapid_fire', 'OS Update via Official Settings App', 1, FALSE,
 'Updating through your device''s own official settings app is the safe, standard way to patch software',
 'safe',
 '{"statement": "You update your phone''s operating system through the official system settings app."}'),

-- vulnerability_hunt: explore a small office scene, judge each prop as a real vulnerability or not
('vulnerability_hunt_01', 'vulnerability_hunt', 'Sticky Note on the Monitor', 1, TRUE,
 'A password written on a sticky note in plain view is an exposed credential anyone nearby can read',
 'flag',
 '{"object_label": "Sticky Note with a Password Written on It"}'),
('vulnerability_hunt_02', 'vulnerability_hunt', 'Unattended Unlocked Workstation', 1, TRUE,
 'An unlocked, unattended computer gives anyone who walks by full access to the logged-in account',
 'flag',
 '{"object_label": "Unattended Computer, Unlocked and Logged In"}'),
('vulnerability_hunt_03', 'vulnerability_hunt', 'Unknown USB Drive Plugged In', 2, TRUE,
 'Unknown USB drives are a classic malware delivery method (a "USB drop" attack) and should never be trusted',
 'flag',
 '{"object_label": "Unknown USB Drive Plugged Into the Computer"}'),
('vulnerability_hunt_04', 'vulnerability_hunt', 'Locked Filing Cabinet', 1, FALSE,
 'None — a properly locked cabinet is standard, appropriate physical security for sensitive paperwork',
 'ignore',
 '{"object_label": "Filing Cabinet, Locked"}'),
('vulnerability_hunt_05', 'vulnerability_hunt', 'Encrypted External Backup Drive', 2, FALSE,
 'None — an encrypted backup drive, properly labeled and stored, is a safe and responsible backup practice',
 'ignore',
 '{"object_label": "External Backup Drive, Labeled and Encrypted"}');
