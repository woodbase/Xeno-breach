## ImpactEffect — brief visual flash shown at projectile collision point.
##
## Tweens modulate alpha from 1 to 0 over [member duration] seconds, then frees itself.
## Pre-instantiate and add to the level; it is self-cleaning and does not leak nodes.
class_name ImpactEffect
extends Node2D

@export var duration: float = 0.1


func _ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)
