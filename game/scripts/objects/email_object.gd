class_name EmailObject
extends InteractableObject3D
## A floating "email card" the player can Open / Report / Delete / Ignore.

@onready var subject_label: Label3D = $SubjectLabel
@onready var card_mesh: MeshInstance3D = $CardMesh
@onready var stamp_label: Label3D = $StampLabel

var _material: StandardMaterial3D


func _ready() -> void:
	stamp_label.visible = false
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.92, 0.92, 0.95)
	card_mesh.set_surface_override_material(0, _material)


func _configure(scenario: Dictionary) -> void:
	subject_label.text = str(scenario.get("title", ""))


func get_action_options() -> Array:
	return [
		{"action": "opened", "label_key": "action.email.opened"},
		{"action": "reported", "label_key": "action.email.reported"},
		{"action": "deleted", "label_key": "action.email.deleted"},
		{"action": "ignored", "label_key": "action.email.ignored"},
	]


func play_consequence(was_correct: bool, action: String) -> void:
	stamp_label.visible = true

	match action:
		"reported":
			stamp_label.text = "REPORT SENT"
			_material.albedo_color = Color(0.25, 0.55, 0.95) if was_correct else Color(0.55, 0.55, 0.6)
		"deleted":
			stamp_label.text = "DELETED"
			_material.albedo_color = Color(0.45, 0.45, 0.5) if was_correct else Color(0.55, 0.55, 0.6)
		"opened":
			stamp_label.text = "CREDENTIALS STOLEN" if not was_correct else "OPENED"
			_material.albedo_color = Color(0.85, 0.2, 0.2) if not was_correct else Color(0.3, 0.75, 0.4)
		_:
			stamp_label.text = "IGNORED"
			_material.albedo_color = Color(0.6, 0.6, 0.65)

	stamp_label.modulate = Color(0.3, 0.85, 0.45) if was_correct else Color(0.9, 0.25, 0.25)
