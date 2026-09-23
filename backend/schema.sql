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
-- `content` is a JSON object shown to the player BEFORE a decision (never leaks
-- is_fraud/correct_actions/red_flags), nested per language as {"en": {...}, "hi": {...},
-- "mr": {...}} - the API's `?lang=` query param picks which one to send (see
-- Scenario.to_public_dict in models.py). Fields that are themselves the thing being inspected
-- for red flags - domains, URLs, email addresses - are deliberately identical across all three
-- languages, since translating a URL would erase the exact detail the player needs to check.
-- Shape per room (per language):
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
 '{"en": {"sender_display": "SBI Bank Support", "sender_domain": "kyc-update-sbi.net", "body": "Dear Customer, your SBI account will be suspended within 24 hours unless you verify your KYC details immediately. Click below to avoid service interruption.", "link_text": "Verify My Account Now", "link_url": "http://kyc-update-sbi.net/verify?id=88231"}, "hi": {"sender_display": "SBI बैंक सहायता", "sender_domain": "kyc-update-sbi.net", "body": "प्रिय ग्राहक, यदि आपने तुरंत अपनी KYC जानकारी सत्यापित नहीं की, तो आपका SBI खाता 24 घंटे के भीतर निलंबित कर दिया जाएगा। सेवा बाधित होने से बचने के लिए नीचे क्लिक करें।", "link_text": "अभी अपना खाता सत्यापित करें", "link_url": "http://kyc-update-sbi.net/verify?id=88231"}, "mr": {"sender_display": "SBI बँक सहाय्य", "sender_domain": "kyc-update-sbi.net", "body": "प्रिय ग्राहक, जर तुम्ही ताबडतोब तुमची KYC माहिती पडताळली नाही, तर तुमचे SBI खाते 24 तासांत निलंबित केले जाईल. सेवेत अडथळा येऊ नये म्हणून खाली क्लिक करा.", "link_text": "आता माझे खाते पडताळा", "link_url": "http://kyc-update-sbi.net/verify?id=88231"}}'),
('phishing_inbox_02', 'phishing_inbox', 'Shared Project Document from Colleague', 1, FALSE,
 'None — sender matches a known contact''s real address, no suspicious links or attachments, professional and specific tone',
 'opened',
 '{"en": {"sender_display": "Priya Sharma", "sender_domain": "priya.sharma@company.com", "body": "Hi, sharing the Q3 project report we discussed in today''s meeting. Let me know if you have questions before Friday''s review.", "link_text": "Q3_Project_Report.pdf", "link_url": "https://company-drive.com/files/Q3_Project_Report.pdf"}, "hi": {"sender_display": "प्रिया शर्मा", "sender_domain": "priya.sharma@company.com", "body": "नमस्ते, आज की मीटिंग में चर्चा की गई Q3 प्रोजेक्ट रिपोर्ट भेज रही हूं। शुक्रवार की समीक्षा से पहले कोई सवाल हो तो बताइए।", "link_text": "Q3_प्रोजेक्ट_रिपोर्ट.pdf", "link_url": "https://company-drive.com/files/Q3_Project_Report.pdf"}, "mr": {"sender_display": "प्रिया शर्मा", "sender_domain": "priya.sharma@company.com", "body": "नमस्कार, आजच्या मीटिंगमध्ये चर्चा केलेला Q3 प्रोजेक्ट अहवाल पाठवत आहे. शुक्रवारच्या आढाव्यापूर्वी काही प्रश्न असल्यास कळवा.", "link_text": "Q3_प्रोजेक्ट_अहवाल.pdf", "link_url": "https://company-drive.com/files/Q3_Project_Report.pdf"}}'),
('phishing_inbox_03', 'phishing_inbox', 'Congratulations! You Won UPI Cashback', 2, TRUE,
 'Too-good-to-be-true cashback amount, shortened/obfuscated link, requests your UPI PIN which no legitimate offer ever needs',
 'reported,deleted',
 '{"en": {"sender_display": "UPI Rewards Team", "sender_domain": "upi-cashback-bonus.info", "body": "Congratulations! You are eligible for a Rs 5,000 UPI cashback. Offer expires today. Enter your UPI PIN on the linked page to claim your reward instantly.", "link_text": "Claim Rs 5,000 Cashback", "link_url": "http://bit.ly/3xUp1Cash"}, "hi": {"sender_display": "UPI रिवॉर्ड्स टीम", "sender_domain": "upi-cashback-bonus.info", "body": "बधाई हो! आप 5,000 रुपये के UPI कैशबैक के हकदार हैं। ऑफर आज ही समाप्त हो रहा है। अपना इनाम तुरंत पाने के लिए लिंक किए गए पेज पर अपना UPI पिन दर्ज करें।", "link_text": "5,000 रुपये कैशबैक पाएं", "link_url": "http://bit.ly/3xUp1Cash"}, "mr": {"sender_display": "UPI रिवॉर्ड्स टीम", "sender_domain": "upi-cashback-bonus.info", "body": "अभिनंदन! तुम्ही 5,000 रुपयांच्या UPI कॅशबॅकसाठी पात्र आहात. ऑफर आजच संपत आहे. तुमचे बक्षीस त्वरित मिळवण्यासाठी लिंक केलेल्या पृष्ठावर तुमचा UPI पिन टाका.", "link_text": "5,000 रुपये कॅशबॅक मिळवा", "link_url": "http://bit.ly/3xUp1Cash"}}'),
('phishing_inbox_04', 'phishing_inbox', 'Package Delivery Failed - Pay Redelivery Fee', 1, TRUE,
 'Sender domain is not India Post''s official domain, legitimate courier services do not charge redelivery fees via email links, urgency and threat of parcel return, generic tracking reference',
 'reported,deleted',
 '{"en": {"sender_display": "IndiaPost Delivery", "sender_domain": "delivery-indiapost-track.com", "body": "Your package could not be delivered due to an incomplete address. Pay a small redelivery fee of Rs 49 within 24 hours to reschedule delivery, or your parcel will be returned to sender.", "link_text": "Pay Redelivery Fee", "link_url": "http://delivery-indiapost-track.com/pay?track=IN44821903"}, "hi": {"sender_display": "इंडियापोस्ट डिलीवरी", "sender_domain": "delivery-indiapost-track.com", "body": "अधूरे पते के कारण आपका पार्सल डिलीवर नहीं हो सका। डिलीवरी दोबारा शेड्यूल करने के लिए 24 घंटे के भीतर 49 रुपये का मामूली शुल्क चुकाएं, वरना आपका पार्सल वापस भेज दिया जाएगा।", "link_text": "पुनः डिलीवरी शुल्क चुकाएं", "link_url": "http://delivery-indiapost-track.com/pay?track=IN44821903"}, "mr": {"sender_display": "इंडियापोस्ट डिलिव्हरी", "sender_domain": "delivery-indiapost-track.com", "body": "अपूर्ण पत्त्यामुळे तुमचे पार्सल डिलिव्हर होऊ शकले नाही. डिलिव्हरी पुन्हा शेड्यूल करण्यासाठी 24 तासांत 49 रुपयांचे किरकोळ शुल्क भरा, अन्यथा तुमचे पार्सल परत पाठवले जाईल.", "link_text": "पुनर्वितरण शुल्क भरा", "link_url": "http://delivery-indiapost-track.com/pay?track=IN44821903"}}'),
('phishing_inbox_05', 'phishing_inbox', 'Your Flipkart Order Has Shipped', 1, FALSE,
 'None — sender domain matches Flipkart''s real domain, order details are specific and match a real purchase, link points to the official flipkart.com domain',
 'opened',
 '{"en": {"sender_display": "Flipkart", "sender_domain": "noreply@flipkart.com", "body": "Hi, your order #OD328471905 for Wireless Mouse has shipped and is expected to arrive by Thursday. Track your shipment anytime from the Flipkart app or website.", "link_text": "Track My Order", "link_url": "https://www.flipkart.com/track/OD328471905"}, "hi": {"sender_display": "फ्लिपकार्ट", "sender_domain": "noreply@flipkart.com", "body": "नमस्ते, वायरलेस माउस के लिए आपका ऑर्डर #OD328471905 भेज दिया गया है और गुरुवार तक पहुंचने की उम्मीद है। Flipkart ऐप या वेबसाइट से कभी भी अपनी शिपमेंट ट्रैक करें।", "link_text": "मेरा ऑर्डर ट्रैक करें", "link_url": "https://www.flipkart.com/track/OD328471905"}, "mr": {"sender_display": "फ्लिपकार्ट", "sender_domain": "noreply@flipkart.com", "body": "नमस्कार, वायरलेस माउससाठी तुमची ऑर्डर #OD328471905 पाठवली गेली आहे आणि गुरुवारपर्यंत पोहोचण्याची शक्यता आहे. Flipkart अॅप किंवा वेबसाइटवरून कधीही तुमची शिपमेंट ट्रॅक करा.", "link_text": "माझी ऑर्डर ट्रॅक करा", "link_url": "https://www.flipkart.com/track/OD328471905"}}'),
('phishing_inbox_06', 'phishing_inbox', 'Work From Home - Earn Rs 5000 Daily, No Experience Needed', 2, TRUE,
 'Unrealistic guaranteed daily earnings for unskilled work, legitimate employers never ask candidates to pay a "registration fee", requests bank details before any actual hiring process, sender domain is not a real company',
 'reported,deleted',
 '{"en": {"sender_display": "HR Recruitment Team", "sender_domain": "careers-homejobs-apply.info", "body": "We are hiring for a simple data entry job you can do from home. Earn Rs 5000 per day guaranteed. To secure your position, pay a refundable registration fee of Rs 999 and share your bank details for salary processing.", "link_text": "Apply Now & Pay Registration Fee", "link_url": "http://careers-homejobs-apply.info/register"}, "hi": {"sender_display": "HR भर्ती टीम", "sender_domain": "careers-homejobs-apply.info", "body": "हम एक आसान डेटा एंट्री जॉब के लिए भर्ती कर रहे हैं जो आप घर से कर सकते हैं। रोजाना गारंटीशुदा 5000 रुपये कमाएं। अपनी जगह पक्की करने के लिए, 999 रुपये का वापस मिलने वाला पंजीकरण शुल्क चुकाएं और वेतन प्रोसेसिंग के लिए अपनी बैंक जानकारी साझा करें।", "link_text": "अभी आवेदन करें और पंजीकरण शुल्क भरें", "link_url": "http://careers-homejobs-apply.info/register"}, "mr": {"sender_display": "HR भरती टीम", "sender_domain": "careers-homejobs-apply.info", "body": "आम्ही घरुन करता येणार्या साध्या डेटा एंट्री कामासाठी भरती करत आहोत. दररोज हमी 5000 रुपये कमवा. तुमची जागा निश्चित करण्यासाठी 999 रुपयांचे परतावा-योग्य नोंदणी शुल्क भरा आणि पगार प्रक्रियेसाठी तुमची बॅंक माहिती शेअर करा.", "link_text": "आता अर्ज करा आणि नोंदणी शुल्क भरा", "link_url": "http://careers-homejobs-apply.info/register"}}'),
('phishing_inbox_07', 'phishing_inbox', 'Re: Tomorrow''s Team Meeting', 1, FALSE,
 'None — sender is a known colleague''s real address, content is specific and expected, link points to the internal company-drive.com domain already used for legitimate files',
 'opened',
 '{"en": {"sender_display": "Arjun Mehta", "sender_domain": "arjun.mehta@company.com", "body": "Hi, just confirming we''re moving tomorrow''s 10am team meeting to the 3rd floor conference room. I''ve attached the updated agenda for reference.", "link_text": "Meeting_Agenda.pdf", "link_url": "https://company-drive.com/files/Meeting_Agenda.pdf"}, "hi": {"sender_display": "अर्जुन मेहता", "sender_domain": "arjun.mehta@company.com", "body": "नमस्ते, बस यह पुष्टि कर रहा हूं कि कल सुबह 10 बजे की टीम मीटिंग हम तीसरी मंज़िल के कॉन्फ्रेंस रूम में शिफ्ट कर रहे हैं। संदर्भ के लिए अपडेटेड एजेंडा अटैच किया है।", "link_text": "मीटिंग_एजेंडा.pdf", "link_url": "https://company-drive.com/files/Meeting_Agenda.pdf"}, "mr": {"sender_display": "अर्जुन मेहता", "sender_domain": "arjun.mehta@company.com", "body": "नमस्कार, उद्या सकाळी 10 वाजताची टीम मीटिंग आपण तिसर्या मजल्यावरील कॉन्फरन्स रूममध्ये हलवत आहोत याची पुष्टी करत आहे. संदर्भासाठी अद्ययावत अजेंडा जोडला आहे.", "link_text": "मीटिंग_अजेंडा.pdf", "link_url": "https://company-drive.com/files/Meeting_Agenda.pdf"}}'),

-- upi_otp_kiosk
('upi_otp_kiosk_01', 'upi_otp_kiosk', 'Caller Requests OTP to "Verify Your Account"', 1, TRUE,
 'Banks and UPI apps never ask for your OTP over a phone call, request is unsolicited, caller manufactures urgency to rush you',
 'declined',
 '{"en": {"caller_name": "Unknown Caller", "caller_lines": ["Hello, I''m calling from your bank''s security department.", "We''ve detected suspicious activity on your account just now.", "To verify it''s really you, please read out the OTP you just received."]}, "hi": {"caller_name": "अज्ञात कॉलर", "caller_lines": ["नमस्ते, मैं आपके बैंक के सुरक्षा विभाग से बोल रहा हूं।", "हमने अभी-अभी आपके खाते में संदिग्ध गतिविधि का पता लगाया है।", "यह सत्यापित करने के लिए कि यह वाकई आप ही हैं, कृपया अभी मिला OTP बताएं।"]}, "mr": {"caller_name": "अज्ञात कॉलर", "caller_lines": ["नमस्कार, मी तुमच्या बँकेच्या सुरक्षा विभागातून बोलत आहे.", "आम्हाला आत्ताच तुमच्या खात्यात संशयास्पद हलचाल आढळली आहे.", "हे खरंच तुम्हीच आहात हे पडताळण्यासाठी, कृपया आत्ता मिळालेला OTP सांगा."]}}'),
('upi_otp_kiosk_02', 'upi_otp_kiosk', 'Payment Confirmation from Known Merchant', 1, FALSE,
 'None — amount matches your actual purchase, merchant name is recognized, no OTP or PIN requested outside the app',
 'approved',
 '{"en": {"caller_name": "PhonePe Payment Request", "caller_lines": ["Payment request received from Ramesh General Store.", "Amount: Rs 450.00", "This matches your recent purchase at the store."]}, "hi": {"caller_name": "PhonePe भुगतान अनुरोध", "caller_lines": ["रमेश जनरल स्टोर से भुगतान अनुरोध प्राप्त हुआ।", "राशि: 450.00 रुपये", "यह स्टोर पर आपकी हाल की खरीदारी से मेल खाता है।"]}, "mr": {"caller_name": "PhonePe पेमेंट विनंती", "caller_lines": ["रमेश जनरल स्टोअरकडून पेमेंट विनंती प्राप्त झाली.", "रक्कम: 450.00 रुपये", "हे स्टोअरमधील तुमच्या अलीकडील खरेदीशी जुळते."]}}'),
('upi_otp_kiosk_03', 'upi_otp_kiosk', 'Incoming "Refund" Collect Request', 2, TRUE,
 'Genuine refunds are credited automatically and never require you to approve a collect/payment request, requester is unknown, pressure to approve quickly',
 'declined',
 '{"en": {"caller_name": "Incoming Collect Request", "caller_lines": ["You have an incoming refund request for Rs 2,000.", "Note: approving a collect request DEBITS money from your account, not credit it.", "Genuine refunds are credited automatically and never need your approval."]}, "hi": {"caller_name": "इनकमिंग कलेक्ट रिक्वेस्ट", "caller_lines": ["आपके पास 2,000 रुपये के रिफंड की एक इनकमिंग रिक्वेस्ट है।", "ध्यान दें: कलेक्ट रिक्वेस्ट स्वीकार करने से आपके खाते से पैसे कटते हैं, जमा नहीं होते।", "असली रिफंड अपने आप जमा हो जाते हैं और कभी आपकी मंज़ूरी की जरूरत नहीं होती।"]}, "mr": {"caller_name": "इनकमिंग कलेक्ट रिक्वेस्ट", "caller_lines": ["तुम्हाला 2,000 रुपयांच्या परताव्यासाठी एक इनकमिंग विनंती आली आहे.", "टीप: कलेक्ट रिक्वेस्ट मान्य केल्यास तुमच्या खात्यातून पैसे वजा होतात, जमा होत नाहीत.", "खरे परतावे आपोआप जमा होतात आणि त्यासाठी कधीही तुमच्या मंजुरीची गरज नसते."]}}'),
('upi_otp_kiosk_04', 'upi_otp_kiosk', 'Fake Customer Care Calls Back After Complaint', 2, TRUE,
 'You never filed a complaint, so this callback is unsolicited, no genuine customer care resolves issues by asking for your OTP, artificial urgency to "fix" a problem you didn''t report',
 'declined',
 '{"en": {"caller_name": "Bank Customer Care Callback", "caller_lines": ["Hello, this is customer care returning your recent complaint call.", "To resolve your issue immediately, please share the OTP sent to your registered mobile.", "This will help us verify and fix your account right away."]}, "hi": {"caller_name": "बैंक ग्राहक सेवा कॉलबैक", "caller_lines": ["नमस्ते, यह ग्राहक सेवा है, आपकी हाल की शिकायत कॉल पर वापस कॉल कर रहे हैं।", "आपकी समस्या तुरंत हल करने के लिए, कृपया अपने पंजीकृत मोबाइल पर भेजा गया OTP साझा करें।", "इससे हमें आपके खाते को तुरंत सत्यापित और ठीक करने में मदद मिलेगी।"]}, "mr": {"caller_name": "बँक ग्राहक सेवा कॉलबॅक", "caller_lines": ["नमस्कार, ही ग्राहक सेवा आहे, तुमच्या अलीकडील तक्रार कॉलला परत कॉल करत आहोत.", "तुमची समस्या तातडीने सोडवण्यासाठी, कृपया तुमच्या नोंदणीकृत मोबाइलवर आलेला OTP शेअर करा.", "यामुळे आम्हाला तुमचे खाते तातडीने पडताळण्यास आणि ठीक करण्यास मदत होईल."]}}'),
('upi_otp_kiosk_05', 'upi_otp_kiosk', 'Electricity Bill Autopay Confirmation', 1, FALSE,
 'None — amount matches your known monthly bill, biller name is recognized and already set up for autopay, no OTP or PIN requested outside the app',
 'approved',
 '{"en": {"caller_name": "Electricity Board Autopay", "caller_lines": ["Scheduled autopay request from State Electricity Board.", "Amount: Rs 1,240.00", "This matches your monthly electricity bill due today."]}, "hi": {"caller_name": "बिजली बोर्ड ऑटोपे", "caller_lines": ["राज्य बिजली बोर्ड से निर्धारित ऑटोपे अनुरोध।", "राशि: 1,240.00 रुपये", "यह आज देय आपके मासिक बिजली के बिल से मेल खाता है।"]}, "mr": {"caller_name": "वीज मंडळ ऑटोपे", "caller_lines": ["राज्य वीज मंडळाकडून नियोजित ऑटोपे विनंती.", "रक्कम: 1,240.00 रुपये", "हे आज देय असलेल्या तुमच्या मासिक वीज बिलाशी जुळते."]}}'),
('upi_otp_kiosk_06', 'upi_otp_kiosk', 'You''ve Won a Lucky Draw - Claim via UPI Request', 1, TRUE,
 'Genuine prizes are never claimed by approving a payment request, "verification" collect requests are a common scam to debit money or harvest your UPI PIN, you never entered this lucky draw',
 'declined',
 '{"en": {"caller_name": "Lucky Draw Winnings", "caller_lines": ["Congratulations! You''ve been selected in our festival lucky draw.", "To receive your Rs 10,000 prize, approve the small Rs 1 verification collect request.", "Approve now before the offer window closes."]}, "hi": {"caller_name": "लकी ड्रॉ जीत", "caller_lines": ["बधाई हो! आपको हमारे त्योहार लकी ड्रॉ में चुना गया है।", "अपना 10,000 रुपये का इनाम पाने के लिए, 1 रुपये की छोटी सत्यापन कलेक्ट रिक्वेस्ट स्वीकार करें।", "ऑफर बंद होने से पहले अभी स्वीकार करें।"]}, "mr": {"caller_name": "लकी ड्रॉ विजय", "caller_lines": ["अभिनंदन! तुमची आमच्या सणाच्या लकी ड्रॉमध्ये निवड झाली आहे.", "तुमचे 10,000 रुपयांचे बक्षीस मिळवण्यासाठी, 1 रुपयाची छोटी पडताळणी कलेक्ट रिक्वेस्ट मान्य करा.", "ऑफर बंद होण्यापूर्वी आत्ताच मान्य करा."]}}'),
('upi_otp_kiosk_07', 'upi_otp_kiosk', 'Friend Requesting Dinner Split via UPI', 1, FALSE,
 'None — request is from a saved contact you know personally, amount is small and matches a real shared expense, no OTP or PIN requested outside the app',
 'approved',
 '{"en": {"caller_name": "Rohit Verma (Collect Request)", "caller_lines": ["Collect request from Rohit Verma, saved contact.", "Amount: Rs 350.00", "Note: For last night''s dinner split."]}, "hi": {"caller_name": "रोहित वर्मा (कलेक्ट रिक्वेस्ट)", "caller_lines": ["सेव्ड कॉन्टैक्ट रोहित वर्मा से कलेक्ट रिक्वेस्ट।", "राशि: 350.00 रुपये", "नोट: कल रात के डिनर के बंटवारे के लिए।"]}, "mr": {"caller_name": "रोहित वर्मा (कलेक्ट रिक्वेस्ट)", "caller_lines": ["जतन केलेल्या संपर्क रोहित वर्माकडून कलेक्ट रिक्वेस्ट.", "रक्कम: 350.00 रुपये", "टीप: कालच्या रात्रीच्या जेवणाचा खर्च वाटण्यासाठी."]}}'),

-- fake_login_corridor
('fake_login_corridor_01', 'fake_login_corridor', 'Bank Login Page (from SMS link)', 1, TRUE,
 'Domain is a lookalike ("secure-sbi-login.net") not the bank''s official domain, "account suspended" scare message, reached via an unsolicited SMS link',
 'check_url,leave_page',
 '{"en": {"domain": "secure-sbi-login.net", "page_heading": "SBI Net Banking - Account Suspended"}, "hi": {"domain": "secure-sbi-login.net", "page_heading": "SBI नेट बैंकिंग - खाता निलंबित"}, "mr": {"domain": "secure-sbi-login.net", "page_heading": "SBI नेट बँकिंग - खाते निलंबित"}}'),
('fake_login_corridor_02', 'fake_login_corridor', 'Bank Login Page (typed manually)', 1, FALSE,
 'None — domain matches the bank''s official site exactly, valid HTTPS certificate, reached by typing the address yourself',
 'enter_credentials,confirmed_legit',
 '{"en": {"domain": "www.onlinesbi.sbi", "page_heading": "SBI Net Banking - Login"}, "hi": {"domain": "www.onlinesbi.sbi", "page_heading": "SBI नेट बैंकिंग - लॉगिन"}, "mr": {"domain": "www.onlinesbi.sbi", "page_heading": "SBI नेट बँकिंग - लॉगइन"}}'),
('fake_login_corridor_03', 'fake_login_corridor', 'Social Media Login (from ad link)', 2, TRUE,
 'Lookalike domain with extra words ("facebook-secure-verify.com"), credentials requested on a page reached via an unsolicited ad/link, no valid certificate for the real site',
 'check_url,leave_page',
 '{"en": {"domain": "facebook-secure-verify.com", "page_heading": "Facebook - Verify Your Identity"}, "hi": {"domain": "facebook-secure-verify.com", "page_heading": "Facebook - अपनी पहचान सत्यापित करें"}, "mr": {"domain": "facebook-secure-verify.com", "page_heading": "Facebook - तुमची ओळख पडताळा"}}'),
('fake_login_corridor_04', 'fake_login_corridor', 'Email Login Page (password reset link)', 2, TRUE,
 'Domain is not google.com or accounts.google.com, page reached via an unsolicited "unusual activity" link, urgent security-scare framing designed to rush a credential entry',
 'check_url,leave_page',
 '{"en": {"domain": "gmail-account-security-check.com", "page_heading": "Google Account - Unusual Sign-In Activity"}, "hi": {"domain": "gmail-account-security-check.com", "page_heading": "Google खाता - असामान्य साइन-इन गतिविधि"}, "mr": {"domain": "gmail-account-security-check.com", "page_heading": "Google खाते - असामान्य साइन-इन क्रियाकलाप"}}'),
('fake_login_corridor_05', 'fake_login_corridor', 'Email Login Page (typed manually)', 1, FALSE,
 'None — domain matches Google''s official accounts domain exactly, valid HTTPS certificate, reached by typing the address yourself',
 'enter_credentials,confirmed_legit',
 '{"en": {"domain": "accounts.google.com", "page_heading": "Google - Sign in to your account"}, "hi": {"domain": "accounts.google.com", "page_heading": "Google - अपने खाते में साइन इन करें"}, "mr": {"domain": "accounts.google.com", "page_heading": "Google - तुमच्या खात्यात साइन इन करा"}}'),
('fake_login_corridor_06', 'fake_login_corridor', 'UPI App Login Page (from SMS link)', 1, TRUE,
 'Lookalike domain with extra words not matching paytm.com, reached via an unsolicited SMS link, "complete KYC to continue" framing pressures you to log in immediately',
 'check_url,leave_page',
 '{"en": {"domain": "paytm-secure-kyc-update.net", "page_heading": "Paytm - Complete Your KYC to Continue"}, "hi": {"domain": "paytm-secure-kyc-update.net", "page_heading": "Paytm - जारी रखने के लिए अपनी KYC पूरी करें"}, "mr": {"domain": "paytm-secure-kyc-update.net", "page_heading": "Paytm - सुरू ठेवण्यासाठी तुमची KYC पूर्ण करा"}}'),
('fake_login_corridor_07', 'fake_login_corridor', 'Social Media Login Page (typed manually)', 1, FALSE,
 'None — domain matches Instagram''s official site exactly, valid HTTPS certificate, reached by typing the address yourself',
 'enter_credentials,confirmed_legit',
 '{"en": {"domain": "www.instagram.com", "page_heading": "Instagram - Log in"}, "hi": {"domain": "www.instagram.com", "page_heading": "Instagram - लॉग इन करें"}, "mr": {"domain": "www.instagram.com", "page_heading": "Instagram - लॉग इन करा"}}'),

-- password_vault_lab (not fraud-based — strength evaluated client-side in real time)
('password_vault_lab_01', 'password_vault_lab', 'Set Your Vault Master Password', 1, FALSE,
 'Avoid common dictionary words and keyboard patterns, avoid reusing your name/birth year, aim for 12+ characters mixing upper/lowercase, digits, and symbols',
 'strong',
 '{"en": {"hint": "This vault protects real financial data - treat it like a bank password."}, "hi": {"hint": "यह वॉल्ट वास्तविक वित्तीय डेटा की रक्षा करता है - इसे बैंक पासवर्ड की तरह मानें।"}, "mr": {"hint": "हे व्हॉल्ट खर्या आर्थिक डेटाचे संरक्षण करते - याला बँक पासवर्डसारखे समजा."}}'),
('password_vault_lab_02', 'password_vault_lab', 'Create a Recovery Passphrase', 2, FALSE,
 'A long random passphrase beats a short complex one — combine unrelated words, avoid personal information, avoid reusing passwords from other sites',
 'strong',
 '{"en": {"hint": "A long random passphrase beats a short complex one."}, "hi": {"hint": "एक लंबा रैंडम पासफ़्रेज़ एक छोटे जटिल पासवर्ड से बेहतर होता है।"}, "mr": {"hint": "एक लांब यादृच्छिक पासफ्रेझ एका छोट्या क्लिष्ट पासवर्डपेक्षा चांगला असतो."}}'),
('password_vault_lab_03', 'password_vault_lab', 'Set an Admin Vault Key', 2, FALSE,
 'Admin-level credentials need the highest strength — avoid predictable substitutions like "P@ssw0rd", avoid short lengths even with symbols',
 'strong',
 '{"en": {"hint": "Admin-level credentials need the highest possible strength."}, "hi": {"hint": "एडमिन-स्तर के क्रेडेंशियल्स को सबसे मज़बूत सुरक्षा की जरूरत होती है।"}, "mr": {"hint": "अॅडमिन-स्तरीय क्रेडेन्शियल्सना सर्वाधिक शक्य मजबूतीची गरज असते."}}'),
('password_vault_lab_04', 'password_vault_lab', 'Set a Password for Your Email Account', 1, FALSE,
 'Avoid using the same password as other accounts, avoid dictionary words, use a mix of unrelated words or random characters with 12+ length',
 'strong',
 '{"en": {"hint": "This inbox is the recovery point for most of your other accounts - a breach here cascades everywhere."}, "hi": {"hint": "यह इनबॉक्स आपके अधिकतर अन्य खातों का रिकवरी पॉइंट है - यहां सेंध लगने से हर जगह असर पड़ता है।"}, "mr": {"hint": "हा इनबॉक्स तुमच्या इतर बहतेक खात्यांचा रिकव्हरी पॉइंट आहे - इथे भंग झाल्यास सर्वत्र परिणाम होतो."}}'),
('password_vault_lab_05', 'password_vault_lab', 'Create a Wi-Fi Router Password', 1, FALSE,
 'Avoid the router''s default password, avoid simple number sequences, aim for a long unique passphrase not used anywhere else',
 'strong',
 '{"en": {"hint": "Anyone within range of your home network could try to guess a weak router password."}, "hi": {"hint": "आपके होम नेटवर्क की रेंज में कोई भी कमज़ोर राउटर पासवर्ड का अंदाज़ा लगा सकता है।"}, "mr": {"hint": "तुमच्या घरगुती नेटवर्कच्या रेंजमध्ये कोणीही कमकुवत राउटर पासवर्डचा अंदाज घेण्याचा प्रयत्न करू शकतो."}}'),
('password_vault_lab_06', 'password_vault_lab', 'Set a Password for a New Social Media Account', 2, FALSE,
 'Avoid anything guessable from your public profile, avoid short passwords even if they feel clever, use a password manager-generated string if possible',
 'strong',
 '{"en": {"hint": "Attackers often try passwords built from your public profile info first - birthdays, pet names, hometowns."}, "hi": {"hint": "हमलावर अक्सर पहले आपकी सार्वजनिक प्रोफ़ाइल जानकारी से बने पासवर्ड आज़माते हैं - जन्मदिन, पालतू जानवर के नाम, गृहनगर।"}, "mr": {"hint": "हल्लेखोर अनेकदा प्रथम तुमच्या सार्वजनिक प्रोफाइल माहितीवरून बनवलेले पासवर्ड वापरून पाहतात - वाढदिवस, पाळीव प्राण्यांची नावे, गावाचे नाव."}}'),
('password_vault_lab_07', 'password_vault_lab', 'Create a Shared Team Vault Password', 2, FALSE,
 'Avoid simple substitutions like "Team@123", avoid short lengths, prefer a long memorable passphrase the whole team can type reliably',
 'strong',
 '{"en": {"hint": "Multiple teammates will type this password - it should stay strong without becoming impossible to type correctly."}, "hi": {"hint": "इस पासवर्ड को कई टीम सदस्य टाइप करेंगे - यह मज़बूत रहना चाहिए लेकिन इतना कठिन नहीं कि सही टाइप करना मुश्किल हो जाए।"}, "mr": {"hint": "हा पासवर्ड अनेक टीम सदस्य टाइप करतील - तो मजबूत राहिला हवा पण बरोबर टाइप करणे अशक्य होऊ नये."}}'),

-- safe_browsing_street
('safe_browsing_street_01', 'safe_browsing_street', 'Discount Electronics Store (HTTP only)', 1, TRUE,
 'No HTTPS/padlock on a page asking for payment details, generic unfamiliar domain, prices far below market rate',
 'leave,check_certificate',
 '{"en": {"domain": "http://mega-discount-electronics.xyz", "storefront_name": "Mega Discount Electronics"}, "hi": {"domain": "http://mega-discount-electronics.xyz", "storefront_name": "मेगा डिस्काउंट इलेक्ट्रॉनिक्स"}, "mr": {"domain": "http://mega-discount-electronics.xyz", "storefront_name": "मेगा डिस्काउंट इलेक्ट्रॉनिक्स"}}'),
('safe_browsing_street_02', 'safe_browsing_street', 'Well-Known Retailer (HTTPS)', 1, FALSE,
 'None — valid HTTPS certificate, familiar established domain, no unusual pop-ups or urgency tactics',
 'enter_site',
 '{"en": {"domain": "https://www.amazon.in", "storefront_name": "Amazon India"}, "hi": {"domain": "https://www.amazon.in", "storefront_name": "Amazon India"}, "mr": {"domain": "https://www.amazon.in", "storefront_name": "Amazon India"}}'),
('safe_browsing_street_03', 'safe_browsing_street', 'Storefront with "You''ve Won a Prize!" Popup', 2, TRUE,
 'Unsolicited prize popup interrupting checkout, urgency countdown timer, requests personal details to "claim" a prize you never entered to win',
 'leave,check_certificate',
 '{"en": {"domain": "https://trusted-shop-example.com", "storefront_name": "Trusted Shop", "popup_text": "Congratulations! You''ve Won a Free iPhone! Click Claim Now to receive your prize."}, "hi": {"domain": "https://trusted-shop-example.com", "storefront_name": "ट्रस्टेड शॉप", "popup_text": "बधाई हो! आपने एक मुफ़्त iPhone जीता है! अपना इनाम पाने के लिए अभी क्लेम पर क्लिक करें।"}, "mr": {"domain": "https://trusted-shop-example.com", "storefront_name": "ट्रस्टेड शॉप", "popup_text": "अभिनंदन! तुम्ही एक मोफत iPhone जिंकला आहे! तुमचे बक्षीस मिळवण्यासाठी आता क्लेम वर क्लिक करा."}}'),
('safe_browsing_street_04', 'safe_browsing_street', 'Flash Sale Furniture Store (HTTP only)', 1, TRUE,
 'No HTTPS/padlock on a page collecting payment details, unfamiliar domain with a generic "sale" name, countdown timer pressuring an immediate purchase',
 'leave,check_certificate',
 '{"en": {"domain": "http://superdeal-furniture-sale.xyz", "storefront_name": "SuperDeal Furniture Sale"}, "hi": {"domain": "http://superdeal-furniture-sale.xyz", "storefront_name": "सुपरडील फर्नीचर सेल"}, "mr": {"domain": "http://superdeal-furniture-sale.xyz", "storefront_name": "सुपरडील फर्निचर सेल"}}'),
('safe_browsing_street_05', 'safe_browsing_street', 'Well-Known Grocery Delivery (HTTPS)', 1, FALSE,
 'None — valid HTTPS certificate, familiar established domain, no unusual pop-ups or urgency tactics',
 'enter_site',
 '{"en": {"domain": "https://www.bigbasket.com", "storefront_name": "BigBasket"}, "hi": {"domain": "https://www.bigbasket.com", "storefront_name": "BigBasket"}, "mr": {"domain": "https://www.bigbasket.com", "storefront_name": "BigBasket"}}'),
('safe_browsing_street_06', 'safe_browsing_street', 'Storefront with Fake "Browser Out of Date" Popup', 2, TRUE,
 'Legitimate sites never ask you to "update your browser" through an in-page popup, this is a common tactic to trick you into downloading malware, popup interrupts checkout with urgency',
 'leave,check_certificate',
 '{"en": {"domain": "https://deal-hub-shopping.com", "storefront_name": "Deal Hub Shopping", "popup_text": "Warning! Your browser is out of date and unsafe. Click Update Now to install the latest security patch before continuing to shop."}, "hi": {"domain": "https://deal-hub-shopping.com", "storefront_name": "डील हब शॉपिंग", "popup_text": "चेतावनी! आपका ब्राउज़र पुराना और असुरक्षित है। खरीदारी जारी रखने से पहले नवीनतम सुरक्षा पैच इंस्टॉल करने के लिए अभी अपडेट पर क्लिक करें।"}, "mr": {"domain": "https://deal-hub-shopping.com", "storefront_name": "डील हब शॉपिंग", "popup_text": "इशारा! तुमचा ब्राउझर जुना आणि असुरक्षित आहे. खरेदी सुरू ठेवण्यापूर्वी नवीनतम सुरक्षा पॅच इन्स्टॉल करण्यासाठी आता अपडेटवर क्लिक करा."}}'),
('safe_browsing_street_07', 'safe_browsing_street', 'Well-Known Clothing Retailer (HTTPS)', 1, FALSE,
 'None — valid HTTPS certificate, familiar established domain, no unusual pop-ups or urgency tactics',
 'enter_site',
 '{"en": {"domain": "https://www.myntra.com", "storefront_name": "Myntra"}, "hi": {"domain": "https://www.myntra.com", "storefront_name": "Myntra"}, "mr": {"domain": "https://www.myntra.com", "storefront_name": "Myntra"}}'),

-- rapid_fire: short mixed-topic statements, judged SAFE or UNSAFE under time pressure
('rapid_fire_01', 'rapid_fire', 'Unsolicited Password Verification Email', 1, TRUE,
 'Unknown email asking you to "verify" your password by clicking a link is a classic phishing pattern',
 'unsafe',
 '{"en": {"statement": "An unknown email asks you to verify your password by clicking a link."}, "hi": {"statement": "एक अज्ञात ईमेल आपसे लिंक पर क्लिक करके अपना पासवर्ड सत्यापित करने को कहता है।"}, "mr": {"statement": "एक अनोळखी ईमेल तुम्हाला लिंकवर क्लिक करून तुमचा पासवर्ड पडताळण्यास सांगते."}}'),
('rapid_fire_02', 'rapid_fire', 'Unexpected Executable from a Friend', 1, TRUE,
 'Unexpected executable files can carry malware even from a real contact whose account may be compromised',
 'unsafe',
 '{"en": {"statement": "A friend sends you an executable file you were not expecting."}, "hi": {"statement": "एक दोस्त आपको एक ऐसी एक्ज़ीक्यूटेबल फ़ाइल भेजता है जिसकी आपने उम्मीद नहीं की थी।"}, "mr": {"statement": "एक मित्र तुम्हाला अपेक्षित असलेली एक्झिक्युटेबल फाइल पाठवतो."}}'),
('rapid_fire_03', 'rapid_fire', 'Caller Requests Your OTP', 1, TRUE,
 'No legitimate bank or service ever asks you to read out your OTP over a call',
 'unsafe',
 '{"en": {"statement": "Someone on a phone call asks you to read out your OTP to verify your identity."}, "hi": {"statement": "फ़ोन कॉल पर कोई आपकी पहचान सत्यापित करने के लिए आपका OTP बताने को कहता है।"}, "mr": {"statement": "फोन कॉलवर कोणीतरी तुमची ओळख पडताळण्यासाठी तुमचा OTP सांगण्यास सांगते."}}'),
('rapid_fire_04', 'rapid_fire', 'Valid HTTPS on the Official Domain', 1, FALSE,
 'A valid certificate on the real, matching domain is exactly what safe browsing looks like',
 'safe',
 '{"en": {"statement": "A website you are on shows a valid HTTPS padlock and matches the official domain."}, "hi": {"statement": "आप जिस वेबसाइट पर हैं वह एक वैध HTTPS पैडलॉक दिखाती है और आधिकारिक डोमेन से मेल खाती है।"}, "mr": {"statement": "तुम्ही असलेली वेबसाइट वैध HTTPS पॅडलॉक दाखवते आणि अधिकृत डोमेनशी जुळते."}}'),
('rapid_fire_05', 'rapid_fire', 'Prize Popup Requesting Card Details', 1, TRUE,
 'Unsolicited prize claims that request payment card details are a common scam pattern',
 'unsafe',
 '{"en": {"statement": "A pop-up says you have won a prize and asks you to enter your card details to claim it."}, "hi": {"statement": "एक पॉप-अप कहता है कि आपने इनाम जीता है और इसे पाने के लिए अपने कार्ड की जानकारी दर्ज करने को कहता है।"}, "mr": {"statement": "एक पॉप-अप सांगतो की तुम्ही बक्षीस जिंकले आहे आणि ते मिळवण्यासाठी तुमची कार्ड माहिती टाकण्यास सांगतो."}}'),
('rapid_fire_06', 'rapid_fire', 'Bank App Confirms Your Own Login', 1, FALSE,
 'A confirmation prompt for a login you actually just performed yourself is normal MFA behavior',
 'safe',
 '{"en": {"statement": "Your bank app asks you to confirm a login you just attempted yourself."}, "hi": {"statement": "आपका बैंक ऐप आपसे अभी-अभी खुद किए गए लॉगिन की पुष्टि करने को कहता है।"}, "mr": {"statement": "तुमचे बॅंक अॅप तुम्ही स्वतः नुकत्या केलेल्या लॉगइनची पुष्टी करण्यास सांगते."}}'),
('rapid_fire_07', 'rapid_fire', '10-Minute Account Suspension Threat', 2, TRUE,
 'Artificial urgency ("act within minutes or lose access") is a manipulation tactic, not how real account issues are handled',
 'unsafe',
 '{"en": {"statement": "A message urges you to act within 10 minutes or lose access to your account."}, "hi": {"statement": "एक संदेश आपसे 10 मिनट के भीतर कार्रवाई करने का आग्रह करता है, वरना आपका खाता एक्सेस खो जाएगा।"}, "mr": {"statement": "एक संदेश तुम्हाला 10 मिनिटांत कृती करण्याचा आग्रह करतो, अन्यथा तुमच्या खात्याचा प्रवेश गमावाल."}}'),
('rapid_fire_08', 'rapid_fire', 'Expected Calendar Invite from a Colleague', 1, FALSE,
 'An expected invite from a real colleague for a meeting you already knew about carries no red flags',
 'safe',
 '{"en": {"statement": "You receive a calendar invite from a colleague for a meeting you already expected."}, "hi": {"statement": "आपको एक सहकर्मी से एक एसी मीटिंग के लिए कैलेंडर इनवाइट मिलता है जिसकी आपको पहले से उम्मीद थी।"}, "mr": {"statement": "तुम्हाला एका सहकार्याकडून आधीच अपेक्षित असलेल्या मीटिंगसाठी कॅलेंडर आमंत्रण मिळते."}}'),
('rapid_fire_09', 'rapid_fire', 'Flyer QR Code Promising Cashback', 2, TRUE,
 'Random QR codes promising cashback for scanning-and-paying are a common UPI scam vector',
 'unsafe',
 '{"en": {"statement": "A QR code on a random flyer promises cashback if you scan it and make a payment."}, "hi": {"statement": "एक रैंडम फ़्लायर पर एक QR कोड वादा करता है कि इसे स्कैन करके भुगतान करने पर कैशबैक मिलेगा।"}, "mr": {"statement": "एका अनोळख्या फ्लायरवरील QR कोड स्कॅन करून पेमेंट केल्यास कॅशबॅकचे आश्वासन देतो."}}'),
('rapid_fire_10', 'rapid_fire', 'OS Update via Official Settings App', 1, FALSE,
 'Updating through your device''s own official settings app is the safe, standard way to patch software',
 'safe',
 '{"en": {"statement": "You update your phone''s operating system through the official system settings app."}, "hi": {"statement": "आप अपने फ़ोन के आधिकारिक सिस्टम सेटिंग्स ऐप के ज़रिए ऑपरेटिंग सिस्टम अपडेट करते हैं।"}, "mr": {"statement": "तुम्ही तुमच्या फोनची ऑपरेटिंग सिस्टीम अधिकृत सिस्टीम सेटिंग्ज अॅपद्वारे अपडेट करता."}}'),

-- vulnerability_hunt: explore a small office scene, judge each prop as a real vulnerability or not
('vulnerability_hunt_01', 'vulnerability_hunt', 'Sticky Note on the Monitor', 1, TRUE,
 'A password written on a sticky note in plain view is an exposed credential anyone nearby can read',
 'flag',
 '{"en": {"object_label": "Sticky Note with a Password Written on It"}, "hi": {"object_label": "स्टिकी नोट जिस पर पासवर्ड लिखा है"}, "mr": {"object_label": "पासवर्ड लिहिलेली स्टिकी नोट"}}'),
('vulnerability_hunt_02', 'vulnerability_hunt', 'Unattended Unlocked Workstation', 1, TRUE,
 'An unlocked, unattended computer gives anyone who walks by full access to the logged-in account',
 'flag',
 '{"en": {"object_label": "Unattended Computer, Unlocked and Logged In"}, "hi": {"object_label": "बिना निगरानी का कंप्यूटर, अनलॉक्ड और लॉग्ड इन"}, "mr": {"object_label": "दुर्लक्षित संगणक, अनलॉक्ड आणि लॉगइन केलेला"}}'),
('vulnerability_hunt_03', 'vulnerability_hunt', 'Unknown USB Drive Plugged In', 2, TRUE,
 'Unknown USB drives are a classic malware delivery method (a "USB drop" attack) and should never be trusted',
 'flag',
 '{"en": {"object_label": "Unknown USB Drive Plugged Into the Computer"}, "hi": {"object_label": "कंप्यूटर में लगाई गई अज्ञात USB ड्राइव"}, "mr": {"object_label": "संगणकात लावलेली अज्ञात USB ड्राइव्ह"}}'),
('vulnerability_hunt_04', 'vulnerability_hunt', 'Locked Filing Cabinet', 1, FALSE,
 'None — a properly locked cabinet is standard, appropriate physical security for sensitive paperwork',
 'ignore',
 '{"en": {"object_label": "Filing Cabinet, Locked"}, "hi": {"object_label": "फाइलिंग कैबिनेट, लॉक्ड"}, "mr": {"object_label": "फायलिंग कॅबिनेट, लॉक केलेले"}}'),
('vulnerability_hunt_05', 'vulnerability_hunt', 'Encrypted External Backup Drive', 2, FALSE,
 'None — an encrypted backup drive, properly labeled and stored, is a safe and responsible backup practice',
 'ignore',
 '{"en": {"object_label": "External Backup Drive, Labeled and Encrypted"}, "hi": {"object_label": "एक्सटर्नल बैकअप ड्राइव, लेबल्ड और एन्क्रिप्टेड"}, "mr": {"object_label": "एक्सटर्नल बॅकअप ड्राइव्ह, लेबल केलेली आणि एन्क्रिप्टेड"}}');
