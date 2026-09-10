extends Node
## Central lookup for every UI-facing string. Never hardcode player-visible text in a scene script —
## add a key here (in every language table) and call Localization.get_string(key) instead.

signal language_changed(language_code: String)

var current_language: String = "en"

var _strings: Dictionary = {
	"en": {
		"common.connection_error": "Connection error, is the server running?",
		"common.continue": "Continue",
		"common.back": "Back",
		"common.cancel": "Cancel",
		"common.submit": "Submit",
		"common.loading": "Loading...",

		"menu.title": "CyberGuard 3D",
		"menu.login": "Login",
		"menu.register": "Register",
		"menu.leaderboard": "Leaderboard",
		"menu.quit": "Quit",
		"menu.language": "Language",
		"menu.logout": "Log Out",

		"login.title": "Login",
		"login.username": "Username",
		"login.password": "Password",
		"login.submit": "Login",
		"login.switch_to_register": "Need an account? Register",
		"login.error_generic": "Login failed.",

		"register.title": "Register",
		"register.username": "Username",
		"register.email": "Email",
		"register.password": "Password",
		"register.confirm_password": "Confirm Password",
		"register.submit": "Register",
		"register.switch_to_login": "Already have an account? Login",
		"register.error_password_mismatch": "Passwords do not match.",
		"register.error_empty_fields": "All fields are required.",
		"register.error_invalid_email": "Enter a valid email address.",
		"register.success": "Account created! Please log in.",

		"hud.trust_score": "Trust Score",
		"hud.room_label": "Room",

		"rooms.phishing_inbox": "Phishing Inbox",
		"rooms.upi_otp_kiosk": "UPI / OTP Kiosk",
		"rooms.fake_login_corridor": "Fake Login Corridor",
		"rooms.password_vault_lab": "Password Vault Lab",
		"rooms.safe_browsing_street": "Safe Browsing Street",

		"action.email.opened": "Open",
		"action.email.reported": "Report",
		"action.email.deleted": "Delete",
		"action.email.ignored": "Ignore",
		"action.payment.approve": "Approve",
		"action.payment.decline": "Decline",
		"action.payment.verify_first": "Verify First",
		"action.login.enter_credentials": "Enter Credentials",
		"action.login.check_url": "Check URL",
		"action.login.leave_page": "Leave Page",
		"action.storefront.enter_site": "Enter Site",
		"action.storefront.check_certificate": "Check Certificate",
		"action.storefront.leave": "Leave",

		"password.title": "Set Your Password",
		"password.placeholder": "Type a password...",
		"password.strength_weak": "Weak",
		"password.strength_medium": "Medium",
		"password.strength_strong": "Strong",
		"password.submit": "Submit Password",

		"debrief.correct": "Correct!",
		"debrief.incorrect": "That was a mistake.",
		"debrief.trust_change": "Trust Score",
		"debrief.red_flags_title": "What gave it away:",
		"debrief.none_title": "Why this was safe:",
		"debrief.continue": "Continue",

		"badge.toast_prefix": "Badge earned:",
		"badge.phishing_inbox_expert": "Phishing Expert",
		"badge.upi_otp_kiosk_expert": "UPI Safety Expert",
		"badge.fake_login_corridor_expert": "Login Vigilance Expert",
		"badge.password_vault_lab_expert": "Password Pro",
		"badge.safe_browsing_street_expert": "Safe Browsing Expert",

		"leaderboard.title": "Leaderboard",
		"leaderboard.rank": "Rank",
		"leaderboard.username": "Player",
		"leaderboard.trust_score": "Trust Score",
		"leaderboard.empty": "No scores yet. Be the first!",

		"admin.title": "CyberGuard 3D - Scenario Admin",
		"admin.add": "Add Scenario",
		"admin.edit": "Edit",
		"admin.delete": "Delete",
		"admin.save": "Save",
		"admin.cancel": "Cancel",
		"admin.field.code": "Code",
		"admin.field.room": "Room",
		"admin.field.title": "Title",
		"admin.field.difficulty": "Difficulty",
		"admin.field.is_fraud": "Is Fraud",
		"admin.field.red_flags": "Red Flags",
		"admin.field.correct_actions": "Correct Actions",
		"admin.no_auth_notice": "No admin authentication in this build phase - see README.",
	},
	"hi": {
		"common.connection_error": "कनेक्शन त्रुटि, क्या सर्वर चल रहा है?",
		"common.continue": "जारी रखें",
		"common.back": "वापस",
		"common.cancel": "रद्द करें",
		"common.submit": "जमा करें",
		"common.loading": "लोड हो रहा है...",

		"menu.title": "साइबरगार्ड 3D",
		"menu.login": "लॉगिन",
		"menu.register": "रजिस्टर करें",
		"menu.leaderboard": "लीडरबोर्ड",
		"menu.quit": "बाहर निकलें",
		"menu.language": "भाषा",
		"menu.logout": "लॉग आउट",

		"login.title": "लॉगिन",
		"login.username": "उपयोगकर्ता नाम",
		"login.password": "पासवर्ड",
		"login.submit": "लॉगिन करें",
		"login.switch_to_register": "खाता नहीं है? रजिस्टर करें",
		"login.error_generic": "लॉगिन विफल।",

		"register.title": "रजिस्टर करें",
		"register.username": "उपयोगकर्ता नाम",
		"register.email": "ईमेल",
		"register.password": "पासवर्ड",
		"register.confirm_password": "पासवर्ड की पुष्टि करें",
		"register.submit": "रजिस्टर करें",
		"register.switch_to_login": "पहले से खाता है? लॉगिन करें",
		"register.error_password_mismatch": "पासवर्ड मेल नहीं खाते।",
		"register.error_empty_fields": "सभी फ़ील्ड आवश्यक हैं।",
		"register.error_invalid_email": "मान्य ईमेल पता दर्ज करें।",
		"register.success": "खाता बन गया! कृपया लॉगिन करें।",

		"hud.trust_score": "ट्रस्ट स्कोर",
		"hud.room_label": "कमरा",

		"rooms.phishing_inbox": "फ़िशिंग इनबॉक्स",
		"rooms.upi_otp_kiosk": "यूपीआई / ओटीपी कियोस्क",
		"rooms.fake_login_corridor": "नकली लॉगिन गलियारा",
		"rooms.password_vault_lab": "पासवर्ड वॉल्ट लैब",
		"rooms.safe_browsing_street": "सुरक्षित ब्राउज़िंग स्ट्रीट",

		"action.email.opened": "खोलें",
		"action.email.reported": "रिपोर्ट करें",
		"action.email.deleted": "हटाएं",
		"action.email.ignored": "अनदेखा करें",
		"action.payment.approve": "स्वीकृत करें",
		"action.payment.decline": "अस्वीकार करें",
		"action.payment.verify_first": "पहले सत्यापित करें",
		"action.login.enter_credentials": "क्रेडेंशियल दर्ज करें",
		"action.login.check_url": "यूआरएल जांचें",
		"action.login.leave_page": "पेज छोड़ें",
		"action.storefront.enter_site": "साइट में प्रवेश करें",
		"action.storefront.check_certificate": "प्रमाणपत्र जांचें",
		"action.storefront.leave": "छोड़ें",

		"password.title": "अपना पासवर्ड सेट करें",
		"password.placeholder": "एक पासवर्ड टाइप करें...",
		"password.strength_weak": "कमज़ोर",
		"password.strength_medium": "मध्यम",
		"password.strength_strong": "मज़बूत",
		"password.submit": "पासवर्ड जमा करें",

		"debrief.correct": "सही!",
		"debrief.incorrect": "यह एक गलती थी।",
		"debrief.trust_change": "ट्रस्ट स्कोर",
		"debrief.red_flags_title": "इससे पता चला:",
		"debrief.none_title": "यह सुरक्षित क्यों था:",
		"debrief.continue": "जारी रखें",

		"badge.toast_prefix": "बैज अर्जित:",
		"badge.phishing_inbox_expert": "फ़िशिंग विशेषज्ञ",
		"badge.upi_otp_kiosk_expert": "यूपीआई सुरक्षा विशेषज्ञ",
		"badge.fake_login_corridor_expert": "लॉगिन सतर्कता विशेषज्ञ",
		"badge.password_vault_lab_expert": "पासवर्ड प्रो",
		"badge.safe_browsing_street_expert": "सुरक्षित ब्राउज़िंग विशेषज्ञ",

		"leaderboard.title": "लीडरबोर्ड",
		"leaderboard.rank": "रैंक",
		"leaderboard.username": "खिलाड़ी",
		"leaderboard.trust_score": "ट्रस्ट स्कोर",
		"leaderboard.empty": "अभी तक कोई स्कोर नहीं। पहले बनें!",

		"admin.title": "साइबरगार्ड 3D - परिदृश्य व्यवस्थापक",
		"admin.add": "परिदृश्य जोड़ें",
		"admin.edit": "संपादित करें",
		"admin.delete": "हटाएं",
		"admin.save": "सहेजें",
		"admin.cancel": "रद्द करें",
		"admin.field.code": "कोड",
		"admin.field.room": "कमरा",
		"admin.field.title": "शीर्षक",
		"admin.field.difficulty": "कठिनाई",
		"admin.field.is_fraud": "क्या धोखाधड़ी है",
		"admin.field.red_flags": "चेतावनी संकेत",
		"admin.field.correct_actions": "सही कार्रवाई",
		"admin.no_auth_notice": "इस निर्माण चरण में कोई व्यवस्थापक प्रमाणीकरण नहीं है - README देखें।",
	},
}


func set_language(code: String) -> void:
	if not _strings.has(code):
		code = "en"
	current_language = code
	language_changed.emit(code)


func get_string(key: String) -> String:
	var table: Dictionary = _strings.get(current_language, _strings["en"])
	if table.has(key):
		return table[key]
	return _strings["en"].get(key, key)


func available_languages() -> Array:
	return _strings.keys()
