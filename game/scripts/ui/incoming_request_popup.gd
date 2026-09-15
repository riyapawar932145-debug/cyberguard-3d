class_name IncomingRequestPopup
extends Control
## UPI/OTP Kiosk's interaction: a live incoming-call/payment-request card with a ticking 20s
## countdown that creates real time pressure. All three responses (submit OTP, approve, decline)
## stay available for the whole countdown; running out the clock auto-declines - a safe default,
## never a forced wrong answer.

const COUNTDOWN_SECONDS: float = 20.0

@onready var title_label: Label = %TitleLabel
@onready var caller_name_label: Label = %CallerNameLabel
@onready var lines_label: Label = %LinesLabel
@onready var countdown_bar: ProgressBar = %CountdownBar
@onready var countdown_label: Label = %CountdownLabel
@onready var otp_edit: LineEdit = %OtpEdit
@onready var submit_otp_button: Button = %SubmitOtpButton
@onready var approve_button: Button = %ApproveButton
@onready var decline_button: Button = %DeclineButton

var _callback: Callable = Callable()
var _time_left: float = COUNTDOWN_SECONDS
var _active: bool = false


func _ready() -> void:
	visible = false
	set_process(false)
	otp_edit.placeholder_text = Localization.get_string("upi.otp_placeholder")
	submit_otp_button.text = Localization.get_string("upi.submit_otp")
	approve_button.text = Localization.get_string("action.payment.approve")
	decline_button.text = Localization.get_string("action.payment.decline")

	submit_otp_button.pressed.connect(_on_submit_otp_pressed)
	approve_button.pressed.connect(_on_button_pressed.bind("approved"))
	decline_button.pressed.connect(_on_button_pressed.bind("declined"))


func open(title: String, content: Dictionary, on_chosen: Callable) -> void:
	_callback = on_chosen
	title_label.text = title
	caller_name_label.text = str(content.get("caller_name", ""))

	var lines: Array = content.get("caller_lines", [])
	var joined: PackedStringArray = PackedStringArray()
	for line in lines:
		joined.append(str(line))
	lines_label.text = "\n\n".join(joined)

	otp_edit.text = ""
	_time_left = COUNTDOWN_SECONDS
	_update_countdown_display()

	visible = true
	_active = true
	set_process(true)
	_release_mouse()


func _process(delta: float) -> void:
	if not _active:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		_update_countdown_display()
		_close_and_dispatch("declined")
		return
	_update_countdown_display()


func _update_countdown_display() -> void:
	countdown_bar.value = (_time_left / COUNTDOWN_SECONDS) * 100.0
	countdown_label.text = "%s %d" % [Localization.get_string("upi.time_remaining"), ceili(_time_left)]


func _on_submit_otp_pressed() -> void:
	_close_and_dispatch("shared_otp")


func _on_button_pressed(action: String) -> void:
	_close_and_dispatch(action)


func _close_and_dispatch(action: String) -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var callback: Callable = _callback
	_callback = Callable()
	if callback.is_valid():
		callback.call(action)


## See ActionPopup._release_mouse() for why this is deferred rather than set immediately.
func _release_mouse() -> void:
	await get_tree().create_timer(0.1).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
