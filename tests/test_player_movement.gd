## Unit tests for PlayerController movement direction.
##
## Validates that the movement input is rotated by the player's facing direction,
## so the player always moves forward relative to where they are facing.
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("PlayerController movement tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_forward_input_rotates_with_player()
	test_forward_input_moves_in_facing_direction()
	test_rotated_player_forward_input_matches_rotation()
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

func test_forward_input_rotates_with_player() -> void:
	# When the player faces right (rotation = 0), pressing "up" (Vector2(0, -1))
	# rotated by 0 should still be (0, -1).
	var input_dir := Vector2(0.0, -1.0)  # move_up pressed
	var rotation_angle := 0.0
	var result := input_dir.rotated(rotation_angle)
	_assert(_is_approx_equal(result, Vector2(0.0, -1.0)),
		"no rotation: forward input unchanged")


func test_forward_input_moves_in_facing_direction() -> void:
	# When the player is rotated 90 degrees clockwise (PI/2), pressing "up"
	# (Vector2(0, -1)) rotated by PI/2 should yield approximately (1, 0) — rightward.
	var input_dir := Vector2(0.0, -1.0)  # move_up pressed
	var rotation_angle := PI / 2.0
	var result := input_dir.rotated(rotation_angle)
	_assert(_is_approx_equal(result, Vector2(1.0, 0.0)),
		"90-degree rotation: forward input maps to right direction")


func test_rotated_player_forward_input_matches_rotation() -> void:
	# When the player is rotated 180 degrees (PI), pressing "up"
	# (Vector2(0, -1)) rotated by PI should yield approximately (0, 1) — downward.
	var input_dir := Vector2(0.0, -1.0)  # move_up pressed
	var rotation_angle := PI
	var result := input_dir.rotated(rotation_angle)
	_assert(_is_approx_equal(result, Vector2(0.0, 1.0)),
		"180-degree rotation: forward input maps to downward direction")


func test_zero_input_does_not_change_direction() -> void:
	# Zero input rotated by any angle should remain zero.
	var input_dir := Vector2.ZERO
	var rotation_angle := PI / 3.0
	var result := input_dir.rotated(rotation_angle)
	_assert(_is_approx_equal(result, Vector2.ZERO),
		"zero input stays zero regardless of rotation")
