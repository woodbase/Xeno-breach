## MissionObjective — base class for all mission objectives.
##
## Objectives track specific goals within a mission (e.g., kill enemies, reach area).
## Extend this class to create custom objective types.
## Connect to [signal completed] to react when the objective is finished.
class_name MissionObjective
extends RefCounted

## Emitted when the objective is marked as complete.
signal completed

## Emitted when objective progress changes.
signal progress_changed(current: int, target: int)

## Human-readable description of the objective.
var description: String = ""

## Whether this objective is currently completed.
var is_completed: bool = false

## Current progress value (e.g., enemies killed so far).
var current_progress: int = 0

## Target progress value (e.g., total enemies required).
var target_progress: int = 1


## Initialize the objective with a description and optional target.
func _init(desc: String = "", target: int = 1) -> void:
	description = desc
	target_progress = max(1, target)


## Report progress toward this objective.
## Automatically completes when [param value] reaches [member target_progress].
func report_progress(value: int) -> void:
	if is_completed:
		return

	current_progress = clampi(value, 0, target_progress)
	progress_changed.emit(current_progress, target_progress)

	if current_progress >= target_progress:
		complete()


## Increment progress by [param delta].
func increment_progress(delta: int = 1) -> void:
	report_progress(current_progress + delta)


## Mark this objective as complete. Emits [signal completed].
func complete() -> void:
	if is_completed:
		return
	is_completed = true
	completed.emit()


## Returns true when this objective is complete.
func check_completion() -> bool:
	return is_completed


## Get progress as a percentage (0.0 to 1.0).
func get_progress_ratio() -> float:
	if target_progress <= 0:
		return 0.0
	return float(current_progress) / float(target_progress)


## Optional hook called when the objective is activated.
## Override in subclasses to set up event listeners.
func activate() -> void:
	pass


## Optional hook called when the objective is deactivated.
## Override in subclasses to clean up event listeners.
func deactivate() -> void:
	pass
