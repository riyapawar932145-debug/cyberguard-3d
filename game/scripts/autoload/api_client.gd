extends Node
## Single point of contact with the Flask REST API.
## Every call spins up its own HTTPRequest child so concurrent calls never collide.

const BASE_URL: String = "http://127.0.0.1:5000"

signal register_success(user: Dictionary)
signal register_failed(message: String)
signal login_success(user: Dictionary)
signal login_failed(message: String)
signal scenarios_loaded(room: String, scenarios: Array)
signal result_submitted(result: Dictionary)
signal leaderboard_loaded(entries: Array)
signal progress_loaded(progress: Dictionary)
signal language_updated(language_code: String)

signal admin_scenarios_loaded(scenarios: Array)
signal admin_scenario_created(scenario: Dictionary)
signal admin_scenario_updated(scenario: Dictionary)
signal admin_scenario_deleted(scenario_id: int)
signal admin_request_failed(context: String, message: String)

## Emitted for any failed/timed-out call that isn't handled by a more specific signal above.
signal request_failed(context: String, message: String)


func register(username: String, email: String, password: String) -> void:
	var body: Dictionary = {"username": username, "email": email, "password": password}
	_request(HTTPClient.METHOD_POST, "/api/register", body, "register")


func login(username: String, password: String) -> void:
	var body: Dictionary = {"username": username, "password": password}
	_request(HTTPClient.METHOD_POST, "/api/login", body, "login")


func load_scenarios(room: String) -> void:
	_request(HTTPClient.METHOD_GET, "/api/scenarios/%s?lang=%s" % [room, Localization.current_language], null, "scenarios:%s" % room)


func submit_result(user_id: int, scenario_id: int, action_taken: String, response_time_ms: int) -> void:
	var body: Dictionary = {
		"user_id": user_id,
		"scenario_id": scenario_id,
		"action_taken": action_taken,
		"response_time_ms": response_time_ms,
	}
	_request(HTTPClient.METHOD_POST, "/api/result", body, "result")


func load_leaderboard() -> void:
	_request(HTTPClient.METHOD_GET, "/api/leaderboard", null, "leaderboard")


func load_progress(user_id: int) -> void:
	_request(HTTPClient.METHOD_GET, "/api/user/%d/progress" % user_id, null, "progress")


func update_language(user_id: int, language_code: String) -> void:
	var body: Dictionary = {"language_code": language_code}
	_request(HTTPClient.METHOD_PUT, "/api/user/%d/language" % user_id, body, "language")


func admin_list_scenarios() -> void:
	_request(HTTPClient.METHOD_GET, "/api/admin/scenarios", null, "admin_list")


func admin_create_scenario(data: Dictionary) -> void:
	_request(HTTPClient.METHOD_POST, "/api/admin/scenarios", data, "admin_create")


func admin_update_scenario(scenario_id: int, data: Dictionary) -> void:
	_request(HTTPClient.METHOD_PUT, "/api/admin/scenarios/%d" % scenario_id, data, "admin_update:%d" % scenario_id)


func admin_delete_scenario(scenario_id: int) -> void:
	_request(HTTPClient.METHOD_DELETE, "/api/admin/scenarios/%d" % scenario_id, null, "admin_delete:%d" % scenario_id)


func _request(method: int, path: String, body, context: String) -> void:
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http, context))

	var headers: PackedStringArray = ["Content-Type: application/json"]
	var err: Error
	if body != null:
		err = http.request(BASE_URL + path, headers, method, JSON.stringify(body))
	else:
		err = http.request(BASE_URL + path, headers, method)

	if err != OK:
		_fail(context, Localization.get_string("common.connection_error"))
		http.queue_free()


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, context: String) -> void:
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS:
		_fail(context, Localization.get_string("common.connection_error"))
		return

	var text: String = body.get_string_from_utf8()
	var parsed = JSON.parse_string(text) if text != "" else null

	if response_code >= 400:
		var message: String = "Request failed."
		if parsed is Dictionary and parsed.has("error"):
			message = parsed["error"]
		_fail(context, message)
		return

	_succeed(context, parsed)


func _succeed(context: String, data) -> void:
	if context == "register":
		register_success.emit(data)
	elif context == "login":
		login_success.emit(data)
	elif context.begins_with("scenarios:"):
		scenarios_loaded.emit(context.split(":")[1], data)
	elif context == "result":
		result_submitted.emit(data)
	elif context == "leaderboard":
		leaderboard_loaded.emit(data)
	elif context == "progress":
		progress_loaded.emit(data)
	elif context == "language":
		language_updated.emit(data.get("preferred_language", "en"))
	elif context == "admin_list":
		admin_scenarios_loaded.emit(data)
	elif context == "admin_create":
		admin_scenario_created.emit(data)
	elif context.begins_with("admin_update:"):
		admin_scenario_updated.emit(data)
	elif context.begins_with("admin_delete:"):
		admin_scenario_deleted.emit(int(context.split(":")[1]))


func _fail(context: String, message: String) -> void:
	if context == "register":
		register_failed.emit(message)
	elif context == "login":
		login_failed.emit(message)
	elif context.begins_with("admin_"):
		admin_request_failed.emit(context, message)
	else:
		request_failed.emit(context, message)
