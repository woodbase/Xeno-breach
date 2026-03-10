## AudioLibrary — lightweight procedural audio streams for core cues.
##
## All streams are synthesized from scratch (no audio files required) and cached
## after first access.  Use [method get_stream] for a name-based lookup that maps
## AudioManager sound keys to the correct generator.
class_name AudioLibrary

const SAMPLE_RATE: int = 44100

static var _blaster_shot: AudioStreamWAV
static var _ambient_loop: AudioStreamWAV
static var _impact_body: AudioStreamWAV
static var _impact_wall: AudioStreamWAV
static var _enemy_death: AudioStreamWAV
static var _player_hurt: AudioStreamWAV
static var _enemy_alert: AudioStreamWAV
static var _enemy_attack: AudioStreamWAV
static var _ui_select: AudioStreamWAV
static var _ui_confirm: AudioStreamWAV
static var _wave_start: AudioStreamWAV
static var _game_over: AudioStreamWAV


## Return a cached procedural stream by AudioManager sound key, or null when
## no procedural fallback is defined for that key.
static func get_stream(sound_name: String) -> AudioStreamWAV:
	match sound_name:
		"weapon_fire":
			return get_blaster_shot()
		"station_ambience":
			return get_ambient_loop()
		"impact_body":
			return get_impact_body()
		"impact_wall":
			return get_impact_wall()
		"enemy_death":
			return get_enemy_death()
		"player_hurt":
			return get_player_hurt()
		"enemy_alert":
			return get_enemy_alert()
		"enemy_attack":
			return get_enemy_attack()
		"button_select":
			return get_ui_select()
		"button_confirm":
			return get_ui_confirm()
		"wave_start":
			return get_wave_start()
		"game_over":
			return get_game_over()
	return null


static func get_blaster_shot() -> AudioStreamWAV:
	if _blaster_shot == null:
		_blaster_shot = _make_blaster_shot()
	return _blaster_shot


static func get_ambient_loop() -> AudioStreamWAV:
	if _ambient_loop == null:
		_ambient_loop = _make_ambient_loop()
	return _ambient_loop


static func get_impact_body() -> AudioStreamWAV:
	if _impact_body == null:
		_impact_body = _make_impact_body()
	return _impact_body


static func get_impact_wall() -> AudioStreamWAV:
	if _impact_wall == null:
		_impact_wall = _make_impact_wall()
	return _impact_wall


static func get_enemy_death() -> AudioStreamWAV:
	if _enemy_death == null:
		_enemy_death = _make_enemy_death()
	return _enemy_death


static func get_player_hurt() -> AudioStreamWAV:
	if _player_hurt == null:
		_player_hurt = _make_player_hurt()
	return _player_hurt


static func get_enemy_alert() -> AudioStreamWAV:
	if _enemy_alert == null:
		_enemy_alert = _make_enemy_alert()
	return _enemy_alert


static func get_enemy_attack() -> AudioStreamWAV:
	if _enemy_attack == null:
		_enemy_attack = _make_enemy_attack()
	return _enemy_attack


static func get_ui_select() -> AudioStreamWAV:
	if _ui_select == null:
		_ui_select = _make_ui_select()
	return _ui_select


static func get_ui_confirm() -> AudioStreamWAV:
	if _ui_confirm == null:
		_ui_confirm = _make_ui_confirm()
	return _ui_confirm


static func get_wave_start() -> AudioStreamWAV:
	if _wave_start == null:
		_wave_start = _make_wave_start()
	return _wave_start


static func get_game_over() -> AudioStreamWAV:
	if _game_over == null:
		_game_over = _make_game_over()
	return _game_over


static func _make_blaster_shot() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.12
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var envelope: float = clampf(1.0 - t / duration, 0.0, 1.0)
		var sample: float = (
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
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	var duration: float = 6.0
	var fade: float = 0.25
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var env_lead: float = minf(1.0, t / fade)
		var env_tail: float = minf(1.0, (duration - t) / fade)
		var envelope: float = maxf(0.0, minf(env_lead, env_tail))

		var low: float = sin(TAU * 42.0 * t) * 0.18
		var mid: float = sin(TAU * 73.0 * t) * 0.12
		var slow_pulse: float = sin(TAU * 0.22 * t) * 0.06
		var hiss_seed: float = float((i * 37) % 500) / 500.0
		var hiss: float = (hiss_seed * 2.0 - 1.0) * 0.02

		var sample: float = (low + mid + slow_pulse + hiss) * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Low-frequency thud — organic hit against a soft target (enemy body).
static func _make_impact_body() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.15
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = t / duration
		var envelope: float = (1.0 - progress) * (1.0 - progress)
		# Pitch sweeps down from 200 → 80 Hz for an organic "thud"
		var freq: float = lerpf(200.0, 80.0, progress)
		var noise_seed: float = float((i * 7919) % 1000) / 1000.0
		var noise: float = (noise_seed * 2.0 - 1.0) * 0.35
		var tone: float = sin(TAU * freq * t) * 0.65
		var sample: float = (tone + noise) * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Metallic ping — hard projectile hitting a wall or metal surface.
static func _make_impact_wall() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.22
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var envelope: float = clampf(1.0 - t / duration, 0.0, 1.0)
		var sample: float = (
			sin(TAU * 780.0 * t) * 0.5 +
			sin(TAU * 1560.0 * t) * 0.25 +
			sin(TAU * 390.0 * t) * 0.25
		) * envelope * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Descending frequency sweep — enemy expiring.
static func _make_enemy_death() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.35
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = t / duration
		var envelope: float = (1.0 - progress) * (1.0 - progress)
		var freq: float = lerpf(480.0, 60.0, progress)
		var noise_seed: float = float((i * 6271) % 1000) / 1000.0
		var noise: float = (noise_seed * 2.0 - 1.0) * 0.25
		var tone: float = sin(TAU * freq * t) * 0.75
		var sample: float = (tone + noise) * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Sharp high-frequency sting — player receives damage.
static func _make_player_hurt() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.1
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var envelope: float = clampf(1.0 - t / duration, 0.0, 1.0)
		var noise_seed: float = float((i * 9001) % 1000) / 1000.0
		var noise: float = (noise_seed * 2.0 - 1.0) * 0.5
		var tone: float = sin(TAU * 1400.0 * t) * 0.5
		var sample: float = (tone + noise) * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Two-tone ascending alert — enemy spots the player.
static func _make_enemy_alert() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.30
	var half: float = duration * 0.5
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 330.0 if t < half else 660.0
		var note_t: float = fmod(t, half)
		var envelope: float = clampf(1.0 - note_t / half, 0.0, 1.0)
		var sample: float = sin(TAU * freq * t) * 0.8 * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Buzzing pulse — enemy fires or strikes.
static func _make_enemy_attack() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.18
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var envelope: float = clampf(1.0 - t / duration, 0.0, 1.0)
		var sample: float = (
			sin(TAU * 220.0 * t) * 0.5 +
			sin(TAU * 440.0 * t) * 0.3 +
			sin(TAU * 660.0 * t) * 0.2
		) * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Brief high-frequency tick — UI hover or focus.
static func _make_ui_select() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.05
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var envelope: float = clampf(1.0 - t / duration, 0.0, 1.0)
		var sample: float = sin(TAU * 1800.0 * t) * 0.7 * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Ascending two-note chime — UI confirm or button press.
static func _make_ui_confirm() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.25
	var half: float = duration * 0.5
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = 523.0 if t < half else 784.0
		var note_t: float = fmod(t, half)
		var envelope: float = clampf(1.0 - note_t / half, 0.0, 1.0)
		var sample: float = sin(TAU * freq * t) * 0.75 * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Amplitude-modulated alarm tone — wave commencing.
static func _make_wave_start() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var duration: float = 0.55
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var global_env: float = clampf(1.0 - t / duration, 0.0, 1.0)
		# Siren effect: carrier at 440 Hz with 8 Hz LFO on amplitude
		var lfo: float = sin(TAU * 8.0 * t) * 0.5 + 0.5
		var sample: float = sin(TAU * 440.0 * t) * lfo * global_env
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream


## Three descending notes — game over or player death.
static func _make_game_over() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var note_dur: float = 0.2
	var duration: float = note_dur * 3.0
	var samples: int = int(duration * SAMPLE_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	var freqs: PackedFloat32Array = PackedFloat32Array([294.0, 220.0, 147.0])

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var note_idx: int = int(t / note_dur)
		if note_idx >= freqs.size():
			note_idx = freqs.size() - 1
		var note_t: float = fmod(t, note_dur)
		var envelope: float = clampf(1.0 - note_t / note_dur, 0.0, 1.0)
		var sample: float = sin(TAU * freqs[note_idx] * t) * 0.8 * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	stream.data = data
	return stream
