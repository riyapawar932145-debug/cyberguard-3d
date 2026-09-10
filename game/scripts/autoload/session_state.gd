extends Node
## Holds the current user, trust score, per-room adaptive-difficulty streaks, and language.

const HARD_SCENARIO_STREAK_THRESHOLD: int = 3

var user_id: int = -1
var username: String = ""
var trust_score: int = 0
var preferred_language: String = "en"

## room_name -> consecutive correct answers in that room.
var streaks: Dictionary = {}


func is_logged_in() -> bool:
	return user_id != -1


func set_user(data: Dictionary) -> void:
	user_id = data.get("id", -1)
	username = data.get("username", "")
	trust_score = data.get("trust_score", 0)
	preferred_language = data.get("preferred_language", "en")
	streaks.clear()


func log_out() -> void:
	user_id = -1
	username = ""
	trust_score = 0
	preferred_language = "en"
	streaks.clear()


func record_result(room: String, was_correct: bool, new_trust_score: int) -> void:
	trust_score = new_trust_score
	if was_correct:
		streaks[room] = streaks.get(room, 0) + 1
	else:
		streaks[room] = 0


func get_streak(room: String) -> int:
	return streaks.get(room, 0)


## After 3 consecutive correct answers in a room, the room should prefer difficulty >= 2 scenarios.
func prefers_hard_scenarios(room: String) -> bool:
	return get_streak(room) >= HARD_SCENARIO_STREAK_THRESHOLD
