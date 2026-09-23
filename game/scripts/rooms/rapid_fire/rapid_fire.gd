class_name RapidFireRoom
extends RoomBase
## The Terminal is hand-placed in the scene (not spawned from SpawnPoints - this room's
## SpawnPoints node has no Marker3D children), since one session cycles through many scenarios
## via RapidFirePopup rather than RoomBase's one-object-per-click flow. `_session_active` is a
## separate flag from RoomBase's `_busy` so the two states never interfere with each other -
## RoomBase's own `_on_result_submitted` still fires for each rapid-fire submission (the API
## response signal is global) but harmlessly no-ops since `_pending_object` is never touched here.

@onready var rapid_fire_popup: RapidFirePopup = %RapidFirePopup
@onready var officer_npc: Node3D = get_node_or_null("Officer")

var _session_active: bool = false


func on_object_clicked(object: Node) -> void:
	if _session_active or object == null:
		return
	_session_active = true
	rapid_fire_popup.start_session(_get_scenario_pool(), _on_session_result, _on_session_complete, officer_npc)


func _on_session_result(result: Dictionary) -> void:
	var was_correct: bool = result.get("was_correct", false)
	var old_trust_score: int = SessionState.trust_score
	var new_trust_score: int = result.get("new_trust_score", SessionState.trust_score)
	SessionState.record_result(room_name, was_correct, new_trust_score)
	_handle_progression_toasts(was_correct, old_trust_score, new_trust_score, result.get("badges_awarded", []))


func _on_session_complete() -> void:
	_session_active = false
