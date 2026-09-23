extends Node3D
## Hub World ("Cyber City"): instances the player's chosen avatar (SessionState.avatar_gender)
## at the spawn point and shows a brief welcome hint. Room entry itself is entirely handled by
## the HubEntrance trigger volumes scattered around the plaza - see hub_entrance.gd.

const AVATAR_SCENES: Dictionary = {
	"man": "res://scenes/hub/avatar_man.tscn",
	"woman": "res://scenes/hub/avatar_woman.tscn",
}

@onready var spawn_point: Marker3D = $SpawnPoint
@onready var welcome_label: Label = %WelcomeLabel
@onready var hint_label: Label = %HintLabel


func _ready() -> void:
	if not SessionState.is_logged_in():
		get_tree().change_scene_to_file("res://scenes/ui/login_screen.tscn")
		return

	var avatar_path: String = AVATAR_SCENES.get(SessionState.avatar_gender, AVATAR_SCENES["man"])
	var avatar_scene: PackedScene = load(avatar_path)
	var avatar: Node3D = avatar_scene.instantiate()
	add_child(avatar)
	avatar.global_position = spawn_point.global_position

	welcome_label.text = Localization.get_string("hub.welcome")
	hint_label.text = Localization.get_string("hub.walk_hint")

	var timer: SceneTreeTimer = get_tree().create_timer(4.5)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(welcome_label):
			welcome_label.visible = false
		if is_instance_valid(hint_label):
			hint_label.visible = false
	)
