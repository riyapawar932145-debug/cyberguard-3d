class_name DebriefPanel
extends Control
## Shown after the in-world consequence plays: verdict, trust score delta, and a bulleted
## explanation built from the scenario's red_flags string (only revealed after submission).

@onready var verdict_label: Label = %VerdictLabel
@onready var trust_label: Label = %TrustLabel
@onready var breakdown_label: Label = %BreakdownLabel
@onready var flags_title_label: Label = %FlagsTitleLabel
@onready var flags_list: VBoxContainer = %FlagsList
@onready var continue_button: Button = %ContinueButton

var _callback: Callable = Callable()


func _ready() -> void:
	visible = false
	continue_button.text = Localization.get_string("debrief.continue")
	continue_button.pressed.connect(_on_continue_pressed)


func show_debrief(result: Dictionary, on_continue: Callable) -> void:
	_callback = on_continue

	var was_correct: bool = result.get("was_correct", false)
	verdict_label.text = Localization.get_string("debrief.correct" if was_correct else "debrief.incorrect")
	verdict_label.modulate = Color(0.35, 0.85, 0.45) if was_correct else Color(0.9, 0.32, 0.32)

	var delta: int = int(result.get("score_delta", 0))
	var sign_str: String = "+" if delta >= 0 else ""
	trust_label.text = "%s: %s%d  (%d)" % [
		Localization.get_string("debrief.trust_change"),
		sign_str,
		delta,
		int(result.get("new_trust_score", 0)),
	]

	var breakdown: Dictionary = result.get("score_breakdown", {})
	if was_correct and not breakdown.is_empty():
		var parts: PackedStringArray = []
		parts.append("%s %+d" % [Localization.get_string("debrief.score_base"), int(breakdown.get("base", 0))])
		if int(breakdown.get("speed_bonus", 0)) > 0:
			parts.append("%s %+d" % [Localization.get_string("debrief.score_speed_bonus"), int(breakdown.get("speed_bonus", 0))])
		if int(breakdown.get("streak_bonus", 0)) > 0:
			parts.append("%s %+d" % [Localization.get_string("debrief.score_streak_bonus"), int(breakdown.get("streak_bonus", 0))])
		breakdown_label.text = "  |  ".join(parts)
		breakdown_label.visible = true
	else:
		breakdown_label.visible = false

	var flags_text: String = str(result.get("red_flags", ""))
	flags_title_label.text = Localization.get_string(
		"debrief.none_title" if flags_text.begins_with("None") else "debrief.red_flags_title"
	)

	for child in flags_list.get_children():
		child.queue_free()

	for part in flags_text.split(","):
		var trimmed: String = part.strip_edges()
		if trimmed == "":
			continue
		var label: Label = Label.new()
		label.text = "- %s" % trimmed
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		flags_list.add_child(label)

	visible = true
	_release_mouse()


## See ActionPopup._release_mouse() for why this is deferred rather than set immediately.
func _release_mouse() -> void:
	await get_tree().create_timer(0.1).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_continue_pressed() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var callback: Callable = _callback
	_callback = Callable()
	if callback.is_valid():
		callback.call()
