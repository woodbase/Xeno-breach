## GameStateManager — autoload singleton that owns the global game state machine.
##
## Access via the global [code]GameStateManager[/code] singleton.
## Connect to [signal state_changed] to react to transitions without polling.

extends Node

enum State {
	MAIN_MENU,
	INTRO,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY,
	DEMO_END,
}

## Emitted whenever the game state transitions.
signal state_changed(new_state: State, old_state: State)

var current_state: State = State.MAIN_MENU

## Score and wave data carried from gameplay to the victory / demo end screen.
var final_score: int = 0
var final_waves_survived: int = 0

## Scene path for the level to load after the victory screen.  Set by
## [method LevelBase.go_to_next_level] before transitioning to the victory screen.
var next_level_scene_path: String = ""


## Transition to [param new_state]. No-ops if already in that state.
func change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	var old_state: State = current_state
	current_state = new_state
	state_changed.emit(new_state, old_state)


func is_playing() -> bool:
	return current_state == State.PLAYING


func is_paused() -> bool:
	return current_state == State.PAUSED
