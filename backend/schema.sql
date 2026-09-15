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
