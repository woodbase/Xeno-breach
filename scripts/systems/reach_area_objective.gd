## ReachAreaObjective — objective requiring the player to reach a specific location.
##
## Completes when any player enters the target area (within [member radius]).
## Must be activated with [method set_target_position] before use.
class_name ReachAreaObjective
extends MissionObjective

## Target world position the player must reach.
var target_position: Vector2 = Vector2.ZERO

## Acceptance radius in pixels.
var radius: float = 100.0

var _is_checking: bool = false


func _init(desc: String = "Reach the designated area", pos: Vector2 = Vector2.ZERO, check_radius: float = 100.0) -> void:
	super._init(desc, 1)
	target_position = pos
	radius = check_radius


## Set the target position the player must reach.
func set_target_position(pos: Vector2, check_radius: float = 100.0) -> void:
	target_position = pos
	radius = check_radius


## Check if [param player_position] is within the target area.
func check_player_position(player_position: Vector2) -> void:
	if is_completed:
		return

	var distance: float = player_position.distance_to(target_position)
	if distance <= radius:
		complete()
