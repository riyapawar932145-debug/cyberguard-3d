extends Node
## Entry point. Routes to the hidden admin scene when launched with --admin, otherwise
## the normal player-facing main menu.

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	var target: String = "res://scenes/admin/admin_main.tscn" if args.has("--admin") else "res://scenes/ui/main_menu.tscn"
	# The scene tree is still finishing setup of this very scene during its own _ready() -
	# changing scenes synchronously here races with that and throws a "Parent node is busy" error.
	get_tree().change_scene_to_file.call_deferred(target)
