class_name PasswordTerminal
extends InteractableObject3D
## A vault terminal. It has no fixed action buttons - password_vault_lab.gd's
## on_object_clicked() opens PasswordInputPopup (a free-text field with a live strength
## meter) instead of the generic ActionPopup, then submits "strong" or "weak" as the action.

@onready var title_label: Label3D = $TitleLabel
@onready var card_mesh: MeshInstance3D = $CardMesh
@onready var stamp_label: Label3D = $StampLabel

var _material: StandardMaterial3D


func _ready() -> void:
	stamp_label.visible = false
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.35, 0.65, 0.68)
	card_mesh.set_surface_override_material(0, _material)


func _configure(scenario: Dictionary) -> void:
	title_label.text = str(scenario.get("title", ""))


## Intentionally empty: this room's click flow bypasses the generic ActionPopup entirely.
func get_action_options() -> Array:
	return []


func play_consequence(was_correct: bool, _action: String) -> void:
	stamp_label.visible = true
	if was_correct:
		stamp_label.text = "VAULT SECURED"
		_material.albedo_color = Color(0.3, 0.75, 0.4)
	else:
		stamp_label.text = "VAULT AT RISK"
		_material.albedo_color = Color(0.85, 0.2, 0.2)
	stamp_label.modulate = Color(0.3, 0.85, 0.45) if was_correct else Color(0.9, 0.25, 0.25)
