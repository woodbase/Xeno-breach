## Test level orchestration — wires up player, HUD, and wave spawner.
extends Node2D

@onready var player: PlayerController = $Player
@onready var hud: HUD = $HUD
@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var spawn_points_container: Node2D = $SpawnPoints


func _ready() -> void:
	GameStateManager.change_state(GameStateManager.State.PLAYING)

	# Collect spawn points from scene tree
	var points: Array[Node2D] = []
	for child: Node in spawn_points_container.get_children():
		var point := child as Node2D
		if point != null:
			points.append(point)
	wave_spawner.spawn_points = points

	# Bind HUD to player health
	hud.connect_to_player(player)

	# Connect player death
	player.died.connect(_on_player_died)

	# Connect wave events
	wave_spawner.wave_started.connect(_on_wave_started)
	wave_spawner.wave_completed.connect(_on_wave_completed)
	wave_spawner.all_waves_completed.connect(_on_all_waves_completed)

	# Begin
	wave_spawner.start(player)


func _on_player_died() -> void:
	GameStateManager.change_state(GameStateManager.State.GAME_OVER)
	print("GAME OVER")


func _on_wave_started(wave_number: int) -> void:
	print("Wave %d started!" % wave_number)


func _on_wave_completed(wave_number: int) -> void:
	print("Wave %d cleared!" % wave_number)


func _on_all_waves_completed() -> void:
	GameStateManager.change_state(GameStateManager.State.VICTORY)
	print("VICTORY — all waves cleared!")
