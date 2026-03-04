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
@onready var final_wave_label: Label = $GameOverPanel/Margin/VBox/FinalWaveLabel
@onready var final_score_label: Label = $GameOverPanel/Margin/VBox/FinalScoreLabel
@onready var retry_button: Button = $GameOverPanel/Margin/VBox/Buttons/RetryButton
@onready var menu_button: Button = $GameOverPanel/Margin/VBox/Buttons/MenuButton

var _total_waves: int = 0
var _current_wave: int = 1
var _banner_tween: Tween = null
var _summary_tween: Tween = null


func _ready() -> void:
	game_over_panel.visible = false
	wave_banner.visible = false
	wave_summary_banner.visible = false
	retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	menu_button.pressed.connect(func() -> void: menu_pressed.emit())


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


## Display a centered banner announcing [param wave_number].
func show_wave_banner(wave_number: int, total_waves: int = -1) -> void:
	set_wave(wave_number, total_waves)
	_play_banner(wave_banner, wave_label.text, true)


## Show a short summary after a wave is cleared.
func show_wave_summary(wave_number: int, score: int) -> void:
	var text := "Wave %d cleared — Score %d" % [wave_number, score]
	_play_banner(wave_summary_banner, text, false)


func show_final_results(score: int, waves_survived: int) -> void:
	if _banner_tween != null:
		_banner_tween.kill()
	if _summary_tween != null:
		_summary_tween.kill()
	wave_banner.visible = false
	wave_summary_banner.visible = false

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
