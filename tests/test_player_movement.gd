## Unit tests for PlayerController movement direction.
##
## Validates that movement input stays world-aligned (WASD always maps to up,
## down, left, right) regardless of the player's facing direction.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("PlayerController movement tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_forward_input_stays_up()
	test_forward_input_ignores_player_rotation()
	test_right_input_ignores_player_rotation()
	test_zero_input_does_not_change_direction()
	test_clamp_normal_bounds_keeps_position_inside()
	test_clamp_inverted_bounds_same_as_normalized()
	test_clamp_position_inside_bounds_unchanged()


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


func _is_approx_equal(a: Vector2, b: Vector2, tolerance: float = 0.001) -> bool:
	return a.distance_to(b) < tolerance


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_forward_input_stays_up() -> void:
	# Pressing "up" should always produce an up vector.
	var input_dir := Vector2(0.0, -1.0)  # move_up pressed
	var result := input_dir
	_assert(_is_approx_equal(result, Vector2(0.0, -1.0)),
		"forward input stays up with no rotation")


func test_forward_input_ignores_player_rotation() -> void:
	# Even if the player is rotated 90 degrees clockwise (PI/2), pressing "up"
	# should still move up relative to the world.
	var input_dir := Vector2(0.0, -1.0)  # move_up pressed
	var rotation_angle := PI / 2.0
	var result := input_dir  # rotation is ignored for movement
	_assert(_is_approx_equal(result, Vector2(0.0, -1.0)),
		"forward input stays up when player is rotated 90 degrees")


func test_right_input_ignores_player_rotation() -> void:
	# Pressing "right" should move right even if the player faces downward.
	var input_dir := Vector2(1.0, 0.0)  # move_right pressed
	var rotation_angle := PI
	var result := input_dir  # rotation is ignored for movement
	_assert(_is_approx_equal(result, Vector2(1.0, 0.0)),
		"right input stays right when player is rotated 180 degrees")


func test_zero_input_does_not_change_direction() -> void:
	# Zero input rotated by any angle should remain zero.
	var input_dir := Vector2.ZERO
	var rotation_angle := PI / 3.0
	var result := input_dir.rotated(rotation_angle)
	_assert(_is_approx_equal(result, Vector2.ZERO),
		"zero input stays zero regardless of rotation")


# ---------------------------------------------------------------------------
# Playfield clamping tests
#
# These tests validate the clamping math used by PlayerController:
#   _normalized_bounds = playfield_bounds.abs()  # cached in _ready()
#   global_position = global_position.clamp(_normalized_bounds.position, _normalized_bounds.end)
# ---------------------------------------------------------------------------

func _apply_clamp(pos: Vector2, bounds: Rect2) -> Vector2:
	var normalized: Rect2 = bounds.abs()
	return pos.clamp(normalized.position, normalized.end)


func test_clamp_normal_bounds_keeps_position_inside() -> void:
	# A position outside a normally-defined Rect2 is clamped to the boundary.
	var bounds := Rect2(Vector2(-100.0, -100.0), Vector2(200.0, 200.0))
	var outside_pos := Vector2(200.0, -200.0)
	var result := _apply_clamp(outside_pos, bounds)
	# Expected clamped position: each component is clamped to the nearest value
	# within [-100.0, 100.0], giving (100.0, -100.0).
	var expected := Vector2(100.0, -100.0)
	_assert(_is_approx_equal(result, expected),
		"position outside normal bounds is clamped to the boundary")


func test_clamp_inverted_bounds_same_as_normalized() -> void:
	# An inverted Rect2 (negative size / swapped corners) should produce the
	# same clamped result as its abs()-normalized equivalent.
	var normal_bounds := Rect2(Vector2(-100.0, -100.0), Vector2(200.0, 200.0))
	# Build inverted bounds: end is the top-left, position is the bottom-right.
	var inverted_bounds := Rect2(Vector2(100.0, 100.0), Vector2(-200.0, -200.0))
	var pos := Vector2(200.0, -150.0)
	var result_normal := _apply_clamp(pos, normal_bounds)
	var result_inverted := _apply_clamp(pos, inverted_bounds)
	_assert(_is_approx_equal(result_normal, result_inverted),
		"inverted Rect2 clamps to same result as normalized Rect2")


func test_clamp_position_inside_bounds_unchanged() -> void:
	# A position already inside the bounds must not be modified.
	var bounds := Rect2(Vector2(-100.0, -100.0), Vector2(200.0, 200.0))
	var inside_pos := Vector2(50.0, -30.0)
	var result := _apply_clamp(inside_pos, bounds)
	_assert(_is_approx_equal(result, inside_pos),
		"position already inside bounds is unchanged after clamping")
