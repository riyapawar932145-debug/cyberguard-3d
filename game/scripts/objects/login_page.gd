class_name LoginPage
extends InteractableObject3D
## A "browser window" card. Interaction now happens entirely inside DomainInspectorPopup -
## the player must zoom the address bar before the judgment-call buttons (Flag as Suspicious /
## Looks Legitimate) appear. The AddressBarMesh strip tints red/green so the consequence reads
## at a glance in the 3D world.

@onready var heading_label: Label3D = $HeadingLabel
@onready var page_mesh: MeshInstance3D = $PageMesh
@onready var address_bar_mesh: MeshInstance3D = $AddressBarMesh
@onready var stamp_label: Label3D = $StampLabel

var _page_material: StandardMaterial3D
var _bar_material: StandardMaterial3D


func _ready() -> void:
	stamp_label.visible = false
	_page_material = StandardMaterial3D.new()
	_page_material.albedo_color = Color(0.92, 0.92, 0.95)
	page_mesh.set_surface_override_material(0, _page_material)

	_bar_material = StandardMaterial3D.new()
	_bar_material.albedo_color = Color(0.6, 0.6, 0.65)
	address_bar_mesh.set_surface_override_material(0, _bar_material)


func _configure(scenario: Dictionary) -> void:
	heading_label.text = str(scenario.get("title", ""))


## Intentionally empty: FakeLoginCorridorRoom opens DomainInspectorPopup directly instead of
## the generic ActionPopup - "check_url"/"confirmed_legit" only ever fire after the player
## zooms into the address bar to inspect it.
func get_action_options() -> Array:
	return []


func play_consequence(was_correct: bool, action: String) -> void:
	stamp_label.visible = true

	match action:
		"enter_credentials":
			if was_correct:
				stamp_label.text = "LOGGED IN SECURELY"
				_bar_material.albedo_color = Color(0.3, 0.75, 0.4)
			else:
				stamp_label.text = "ACCOUNT COMPROMISED"
				_bar_material.albedo_color = Color(0.85, 0.2, 0.2)
		"confirmed_legit":
			if was_correct:
				stamp_label.text = "CORRECTLY VERIFIED"
				_bar_material.albedo_color = Color(0.3, 0.75, 0.4)
			else:
				stamp_label.text = "ACCOUNT COMPROMISED"
				_bar_material.albedo_color = Color(0.85, 0.2, 0.2)
		"check_url":
			stamp_label.text = "THREAT AVOIDED" if was_correct else "UNNECESSARY CAUTION"
			_bar_material.albedo_color = Color(0.3, 0.75, 0.4) if was_correct else Color(0.55, 0.55, 0.6)
		"leave_page":
			stamp_label.text = "THREAT AVOIDED" if was_correct else "LEFT SAFE PAGE"
			_bar_material.albedo_color = Color(0.3, 0.75, 0.4) if was_correct else Color(0.55, 0.55, 0.6)
		_:
			stamp_label.text = "NO ACTION"
			_bar_material.albedo_color = Color(0.6, 0.6, 0.65)

	stamp_label.modulate = Color(0.3, 0.85, 0.45) if was_correct else Color(0.9, 0.25, 0.25)
