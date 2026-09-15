class_name CyberSenseScreen
extends Control
## A standalone bonus tool: paste any suspicious message and get an instant rule-based risk
## analysis. Deliberately simple keyword/pattern matching, not a machine-learning model - see
## the project README for why that distinction matters.

## Each category: [indicator_text_key, Array[keyword]]. A category counts once if ANY of its
## keywords appear anywhere in the (lowercased) input text.
const CATEGORIES: Array = [
	["cybersense.indicator_urgency", ["immediately", "within 24 hours", "act now", "urgent", "suspend", "expire", "act fast", "limited time"]],
	["cybersense.indicator_credential_request", ["otp", "pin", "cvv", "password", "verify your account", "verify your identity", "upi pin"]],
	["cybersense.indicator_suspicious_link", ["bit.ly", "click here", "click below", "click the link", "http://"]],
	["cybersense.indicator_generic_greeting", ["dear customer", "dear user", "dear account holder", "valued customer"]],
	["cybersense.indicator_too_good", ["you won", "you've won", "cashback", "prize", "free gift", "congratulations"]],
	["cybersense.indicator_payment_pressure", ["pay now", "transfer immediately", "collect request", "share your pin", "send money now"]],
]

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var input_edit: TextEdit = %InputEdit
@onready var analyze_button: Button = %AnalyzeButton
@onready var back_button: Button = %BackButton
@onready var risk_label: Label = %RiskLabel
@onready var indicators_title_label: Label = %IndicatorsTitleLabel
@onready var indicators_list: VBoxContainer = %IndicatorsList
@onready var error_label: Label = %ErrorLabel


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	title_label.text = Localization.get_string("cybersense.title")
	subtitle_label.text = Localization.get_string("cybersense.subtitle")
	input_edit.placeholder_text = Localization.get_string("cybersense.placeholder")
	analyze_button.text = Localization.get_string("cybersense.analyze")
	back_button.text = Localization.get_string("common.back")
	indicators_title_label.text = Localization.get_string("cybersense.indicators_title")
	risk_label.text = ""
	error_label.visible = false

	analyze_button.pressed.connect(_on_analyze_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/room_select_screen.tscn")


func _on_analyze_pressed() -> void:
	var text: String = input_edit.text.strip_edges()
	if text == "":
		error_label.text = Localization.get_string("cybersense.empty_input")
		error_label.visible = true
		risk_label.text = ""
		_clear_indicators()
		return

	error_label.visible = false
	var lower_text: String = text.to_lower()

	var matched: Array = []
	for category in CATEGORIES:
		var indicator_key: String = category[0]
		var keywords: Array = category[1]
		for keyword in keywords:
			if lower_text.contains(keyword):
				matched.append(indicator_key)
				break

	_show_result(matched.size(), matched)


func _show_result(matched_count: int, matched_keys: Array) -> void:
	var risk_key: String
	var color: Color

	if matched_count >= 6:
		risk_key = "cybersense.risk_critical"
		color = Color(0.9, 0.2, 0.25)
	elif matched_count >= 4:
		risk_key = "cybersense.risk_high"
		color = Color(0.9, 0.45, 0.2)
	elif matched_count >= 2:
		risk_key = "cybersense.risk_medium"
		color = Color(0.9, 0.75, 0.2)
	else:
		risk_key = "cybersense.risk_low"
		color = Color(0.3, 0.8, 0.4)

	risk_label.text = "%s %s" % [Localization.get_string("cybersense.risk_label"), Localization.get_string(risk_key)]
	risk_label.modulate = color

	_clear_indicators()
	if matched_keys.is_empty():
		var label: Label = Label.new()
		label.text = Localization.get_string("cybersense.no_indicators")
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		indicators_list.add_child(label)
	else:
		for key in matched_keys:
			var label: Label = Label.new()
			label.text = "- %s" % Localization.get_string(key)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			indicators_list.add_child(label)


func _clear_indicators() -> void:
	for child in indicators_list.get_children():
		child.queue_free()
