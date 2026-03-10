## Mission — runtime instance tracking a mission's state and objectives.
##
## Manages a list of [MissionObjective] instances and emits signals when
## objectives or the mission itself complete.
## Created from [MissionData] via [method MissionData.create_mission_instance].
class_name Mission
extends RefCounted

enum State {
	INACTIVE,
	ACTIVE,
	COMPLETED,
	FAILED,
}

## Emitted when the mission state changes.
signal state_changed(new_state: State)

## Emitted when any objective within this mission completes.
signal objective_completed(objective: MissionObjective)

## Emitted when this mission is fully completed.
signal completed

## Emitted when this mission fails.
signal failed

## Unique identifier for this mission.
var mission_id: String = ""

## Human-readable mission name.
var mission_name: String = "Untitled Mission"

## Mission description shown to the player.
var mission_description: String = ""

## Whether this mission is optional.
var is_optional: bool = false

## XP or score reward for completing this mission.
var reward_score: int = 0

## Current mission state.
var current_state: State = State.INACTIVE

## List of objectives for this mission.
var objectives: Array[MissionObjective] = []


## Add an objective to this mission.
func add_objective(objective: MissionObjective) -> void:
	if objective == null:
		push_warning("Mission: Cannot add null objective to mission %s" % mission_id)
		return

	objectives.append(objective)
	objective.completed.connect(_on_objective_completed.bind(objective))


## Start this mission and activate all objectives.
func start() -> void:
	if current_state != State.INACTIVE:
		return

	_change_state(State.ACTIVE)
	for obj: MissionObjective in objectives:
		obj.activate()


## Check if all objectives are complete and finish the mission if so.
func check_completion() -> bool:
	if current_state != State.ACTIVE:
		return false

	for obj: MissionObjective in objectives:
		if not obj.is_completed:
			return false

	_complete()
	return true


## Mark this mission as complete.
func _complete() -> void:
	if current_state != State.ACTIVE:
		return

	_change_state(State.COMPLETED)
	for obj: MissionObjective in objectives:
		obj.deactivate()
	completed.emit()


## Mark this mission as failed.
func fail() -> void:
	if current_state != State.ACTIVE:
		return

	_change_state(State.FAILED)
	for obj: MissionObjective in objectives:
		obj.deactivate()
	failed.emit()


## Change the mission state and emit [signal state_changed].
func _change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	current_state = new_state
	state_changed.emit(new_state)


## Called when any objective completes.
func _on_objective_completed(objective: MissionObjective) -> void:
	objective_completed.emit(objective)
	check_completion()


## Get the list of active (incomplete) objectives.
func get_active_objectives() -> Array[MissionObjective]:
	var active: Array[MissionObjective] = []
	for obj: MissionObjective in objectives:
		if not obj.is_completed:
			active.append(obj)
	return active


## Get the list of completed objectives.
func get_completed_objectives() -> Array[MissionObjective]:
	var completed_objs: Array[MissionObjective] = []
	for obj: MissionObjective in objectives:
		if obj.is_completed:
			completed_objs.append(obj)
	return completed_objs


## Get mission progress as a percentage (0.0 to 1.0).
func get_progress_ratio() -> float:
	if objectives.is_empty():
		return 0.0

	var completed_count: int = 0
	for obj: MissionObjective in objectives:
		if obj.is_completed:
			completed_count += 1

	return float(completed_count) / float(objectives.size())
