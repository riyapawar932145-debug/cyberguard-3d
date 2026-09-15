class_name RapidFireTerminal
extends InteractableObject3D
## A single hand-placed kiosk in the Rapid Fire room - not spawned per-scenario like every other
## room's objects, since one Rapid Fire session cycles through many scenarios itself. Clicking it
## opens RapidFirePopup, which RapidFireRoom drives directly rather than through RoomBase's
## default one-object-per-click flow. play_consequence() is unused here for the same reason.

@onready var label_3d: Label3D = $Label3D


func _ready() -> void:
	label_3d.text = "RAPID FIRE\nClick to Start"


func get_action_options() -> Array:
	return []


func play_consequence(_was_correct: bool, _action: String) -> void:
	pass
