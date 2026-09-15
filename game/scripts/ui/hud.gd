class_name HUD
extends Control
## Always-on overlay inside a room: room name, live trust score + level title, inline
## connection-error text, and a non-blocking toast queue (badges, streak combos, level-ups).

const TOAST_COLOR_BADGE: Color = Color(0.95, 0.8, 0.25)
const TOAST_COLOR_STREAK: Color = Color(0.95, 0.55, 0.2)
const TOAST_COLOR_LEVEL_UP: Color = Color(0.45, 0.85, 0.95)

@onready var room_label: Label = %RoomLabel
@onready var trust_label: Label = %TrustLabel
@onready var connection_error_label: Label = %ConnectionErrorLabel
@onready var badge_toast: Panel = %BadgeToast
@onready var badge_toast_label: Label = %BadgeToastLabel
@onready var menu_button: Button = %MenuButton

var _toast_queue: Array = []
var _toast_active: bool = false


func _ready() -> void:
	connection_error_label.visible = false
	badge_toast.visible = false
	menu_button.text = Localization.get_string("common.back")
	menu_button.pressed.connect(_on_menu_pressed)


func set_room_label(room_name: String) -> void:
	room_label.text = Localization.get_string("rooms." + room_name)


func set_trust_score(value: int) -> void:
	trust_label.text = "%s (%s: %d)" % [
		SessionState.get_level_title(value),
		Localization.get_string("hud.trust_score"),
		value,
	]


func show_connection_error(message: String) -> void:
	connection_error_label.text = message
	connection_error_label.visible = true
	var timer: SceneTreeTimer = get_tree().create_timer(3.0)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(connection_error_label):
			connection_error_label.visible = false
	)


func show_badge_toast(badge_code: String) -> void:
	var text: String = "%s %s" % [
		Localization.get_string("badge.toast_prefix"),
		Localization.get_string("badge.%s" % badge_code),
	]
	_enqueue_toast(text, TOAST_COLOR_BADGE)


func show_streak_toast(streak: int) -> void:
	var text: String = "%s x%d!" % [Localization.get_string("streak.combo_prefix"), streak]
	_enqueue_toast(text, TOAST_COLOR_STREAK)


func show_level_up_toast(new_title: String) -> void:
	var text: String = "%s %s" % [Localization.get_string("streak.level_up_prefix"), new_title]
	_enqueue_toast(text, TOAST_COLOR_LEVEL_UP)


func _enqueue_toast(text: String, color: Color) -> void:
	_toast_queue.append([text, color])
	if not _toast_active:
		_play_next_toast()


func _play_next_toast() -> void:
	if _toast_queue.is_empty():
		_toast_active = false
		return

	_toast_active = true
	var item: Array = _toast_queue.pop_front()
	badge_toast_label.text = item[0]
	badge_toast_label.modulate = item[1]
	badge_toast.visible = true
	badge_toast.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(badge_toast, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.8)
	tween.tween_property(badge_toast, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		badge_toast.visible = false
		_play_next_toast()
	)


func _on_menu_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/ui/room_select_screen.tscn")
