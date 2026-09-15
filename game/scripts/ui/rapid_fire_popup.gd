class_name RapidFirePopup
extends Control
## Rapid Fire's session UI: cycles through several short statements in a row, each under a
## visible countdown, judged SAFE or UNSAFE. Unlike every other room's popup this does NOT show
## the full DebriefPanel per answer - only a quick flash - because showing a full debrief after
## every one of many rapid answers would defeat the entire point of "rapid". A session summary
## appears at the end instead. Runs its own submit-and-wait cycle directly against ApiClient
## rather than RoomBase's one-object flow; see RapidFireRoom for how the two stay decoupled.

const SESSION_LENGTH: int = 8
const COUNTDOWN_SECONDS: float = 6.0

@onready var title_label: Label = %TitleLabel
@onready var session_progress_label: Label = %SessionProgressLabel
@onready var countdown_bar: ProgressBar = %CountdownBar
@onready var statement_label: Label = %StatementLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var safe_button: Button = %SafeButton
@onready var unsafe_button: Button = %UnsafeButton
@onready var error_label: Label = %ErrorLabel
@onready var question_box: Control = %QuestionBox
@onready var summary_box: Control = %SummaryBox
@onready var summary_label: Label = %SummaryLabel
@onready var done_button: Button = %DoneButton

var _queue: Array = []
var _index: int = 0
var _correct_count: int = 0
var _total_score: int = 0
var _time_left: float = 0.0
var _awaiting_result: bool = false
var _click_time_ms: int = 0
var _on_result: Callable = Callable()
var _on_complete: Callable = Callable()


func _ready() -> void:
	visible = false
	set_process(false)
	title_label.text = Localization.get_string("rooms.rapid_fire")
	safe_button.text = Localization.get_string("action.rapidfire.safe")
	unsafe_button.text = Localization.get_string("action.rapidfire.unsafe")
	done_button.text = Localization.get_string("debrief.continue")
	error_label.visible = false

	safe_button.pressed.connect(_on_answer_pressed.bind("safe"))
	unsafe_button.pressed.connect(_on_answer_pressed.bind("unsafe"))
	done_button.pressed.connect(_on_done_pressed)


## on_result(result: Dictionary) fires after each answered (non-timeout) statement, before the
## next one loads - the room uses it to update Trust Score and show progression toasts.
## on_complete() fires once, after the session summary's Done button is pressed.
func start_session(pool: Array, on_result: Callable, on_complete: Callable) -> void:
	_on_result = on_result
	_on_complete = on_complete

	_queue = pool.duplicate(true)
	_queue.shuffle()
	_queue = _queue.slice(0, mini(SESSION_LENGTH, _queue.size()))
	_index = 0
	_correct_count = 0
	_total_score = 0
	error_label.visible = false
	summary_box.visible = false
	question_box.visible = true

	visible = true
	_release_mouse()

	if _queue.is_empty():
		_show_summary()
		return

	_show_current()


func _show_current() -> void:
	var scenario: Dictionary = _queue[_index]
	var content: Dictionary = scenario.get("content", {})
	session_progress_label.text = "%d / %d" % [_index + 1, _queue.size()]
	statement_label.text = str(content.get("statement", scenario.get("title", "")))
	feedback_label.text = ""
	_time_left = COUNTDOWN_SECONDS
	_awaiting_result = false
	_set_buttons_enabled(true)
	_click_time_ms = Time.get_ticks_msec()
	set_process(true)


func _process(delta: float) -> void:
	if _awaiting_result:
		return
	_time_left -= delta
	countdown_bar.value = clampf(_time_left / COUNTDOWN_SECONDS, 0.0, 1.0) * 100.0
	if _time_left <= 0.0:
		_time_left = 0.0
		_on_timeout()


func _on_answer_pressed(action: String) -> void:
	if _awaiting_result:
		return
	set_process(false)
	_set_buttons_enabled(false)
	_awaiting_result = true

	var scenario: Dictionary = _queue[_index]
	var response_time_ms: int = Time.get_ticks_msec() - _click_time_ms

	ApiClient.result_submitted.connect(_on_result_received, CONNECT_ONE_SHOT)
	ApiClient.request_failed.connect(_on_submit_failed, CONNECT_ONE_SHOT)
	ApiClient.submit_result(SessionState.user_id, int(scenario.get("id", -1)), action, response_time_ms)


## Deliberately does NOT submit a wrong answer on timeout - not deciding in time forfeits that
## statement's score rather than being punished as if you'd actively chosen wrong.
func _on_timeout() -> void:
	set_process(false)
	_set_buttons_enabled(false)
	feedback_label.text = Localization.get_string("rapidfire.timeout")
	feedback_label.modulate = Color(0.9, 0.7, 0.2)
	await get_tree().create_timer(0.7).timeout
	_advance()


func _on_result_received(result: Dictionary) -> void:
	if ApiClient.request_failed.is_connected(_on_submit_failed):
		ApiClient.request_failed.disconnect(_on_submit_failed)

	var was_correct: bool = result.get("was_correct", false)
	_total_score += int(result.get("score_delta", 0))
	if was_correct:
		_correct_count += 1

	feedback_label.text = Localization.get_string("debrief.correct" if was_correct else "debrief.incorrect")
	feedback_label.modulate = Color(0.35, 0.85, 0.45) if was_correct else Color(0.9, 0.32, 0.32)

	if _on_result.is_valid():
		_on_result.call(result)

	await get_tree().create_timer(0.7).timeout
	_advance()


func _on_submit_failed(_context: String, message: String) -> void:
	if ApiClient.result_submitted.is_connected(_on_result_received):
		ApiClient.result_submitted.disconnect(_on_result_received)
	error_label.text = message
	error_label.visible = true
	_set_buttons_enabled(true)
	_awaiting_result = false
	set_process(true)


func _advance() -> void:
	_index += 1
	if _index >= _queue.size():
		_show_summary()
	else:
		_show_current()


func _show_summary() -> void:
	question_box.visible = false
	summary_box.visible = true
	var sign_str: String = "+" if _total_score >= 0 else ""
	summary_label.text = "%d / %d  •  %s%d %s" % [
		_correct_count,
		_queue.size(),
		sign_str,
		_total_score,
		Localization.get_string("hud.trust_score"),
	]


func _on_done_pressed() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var callback: Callable = _on_complete
	_on_complete = Callable()
	if callback.is_valid():
		callback.call()


func _set_buttons_enabled(enabled: bool) -> void:
	safe_button.disabled = not enabled
	unsafe_button.disabled = not enabled


## See ActionPopup._release_mouse() for why this is deferred rather than set immediately.
func _release_mouse() -> void:
	await get_tree().create_timer(0.1).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
