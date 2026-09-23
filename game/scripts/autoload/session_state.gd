extends Node
## Holds the current user, trust score, per-room adaptive-difficulty streaks, and language.

const HARD_SCENARIO_STREAK_THRESHOLD: int = 3

## Trust Score required to reach each level, index 0 == level 1. Mirrors Localization's
## "level.1".."level.10" keys (Cyber Rookie through Cyber Sentinel).
const LEVEL_THRESHOLDS: Array[int] = [0, 50, 120, 220, 350, 500, 700, 950, 1250, 1600]

var user_id: int = -1
var username: String = ""
var trust_score: int = 0
var preferred_language: String = "en"
## "man" or "woman" - chosen on the Avatar Selection screen, used by the hub to pick which
## avatar scene to spawn. Not persisted server-side; re-chosen each time Start is pressed.
var avatar_gender: String = "man"

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


func get_level_number(score: int = -1) -> int:
	var s: int = trust_score if score < 0 else score
	var level: int = 1
	for i in range(LEVEL_THRESHOLDS.size()):
		if s >= LEVEL_THRESHOLDS[i]:
			level = i + 1
	return level


func get_level_title(score: int = -1) -> String:
	return Localization.get_string("level.%d" % get_level_number(score))


## Compares the level at two Trust Score values; returns the new level's title if it crossed a
## threshold, or "" if not. Call with the score just before and just after a result is recorded.
func check_level_up(old_score: int, new_score: int) -> String:
	if get_level_number(new_score) > get_level_number(old_score):
		return get_level_title(new_score)
	return ""
