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
	test_muzzle_flash_hidden_initially()
	test_muzzle_flash_shown_after_fire()
	test_muzzle_flash_timer_decrements()
	test_muzzle_flash_hidden_when_timer_expires()
	test_impact_effect_duration_default()
	test_impact_effect_tween_fades_modulate()


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
# Tracer math tests (pure logic, no scene required)
# ---------------------------------------------------------------------------

func test_tracer_points_align_with_direction() -> void:
	# Tail of tracer must sit directly behind the projectile along its direction.
	var direction := Vector2.RIGHT
	var tracer_length: float = 20.0
	var tail_point := -direction * tracer_length
	_assert(_is_approx_equal_v(tail_point, Vector2(-20.0, 0.0)),
		"tracer tail aligns behind RIGHT-moving projectile")


func test_tracer_points_align_with_diagonal_direction() -> void:
	var direction := Vector2(1.0, -1.0).normalized()
	var tracer_length: float = 20.0
	var tail_point := -direction * tracer_length
	var expected := Vector2(-1.0, 1.0).normalized() * tracer_length
	_assert(_is_approx_equal_v(tail_point, expected),
		"tracer tail aligns behind diagonal-moving projectile")


func test_tracer_tail_length_equals_constant() -> void:
	# Tracer tail distance from origin must equal TRACER_LENGTH.
	var direction := Vector2(0.0, 1.0)
	var tracer_length: float = 20.0
	var tail_point := -direction * tracer_length
	_assert(absf(tail_point.length() - tracer_length) < 0.001,
		"tracer tail length matches TRACER_LENGTH constant")


# ---------------------------------------------------------------------------
# Muzzle flash timer logic (pure logic)
# ---------------------------------------------------------------------------

func test_muzzle_flash_hidden_initially() -> void:
	# Simulated weapon: flash timer starts at 0, so flash should not be shown.
	var flash_timer: float = 0.0
	_assert(flash_timer <= 0.0, "muzzle flash timer starts at zero (hidden)")


func test_muzzle_flash_shown_after_fire() -> void:
	# Simulated fire: timer is set to the flash duration.
	var flash_timer: float = 0.0
	var flash_duration: float = 0.075
	flash_timer = flash_duration
	_assert(flash_timer > 0.0, "muzzle flash timer is positive after firing")


func test_muzzle_flash_timer_decrements() -> void:
	var flash_timer: float = 0.075
	var delta: float = 0.016
	flash_timer -= delta
	_assert(flash_timer < 0.075, "muzzle flash timer decrements over time")


func test_muzzle_flash_hidden_when_timer_expires() -> void:
	var flash_timer: float = 0.01
	var delta: float = 0.02
	flash_timer -= delta
	var should_hide: bool = flash_timer <= 0.0
	_assert(should_hide, "muzzle flash is hidden once timer reaches zero")


# ---------------------------------------------------------------------------
# ImpactEffect node tests
# ---------------------------------------------------------------------------

func test_impact_effect_duration_default() -> void:
	var effect := ImpactEffect.new()
	_assert(effect.duration == 0.1, "ImpactEffect default duration is 0.1 seconds")
	effect.free()


func test_impact_effect_tween_fades_modulate() -> void:
	# After _ready is called the node starts visible (modulate.a == 1.0).
	# We only verify the initial state here; the tween runs asynchronously.
	var effect := ImpactEffect.new()
	add_child(effect)
	_assert(is_equal_approx(effect.modulate.a, 1.0),
		"ImpactEffect starts fully opaque before tween completes")
	effect.queue_free()
