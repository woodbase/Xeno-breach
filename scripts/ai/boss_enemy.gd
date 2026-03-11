## BossEnemy — EnemyBase extension with two-phase combat.
##
## Phase 1 (≥ 50 % HP): standard EnemyBase behaviour.
## Phase 2 (<  50 % HP): [member move_speed] and [member attack_cooldown] are scaled by
##   [member phase_2_speed_mult] and [member phase_2_cooldown_mult] respectively,
##   and the body tint shifts to an intense red to signal the power surge.
##
## Connect to [signal phase_changed] to drive UI / audio feedback on the transition.
class_name BossEnemy
extends EnemyBase

## Emitted when the boss transitions between phases. [param new_phase] is 1-indexed.
signal phase_changed(new_phase: int)

## Move-speed multiplier applied when entering phase 2.
@export var phase_2_speed_mult: float = 1.5
## Attack-cooldown multiplier applied when entering phase 2 (< 1 means faster attacks).
@export var phase_2_cooldown_mult: float = 0.6

var _current_phase: int = 1
var _phase_2_triggered: bool = false


func _ready() -> void:
	super._ready()
	health_component.health_changed.connect(_on_boss_health_changed)


## Returns the boss's current combat phase (1 or 2).
func get_current_phase() -> int:
	return _current_phase


func _on_boss_health_changed(current: float, maximum: float) -> void:
	if _phase_2_triggered:
		return
	if maximum > 0.0 and current / maximum < 0.5:
		_trigger_phase_2()


func _trigger_phase_2() -> void:
	_phase_2_triggered = true
	_current_phase = 2
	move_speed *= phase_2_speed_mult
	attack_cooldown *= phase_2_cooldown_mult
	# Shift body tint to intense crimson to signal the phase transition.
	if _body != null:
		var rage_tint := Color(1.8, 0.2, 0.2, 1.0)
		_body.modulate = rage_tint
		_base_modulate = rage_tint
	phase_changed.emit(2)
	AudioManager.play_sfx("enemy_alert", global_position)
