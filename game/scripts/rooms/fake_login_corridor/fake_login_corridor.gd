class_name FakeLoginCorridorRoom
extends RoomBase
## Fake Login Corridor opens the domain inspector card (DomainInspectorPopup) instead of the
## generic ActionPopup - the judgment-call buttons only appear after the player zooms into the
## address bar. Everything else (submit, result handling, debrief, respawn, adaptive difficulty)
## is inherited from RoomBase unchanged - this override only replaces how the click is turned
## into a submission.

@onready var domain_inspector_popup: DomainInspectorPopup = %DomainInspectorPopup


func on_object_clicked(object: Node) -> void:
	if _busy or object == null:
		return

	var click_time_ms: int = Time.get_ticks_msec()
	domain_inspector_popup.open(object.scenario_title, object.scenario_content, func(action: String) -> void:
		_submit(object, action, Time.get_ticks_msec() - click_time_ms)
	)
