class_name PhishingInboxRoom
extends RoomBase
## Phishing Inbox opens the email inline (EmailReaderPopup) instead of the generic ActionPopup.
## Everything else (submit, result handling, debrief, respawn, adaptive difficulty) is inherited
## from RoomBase unchanged - this override only replaces how the click is turned into a submission.

@onready var email_reader: EmailReaderPopup = %EmailReaderPopup


func on_object_clicked(object: Node) -> void:
	if _busy or object == null:
		return

	var click_time_ms: int = Time.get_ticks_msec()
	email_reader.open(object.scenario_title, object.scenario_content, func(action: String) -> void:
		_submit(object, action, Time.get_ticks_msec() - click_time_ms)
	)
