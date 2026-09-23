class_name PasswordVaultLabRoom
extends RoomBase
## Password Vault Lab is not fraud-detection: clicking a terminal opens a free-text password
## popup (no live strength meter - see password_input_popup.gd) instead of the generic
## ActionPopup. The real consequence plays out in the room itself: a strong password gets a
## clean "VAULT SECURED" flash; a weak one gets an attacker sprinting in from the door before
## the debrief explains why. PasswordTerminal.play_consequence() calls back into
## play_vault_outcome() below via the "room_controller" group, same lookup pattern player.gd
## already uses to reach whichever room is active.

@onready var password_popup: PasswordInputPopup = %PasswordInputPopup
@onready var attacker: Node3D = $Attacker
@onready var attacker_label: Label3D = $Attacker/Label3D
@onready var door_marker: Marker3D = $DoorMarker
@onready var confrontation_marker: Marker3D = $ConfrontationMarker
@onready var alert_overlay: Control = %AlertOverlay
@onready var alert_title_label: Label = %AlertTitleLabel
@onready var alert_body_label: Label = %AlertBodyLabel


func _ready() -> void:
	super._ready()
	attacker.visible = false
	attacker_label.text = Localization.get_string("vault.attacker_label")
	alert_overlay.visible = false


func on_object_clicked(object: Node) -> void:
	if _busy or object == null:
		return

	var click_time_ms: int = Time.get_ticks_msec()
	var hint: String = str(object.scenario_content.get("hint", ""))
	password_popup.open(object.scenario_title, func(action: String) -> void:
		_submit(object, action, Time.get_ticks_msec() - click_time_ms)
	, hint)


## Called by PasswordTerminal.play_consequence() via the "room_controller" group lookup.
func play_vault_outcome(was_correct: bool) -> void:
	if was_correct:
		_flash_alert(
			Localization.get_string("vault.secured_title"),
			Localization.get_string("vault.secured_body"),
			Color(0.25, 0.8, 0.4),
		)
	else:
		_flash_alert(
			Localization.get_string("vault.alert_title"),
			Localization.get_string("vault.alert_body"),
			Color(0.9, 0.2, 0.2),
		)
		_run_attacker_sequence()


func _flash_alert(title: String, body: String, color: Color) -> void:
	alert_title_label.text = title
	alert_body_label.text = body
	alert_title_label.modulate = color
	alert_overlay.visible = true
	alert_overlay.modulate.a = 0.0

	var tween: Tween = create_tween()
	tween.tween_property(alert_overlay, "modulate:a", 1.0, 0.12)
	tween.tween_interval(1.0)
	tween.tween_property(alert_overlay, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		if is_instance_valid(alert_overlay):
			alert_overlay.visible = false
	)


func _run_attacker_sequence() -> void:
	attacker.position = door_marker.position
	attacker.look_at(confrontation_marker.global_position, Vector3.UP)
	attacker.visible = true

	var tween: Tween = create_tween()
	tween.tween_property(attacker, "position", confrontation_marker.position, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.5)
	tween.tween_callback(func() -> void:
		if is_instance_valid(attacker):
			attacker.visible = false
	)
