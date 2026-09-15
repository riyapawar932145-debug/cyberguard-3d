class_name SafeBrowsingStreetRoom
extends RoomBase
## Safe Browsing Street opens the storefront card (StorefrontPopup) instead of the generic
## ActionPopup - the same layout renders every time so the UI never hints at whether a given
## scenario is a trap. Everything else (submit, result handling, debrief, respawn, adaptive
## difficulty) is inherited from RoomBase unchanged - this override only replaces how the click
## is turned into a submission.

@onready var storefront_popup: StorefrontPopup = %StorefrontPopup


func on_object_clicked(object: Node) -> void:
	if _busy or object == null:
		return

	var click_time_ms: int = Time.get_ticks_msec()
	storefront_popup.open(object.scenario_title, object.scenario_content, func(action: String) -> void:
		_submit(object, action, Time.get_ticks_msec() - click_time_ms)
	)
