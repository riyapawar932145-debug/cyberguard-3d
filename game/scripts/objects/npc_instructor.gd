class_name NPCInstructor
extends Node3D
## A stationary figure placed near a room's entrance - purely decorative, giving "a person is
## here" presence for the instruction briefing RoomBase shows on entry. Idle animation only;
## interaction happens through the InstructionPopup RoomBase triggers, not by clicking this NPC.

@onready var head: Node3D = $Model/Head

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	head.rotation.y = sin(_time * 0.6) * 0.15
