## Unit tests for FPSPlayerController.
##
## Validates movement speed selection, camera pitch clamping,
## and the health / damage delegation contract.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("FPSPlayerController tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_walk_speed_default()
	test_sprint_speed_greater_than_walk()
	test_pitch_clamped_to_min()
	test_pitch_clamped_to_max()
	test_pitch_within_range_unchanged()
	test_take_damage_reduces_health()
	test_take_damage_below_zero_clamps_at_zero()
	test_died_signal_emitted_on_lethal_damage()
	test_damaged_signal_emitted_on_hit()
	test_health_component_is_alive_after_partial_damage()


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


## Build a minimal FPSPlayerController with a HealthComponent child.
func _make_player() -> FPSPlayerController:
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 100.0

	# Camera3D is required by @onready in the controller.
	var cam := Camera3D.new()
	cam.name = "Camera3D"

	var player := FPSPlayerController.new()
	player.add_child(hc)
	player.add_child(cam)
	add_child(player)
	return player


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_walk_speed_default() -> void:
	var player := _make_player()
	_assert(is_equal_approx(player.walk_speed, 5.0),
		"walk_speed defaults to 5.0 m/s")
	player.queue_free()


func test_sprint_speed_greater_than_walk() -> void:
	var player := _make_player()
	_assert(player.sprint_speed > player.walk_speed,
		"sprint_speed is greater than walk_speed")
	player.queue_free()


func test_pitch_clamped_to_min() -> void:
	var player := _make_player()
	# Create a large downward mouse movement that would exceed pitch_min.
	var event := InputEventMouseMotion.new()
	# A large positive y delta rotates the camera downward (negative pitch).
	# With sensitivity 0.002, a 1000-pixel delta gives -2.0 rad, below -1.5 limit.
	event.relative = Vector2(0.0, 1000.0)
	player._handle_mouse_look(event)
	_assert(player.camera.rotation.x >= player.pitch_min,
		"downward mouse look is clamped to pitch_min")
	player.queue_free()


func test_pitch_clamped_to_max() -> void:
	var player := _make_player()
	var event := InputEventMouseMotion.new()
	# A large negative y delta rotates the camera upward (positive pitch).
	event.relative = Vector2(0.0, -1000.0)
	player._handle_mouse_look(event)
	_assert(player.camera.rotation.x <= player.pitch_max,
		"upward mouse look is clamped to pitch_max")
	player.queue_free()


func test_pitch_within_range_unchanged() -> void:
	var player := _make_player()
	# A small movement should not hit the clamp limit.
	var event := InputEventMouseMotion.new()
	event.relative = Vector2(0.0, 100.0)  # -0.2 rad, within [-1.5, 1.5]
	player._handle_mouse_look(event)
	var expected: float = -100.0 * player.mouse_sensitivity
	_assert(absf(player.camera.rotation.x - expected) < 0.001,
		"small downward mouse look sets camera pitch without clamping")
	player.queue_free()


func test_take_damage_reduces_health() -> void:
	var player := _make_player()
	player.take_damage(30.0)
	_assert(is_equal_approx(player.health_component.current_health, 70.0),
		"take_damage(30) reduces health from 100 to 70")
	player.queue_free()


func test_take_damage_below_zero_clamps_at_zero() -> void:
	var player := _make_player()
	player.take_damage(200.0)
	_assert(is_equal_approx(player.health_component.current_health, 0.0),
		"lethal damage clamps health to 0")
	player.queue_free()


func test_died_signal_emitted_on_lethal_damage() -> void:
	var player := _make_player()
	var died_received := false
	player.died.connect(func() -> void: died_received = true)
	player.take_damage(100.0)
	_assert(died_received, "died signal is emitted when health reaches 0")
	player.queue_free()


func test_damaged_signal_emitted_on_hit() -> void:
	var player := _make_player()
	var last_amount := 0.0
	player.damaged.connect(func(amount: float) -> void: last_amount = amount)
	player.take_damage(25.0)
	_assert(is_equal_approx(last_amount, 25.0),
		"damaged signal carries the correct damage amount")
	player.queue_free()


func test_health_component_is_alive_after_partial_damage() -> void:
	var player := _make_player()
	player.take_damage(50.0)
	_assert(player.health_component.is_alive(),
		"player is still alive after 50 damage from 100 max health")
	player.queue_free()
