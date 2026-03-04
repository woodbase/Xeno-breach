## CoopManager — tracks co-op player count and provides difficulty scaling.
##
## Access via the global [code]CoopManager[/code] singleton.
## Set [member player_count] before loading a level to configure the session.
## Connect to [signal player_count_changed] to update UI when the count changes.
extends Node

## Emitted whenever [member player_count] changes.
signal player_count_changed(new_count: int)

## Maximum supported players in a co-op session.
const MAX_PLAYERS: int = 4

## Active player count. Clamped to [1, MAX_PLAYERS] on assignment.
## 1 = single-player; 2–4 = co-op.
var player_count: int = 1:
	set(value):
		var clamped: int = clampi(value, 1, MAX_PLAYERS)
		if clamped != player_count:
			player_count = clamped
			player_count_changed.emit(player_count)


## Returns the enemy-count multiplier for the current player count.
## Scales linearly: 1p = ×1.0, 2p = ×1.5, 3p = ×2.0, 4p = ×2.5.
func get_enemy_count_multiplier() -> float:
	return 1.0 + (player_count - 1) * 0.5


## Returns the enemy max-health multiplier for the current player count.
## Scales linearly: 1p = ×1.0, 2p = ×1.25, 3p = ×1.5, 4p = ×1.75.
func get_enemy_health_multiplier() -> float:
	return 1.0 + (player_count - 1) * 0.25
