class_name EmailReaderPopup
extends Control
## Phishing Inbox's interaction: the email opens inline with its real body text. Hovering over
## the sender reveals its real address (native Control tooltip); hovering over the body link
## reveals its real destination URL in a preview line. Clicking the link IS the "opened" action -
## there is no "Open" button. Report/Delete/Ignore remain as an explicit judgment call.

@onready var title_label: Label = %TitleLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var sender_label: Label = %SenderLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var link_preview_label: Label = %LinkPreviewLabel
@onready var report_button: Button = %ReportButton
@onready var delete_button: Button = %DeleteButton
@onready var ignore_button: Button = %IgnoreButton

var _callback: Callable = Callable()
var _link_url: String = ""


func _ready() -> void:
	visible = false
	instruction_label.text = Localization.get_string("email.reader.instruction")
	report_button.text = Localization.get_string("action.email.reported")
	delete_button.text = Localization.get_string("action.email.deleted")
	ignore_button.text = Localization.get_string("action.email.ignored")

	body_label.meta_hover_started.connect(_on_link_hover_started)
	body_label.meta_hover_ended.connect(_on_link_hover_ended)
	body_label.meta_clicked.connect(_on_link_clicked)
	report_button.pressed.connect(_on_button_pressed.bind("reported"))
	delete_button.pressed.connect(_on_button_pressed.bind("deleted"))
	ignore_button.pressed.connect(_on_button_pressed.bind("ignored"))


func open(title: String, content: Dictionary, on_chosen: Callable) -> void:
	_callback = on_chosen
	title_label.text = title

	var sender_display: String = str(content.get("sender_display", "Unknown Sender"))
	var sender_domain: String = str(content.get("sender_domain", ""))
	sender_label.text = sender_display
	sender_label.tooltip_text = Localization.get_string("email.reader.tooltip_prefix") + sender_domain

	var body: String = str(content.get("body", ""))
	var link_text: String = str(content.get("link_text", ""))
	_link_url = str(content.get("link_url", ""))

	link_preview_label.text = ""
	body_label.clear()
	body_label.append_text(body.replace("[", "[lb]"))
	if link_text != "":
		body_label.append_text("\n\n[url=link][color=#6db3ff][u]%s[/u][/color][/url]" % link_text.replace("[", "[lb]"))

	visible = true
	_release_mouse()


func _on_link_hover_started(_meta) -> void:
	link_preview_label.text = Localization.get_string("email.reader.tooltip_prefix") + _link_url


func _on_link_hover_ended() -> void:
	link_preview_label.text = ""


func _on_link_clicked(_meta) -> void:
	_close_and_dispatch("opened")


func _on_button_pressed(action: String) -> void:
	_close_and_dispatch(action)


func _close_and_dispatch(action: String) -> void:
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
