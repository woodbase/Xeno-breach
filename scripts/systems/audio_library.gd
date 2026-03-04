## AudioLibrary — lightweight procedural audio streams for core cues.
class_name AudioLibrary

const SAMPLE_RATE: int = 44100

static var _blaster_shot: AudioStreamWAV
static var _ambient_loop: AudioStreamWAV


static func get_blaster_shot() -> AudioStreamWAV:
	if _blaster_shot == null:
		_blaster_shot = _make_blaster_shot()
	return _blaster_shot


static func get_ambient_loop() -> AudioStreamWAV:
	if _ambient_loop == null:
		_ambient_loop = _make_ambient_loop()
	return _ambient_loop


static func _make_blaster_shot() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration := 0.12
	var samples: int = int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var envelope := clamp(1.0 - t / duration, 0.0, 1.0)
		var sample := (
			sin(TAU * 620.0 * t) * 0.6 +
			sin(TAU * 1240.0 * t) * 0.25 +
			sin(TAU * 180.0 * t) * 0.15
		) * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


static func _make_ambient_loop() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	var duration := 6.0
	var fade := 0.25
	var samples: int = int(duration * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / SAMPLE_RATE
		var env_lead := min(1.0, t / fade)
		var env_tail := min(1.0, (duration - t) / fade)
		var envelope := max(0.0, min(env_lead, env_tail))

		var low := sin(TAU * 42.0 * t) * 0.18
		var mid := sin(TAU * 73.0 * t) * 0.12
		var slow_pulse := sin(TAU * 0.22 * t) * 0.06
		var hiss_seed := float((i * 37) % 500) / 500.0
		var hiss := (hiss_seed * 2.0 - 1.0) * 0.02

		var sample := (low + mid + slow_pulse + hiss) * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream
