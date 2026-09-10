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
    correct_actions VARCHAR(100) NOT NULL  -- comma-separated action_taken values considered correct
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
-- Action vocabulary sent by the game client as `action_taken`, per room:
--   phishing_inbox        : opened | reported | deleted | ignored
--   upi_otp_kiosk          : approve | decline | verify_first
--   fake_login_corridor    : enter_credentials | check_url | leave_page
--   password_vault_lab     : strong | weak   (derived client-side from the live strength meter)
--   safe_browsing_street   : enter_site | check_certificate | leave
-- ---------------------------------------------------------------------

INSERT INTO scenarios (code, room, title, difficulty, is_fraud, red_flags, correct_actions) VALUES
-- phishing_inbox
('phishing_inbox_01', 'phishing_inbox', 'Urgent: Complete Your Bank KYC Update', 1, TRUE,
 'Sender domain does not match the bank''s real domain, urgent threatening tone ("account will be blocked"), generic greeting ("Dear Customer"), link asks for full card details',
 'reported,deleted'),
('phishing_inbox_02', 'phishing_inbox', 'Shared Project Document from Colleague', 1, FALSE,
 'None — sender matches a known contact''s real address, no suspicious links or attachments, professional and specific tone',
 'opened'),
('phishing_inbox_03', 'phishing_inbox', 'Congratulations! You Won UPI Cashback', 2, TRUE,
 'Too-good-to-be-true cashback amount, shortened/obfuscated link, requests your UPI PIN which no legitimate offer ever needs',
 'reported,deleted'),

-- upi_otp_kiosk
('upi_otp_kiosk_01', 'upi_otp_kiosk', 'Caller Requests OTP to "Verify Your Account"', 1, TRUE,
 'Banks and UPI apps never ask for your OTP over a phone call, request is unsolicited, caller manufactures urgency to rush you',
 'decline'),
('upi_otp_kiosk_02', 'upi_otp_kiosk', 'Payment Confirmation from Known Merchant', 1, FALSE,
 'None — amount matches your actual purchase, merchant name is recognized, no OTP or PIN requested outside the app',
 'approve'),
('upi_otp_kiosk_03', 'upi_otp_kiosk', 'Incoming "Refund" Collect Request', 2, TRUE,
 'Genuine refunds are credited automatically and never require you to approve a collect/payment request, requester is unknown, pressure to approve quickly',
 'decline,verify_first'),

-- fake_login_corridor
('fake_login_corridor_01', 'fake_login_corridor', 'Bank Login Page (from SMS link)', 1, TRUE,
 'Domain is a lookalike ("secure-sbi-login.net") not the bank''s official domain, "account suspended" scare message, reached via an unsolicited SMS link',
 'check_url,leave_page'),
('fake_login_corridor_02', 'fake_login_corridor', 'Bank Login Page (typed manually)', 1, FALSE,
 'None — domain matches the bank''s official site exactly, valid HTTPS certificate, reached by typing the address yourself',
 'enter_credentials'),
('fake_login_corridor_03', 'fake_login_corridor', 'Social Media Login (from ad link)', 2, TRUE,
 'Lookalike domain with extra words ("facebook-secure-verify.com"), credentials requested on a page reached via an unsolicited ad/link, no valid certificate for the real site',
 'check_url,leave_page'),

-- password_vault_lab (not fraud-based — strength evaluated client-side in real time)
('password_vault_lab_01', 'password_vault_lab', 'Set Your Vault Master Password', 1, FALSE,
 'Avoid common dictionary words and keyboard patterns, avoid reusing your name/birth year, aim for 12+ characters mixing upper/lowercase, digits, and symbols',
 'strong'),
('password_vault_lab_02', 'password_vault_lab', 'Create a Recovery Passphrase', 2, FALSE,
 'A long random passphrase beats a short complex one — combine unrelated words, avoid personal information, avoid reusing passwords from other sites',
 'strong'),
('password_vault_lab_03', 'password_vault_lab', 'Set an Admin Vault Key', 2, FALSE,
 'Admin-level credentials need the highest strength — avoid predictable substitutions like "P@ssw0rd", avoid short lengths even with symbols',
 'strong'),

-- safe_browsing_street
('safe_browsing_street_01', 'safe_browsing_street', 'Discount Electronics Store (HTTP only)', 1, TRUE,
 'No HTTPS/padlock on a page asking for payment details, generic unfamiliar domain, prices far below market rate',
 'leave,check_certificate'),
('safe_browsing_street_02', 'safe_browsing_street', 'Well-Known Retailer (HTTPS)', 1, FALSE,
 'None — valid HTTPS certificate, familiar established domain, no unusual pop-ups or urgency tactics',
 'enter_site'),
('safe_browsing_street_03', 'safe_browsing_street', 'Storefront with "You''ve Won a Prize!" Popup', 2, TRUE,
 'Unsolicited prize popup interrupting checkout, urgency countdown timer, requests personal details to "claim" a prize you never entered to win',
 'leave,check_certificate');
