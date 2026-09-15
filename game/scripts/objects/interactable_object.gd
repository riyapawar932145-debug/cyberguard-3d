class_name InteractableObject3D
extends StaticBody3D
## Common base for every interactable 3D object (emails, payment prompts, login pages,
## storefronts, password terminals). Subclasses override _configure(), get_action_options()
## and play_consequence() to give each room its own look and feedback.

var scenario_id: int = -1
var scenario_code: String = ""
var scenario_title: String = ""
var scenario_difficulty: int = 1
## Room-specific rich flavor content from the API (email body, caller dialogue, domain, ...).
var scenario_content: Dictionary = {}


func setup(scenario: Dictionary) -> void:
	scenario_id = int(scenario.get("id", -1))
	scenario_code = scenario.get("code", "")
	scenario_title = scenario.get("title", "")
	scenario_difficulty = int(scenario.get("difficulty", 1))
	scenario_content = scenario.get("content", {})
	_configure(scenario)


## Override: update visuals (labels, materials) from scenario data.
func _configure(_scenario: Dictionary) -> void:
	pass


## Override: return an Array of {"action": String, "label_key": String} shown in the ActionPopup.
func get_action_options() -> Array:
	return []


## Override: render a distinct in-world consequence for this object type and outcome.
func play_consequence(_was_correct: bool, _action: String) -> void:
	pass
