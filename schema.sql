-- CyberGuard 3D — MySQL schema
-- Run: mysql -u root -p < schema.sql

CREATE DATABASE IF NOT EXISTS cyberguard3d CHARACTER SET utf8mb4;
USE cyberguard3d;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    trust_score INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scenarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,        -- e.g. 'phishing_inbox_01'
    room VARCHAR(50) NOT NULL,               -- e.g. 'phishing_inbox'
    title VARCHAR(150) NOT NULL,
    difficulty INT DEFAULT 1,
    is_fraud BOOLEAN NOT NULL,               -- ground truth for this scenario item
    red_flags TEXT                           -- comma-separated cues, shown in debrief
);

CREATE TABLE results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    scenario_id INT NOT NULL,
    action_taken VARCHAR(30) NOT NULL,       -- e.g. 'clicked', 'reported', 'deleted', 'ignored'
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
    badge_code VARCHAR(50) NOT NULL,         -- e.g. 'phishing_expert'
    awarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Seed a few Phishing Inbox scenario items for the vertical slice
INSERT INTO scenarios (code, room, title, difficulty, is_fraud, red_flags) VALUES
('phishing_inbox_01', 'phishing_inbox', 'Bank KYC Update Email', 1, TRUE,
 'Sender domain is not the bank''s real domain, urgent tone, generic greeting'),
('phishing_inbox_02', 'phishing_inbox', 'Colleague Shared Document', 1, FALSE,
 'None — sender matches known contact, no suspicious link'),
('phishing_inbox_03', 'phishing_inbox', 'UPI Cashback Offer', 2, TRUE,
 'Too-good-to-be-true offer, shortened link, requests UPI PIN');
