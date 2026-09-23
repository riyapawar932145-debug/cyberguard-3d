class_name RoomBase
extends Node3D
## Shared logic for every 3D room: fetch scenarios, spawn interactable objects at design-time
## Marker3D spawn points, route clicks to an ActionPopup, submit results, render the object's
## in-world consequence, then show the DebriefPanel before spawning the next scenario.
##
## Concrete room scenes set `room_name` and `object_scene` in the Inspector and provide a
## "SpawnPoints" node containing one Marker3D per simultaneous scenario, plus %ActionPopup,
## %DebriefPanel and %HUD unique-named nodes.

@export var room_name: String = ""
@export var object_scene: PackedScene
## Localization key for the Training Officer's briefing shown every time this room is entered.
## Leave empty to skip (no room currently does, but the hook stays optional/defensive).
@export var instruction_key: String = ""

@onready var action_popup: Control = %ActionPopup
@onready var debrief_panel: Control = %DebriefPanel
@onready var hud: Control = %HUD
@onready var instruction_popup: Control = get_node_or_null("%InstructionPopup")
## The room's Training Officer NPC, if it has one - every room names it "Officer" by
## convention. The instruction popup anchors its speech bubble above this node.
@onready var officer_npc: Node3D = get_node_or_null("Officer")

var _spawn_points: Array[Marker3D] = []
var _all_scenarios: Array = []
var _pool: Array = []
var _spawned: Dictionary = {}  # Marker3D -> InteractableObject3D

var _pending_object: Node = null
var _pending_action: String = ""
var _click_time_ms: int = 0
var _busy: bool = false


func _ready() -> void:
	add_to_group("room_controller")
	_spawn_points = _collect_spawn_points()

	ApiClient.scenarios_loaded.connect(_on_scenarios_loaded)
	ApiClient.result_submitted.connect(_on_result_submitted)
	ApiClient.request_failed.connect(_on_request_failed)

	if hud:
		hud.set_room_label(room_name)
		hud.set_trust_score(SessionState.trust_score)

	if instruction_popup and instruction_key != "":
		instruction_popup.open(instruction_key, officer_npc)

	ApiClient.load_scenarios(room_name)


func _exit_tree() -> void:
	if ApiClient.scenarios_loaded.is_connected(_on_scenarios_loaded):
		ApiClient.scenarios_loaded.disconnect(_on_scenarios_loaded)
	if ApiClient.result_submitted.is_connected(_on_result_submitted):
		ApiClient.result_submitted.disconnect(_on_result_submitted)
	if ApiClient.request_failed.is_connected(_on_request_failed):
		ApiClient.request_failed.disconnect(_on_request_failed)


func _collect_spawn_points() -> Array[Marker3D]:
	var points: Array[Marker3D] = []
	var container: Node = get_node_or_null("SpawnPoints")
	if container:
		for child in container.get_children():
			if child is Marker3D:
				points.append(child)
	return points


func _on_scenarios_loaded(room: String, scenarios: Array) -> void:
	if room != room_name:
		return
	_all_scenarios = scenarios.duplicate(true)
	_refill_pool()
	for point in _spawn_points:
		_spawn_next(point)


## Protected hook: a read-only copy of the scenarios already fetched for this room, for
## subclasses (like RapidFireRoom) that manage their own multi-scenario flow instead of the
## default one-object-per-SpawnPoint spawn cycle.
func _get_scenario_pool() -> Array:
	return _all_scenarios.duplicate(true)


## Protected hook: HUD streak/level-up/badge toast handling, shared between the normal
## single-object flow above and subclasses with a custom multi-submission flow (Rapid Fire).
## Call SessionState.record_result() first - this only reacts to state that's already updated.
func _handle_progression_toasts(was_correct: bool, old_trust_score: int, new_trust_score: int, badges_awarded: Array) -> void:
	if not hud:
		return
	hud.set_trust_score(SessionState.trust_score)

	if was_correct:
		var streak: int = SessionState.get_streak(room_name)
		if streak == 3 or streak == 5 or (streak >= 10 and streak % 5 == 0):
			hud.show_streak_toast(streak)

	var level_up_title: String = SessionState.check_level_up(old_trust_score, new_trust_score)
	if level_up_title != "":
		hud.show_level_up_toast(level_up_title)

	for badge in badges_awarded:
		hud.show_badge_toast(badge)


func _refill_pool() -> void:
	_pool = _all_scenarios.duplicate(true)
	_pool.shuffle()


func _pick_scenario() -> Dictionary:
	if _pool.is_empty():
		_refill_pool()
	if _pool.is_empty():
		return {}

	if SessionState.prefers_hard_scenarios(room_name):
		for i in range(_pool.size()):
			if int(_pool[i].get("difficulty", 1)) >= 2:
				return _pool.pop_at(i)

	return _pool.pop_front()


func _spawn_next(point: Marker3D) -> void:
	if object_scene == null or not is_instance_valid(point):
		return

	var scenario: Dictionary = _pick_scenario()
	if scenario.is_empty():
		return

	var instance: Node = object_scene.instantiate()
	point.add_child(instance)
	if instance.has_method("setup"):
		instance.setup(scenario)
	_spawned[point] = instance


## Called by Player (via the "room_controller" group) when a raycast hits an interactable object.
func on_object_clicked(object: Node) -> void:
	if _busy or object == null or not object.has_method("get_action_options"):
		return

	_pending_object = object
	_click_time_ms = Time.get_ticks_msec()
	var options: Array = object.get_action_options()
	action_popup.open(object.scenario_title, options, _on_action_selected)


func _on_action_selected(action: String) -> void:
	if _pending_object == null or not is_instance_valid(_pending_object):
		_pending_object = null
		return

	_submit(_pending_object, action, Time.get_ticks_msec() - _click_time_ms)


## Protected hook for subclasses with a non-standard click flow (e.g. password_vault_lab's
## free-text popup instead of the generic ActionPopup) to submit a result without reaching
## into the underscore-prefixed pending-state vars directly. Result handling, debrief and
## respawn all continue through the normal _on_result_submitted() path below.
func _submit(object: Node, action: String, response_time_ms: int) -> void:
	if _busy or object == null or not is_instance_valid(object):
		return
	_busy = true
	_pending_object = object
	_pending_action = action
	ApiClient.submit_result(SessionState.user_id, object.scenario_id, action, response_time_ms)


func _on_result_submitted(result: Dictionary) -> void:
	if not _busy or _pending_object == null or not is_instance_valid(_pending_object):
		_busy = false
		return

	var was_correct: bool = result.get("was_correct", false)
	var old_trust_score: int = SessionState.trust_score
	var new_trust_score: int = result.get("new_trust_score", SessionState.trust_score)
	SessionState.record_result(room_name, was_correct, new_trust_score)
	_handle_progression_toasts(was_correct, old_trust_score, new_trust_score, result.get("badges_awarded", []))

	var object: Node = _pending_object
	if object.has_method("play_consequence"):
		object.play_consequence(was_correct, _pending_action)

	await get_tree().create_timer(1.4).timeout

	if is_instance_valid(object):
		var point: Marker3D = object.get_parent()
		debrief_panel.show_debrief(result, func() -> void:
			_on_debrief_continue(object, point)
		)
	else:
		_busy = false
		_pending_object = null


func _on_debrief_continue(object: Node, point: Marker3D) -> void:
	if is_instance_valid(object):
		object.queue_free()
	_pending_object = null
	_busy = false
	if is_instance_valid(point):
		_spawn_next(point)


func _on_request_failed(_context: String, message: String) -> void:
	_busy = false
	if hud:
		hud.show_connection_error(message)
