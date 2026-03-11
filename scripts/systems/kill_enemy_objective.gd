## KillEnemyObjective — objective requiring the player to kill a number of enemies.
##
## Tracks enemy kills via [method report_kill] and completes when
## [member target_progress] kills are reached.
## Optionally filter by enemy type via [member required_enemy_type].
class_name KillEnemyObjective
extends MissionObjective

## Optional enemy type name filter (e.g., "xeno_crawler").
## Leave empty to count all enemy kills.
var required_enemy_type: String = ""


func _init(desc: String = "Eliminate enemies", kill_count: int = 10, enemy_type: String = "") -> void:
	super._init(desc, kill_count)
	required_enemy_type = enemy_type


## Report an enemy kill. Increments progress if the enemy type matches
## (or if no type filter is set).
func report_kill(enemy_type: String = "") -> void:
	if is_completed:
		return

	# If we have a type filter, check it
	if not required_enemy_type.is_empty():
		if enemy_type != required_enemy_type:
			return

	increment_progress(1)
