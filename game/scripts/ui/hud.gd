class_name HUD
extends Control
## Always-on overlay inside a room: room name, live trust score, inline connection-error
## text, and a non-blocking badge-earned toast.

@onready var room_label: Label = %RoomLabel
@onready var trust_label: Label = %TrustLabel
@onready var connection_error_label: Label = %ConnectionErrorLabel
@onready var badge_toast: Panel = %BadgeToast
@onready var badge_toast_label: Label = %BadgeToastLabel
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	connection_error_label.visible = false
	badge_toast.visible = false
	menu_button.text = Localization.get_string("common.back")
	menu_button.pressed.connect(_on_menu_pressed)


func set_room_label(room_name: String) -> void:
	room_label.text = Localization.get_string("rooms." + room_name)


func set_trust_score(value: int) -> void:
	trust_label.text = "%s: %d" % [Localization.get_string("hud.trust_score"), value]


func show_connection_error(message: String) -> void:
	connection_error_label.text = message
	connection_error_label.visible = true
	var timer: SceneTreeTimer = get_tree().create_timer(3.0)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(connection_error_label):
			connection_error_label.visible = false
	)


func show_badge_toast(badge_code: String) -> void:
	badge_toast_label.text = "%s %s" % [
		Localization.get_string("badge.toast_prefix"),
		Localization.get_string("badge.%s" % badge_code),
	]
	badge_toast.visible = true
	badge_toast.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(badge_toast, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(badge_toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: badge_toast.visible = false)


func _on_menu_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/ui/room_select_screen.tscn")
