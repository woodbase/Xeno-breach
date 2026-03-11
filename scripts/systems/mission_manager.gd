## MissionManager — autoload singleton managing all active missions.
##
## Access via the global [code]MissionManager[/code] singleton.
## Tracks active missions, handles event triggers, and emits signals for UI updates.
## Connect to signals to react to mission state changes without polling.

extends Node

## Emitted when a mission is started.
signal mission_started(mission: Mission)

## Emitted when a mission is completed.
signal mission_completed(mission: Mission)

## Emitted when a mission fails.
signal mission_failed(mission: Mission)

## Emitted when an objective within any active mission completes.
signal objective_completed(mission: Mission, objective: MissionObjective)

## Emitted when an enemy is killed (for KillEnemyObjective tracking).
signal enemy_killed(enemy_type: String)

## Emitted when a terminal is activated (for ActivateTerminalObjective tracking).
signal terminal_activated(terminal_id: String)

## Emitted when an item is retrieved (for RetrieveItemObjective tracking).
signal item_retrieved(item_id: String)

## Dictionary of active missions by mission_id.
var active_missions: Dictionary = {}


## Start a mission from a [MissionData] resource.
## Returns the created [Mission] instance.
func start_mission(mission_data: MissionData) -> Mission:
	if mission_data == null:
		push_warning("MissionManager: Cannot start mission from null MissionData")
		return null

	if active_missions.has(mission_data.mission_id):
		push_warning("MissionManager: Mission %s is already active" % mission_data.mission_id)
		return active_missions[mission_data.mission_id]

	var mission: Mission = mission_data.create_mission_instance()
	active_missions[mission.mission_id] = mission

	mission.completed.connect(_on_mission_completed.bind(mission))
	mission.failed.connect(_on_mission_failed.bind(mission))
	mission.objective_completed.connect(_on_objective_completed.bind(mission))

	mission.start()
	mission_started.emit(mission)

	return mission


## Start a mission by creating it directly (without MissionData).
## Returns the created [Mission] instance.
func start_mission_direct(mission: Mission) -> Mission:
	if mission == null:
		push_warning("MissionManager: Cannot start null mission")
		return null

	if active_missions.has(mission.mission_id):
		push_warning("MissionManager: Mission %s is already active" % mission.mission_id)
		return active_missions[mission.mission_id]

	active_missions[mission.mission_id] = mission

	mission.completed.connect(_on_mission_completed.bind(mission))
	mission.failed.connect(_on_mission_failed.bind(mission))
	mission.objective_completed.connect(_on_objective_completed.bind(mission))

	mission.start()
	mission_started.emit(mission)

	return mission


## Get an active mission by its ID.
func get_mission(mission_id: String) -> Mission:
	return active_missions.get(mission_id, null)


## Get all active missions.
func get_active_missions() -> Array[Mission]:
	var missions: Array[Mission] = []
	for mission: Mission in active_missions.values():
		missions.append(mission)
	return missions


## Report an enemy kill. Forwards to all [KillEnemyObjective] instances.
func report_enemy_killed(enemy_type: String = "") -> void:
	enemy_killed.emit(enemy_type)

	for mission: Mission in active_missions.values():
		if mission.current_state != Mission.State.ACTIVE:
			continue

		for obj: MissionObjective in mission.objectives:
			var kill_obj := obj as KillEnemyObjective
			if kill_obj != null:
				kill_obj.report_kill(enemy_type)


## Report a terminal activation. Forwards to all [ActivateTerminalObjective] instances.
func report_terminal_activated(terminal_id: String) -> void:
	terminal_activated.emit(terminal_id)

	for mission: Mission in active_missions.values():
		if mission.current_state != Mission.State.ACTIVE:
			continue

		for obj: MissionObjective in mission.objectives:
			var terminal_obj := obj as ActivateTerminalObjective
			if terminal_obj != null:
				terminal_obj.report_activation(terminal_id)


## Report an item retrieval. Forwards to all [RetrieveItemObjective] instances.
func report_item_retrieved(item_id: String) -> void:
	item_retrieved.emit(item_id)

	for mission: Mission in active_missions.values():
		if mission.current_state != Mission.State.ACTIVE:
			continue

		for obj: MissionObjective in mission.objectives:
			var retrieve_obj := obj as RetrieveItemObjective
			if retrieve_obj != null:
				retrieve_obj.report_retrieval(item_id)


## Check player position against all [ReachAreaObjective] instances.
## Call this from player movement code or a level timer.
func check_player_position(player_position: Vector2) -> void:
	for mission: Mission in active_missions.values():
		if mission.current_state != Mission.State.ACTIVE:
			continue

		for obj: MissionObjective in mission.objectives:
			var reach_obj := obj as ReachAreaObjective
			if reach_obj != null:
				reach_obj.check_player_position(player_position)


## Clear all active missions (useful when returning to main menu).
func clear_all_missions() -> void:
	for mission: Mission in active_missions.values():
		if mission.current_state == Mission.State.ACTIVE:
			mission.fail()

	active_missions.clear()


func _on_mission_completed(mission: Mission) -> void:
	mission_completed.emit(mission)
	active_missions.erase(mission.mission_id)


func _on_mission_failed(mission: Mission) -> void:
	mission_failed.emit(mission)
	active_missions.erase(mission.mission_id)


func _on_objective_completed(objective: MissionObjective, mission: Mission) -> void:
	objective_completed.emit(mission, objective)
