## BiomeProfile — data resource describing a level biome.
##
## Stores colour palette and descriptive metadata used by level visuals and
## environmental flavour systems.
class_name BiomeProfile
extends Resource

@export var biome_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

## Ambient canvas tint applied to the level.
@export var ambient_color: Color = Color(0.32, 0.32, 0.42, 1.0)

## Default colours for light sources in the biome.
@export var emergency_light_color: Color = Color(1.0, 0.18, 0.1, 1.0)
@export var terminal_light_color: Color = Color(0.1, 0.85, 0.95, 1.0)
@export var ambient_fill_color: Color = Color(0.45, 0.45, 0.65, 1.0)

## Short list of environmental hazards commonly found in this biome.
@export var signature_hazards: Array[String] = []
