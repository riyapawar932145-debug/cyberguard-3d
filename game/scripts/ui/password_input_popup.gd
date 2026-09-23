class_name PasswordInputPopup
extends Control
## Free-text password entry for Password Vault Lab. Replaces the fixed ActionPopup button list
## for this room only: the player types into PasswordEdit and submits blind - deliberately NO
## live strength feedback while typing, so the player can't just watch a meter to pass. The
## room itself (password_vault_lab.gd) renders the actual consequence - a "vault secured" flash
## for a strong password, or an attacker breaking in through the door for a weak one.

const COMMON_PASSWORDS: Array[String] = [
	"password", "123456", "12345678", "qwerty", "letmein", "admin",
	"welcome", "iloveyou", "abc123", "password1", "111111", "123123",
	"monkey", "dragon", "trustno1",
]

@onready var title_label: Label = %TitleLabel
@onready var hint_label: Label = %HintLabel
@onready var password_edit: LineEdit = %PasswordEdit
@onready var submit_button: Button = %SubmitButton

var _callback: Callable = Callable()


func _ready() -> void:
	visible = false
	password_edit.placeholder_text = Localization.get_string("password.placeholder")
	submit_button.text = Localization.get_string("password.submit")
	submit_button.pressed.connect(_on_submit_pressed)


## on_submitted is called with a single String argument: "strong" or "weak".
func open(title: String, on_submitted: Callable, hint: String = "") -> void:
	_callback = on_submitted
	title_label.text = title if title != "" else Localization.get_string("password.title")
	hint_label.text = hint
	hint_label.visible = hint != ""
	password_edit.text = ""
	visible = true
	_release_mouse()
	password_edit.grab_focus()


## See ActionPopup._release_mouse() for why this is deferred rather than set immediately.
func _release_mouse() -> void:
	await get_tree().create_timer(0.1).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


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


func _on_submit_pressed() -> void:
	var password: String = password_edit.text
	var action: String = "strong" if _is_strong(password) else "weak"

	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var callback: Callable = _callback
	_callback = Callable()
	if callback.is_valid():
		callback.call(action)
