## WaveSpawner — spawns waves of enemies at registered spawn points.
##
## Call [method start] with a target [Node2D] (typically the player) to begin.
## Enemies are given the target reference automatically.
## Connect to [signal wave_started], [signal wave_completed], and [signal all_waves_completed]
## to drive level progression and UI feedback.
class_name WaveSpawner
extends Node

## Emitted at the start of each wave. [param wave_number] is 1-based.
signal wave_started(wave_number: int)

## Emitted when every enemy in a wave has been defeated.
signal wave_completed(wave_number: int)

## Emitted after the final wave is cleared.
signal all_waves_completed

@export var enemy_scene: PackedScene
@export var total_waves: int = 3
@export var enemies_per_wave: int = 5
@export var spawn_delay: float = 0.3
@export var between_wave_delay: float = 2.0

## Set by the owning level. Also accepted via [method start].
var spawn_points: Array[Node2D] = []

var _current_wave: int = 0
var _active_enemies: int = 0
var _player: Node2D = null
var _spawning: bool = false


## Begin spawning waves, targeting [param player].
func start(player: Node2D) -> void:
	_player = player
	_current_wave = 0
	_start_wave(_current_wave)


func _start_wave(index: int) -> void:
	if index >= total_waves:
		all_waves_completed.emit()
		return

	wave_started.emit(index + 1)
	_active_enemies = enemies_per_wave
	_spawn_wave_enemies()


func _spawn_wave_enemies() -> void:
	for i: int in _active_enemies:
		await get_tree().create_timer(spawn_delay * i).timeout
		_spawn_single_enemy()


func _spawn_single_enemy() -> void:
	if spawn_points.is_empty():
		push_warning("WaveSpawner: no spawn_points assigned.")
		return
	if enemy_scene == null:
		push_warning("WaveSpawner: enemy_scene is not assigned.")
		return

	var point: Node2D = spawn_points[randi() % spawn_points.size()]
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
	if enemy == null:
		push_warning("WaveSpawner: enemy_scene root is not an EnemyBase.")
		return

	enemy.global_position = point.global_position
	if _player != null:
		enemy.set_target(_player)
	enemy.died.connect(_on_enemy_died)
	get_parent().add_child(enemy)


func _on_enemy_died() -> void:
	_active_enemies -= 1
	if _active_enemies <= 0:
		wave_completed.emit(_current_wave + 1)
		_current_wave += 1
		await get_tree().create_timer(between_wave_delay).timeout
		_start_wave(_current_wave)
