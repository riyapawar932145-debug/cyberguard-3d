extends Node
## Entry point. Routes to the hidden admin scene when launched with --admin, otherwise
## the normal player-facing main menu.

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	if args.has("--admin"):
		get_tree().change_scene_to_file("res://scenes/admin/admin_main.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
