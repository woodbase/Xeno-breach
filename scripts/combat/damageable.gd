## Damageable — interface pattern for objects that can receive damage.
##
## The damage system uses duck-typing rather than hard class references:
##   1. Call [method take_damage] directly if the node exposes it, OR
##   2. Retrieve the [HealthComponent] child with [code]get_node_or_null("HealthComponent")[/code].
##
## Recommended pattern: add a [HealthComponent] child to any damageable entity and
## apply damage through [code]HealthComponent.take_damage(amount)[/code].
## This keeps damage logic centrally managed and easily extensible for status effects,
## difficulty scaling, or damage modifiers.
##
## Extending this class is optional; it documents the expected contract.
class_name Damageable
extends Node

## Apply [param amount] damage to this object. Override in subclasses.
func take_damage(amount: float) -> void:
	pass
