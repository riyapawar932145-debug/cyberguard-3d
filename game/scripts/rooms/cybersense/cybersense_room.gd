class_name CyberSenseRoom
extends Node3D
## CyberSense is a self-contained client-side tool, not a scored scenario room - no
## ApiClient.load_scenarios/submit_result involved, so this deliberately does NOT extend
## RoomBase. Clicking the terminal just changes scene to the analysis screen directly.

@onready var hud: Control = %HUD
@onready var instruction_popup: Control = %InstructionPopup


func _ready() -> void:
	add_to_group("room_controller")
	if hud:
		hud.set_room_label("cybersense")
		hud.set_trust_score(SessionState.trust_score)
	if instruction_popup:
		instruction_popup.open("instruction.cybersense")


func on_object_clicked(_object: Node) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/ui/cybersense_screen.tscn")
