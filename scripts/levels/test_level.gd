## Test level orchestration — wires up player, HUD, and wave spawner.
extends Node2D

const AudioLibrary = preload("res://scripts/systems/audio_library.gd")

@onready var player: PlayerController = $Player
@onready var hud: HUD = $HUD
@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var spawn_points_container: Node2D = $SpawnPoints

const SCORE_PER_KILL: int = 100
const SCORE_WAVE_BONUS: int = 250
const TELEMETRY_TARGET_CLEAR_TIME_MIN: float = 18.0
const TELEMETRY_TARGET_CLEAR_TIME_MAX: float = 40.0
const TELEMETRY_TARGET_KILLS_PER_MIN_MIN: float = 10.0
const TELEMETRY_TARGET_KILLS_PER_MIN_MAX: float = 35.0
const TELEMETRY_TARGET_DAMAGE_TAKEN_MAX: float = 30.0
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"

@export var debug_telemetry_enabled: bool = false
@export_file("*.tscn") var next_level_scene_path: String = ""

var _score: int = 0
var _waves_survived: int = 0
var _wave_started_at_ms: int = 0
var _wave_damage_taken: float = 0.0
var _wave_damage_dealt: float = 0.0
var _wave_kills: int = 0
var _run_finished: bool = false
var _restarting: bool = false
var _current_wave: int = 1
var _transitioning: bool = false
var _ambient_player: AudioStreamPlayer = null


func _ready() -> void:
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	process_mode = PROCESS_MODE_ALWAYS
	_start_ambient_bed()

	# Collect spawn points from scene tree
	var points: Array[Node2D] = []
	for child: Node in spawn_points_container.get_children():
		var point := child as Node2D
		if point != null:
			points.append(point)
	wave_spawner.spawn_points = points

	# Bind HUD to player health
	hud.connect_to_player(player)
	hud.set_total_waves(wave_spawner.get_total_waves())
	hud.set_wave(_current_wave)
	hud.retry_pressed.connect(_restart_run)
	hud.menu_pressed.connect(_return_to_main_menu)

	# Connect player death
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)

	# Connect wave events
	wave_spawner.wave_started.connect(_on_wave_started)
	wave_spawner.wave_completed.connect(_on_wave_completed)
	wave_spawner.all_waves_completed.connect(_on_all_waves_completed)
	wave_spawner.enemy_killed.connect(_on_enemy_killed)
	wave_spawner.enemy_spawned.connect(_on_enemy_spawned)

	# Connect audio signals
	player.damaged.connect(_on_player_damaged_audio)

	hud.set_score(_score)

	# Begin
	wave_spawner.start(player)

	# Start combat music and station ambience
	AudioManager.play_music("combat_theme")


func _on_player_died() -> void:
	_run_finished = true
	GameStateManager.change_state(GameStateManager.State.GAME_OVER)
	hud.show_final_results(_score, _current_wave)
	AudioManager.play_ui("game_over")
	AudioManager.stop_music()
	print("GAME OVER")


func _on_wave_started(wave_number: int) -> void:
	_current_wave = wave_number
	_wave_started_at_ms = Time.get_ticks_msec()
	_wave_damage_taken = 0.0
	_wave_damage_dealt = 0.0
	_wave_kills = 0
	var total: int = wave_spawner.get_total_waves()
	hud.set_wave(wave_number, total)
	hud.show_wave_banner(wave_number, total)
	hud.set_wave(wave_number, wave_spawner.get_total_waves())
	hud.show_wave_banner(wave_number)
	AudioManager.play_ui("wave_start")
	print("Wave %d started!" % wave_number)


func _on_wave_completed(wave_number: int) -> void:
	_waves_survived = wave_number
	_score += SCORE_WAVE_BONUS
	hud.set_score(_score)
	_log_wave_telemetry(wave_number)
	print("Wave %d cleared!" % wave_number)


func _on_all_waves_completed() -> void:
	if not next_level_scene_path.is_empty():
		var has_next_level := ResourceLoader.exists(next_level_scene_path)
		if has_next_level:
			_go_to_next_level()
			return
		else:
			push_warning("Configured next_level_scene_path does not exist: %s" % next_level_scene_path)

	_run_finished = true
	GameStateManager.change_state(GameStateManager.State.VICTORY)
	hud.show_final_results(_score, _current_wave)
	AudioManager.play_music("victory_theme")
	print("VICTORY — all waves cleared!")


func _unhandled_input(event: InputEvent) -> void:
	if _run_finished and not _transitioning:
		if event.is_action_pressed("fire") or event.is_action_pressed("ui_accept"):
			_restarting = true
			_restart_run()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("pause"):
			_restarting = true
			_return_to_main_menu()
			get_viewport().set_input_as_handled()
			return

	if not _run_finished and event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if get_tree().paused:
		get_tree().paused = false
		GameStateManager.change_state(GameStateManager.State.PLAYING)
	else:
		get_tree().paused = true
		GameStateManager.change_state(GameStateManager.State.PAUSED)


func _on_enemy_killed() -> void:
	_wave_kills += 1
	_score += SCORE_PER_KILL
	hud.set_score(_score)


func _on_enemy_spawned(enemy: EnemyBase) -> void:
	var health: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.damaged.connect(func(amount: float) -> void: _wave_damage_dealt += amount)
		health.died.connect(func() -> void:
			AudioManager.play_sfx("enemy_death", enemy.global_position)
		)


func _on_player_damaged(amount: float) -> void:
	_wave_damage_taken += amount


func _log_wave_telemetry(wave_number: int) -> void:
	if not debug_telemetry_enabled:
		return
	var elapsed_sec: float = maxf(0.001, float(Time.get_ticks_msec() - _wave_started_at_ms) / 1000.0)
	var kills_per_minute: float = float(_wave_kills) * 60.0 / elapsed_sec
	print(
		"[Telemetry] Wave %d | clear_time=%.2fs | damage_dealt=%.1f | damage_taken=%.1f | kills=%d | kills_per_min=%.2f"
		% [wave_number, elapsed_sec, _wave_damage_dealt, _wave_damage_taken, _wave_kills, kills_per_minute]
	)
	var notes: Array[String] = []
	if elapsed_sec < TELEMETRY_TARGET_CLEAR_TIME_MIN:
		notes.append("too_fast")
	elif elapsed_sec > TELEMETRY_TARGET_CLEAR_TIME_MAX:
		notes.append("too_slow")
	if kills_per_minute < TELEMETRY_TARGET_KILLS_PER_MIN_MIN:
		notes.append("low_kpm")
	elif kills_per_minute > TELEMETRY_TARGET_KILLS_PER_MIN_MAX:
		notes.append("high_kpm")
	if _wave_damage_taken > TELEMETRY_TARGET_DAMAGE_TAKEN_MAX:
		notes.append("high_damage_taken")
	if not notes.is_empty():
		print("[Telemetry] Wave %d balance_hints=%s" % [wave_number, ",".join(notes)])


func _restart_run() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func _go_to_next_level() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	get_tree().change_scene_to_file(next_level_scene_path)


func _return_to_main_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false
	GameStateManager.change_state(GameStateManager.State.MAIN_MENU)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _start_ambient_bed() -> void:
	if _ambient_player == null:
		_ambient_player = AudioStreamPlayer.new()
		_ambient_player.name = "AmbientBed"
		# Godot 4.x pause handling uses process_mode/PROCESS_MODE_* constants.
		_ambient_player.process_mode = PROCESS_MODE_ALWAYS
		_ambient_player.stream = AudioLibrary.get_ambient_loop()
		_ambient_player.volume_db = -12.0
		_ambient_player.bus = AudioManager.BUS_AMBIENCE
		add_child(_ambient_player)
	if _ambient_player.stream == null:
		_ambient_player.stream = AudioLibrary.get_ambient_loop()
	_ambient_player.play()


func _on_player_damaged_audio(amount: float) -> void:
	AudioManager.play_sfx("player_hurt", player.global_position)
