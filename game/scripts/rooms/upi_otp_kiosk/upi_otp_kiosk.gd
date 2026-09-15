class_name UpiOtpKioskRoom
extends RoomBase
## UPI / OTP Kiosk opens the incoming-request card (IncomingRequestPopup) instead of the generic
## ActionPopup - a live 20s countdown creates time pressure while all three responses stay
## available the whole time. Everything else (submit, result handling, debrief, respawn,
## adaptive difficulty) is inherited from RoomBase unchanged - this override only replaces how
## the click is turned into a submission.

@onready var incoming_request_popup: IncomingRequestPopup = %IncomingRequestPopup


func on_object_clicked(object: Node) -> void:
	if _busy or object == null:
		return

	var click_time_ms: int = Time.get_ticks_msec()
	incoming_request_popup.open(object.scenario_title, object.scenario_content, func(action: String) -> void:
		_submit(object, action, Time.get_ticks_msec() - click_time_ms)
	)
