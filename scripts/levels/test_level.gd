## Test level orchestration — wires up player, HUD, and wave spawner.
extends LevelBase

const AudioLibrary = preload("res://scripts/systems/audio_library.gd")

@onready var player: PlayerController = $Player
@onready var hud: HUD = $HUD
@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var exit_trigger: ExitTrigger = get_node_or_null("ExitTrigger") as ExitTrigger
@onready var spawn_points_container: Node2D = $SpawnPoints
@onready var placed_enemies_container: Node2D = get_node_or_null("PlacedEnemies") as Node2D

const SCORE_PER_KILL: int = 100
const SCORE_WAVE_BONUS: int = 250
const TELEMETRY_TARGET_CLEAR_TIME_MIN: float = 18.0
const TELEMETRY_TARGET_CLEAR_TIME_MAX: float = 40.0
const TELEMETRY_TARGET_KILLS_PER_MIN_MIN: float = 10.0
const TELEMETRY_TARGET_KILLS_PER_MIN_MAX: float = 35.0
const TELEMETRY_TARGET_DAMAGE_TAKEN_MAX: float = 30.0
const PLAYER_SCENE: String = "res://scenes/player/player.tscn"

## Spawn offsets for co-op players 2–4 relative to player 1.
const COOP_SPAWN_OFFSETS: PackedVector2Array = [
	Vector2(80.0, 0.0),
	Vector2(-80.0, 0.0),
	Vector2(0.0, 80.0),
]

var _score: int = 0
var _waves_survived: int = 0
var _wave_started_at_ms: int = 0
var _wave_damage_taken: float = 0.0
var _wave_damage_dealt: float = 0.0
var _wave_kills: int = 0
var _run_finished: bool = false
var _restarting: bool = false
var _run_id: String = ""
var _run_seed: int = 0
var _current_wave: int = 1
var _alive_players: int = 1
var _ambient_player: AudioStreamPlayer = null
var _awaiting_extraction: bool = false


func _ready() -> void:
	super._ready()
	_init_run_identity()
	GameStateManager.change_state(GameStateManager.State.PLAYING)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_ambient_bed()

	# Collect spawn points from direct scene hierarchy and any RoomTemplate children.
	var points: Array[Node2D] = []
	for child: Node in spawn_points_container.get_children():
		var point := child as Node2D
		if point != null:
			points.append(point)
	for rp: Node2D in get_room_spawn_points():
		if not points.has(rp):
			points.append(rp)
	wave_spawner.spawn_points = points

	# Bind HUD to player 1 health
	hud.connect_to_player(player)
	hud.set_total_waves(wave_spawner.get_total_waves())
	hud.set_wave(_current_wave)
	hud.retry_pressed.connect(_restart_run)
	hud.menu_pressed.connect(go_to_main_menu)

	# Track alive players (starts at 1 for the scene player)
	_alive_players = CoopManager.player_count
	player.died.connect(_on_any_player_died)
	player.damaged.connect(_on_player_damaged)

	# Connect wave events before start() so the first wave_started signal is not missed.
	wave_spawner.wave_started.connect(_on_wave_started)
	wave_spawner.wave_completed.connect(_on_wave_completed)
	wave_spawner.all_waves_completed.connect(_on_all_waves_completed)
	wave_spawner.enemy_killed.connect(_on_enemy_killed)
	wave_spawner.enemy_spawned.connect(_on_enemy_spawned)
	_bind_placed_enemies()
	if exit_trigger != null:
		exit_trigger.player_extracted.connect(_on_player_extracted)
		exit_trigger.set_active(false)

	# Spawn extra local co-op players (players 2–4 use gamepad slots 0, 1, 2).
	# Connect audio signals
	player.damaged.connect(_on_player_damaged_audio)

	hud.set_score(_score)

	# Begin
	wave_spawner.start(player)
	var extra_count: int = CoopManager.player_count - 1
	if extra_count > 0:
		var player_packed: PackedScene = load(PLAYER_SCENE) as PackedScene
		for i: int in extra_count:
			if player_packed == null:
				break
			var extra: PlayerController = player_packed.instantiate() as PlayerController
			if extra == null:
				continue
			extra.device_id = i  # player 2 → slot 0, player 3 → slot 1, player 4 → slot 2
			extra.position = player.position + COOP_SPAWN_OFFSETS[i]
			add_child(extra)
			extra.died.connect(_on_any_player_died)
			wave_spawner.add_coop_player(extra)

	hud.set_score(_score)


func _bind_placed_enemies() -> void:
	if placed_enemies_container == null:
		return
	for child: Node in placed_enemies_container.get_children():
		var enemy := child as EnemyBase
		if enemy == null:
			continue
		enemy.died.connect(_on_enemy_killed)
		_on_enemy_spawned(enemy)


func _on_any_player_died() -> void:
	_alive_players -= 1
	if _alive_players <= 0:
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
	AudioManager.play_ui("wave_start")
	print("[Run %s] Wave %d started! (seed=%d)" % [_run_id, wave_number, _run_seed])


func _on_wave_completed(wave_number: int) -> void:
	_waves_survived = wave_number
	_score += SCORE_WAVE_BONUS
	hud.set_score(_score)
	_log_wave_telemetry(wave_number)
	hud.show_wave_summary(wave_number, _score)
	print("[Run %s] Wave %d cleared! Score=%d" % [_run_id, wave_number, _score])


func _on_all_waves_completed() -> void:
	if exit_trigger != null:
		_awaiting_extraction = true
		exit_trigger.set_active(true)
		hud.show_extraction_prompt()
		print("All waves cleared! Reach extraction point.")
		return

	_complete_level_run()


func _on_player_extracted() -> void:
	if not _awaiting_extraction:
		return
	_awaiting_extraction = false
	if exit_trigger != null:
		exit_trigger.set_active(false)
	_complete_level_run()


func _complete_level_run() -> void:
	go_to_next_level()


func _on_no_next_level() -> void:
	_run_finished = true
	_transitioning = true
	GameStateManager.final_score = _score
	GameStateManager.final_waves_survived = _current_wave
	GameStateManager.change_state(GameStateManager.State.VICTORY)
	hud.show_final_results(_score, _current_wave, "Demo Complete")
	AudioManager.play_music("victory_theme")
	print("VICTORY — all waves cleared! Score=%d" % _score)
	get_tree().change_scene_to_file("res://scenes/ui/demo_end_screen.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if _run_finished and not _transitioning:
		if event.is_action_pressed("fire") or event.is_action_pressed("ui_accept"):
			_restarting = true
			_restart_run()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("pause"):
			_restarting = true
			go_to_main_menu()
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
		"[Telemetry %s] Wave %d | clear_time=%.2fs | damage_dealt=%.1f | damage_taken=%.1f | kills=%d | kills_per_min=%.2f"
		% [_run_id, wave_number, elapsed_sec, _wave_damage_dealt, _wave_damage_taken, _wave_kills, kills_per_minute]
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
		print("[Telemetry %s] Wave %d balance_hints=%s" % [_run_id, wave_number, ",".join(notes)])


func _restart_run() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func _start_ambient_bed() -> void:
	if _ambient_player == null:
		_ambient_player = AudioStreamPlayer.new()
		_ambient_player.name = "AmbientBed"
		_ambient_player.process_mode = Node.PROCESS_MODE_ALWAYS
		_ambient_player.stream = AudioLibrary.get_ambient_loop()
		_ambient_player.volume_db = -12.0
		_ambient_player.bus = AudioManager.BUS_AMBIENCE
		add_child(_ambient_player)
	if _ambient_player.stream == null:
		_ambient_player.stream = AudioLibrary.get_ambient_loop()
	_ambient_player.play()


func _on_player_damaged_audio(amount: float) -> void:
	AudioManager.play_sfx("player_hurt", player.global_position)


func _init_run_identity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_run_seed = int(abs(rng.seed)) % 1000000000
	_run_id = "run-%d" % _run_seed
	seed(_run_seed)
	print("[Run] id=%s seed=%d" % [_run_id, _run_seed])
