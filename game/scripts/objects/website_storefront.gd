class_name WebsiteStorefront
extends InteractableObject3D
## A storefront card. Interaction now happens entirely inside StorefrontPopup, which always
## renders the same layout (big central button + small corner controls) regardless of scenario
## so the UI never hints at whether this one is a trap. The AwningMesh strip stands in for the
## browser's security indicator (padlock/certificate) and tints red/green with the outcome.

@onready var title_label: Label3D = $TitleLabel
@onready var card_mesh: MeshInstance3D = $CardMesh
@onready var awning_mesh: MeshInstance3D = $AwningMesh
@onready var stamp_label: Label3D = $StampLabel

var _card_material: StandardMaterial3D
var _awning_material: StandardMaterial3D


func _ready() -> void:
	stamp_label.visible = false
	_card_material = StandardMaterial3D.new()
	_card_material.albedo_color = Color(0.92, 0.94, 0.9)
	card_mesh.set_surface_override_material(0, _card_material)

	_awning_material = StandardMaterial3D.new()
	_awning_material.albedo_color = Color(0.4, 0.65, 0.5)
	awning_mesh.set_surface_override_material(0, _awning_material)


func _configure(scenario: Dictionary) -> void:
	title_label.text = str(scenario.get("title", ""))


## Intentionally empty: SafeBrowsingStreetRoom opens StorefrontPopup directly instead of the
## generic ActionPopup.
func get_action_options() -> Array:
	return []


func play_consequence(was_correct: bool, action: String) -> void:
	stamp_label.visible = true

	match action:
		"enter_site":
			if was_correct:
				stamp_label.text = "SECURE CHECKOUT"
				_awning_material.albedo_color = Color(0.3, 0.75, 0.4)
			else:
				stamp_label.text = "MALWARE DOWNLOADED"
				_awning_material.albedo_color = Color(0.85, 0.2, 0.2)
		"check_certificate", "leave":
			stamp_label.text = "SITE AVOIDED"
			_awning_material.albedo_color = Color(0.3, 0.75, 0.4) if was_correct else Color(0.55, 0.55, 0.6)
		_:
			stamp_label.text = "NO ACTION"
			_awning_material.albedo_color = Color(0.6, 0.6, 0.65)

	stamp_label.modulate = Color(0.3, 0.85, 0.45) if was_correct else Color(0.9, 0.25, 0.25)
