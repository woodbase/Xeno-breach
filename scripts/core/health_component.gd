## HealthComponent — reusable composition-based health and damage handling.
##
## Attach as a child node to any entity that can receive damage.
## Connect to [signal damaged], [signal died], or [signal health_changed] to react to health events.
class_name HealthComponent
extends Node

## Emitted when damage is successfully applied. Carries the damage amount.
signal damaged(amount: float)

## Emitted when current_health reaches zero.
signal died

## Emitted whenever current_health changes, useful for HUD binding.
signal health_changed(current: float, maximum: float)
signal invulnerability_changed(active: bool)

@export var max_health: float = 100.0
@export var invulnerability_duration: float = 0.0

var current_health: float
var _invulnerability_timer: float = 0.0


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	set_process(invulnerability_duration > 0.0)


func _process(delta: float) -> void:
	if _invulnerability_timer <= 0.0:
		return
	_invulnerability_timer = maxf(0.0, _invulnerability_timer - delta)
	if _invulnerability_timer == 0.0:
		invulnerability_changed.emit(false)


## Apply [param amount] damage. Negative values are ignored.
func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	if _invulnerability_timer > 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	damaged.emit(amount)
	health_changed.emit(current_health, max_health)
	if invulnerability_duration > 0.0 and current_health > 0.0:
		_invulnerability_timer = invulnerability_duration
		invulnerability_changed.emit(true)
	if current_health <= 0.0:
		died.emit()


## Restore [param amount] health, clamped to max_health.
func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return current_health > 0.0


func get_health_percent() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health


func is_invulnerable() -> bool:
	return _invulnerability_timer > 0.0
