class_name PasswordInputPopup
extends Control
## Free-text password entry for Password Vault Lab. Replaces the fixed ActionPopup button
## list for this room only: the player types into PasswordEdit and a live strength meter
## (length, upper/lower/digit/symbol mix, dictionary check) updates in real time. Submitting
## sends action_taken "strong" (>=4 of 5 criteria met and not a common password) or "weak".

const COMMON_PASSWORDS: Array[String] = [
	"password", "123456", "12345678", "qwerty", "letmein", "admin",
	"welcome", "iloveyou", "abc123", "password1", "111111", "123123",
	"monkey", "dragon", "trustno1",
]

@onready var title_label: Label = %TitleLabel
@onready var password_edit: LineEdit = %PasswordEdit
@onready var strength_bar: ProgressBar = %StrengthBar
@onready var strength_label: Label = %StrengthLabel
@onready var submit_button: Button = %SubmitButton

var _callback: Callable = Callable()


func _ready() -> void:
	visible = false
	password_edit.placeholder_text = Localization.get_string("password.placeholder")
	submit_button.text = Localization.get_string("password.submit")
	password_edit.text_changed.connect(_on_text_changed)
	submit_button.pressed.connect(_on_submit_pressed)


## on_submitted is called with a single String argument: "strong" or "weak".
func open(title: String, on_submitted: Callable) -> void:
	_callback = on_submitted
	title_label.text = title if title != "" else Localization.get_string("password.title")
	password_edit.text = ""
	_update_strength("")
	visible = true
	_release_mouse()
	password_edit.grab_focus()


## See ActionPopup._release_mouse() for why this is deferred rather than set immediately.
func _release_mouse() -> void:
	await get_tree().create_timer(0.1).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_text_changed(new_text: String) -> void:
	_update_strength(new_text)


func _criteria_met(password: String) -> int:
	var count: int = 0
	if password.length() >= 12:
		count += 1
	if _has_upper(password):
		count += 1
	if _has_lower(password):
		count += 1
	if _has_digit(password):
		count += 1
	if _has_symbol(password):
		count += 1
	return count


func _has_upper(text: String) -> bool:
	for c in text:
		if c >= "A" and c <= "Z":
			return true
	return false


func _has_lower(text: String) -> bool:
	for c in text:
		if c >= "a" and c <= "z":
			return true
	return false


func _has_digit(text: String) -> bool:
	for c in text:
		if c >= "0" and c <= "9":
			return true
	return false


func _has_symbol(text: String) -> bool:
	for c in text:
		var is_alnum: bool = (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")
		if not is_alnum:
			return true
	return false


func _is_common(password: String) -> bool:
	var lower: String = password.to_lower()
	return COMMON_PASSWORDS.has(lower)


func _is_strong(password: String) -> bool:
	return password != "" and _criteria_met(password) >= 4 and not _is_common(password)


func _update_strength(password: String) -> void:
	var met: int = _criteria_met(password)
	var common: bool = _is_common(password)

	var ratio: float
	var label_key: String
	var color: Color

	if password == "" or common or met <= 2:
		ratio = 0.15 if password != "" else 0.0
		label_key = "password.strength_weak"
		color = Color(0.85, 0.25, 0.25)
	elif met == 3:
		ratio = 0.6
		label_key = "password.strength_medium"
		color = Color(0.9, 0.7, 0.2)
	else:
		ratio = 1.0
		label_key = "password.strength_strong"
		color = Color(0.3, 0.8, 0.4)

	strength_bar.value = ratio * 100.0
	strength_bar.modulate = color
	strength_label.text = Localization.get_string(label_key)
	strength_label.modulate = color


func _on_submit_pressed() -> void:
	var password: String = password_edit.text
	var action: String = "strong" if _is_strong(password) else "weak"

	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var callback: Callable = _callback
	_callback = Callable()
	if callback.is_valid():
		callback.call(action)
