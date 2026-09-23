class_name HubEntrance
extends Node3D
## A single room doorway in the hub: a small building facade (two side walls + a lintel
## framing an open doorway, with a dark glimpse of an "interior" beyond it) and a floating
## room-name sign above the door. A trigger volume changes scene to `target_scene` the moment
## the player avatar walks through the doorway gap.

@export var room_label_key: String = ""
@export var target_scene: String = ""
@export var panel_color: Color = Color(0.3, 0.4, 0.6)

@onready var label_3d: Label3D = $SignLabel
@onready var wall_left: MeshInstance3D = $WallLeft
@onready var wall_right: MeshInstance3D = $WallRight
@onready var lintel: MeshInstance3D = $Lintel
@onready var trigger: Area3D = $Trigger

var _triggered: bool = false


func _ready() -> void:
	label_3d.text = Localization.get_string(room_label_key)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = panel_color
	material.emission_enabled = true
	material.emission = panel_color
	material.emission_energy_multiplier = 0.35
	wall_left.set_surface_override_material(0, material)
	wall_right.set_surface_override_material(0, material)
	lintel.set_surface_override_material(0, material)

	trigger.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _triggered or target_scene == "" or not body.is_in_group("player"):
		return
	_triggered = true
	get_tree().change_scene_to_file(target_scene)
