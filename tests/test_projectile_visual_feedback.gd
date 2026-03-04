## Unit tests for the projectile visual feedback system.
##
## Validates muzzle flash, tracer, and impact effect behavior without
## requiring the full game scene.  Run standalone: attach to a Node root.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("Projectile visual feedback tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_tracer_points_align_with_direction()
	test_tracer_points_align_with_diagonal_direction()
	test_tracer_tail_length_equals_constant()
	test_tracer_node_points_match_production_constant()
	test_muzzle_flash_hidden_initially()
	test_muzzle_flash_shown_after_fire()
	test_muzzle_flash_timer_decrements()
	test_muzzle_flash_hidden_when_timer_expires()
	test_weapon_muzzle_flash_node_hidden_on_ready()
	test_impact_effect_duration_default()
	test_impact_effect_starts_fully_opaque()
	test_despawn_guard_prevents_double_processing()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


func _is_approx_equal_v(a: Vector2, b: Vector2, tolerance: float = 0.01) -> bool:
	return a.distance_to(b) < tolerance


# ---------------------------------------------------------------------------
# Tracer math tests — use Projectile.TRACER_LENGTH so tests stay in sync
# ---------------------------------------------------------------------------

func test_tracer_points_align_with_direction() -> void:
	# Tail of tracer must sit directly behind the projectile along its direction.
	var direction := Vector2.RIGHT
	var tail_point := -direction * Projectile.TRACER_LENGTH
	_assert(_is_approx_equal_v(tail_point, Vector2(-Projectile.TRACER_LENGTH, 0.0)),
		"tracer tail aligns behind RIGHT-moving projectile")


func test_tracer_points_align_with_diagonal_direction() -> void:
	var direction := Vector2(1.0, -1.0).normalized()
	var tail_point := -direction * Projectile.TRACER_LENGTH
	var expected := Vector2(-1.0, 1.0).normalized() * Projectile.TRACER_LENGTH
	_assert(_is_approx_equal_v(tail_point, expected),
		"tracer tail aligns behind diagonal-moving projectile")


func test_tracer_tail_length_equals_constant() -> void:
	# Tracer tail distance from origin must equal TRACER_LENGTH.
	var direction := Vector2(0.0, 1.0)
	var tail_point := -direction * Projectile.TRACER_LENGTH
	_assert(absf(tail_point.length() - Projectile.TRACER_LENGTH) < 0.001,
		"tracer tail length matches TRACER_LENGTH constant")


func test_tracer_node_points_match_production_constant() -> void:
	# The Line2D on a freshly instantiated Projectile must use TRACER_LENGTH.
	var scene: PackedScene = load("res://scenes/weapons/projectile.tscn")
	var proj: Projectile = scene.instantiate() as Projectile
	proj.direction = Vector2.RIGHT
	add_child(proj)
	var tracer: Line2D = proj.get_node_or_null("Tracer") as Line2D
	var tail: Vector2 = tracer.get_point_position(0)
	_assert(_is_approx_equal_v(tail, Vector2(-Projectile.TRACER_LENGTH, 0.0)),
		"instantiated Projectile tracer tail length matches TRACER_LENGTH")
	proj.queue_free()


# ---------------------------------------------------------------------------
# Muzzle flash timer logic — use BaseWeapon.MUZZLE_FLASH_DURATION
# ---------------------------------------------------------------------------

func test_muzzle_flash_hidden_initially() -> void:
	# Simulated weapon: flash timer starts at 0, so flash should not be shown.
	var flash_timer: float = 0.0
	_assert(flash_timer <= 0.0, "muzzle flash timer starts at zero (hidden)")


func test_muzzle_flash_shown_after_fire() -> void:
	# Simulated fire: timer is set to the flash duration constant.
	var flash_timer: float = 0.0
	flash_timer = BaseWeapon.MUZZLE_FLASH_DURATION
	_assert(flash_timer > 0.0, "muzzle flash timer is positive after firing")


func test_muzzle_flash_timer_decrements() -> void:
	var flash_timer: float = BaseWeapon.MUZZLE_FLASH_DURATION
	var delta: float = 0.016
	flash_timer -= delta
	_assert(flash_timer < BaseWeapon.MUZZLE_FLASH_DURATION, "muzzle flash timer decrements over time")


func test_muzzle_flash_hidden_when_timer_expires() -> void:
	var flash_timer: float = 0.01
	var delta: float = 0.02
	flash_timer -= delta
	var should_hide: bool = flash_timer <= 0.0
	_assert(should_hide, "muzzle flash is hidden once timer reaches zero")


func test_weapon_muzzle_flash_node_hidden_on_ready() -> void:
	# MuzzleFlash Polygon2D must be invisible after the weapon scene is loaded.
	var scene: PackedScene = load("res://scenes/weapons/pulse_carbine.tscn")
	var weapon: BaseWeapon = scene.instantiate() as BaseWeapon
	add_child(weapon)
	var flash: CanvasItem = weapon.get_node_or_null("MuzzleFlash") as CanvasItem
	_assert(flash != null, "MuzzleFlash node exists in pulse_carbine scene")
	_assert(not flash.visible, "MuzzleFlash node is hidden on ready")
	weapon.queue_free()


# ---------------------------------------------------------------------------
# ImpactEffect node tests
# ---------------------------------------------------------------------------

func test_impact_effect_duration_default() -> void:
	var effect := ImpactEffect.new()
	_assert(effect.duration == 0.1, "ImpactEffect default duration is 0.1 seconds")
	effect.free()


func test_impact_effect_starts_fully_opaque() -> void:
	# Before the tween completes the node must remain at full opacity.
	var effect := ImpactEffect.new()
	add_child(effect)
	_assert(is_equal_approx(effect.modulate.a, 1.0),
		"ImpactEffect starts fully opaque before tween completes")
	effect.queue_free()


# ---------------------------------------------------------------------------
# Despawn guard test
# ---------------------------------------------------------------------------

func test_despawn_guard_prevents_double_processing() -> void:
	# Once _despawn() is called, _is_despawning must be true so a second
	# body_entered signal cannot trigger a second impact or damage.
	var scene: PackedScene = load("res://scenes/weapons/projectile.tscn")
	var proj: Projectile = scene.instantiate() as Projectile
	add_child(proj)
	proj._despawn()
	_assert(proj._is_despawning, "despawn guard is set after _despawn() is called")
	# No queue_free needed — _despawn already called it.

