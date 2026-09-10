class_name PasswordVaultLabRoom
extends RoomBase
## Password Vault Lab is not fraud-detection: clicking a terminal opens a free-text password
## popup with a live client-side strength meter instead of the generic ActionPopup. Everything
## else (submit, result handling, debrief, respawn, adaptive difficulty) is inherited from
## RoomBase unchanged - this override only replaces how the click is turned into a submission.

@onready var password_popup: PasswordInputPopup = %PasswordInputPopup


func on_object_clicked(object: Node) -> void:
	if _busy or object == null:
		return

	var click_time_ms: int = Time.get_ticks_msec()
	password_popup.open(object.scenario_title, func(action: String) -> void:
		_submit(object, action, Time.get_ticks_msec() - click_time_ms)
	)
