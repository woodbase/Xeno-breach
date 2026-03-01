## GameStateManager — autoload singleton that owns the global game state machine.
##
## Access via the global [code]GameStateManager[/code] singleton.
## Connect to [signal state_changed] to react to transitions without polling.
class_name GameStateManager
extends Node

enum State {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY,
}

## Emitted whenever the game state transitions.
signal state_changed(new_state: State, old_state: State)

var current_state: State = State.MAIN_MENU


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
