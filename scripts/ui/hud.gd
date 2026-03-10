## HUD — displays player health, wave progression, and end-of-run actions.
##
## Bind to the player via [method connect_to_player] after the scene loads.
class_name HUD
extends CanvasLayer

signal retry_pressed
signal menu_pressed

@onready var health_bar: ProgressBar = $HealthContainer/HealthBar
@onready var health_label: Label = $HealthContainer/HealthLabel
@onready var wave_label: Label = $HealthContainer/WaveLabel
@onready var score_label: Label = $HealthContainer/ScoreLabel
@onready var wave_banner: Label = $WaveBanner
@onready var wave_summary_banner: Label = $WaveSummaryBanner
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var game_over_title: Label = $GameOverPanel/Margin/VBox/GameOverTitle
@onready var final_wave_label: Label = $GameOverPanel/Margin/VBox/FinalWaveLabel
@onready var final_score_label: Label = $GameOverPanel/Margin/VBox/FinalScoreLabel
@onready var retry_button: Button = $GameOverPanel/Margin/VBox/Buttons/RetryButton
@onready var menu_button: Button = $GameOverPanel/Margin/VBox/Buttons/MenuButton
@onready var weapon_label: Label = $WeaponContainer/WeaponLabel
@onready var ammo_label: Label = $WeaponContainer/AmmoLabel
@onready var reload_label: Label = $WeaponContainer/ReloadLabel
@onready var crosshair: Control = $Crosshair

var _total_waves: int = 0
var _current_wave: int = 1
var _banner_tween: Tween = null
var _summary_tween: Tween = null
var _player: PlayerController = null
var _weapon_manager: WeaponManager = null
var _weapon: BaseWeapon = null
var _crosshair_tween: Tween = null


func _ready() -> void:
	game_over_panel.visible = false
	wave_banner.visible = false
	wave_summary_banner.visible = false
	reload_label.visible = false
	retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	menu_button.pressed.connect(func() -> void: menu_pressed.emit())


func _process(_delta: float) -> void:
	_update_crosshair_position()


## Bind the HUD to [param player]'s HealthComponent.
func connect_to_player(player: PlayerController) -> void:
	_player = player
	var health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		push_error("HUD.connect_to_player: Player has no HealthComponent child.")
		return
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)
	player.fired.connect(_on_player_fired)
	player.died.connect(_on_player_died)
	_bind_weapon_from_player(player)


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "HP  %d / %d" % [int(current), int(maximum)]


func set_total_waves(total: int) -> void:
	_total_waves = max(total, 0)
	_update_wave_label()


func set_wave(wave_number: int, total_waves: int = -1) -> void:
	_current_wave = max(1, wave_number)
	if total_waves > 0:
		_total_waves = total_waves
	_update_wave_label()


func set_score(score: int) -> void:
	score_label.text = "Score: %d" % score


func set_crosshair_visible(visible: bool) -> void:
	if crosshair != null:
		crosshair.visible = visible


## Display a centered banner announcing [param wave_number].
func show_wave_banner(wave_number: int, total_waves: int = -1) -> void:
	set_wave(wave_number, total_waves)
	_play_banner(wave_banner, wave_label.text, true)


## Show a short summary after a wave is cleared.
func show_wave_summary(wave_number: int, score: int) -> void:
	var text := "Wave %d cleared — Score %d" % [wave_number, score]
	_play_banner(wave_summary_banner, text, false)


func show_extraction_prompt() -> void:
	_play_banner(wave_summary_banner, "Extraction point is open!", false)


func show_final_results(score: int, waves_survived: int, title: String = "Run Complete") -> void:
	if _banner_tween != null:
		_banner_tween.kill()
	if _summary_tween != null:
		_summary_tween.kill()
	wave_banner.visible = false
	wave_summary_banner.visible = false
	set_crosshair_visible(false)

	game_over_title.text = title
	var wave_text := "Final Wave: %d" % waves_survived
	if _total_waves > 0:
		wave_text = "Final Wave: %d / %d" % [waves_survived, _total_waves]
	final_wave_label.text = wave_text
	final_score_label.text = "Score: %d" % score
	game_over_panel.visible = true
	retry_button.grab_focus()


func _update_wave_label() -> void:
	if _total_waves > 0:
		wave_label.text = "Wave %02d / %02d" % [_current_wave, _total_waves]
	else:
		wave_label.text = "Wave %02d" % _current_wave


func _bind_weapon_from_player(player: PlayerController) -> void:
	_weapon_manager = null
	_weapon = null
	if player.weapon_path.is_empty():
		_set_weapon_labels(null, 0, 0)
		reload_label.visible = false
		return

	var weapon_node := player.get_node_or_null(player.weapon_path)
	if weapon_node is WeaponManager:
		_weapon_manager = weapon_node as WeaponManager
		_weapon_manager.weapon_changed.connect(_on_weapon_changed)
		_weapon_manager.ammo_changed.connect(_on_ammo_changed)
		_weapon_manager.reload_started.connect(_on_reload_started)
		_weapon_manager.reload_completed.connect(_on_reload_completed)
		_weapon_manager.empty_fired.connect(_on_empty_fired)
		_on_weapon_changed(_weapon_manager.get_active_weapon())
	elif weapon_node is BaseWeapon:
		_weapon = weapon_node as BaseWeapon
		_connect_weapon_signals(_weapon)
		_on_weapon_changed(_weapon)
	else:
		_set_weapon_labels(null, 0, 0)
		reload_label.visible = false


func _connect_weapon_signals(weapon: BaseWeapon) -> void:
	if weapon == null:
		return
	if not weapon.ammo_changed.is_connected(_on_ammo_changed):
		weapon.ammo_changed.connect(_on_ammo_changed)
	if not weapon.reload_started.is_connected(_on_reload_started):
		weapon.reload_started.connect(_on_reload_started)
	if not weapon.reload_completed.is_connected(_on_reload_completed):
		weapon.reload_completed.connect(_on_reload_completed)
	if not weapon.empty_fired.is_connected(_on_empty_fired):
		weapon.empty_fired.connect(_on_empty_fired)


func _on_weapon_changed(weapon: BaseWeapon) -> void:
	_weapon = weapon
	reload_label.visible = false
	if weapon == null:
		_set_weapon_labels(null, 0, 0)
		return
	if _weapon_manager == null:
		_connect_weapon_signals(weapon)
	_set_weapon_labels(_format_weapon_name(weapon.name), weapon.current_ammo, weapon.max_ammo)


func _set_weapon_labels(name: String, ammo_current: int, ammo_max: int) -> void:
	var display_name := name if name != null and not name.is_empty() else "No weapon"
	weapon_label.text = display_name
	if ammo_max <= 0:
		ammo_label.text = "-- / --"
		ammo_label.modulate = Color(1, 1, 1, 0.6)
		return
	ammo_label.text = "%d / %d" % [ammo_current, ammo_max]
	var low_threshold := max(1, int(ammo_max * 0.2))
	if ammo_current <= low_threshold:
		ammo_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	else:
		ammo_label.modulate = Color(1, 1, 1, 1)


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	_set_weapon_labels(weapon_label.text, current, max_ammo)
	if current > 0 and reload_label.visible and reload_label.text == "No ammo":
		reload_label.visible = false


func _on_reload_started() -> void:
	reload_label.visible = true
	reload_label.text = "Reloading..."


func _on_reload_completed() -> void:
	reload_label.visible = false


func _on_empty_fired() -> void:
	ammo_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	reload_label.visible = true
	reload_label.text = "No ammo"


func _play_banner(label: Label, text: String, is_primary: bool) -> void:
	if is_primary and _banner_tween != null:
		_banner_tween.kill()
	if not is_primary and _summary_tween != null:
		_summary_tween.kill()

	label.text = text
	label.visible = true
	label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(0.85)
	tween.tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void: label.visible = false)

	if is_primary:
		_banner_tween = tween
	else:
		_summary_tween = tween


func _on_player_fired(_direction: Vector2) -> void:
	if crosshair == null:
		return
	if _crosshair_tween != null:
		_crosshair_tween.kill()
	crosshair.scale = Vector2.ONE * 1.15
	_crosshair_tween = create_tween()
	_crosshair_tween.tween_property(crosshair, "scale", Vector2.ONE, 0.12)


func _on_player_died() -> void:
	set_crosshair_visible(false)


func _update_crosshair_position() -> void:
	if crosshair == null:
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var center := viewport.get_visible_rect().get_center()
	var half_size := crosshair.size * 0.5
	if _player == null:
		crosshair.global_position = center - half_size
		return
	if _player.device_id < 0:
		crosshair.global_position = viewport.get_mouse_position() - half_size
		return

	var aim := Vector2(
		Input.get_joy_axis(_player.device_id, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(_player.device_id, JOY_AXIS_RIGHT_Y)
	)
	if aim.length() > 0.2:
		crosshair.global_position = center + aim.normalized() * 48.0 - half_size
	else:
		crosshair.global_position = center - half_size


func _format_weapon_name(raw_name: String) -> String:
	if raw_name.is_empty():
		return "No weapon"
	var spaced := raw_name.replace("_", " ")
	var buffer := ""
	for i: int in spaced.length():
		var ch_code := spaced.unicode_at(i)
		var ch := char(ch_code)
		if i > 0:
			var prev_code := spaced.unicode_at(i - 1)
			var prev_lower := prev_code >= 97 and prev_code <= 122
			var ch_upper := ch_code >= 65 and ch_code <= 90
			if prev_lower and ch_upper:
				buffer += " "
		buffer += ch
	var trimmed := buffer.strip_edges()
	if trimmed.is_empty():
		return "No weapon"
	return trimmed.left(1).to_upper() + trimmed.substr(1)
