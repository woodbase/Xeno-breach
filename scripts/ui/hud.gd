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


func set_wave(wave_number: int) -> void:
	wave_label.text = "Wave: %d" % wave_number


func set_score(score: int) -> void:
	score_label.text = "Score: %d" % score


func show_final_results(score: int, waves_survived: int) -> void:
	result_label.text = "Run complete\nScore: %d\nWaves survived: %d" % [score, waves_survived]
	result_label.visible = true
