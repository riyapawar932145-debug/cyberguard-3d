class_name StorefrontPopup
extends Control
## Safe Browsing Street's interaction: the SAME layout renders for every scenario regardless of
## whether it's a trap - the client never receives is_fraud, so the UI can't hint at it. The big
## central button always sends "enter_site" (skinned as "Claim Now!" when the scenario carries a
## prize popup_text); the real judgment calls (check certificate / leave) are small, deliberately
## less-prominent controls elsewhere in the panel.

@onready var banner_label: Label = %BannerLabel
@onready var storefront_name_label: Label = %StorefrontNameLabel
@onready var address_label: Label = %AddressLabel
@onready var enter_button: Button = %EnterButton
@onready var check_certificate_button: Button = %CheckCertificateButton
@onready var leave_button: Button = %LeaveButton

var _callback: Callable = Callable()


func _ready() -> void:
	visible = false
	check_certificate_button.text = Localization.get_string("action.storefront.check_certificate")
	leave_button.text = Localization.get_string("action.storefront.leave")

	enter_button.pressed.connect(_on_button_pressed.bind("enter_site"))
	check_certificate_button.pressed.connect(_on_button_pressed.bind("check_certificate"))
	leave_button.pressed.connect(_on_button_pressed.bind("leave"))


func open(_title: String, content: Dictionary, on_chosen: Callable) -> void:
	_callback = on_chosen

	var storefront_name: String = str(content.get("storefront_name", ""))
	var domain: String = str(content.get("domain", ""))
	var popup_text: String = str(content.get("popup_text", ""))

	storefront_name_label.text = storefront_name
	address_label.text = Localization.get_string("storefront.address_prefix") + domain

	banner_label.visible = popup_text != ""
	banner_label.text = popup_text

	enter_button.text = Localization.get_string(
		"storefront.claim_now" if popup_text != "" else "action.storefront.enter_site"
	)

	visible = true
	_release_mouse()


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
