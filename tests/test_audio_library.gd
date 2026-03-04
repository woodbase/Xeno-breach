## Unit tests for AudioLibrary procedural streams.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("AudioLibrary tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_blaster_shot_properties()
	test_ambient_loop_properties()
	test_streams_are_cached()


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


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_blaster_shot_properties() -> void:
	var stream := AudioLibrary.get_blaster_shot()
	_assert(stream != null, "blaster shot stream is created")
	_assert(stream.data.size() > 0, "blaster shot has PCM data")
	_assert(stream.mix_rate == AudioLibrary.SAMPLE_RATE, "blaster shot mix_rate matches sample rate")
	_assert(stream.format == AudioStreamWAV.FORMAT_16_BITS, "blaster shot uses 16-bit format")
	_assert(not stream.stereo, "blaster shot is mono")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "blaster shot does not loop")


func test_ambient_loop_properties() -> void:
	var stream := AudioLibrary.get_ambient_loop()
	_assert(stream != null, "ambient loop stream is created")
	_assert(stream.data.size() > 0, "ambient loop has PCM data")
	_assert(stream.mix_rate == AudioLibrary.SAMPLE_RATE, "ambient loop mix_rate matches sample rate")
	_assert(stream.format == AudioStreamWAV.FORMAT_16_BITS, "ambient loop uses 16-bit format")
	_assert(not stream.stereo, "ambient loop is mono")
	_assert(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "ambient loop is set to loop")


func test_streams_are_cached() -> void:
	var shot_a := AudioLibrary.get_blaster_shot()
	var shot_b := AudioLibrary.get_blaster_shot()
	var ambient_a := AudioLibrary.get_ambient_loop()
	var ambient_b := AudioLibrary.get_ambient_loop()
	_assert(shot_a == shot_b, "blaster shot stream is cached")
	_assert(ambient_a == ambient_b, "ambient loop stream is cached")
