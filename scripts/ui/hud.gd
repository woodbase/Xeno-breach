## HUD — minimal heads-up display showing player health.
##
## Call [method connect_to_player] after the level loads to bind to the player's
## [HealthComponent] signals.
class_name HUD
extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthContainer/HealthBar
@onready var health_label: Label = $HealthContainer/HealthLabel
@onready var wave_label: Label = $HealthContainer/WaveLabel
@onready var score_label: Label = $HealthContainer/ScoreLabel
@onready var result_label: Label = $ResultLabel
@onready var wave_banner: Label = $WaveBanner

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


## Update the persistent wave counter. [param total_waves] is the run length (e.g. 5).
func set_wave(wave_number: int, total_waves: int) -> void:
	wave_label.text = "Wave  %d / %d" % [wave_number, total_waves]


func set_score(score: int) -> void:
	score_label.text = "Score: %d" % score


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
	if _banner_tween:
		_banner_tween.kill()
	wave_banner.visible = false
	result_label.text = (
		"Run Ended\nWaves cleared: %d\nScore: %d\n\n[LMB/Enter]  Retry\n[ESC]  Main Menu"
		% [waves_survived, score]
	)
	result_label.visible = true
