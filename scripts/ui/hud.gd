## HUD — minimal heads-up display showing player health.
##
## Call [method connect_to_player] after the level loads to bind to the player's
## [HealthComponent] signals.
class_name HUD
extends CanvasLayer

signal retry_pressed
signal menu_pressed

@onready var health_bar: ProgressBar = $HealthContainer/HealthBar
@onready var health_label: Label = $HealthContainer/HealthLabel
@onready var wave_label: Label = $HealthContainer/WaveLabel
@onready var score_label: Label = $HealthContainer/ScoreLabel
@onready var result_label: Label = $ResultLabel
@onready var wave_banner: Label = $WaveBanner

## Default matches the 5-wave layout used in the built-in wave_data_list.
## Always call [method set_total_waves] after creation to override.
var _total_waves: int = 5
var _banner_tween: Tween = null
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var final_wave_label: Label = $GameOverPanel/Margin/VBox/FinalWaveLabel
@onready var final_score_label: Label = $GameOverPanel/Margin/VBox/FinalScoreLabel
@onready var retry_button: Button = $GameOverPanel/Margin/VBox/Buttons/RetryButton
@onready var menu_button: Button = $GameOverPanel/Margin/VBox/Buttons/MenuButton

var _total_waves: int = 0
var _current_wave: int = 1
var _banner_tween: Tween


## Bind the HUD to [param player]'s HealthComponent.
func connect_to_player(player: PlayerController) -> void:
	var health: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		push_error("HUD.connect_to_player: Player has no HealthComponent child.")
		return
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "HP  %d / %d" % [int(current), int(maximum)]


func set_total_waves(n: int) -> void:
	_total_waves = n


func set_wave(wave_number: int) -> void:
	wave_label.text = "Wave %d / %d" % [wave_number, _total_waves]
## Update the persistent wave counter. [param total_waves] is the run length (e.g. 5).
func set_wave(wave_number: int, total_waves: int) -> void:
	wave_label.text = "Wave  %d / %d" % [wave_number, total_waves]
func set_wave(wave_number: int) -> void:
	_current_wave = wave_number
	_update_wave_label()


func set_score(score: int) -> void:
	score_label.text = "Score: %d" % score


## Display a centered banner announcing [param wave_number].
## Fades in (0.25 s), holds (0.75 s), fades out (0.25 s).
## Kills any in-progress banner before starting a new one.
func show_wave_banner(wave_number: int) -> void:
	if _banner_tween != null:
		_banner_tween.kill()
	wave_banner.text = "Wave %d" % wave_number
	wave_banner.modulate.a = 0.0
	wave_banner.visible = true
	_banner_tween = create_tween()
	_banner_tween.tween_property(wave_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(0.75)
	_banner_tween.tween_property(wave_banner, "modulate:a", 0.0, 0.25)
## Show a centered banner for the new wave. Kills any banner already animating.
func show_wave_banner(wave_number: int, total_waves: int) -> void:
	if _banner_tween:
		_banner_tween.kill()
	wave_banner.text = "Wave %d / %d" % [wave_number, total_waves]
	wave_banner.modulate.a = 0.0
	wave_banner.visible = true
	_banner_tween = create_tween()
	_banner_tween.tween_property(wave_banner, "modulate:a", 1.0, 0.3)
	_banner_tween.tween_interval(0.8)
	_banner_tween.tween_property(wave_banner, "modulate:a", 0.0, 0.4)
	_banner_tween.tween_callback(func() -> void: wave_banner.visible = false)


func show_final_results(score: int, waves_survived: int) -> void:
	if _banner_tween != null:
		_banner_tween.kill()
	wave_banner.visible = false
	result_label.text = (
		"Waves survived: %d / %d\nScore: %d\n\n[LMB / Enter]  Retry\n[Esc]  Menu"
		% [waves_survived, _total_waves, score]
	if _banner_tween:
		_banner_tween.kill()
	wave_banner.visible = false
	result_label.text = (
		"Run Ended\nWaves cleared: %d\nScore: %d\n\n[LMB/Enter]  Retry\n[ESC]  Main Menu"
		% [waves_survived, score]
	)
	result_label.visible = true
	result_label.visible = false
	_show_wave_banner(false)
	var wave_text := "Final Wave: %d" % waves_survived
	if _total_waves > 0:
		wave_text = "Final Wave: %d / %d" % [waves_survived, _total_waves]
	final_wave_label.text = wave_text
	final_score_label.text = "Score: %d" % score
	game_over_panel.visible = true
	retry_button.grab_focus()


func set_total_waves(total: int) -> void:
	_total_waves = max(total, 0)
	_update_wave_label()


func show_wave_banner(wave_number: int) -> void:
	_current_wave = wave_number
	_update_wave_label()
	_show_wave_banner(true)


func _ready() -> void:
	game_over_panel.visible = false
	wave_banner.visible = false
	retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	menu_button.pressed.connect(func() -> void: menu_pressed.emit())


func _update_wave_label() -> void:
	if _total_waves > 0:
		wave_label.text = "Wave %d / %d" % [_current_wave, _total_waves]
	else:
		wave_label.text = "Wave %d" % _current_wave


func _show_wave_banner(show: bool) -> void:
	if _banner_tween != null:
		_banner_tween.kill()
		banner_cleanup()
	if not show:
		wave_banner.visible = false
		return
	wave_banner.text = wave_label.text
	wave_banner.visible = true
	wave_banner.modulate.a = 0.0
	wave_banner.scale = Vector2(0.9, 0.9)
	_banner_tween = create_tween()
	_banner_tween.tween_property(wave_banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_property(wave_banner, "scale", Vector2.ONE, 0.1)
	_banner_tween.tween_interval(0.7)
	_banner_tween.tween_property(wave_banner, "modulate:a", 0.0, 0.35)
	_banner_tween.tween_callback(banner_cleanup)


func banner_cleanup() -> void:
	wave_banner.visible = false
	_banner_tween = null
