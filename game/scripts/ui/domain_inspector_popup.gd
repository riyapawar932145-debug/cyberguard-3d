class_name DomainInspectorPopup
extends Control
## Fake Login Corridor's interaction: the address bar starts as an inert-looking text strip.
## Clicking it "zooms" into the domain (a larger-font panel) before revealing the judgment-call
## buttons (Flag as Suspicious / Looks Legitimate) - Enter Credentials and Leave Page stay
## available the whole time, so leaving without ever zooming in is always possible.

@onready var title_label: Label = %TitleLabel
@onready var instruction_label: Label = %InstructionLabel
@onready var zoom_label: Label = %ZoomLabel
@onready var address_bar_button: Button = %AddressBarButton
@onready var zoom_panel: PanelContainer = %ZoomPanel
@onready var zoomed_domain_label: Label = %ZoomedDomainLabel
@onready var flag_suspicious_button: Button = %FlagSuspiciousButton
@onready var looks_legit_button: Button = %LooksLegitButton
@onready var enter_credentials_button: Button = %EnterCredentialsButton
@onready var leave_page_button: Button = %LeavePageButton

var _callback: Callable = Callable()


func _ready() -> void:
	visible = false
	instruction_label.text = Localization.get_string("login.zoom_instruction")
	zoom_label.text = Localization.get_string("login.zoom_domain")
	flag_suspicious_button.text = Localization.get_string("login.flag_suspicious")
	looks_legit_button.text = Localization.get_string("login.looks_legit")
	enter_credentials_button.text = Localization.get_string("action.login.enter_credentials")
	leave_page_button.text = Localization.get_string("action.login.leave_page")

	address_bar_button.pressed.connect(_on_zoom_pressed)
	flag_suspicious_button.pressed.connect(_on_button_pressed.bind("check_url"))
	looks_legit_button.pressed.connect(_on_button_pressed.bind("confirmed_legit"))
	enter_credentials_button.pressed.connect(_on_button_pressed.bind("enter_credentials"))
	leave_page_button.pressed.connect(_on_button_pressed.bind("leave_page"))


func open(title: String, content: Dictionary, on_chosen: Callable) -> void:
	_callback = on_chosen

	var domain: String = str(content.get("domain", ""))
	var page_heading: String = str(content.get("page_heading", title))
	title_label.text = page_heading
	address_bar_button.text = domain
	zoomed_domain_label.text = domain

	instruction_label.visible = true
	zoom_panel.visible = false

	visible = true
	_release_mouse()


func _on_zoom_pressed() -> void:
	instruction_label.visible = false
	zoom_panel.visible = true


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
