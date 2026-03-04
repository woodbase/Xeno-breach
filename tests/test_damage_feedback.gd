## Unit tests for player damage feedback overlay behavior.
##
## Verifies that the DamageOverlay is set immediately when damage lands,
## that it is not triggered during invulnerability frames, and that rapid
## successive hits overwrite the pending timer (non-stacking).
##
## Run standalone: create a scene with a Node root, attach this script.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("Damage Feedback tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_overlay_alpha_set_immediately_on_health_damage()
	test_overlay_not_set_when_damage_blocked_by_invulnerability()
	test_rapid_damage_overwrites_timer_reference()


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


## Build a minimal PlayerController with a HealthComponent child and a
## DamageOverlay ColorRect in the scene.  Returns [player, overlay].
func _make_player_with_overlay() -> Array:
	var overlay := ColorRect.new()
	overlay.name = "DamageOverlay"
	overlay.color = Color(1.0, 0.0, 0.0, 0.0)
	add_child(overlay)

	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 100.0

	var player := PlayerController.new()
	# weapon_path must be empty so _ready() does not error on missing child
	player.weapon_path = NodePath("")
	player.add_child(hc)
	add_child(player)

	return [player, overlay]


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_overlay_alpha_set_immediately_on_health_damage() -> void:
	var result := _make_player_with_overlay()
	var player: PlayerController = result[0]
	var overlay: ColorRect = result[1]

	# Damage applied directly to the HealthComponent (the path used by enemy
	# projectiles and melee attacks — bypassing PlayerController.take_damage).
	player.health_component.take_damage(20.0)

	_assert(is_equal_approx(overlay.color.a, 0.5),
		"overlay alpha is 0.5 immediately after HealthComponent receives damage")

	player.queue_free()
	overlay.queue_free()


func test_overlay_not_set_when_damage_blocked_by_invulnerability() -> void:
	var result := _make_player_with_overlay()
	var player: PlayerController = result[0]
	var overlay: ColorRect = result[1]

	# Enable invulnerability frames (i-frames) so the second hit is absorbed without the damaged signal.
	player.health_component.invulnerability_duration = 0.5
	player.health_component.take_damage(10.0)   # first hit — overlay activates
	overlay.color = Color(1.0, 0.0, 0.0, 0.0)   # manually reset to test next hit
	player.health_component.take_damage(10.0)   # blocked — damaged signal not emitted

	_assert(is_equal_approx(overlay.color.a, 0.0),
		"overlay alpha stays 0 when damage is blocked by invulnerability frames")

	player.queue_free()
	overlay.queue_free()


func test_rapid_damage_overwrites_timer_reference() -> void:
	var result := _make_player_with_overlay()
	var player: PlayerController = result[0]
	var overlay: ColorRect = result[1]

	# Two hits in quick succession — each creates a new timer.
	player.health_component.take_damage(10.0)
	var first_timer: SceneTreeTimer = player._damage_feedback_timer

	player.health_component.take_damage(10.0)
	var second_timer: SceneTreeTimer = player._damage_feedback_timer

	_assert(first_timer != second_timer,
		"second hit stores a new timer, overwriting the first")
	_assert(is_equal_approx(overlay.color.a, 0.5),
		"overlay alpha is still 0.5 after rapid second hit")

	player.queue_free()
	overlay.queue_free()
