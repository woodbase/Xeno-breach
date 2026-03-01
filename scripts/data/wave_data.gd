## WaveData — Resource that describes a single wave's composition.
##
## Assign an array of WaveData resources to [WaveSpawner] for fully data-driven wave design.
class_name WaveData
extends Resource

@export var wave_name: String = "Wave 1"
@export var enemy_count: int = 5
@export var spawn_delay: float = 0.3
