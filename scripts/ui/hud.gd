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

var _banner_tween: Tween = null


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


func set_wave(wave_number: int, total_waves: int = 5) -> void:
	wave_label.text = "Wave %d / %d" % [wave_number, total_waves]


func set_score(score: int) -> void:
	score_label.text = "Score: %d" % score


func show_final_results(score: int, waves_survived: int) -> void:
	result_label.text = "Run Complete\n\nFinal Wave: %d\nScore: %d\n\n[LMB/Enter] Retry    [ESC] Menu" % [waves_survived, score]
	result_label.visible = true


## Display wave transition banner with animation.
## Duration: ~1.2s (fade in 0.2s + hold 0.8s + fade out 0.2s)
func show_wave_banner(wave_number: int) -> void:
	# Cancel any existing banner animation to prevent stacking
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()

	wave_banner.text = "Wave %d" % wave_number
	wave_banner.modulate = Color(1, 1, 1, 0)  # Start transparent
	wave_banner.visible = true

	_banner_tween = create_tween()
	_banner_tween.set_ease(Tween.EASE_IN_OUT)
	_banner_tween.set_trans(Tween.TRANS_CUBIC)

	# Fade in: 0.2s
	_banner_tween.tween_property(wave_banner, "modulate:a", 1.0, 0.2)
	# Hold: 0.8s
	_banner_tween.tween_interval(0.8)
	# Fade out: 0.2s
	_banner_tween.tween_property(wave_banner, "modulate:a", 0.0, 0.2)
	# Hide after animation complete
	_banner_tween.tween_callback(func() -> void: wave_banner.visible = false)
