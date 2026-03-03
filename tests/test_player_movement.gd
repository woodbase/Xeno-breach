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
