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
signal enemy_spawned(enemy: EnemyBase)
signal enemy_killed

@export var enemy_scene: PackedScene
@export var total_waves: int = 3
@export var enemies_per_wave: int = 5
@export var spawn_delay: float = 0.3
@export var between_wave_delay: float = 2.0
@export var wave_data_list: Array[WaveData] = []
@export var min_spawn_distance_from_player: float = 220.0
@export var spawn_retry_count: int = 8

## Set by the owning level. Also accepted via [method start].
var spawn_points: Array[Node2D] = []

var _current_wave: int = 0
var _active_enemies: int = 0
var _player: Node2D = null
var _players: Array[Node2D] = []
var _between_waves: bool = false
var _spawning: bool = false
var _transitioning: bool = false
var _starting_wave: bool = false
var _wave_in_progress: bool = false


## Returns true while a wave transition is in progress (between-wave delay).
func is_transitioning() -> bool:
	return _transitioning


## Begin spawning waves, targeting [param player].
func start(player: Node2D) -> void:
	_player = player
	_players = [player]
	_current_wave = 0
	_transitioning = false
	_between_waves = false
	_active_enemies = 0
	_starting_wave = false
	_wave_in_progress = false
	_start_wave(_current_wave)


## Register an additional co-op player as an enemy target.
## Call after [method start] for each extra player (players 2–4).
func add_coop_player(player: Node2D) -> void:
	if not _players.has(player):
		_players.append(player)


func _start_wave(index: int) -> void:
	if _starting_wave:
		return
	_starting_wave = true
	if index >= _get_total_waves():
		all_waves_completed.emit()
		_starting_wave = false
		return

	# Guard against double-triggering wave starts
	if _wave_in_progress:
		_starting_wave = false
		return

	_wave_in_progress = true
	wave_started.emit(index + 1)
	_active_enemies = _get_wave_enemy_count(index)
	_starting_wave = false
	_spawn_wave_enemies()


func _spawn_wave_enemies() -> void:
	var wave_spawn_delay: float = _get_wave_spawn_delay(_current_wave)
	for i: int in _active_enemies:
		if i > 0:
			await get_tree().create_timer(wave_spawn_delay).timeout
		_spawn_single_enemy()


func _spawn_single_enemy() -> void:
	if spawn_points.is_empty():
		push_warning("WaveSpawner: no spawn_points assigned.")
		_on_enemy_removed(false)
		return

	var selected_enemy_scene: PackedScene = _get_wave_enemy_scene(_current_wave)
	if selected_enemy_scene == null:
		push_warning("WaveSpawner: no enemy scene configured for current wave.")
		_on_enemy_removed(false)
		return

	var point: Node2D = _select_spawn_point()
	if point == null:
		push_warning("WaveSpawner: failed to find valid spawn point outside safety radius.")
		_on_enemy_removed(false)
		return
	var enemy: EnemyBase = selected_enemy_scene.instantiate() as EnemyBase
	if enemy == null:
		push_warning("WaveSpawner: selected enemy scene root is not an EnemyBase.")
		_on_enemy_removed(false)
		return

	enemy.global_position = point.global_position
	var active_players: Array[Node2D] = _get_active_players()
	if not active_players.is_empty():
		enemy.set_target(active_players[randi() % active_players.size()])
	elif _player != null:
		enemy.set_target(_player)
	enemy.died.connect(_on_enemy_died)
	get_parent().add_child(enemy)
	# Scale enemy HP for co-op difficulty.
	# add_child() triggers _ready() on the enemy, so HealthComponent is initialized here.
	var health: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		var hp_multiplier: float = CoopManager.get_enemy_health_multiplier()
		if not is_equal_approx(hp_multiplier, 1.0):
			health.max_health *= hp_multiplier
			health.current_health = health.max_health
			health.health_changed.emit(health.current_health, health.max_health)
	enemy_spawned.emit(enemy)


func _on_enemy_died() -> void:
	_on_enemy_removed(true)


func _on_enemy_removed(killed: bool) -> void:
	_active_enemies -= 1
	if killed:
		enemy_killed.emit()
	if _active_enemies > 0 or _between_waves:
		return

	_transitioning = true
	_between_waves = true
	_wave_in_progress = false
	wave_completed.emit(_current_wave + 1)
	_current_wave += 1
	await get_tree().create_timer(between_wave_delay).timeout
	_transitioning = false
	_between_waves = false
	_start_wave(_current_wave)


func _get_total_waves() -> int:
	if not wave_data_list.is_empty():
		return wave_data_list.size()
	return total_waves


## Returns the total number of waves for this run (public accessor).
## Get the actual number of waves that will be spawned.
## Returns the size of wave_data_list if configured, otherwise total_waves.
func get_total_waves() -> int:
	return _get_total_waves()


func _get_wave_enemy_count(index: int) -> int:
	var base_count: int = 0
	if index < wave_data_list.size():
		base_count = maxi(0, wave_data_list[index].enemy_count)
	elif not wave_data_list.is_empty():
		push_warning("WaveSpawner: missing WaveData for index %d; defaulting enemy_count=0." % index)
	else:
		base_count = enemies_per_wave
	return roundi(base_count * CoopManager.get_enemy_count_multiplier())


func _get_wave_spawn_delay(index: int) -> float:
	if index < wave_data_list.size():
		return maxf(0.0, wave_data_list[index].spawn_delay)
	return spawn_delay


func _get_wave_enemy_scene(index: int) -> PackedScene:
	if index < wave_data_list.size():
		var wave_data: WaveData = wave_data_list[index]
		var pool_scene: PackedScene = _pick_enemy_scene_from_pool(wave_data)
		if pool_scene != null:
			return pool_scene
		var data_enemy_scene: PackedScene = wave_data.enemy_scene
		if data_enemy_scene != null:
			return data_enemy_scene
	return enemy_scene


func _pick_enemy_scene_from_pool(wave_data: WaveData) -> PackedScene:
	if wave_data.enemy_scene_pool.is_empty():
		return null
	var valid_scenes: Array[PackedScene] = []
	for scene: PackedScene in wave_data.enemy_scene_pool:
		if scene != null:
			valid_scenes.append(scene)
	if valid_scenes.is_empty():
		return null
	return valid_scenes[randi() % valid_scenes.size()]


## Returns players that are still valid and alive — used for targeting and spawn placement.
func _get_active_players() -> Array[Node2D]:
	return _players.filter(func(p: Node2D) -> bool:
		if not is_instance_valid(p):
			return false
		var hc: HealthComponent = p.get_node_or_null("HealthComponent") as HealthComponent
		return hc == null or hc.is_alive()
	)


func _select_spawn_point() -> Node2D:
	if spawn_points.is_empty():
		return null
	var active_players: Array[Node2D] = _get_active_players()
	if active_players.is_empty():
		return spawn_points[randi() % spawn_points.size()]

	for _attempt: int in spawn_retry_count:
		var candidate: Node2D = spawn_points[randi() % spawn_points.size()]
		if _is_far_from_all_players(candidate.global_position, active_players):
			return candidate

	for candidate: Node2D in spawn_points:
		if _is_far_from_all_players(candidate.global_position, active_players):
			return candidate
	return null


func _is_far_from_all_players(pos: Vector2, active_players: Array[Node2D]) -> bool:
	for p: Node2D in active_players:
		if pos.distance_to(p.global_position) < min_spawn_distance_from_player:
			return false
	return true
