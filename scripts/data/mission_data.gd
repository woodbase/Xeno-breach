## MissionData — Resource that defines a mission's static configuration.
##
## Used as a template to create runtime [Mission] instances.
## Store mission metadata and serialize objective definitions.
class_name MissionData
extends Resource

## Unique identifier for this mission.
@export var mission_id: String = ""

## Human-readable mission name.
@export var mission_name: String = "Untitled Mission"

## Mission description shown to the player.
@export_multiline var mission_description: String = ""

## Whether this mission is optional.
@export var is_optional: bool = false

## XP or score reward for completing this mission.
@export var reward_score: int = 0


## Create a runtime [Mission] instance from this data.
## Objectives must be added programmatically after creation.
func create_mission_instance() -> Mission:
	var mission: Mission = Mission.new()
	mission.mission_id = mission_id
	mission.mission_name = mission_name
	mission.mission_description = mission_description
	mission.is_optional = is_optional
	mission.reward_score = reward_score
	return mission
