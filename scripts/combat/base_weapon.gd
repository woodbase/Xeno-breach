## BaseWeapon — fires [Projectile] instances from a muzzle position.
##
## Assign [member projectile_scene] in the inspector to a [Projectile]-based PackedScene.
## Call [method fire] with a normalised direction vector to spawn a projectile.
##
## A child node named "MuzzleFlash" (any CanvasItem) is shown briefly on each shot
## and hidden automatically, providing lightweight muzzle-flash visual feedback.
class_name BaseWeapon
extends Node2D

const AudioLibrary = preload("res://scripts/systems/audio_library.gd")

@export var fire_rate: float = 0.2
@export var damage: float = 10.0
@export var projectile_scene: PackedScene
@export var muzzle_offset: Vector2 = Vector2(32.0, 0.0)

## Duration in seconds that the muzzle flash remains visible.
const MUZZLE_FLASH_DURATION: float = 0.075

var _muzzle_flash: CanvasItem = null
var _flash_timer: float = 0.0
var _fire_audio: AudioStreamPlayer2D = null


func _ready() -> void:
	_muzzle_flash = get_node_or_null("MuzzleFlash") as CanvasItem
	if _muzzle_flash != null:
		_muzzle_flash.visible = false
	_ensure_fire_audio()


func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and _muzzle_flash != null:
			_muzzle_flash.visible = false


## Fire a projectile in [param direction]. Direction should be normalised.
func fire(direction: Vector2) -> void:
	if projectile_scene == null:
		push_warning("BaseWeapon: projectile_scene is not assigned.")
		return

	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_warning("BaseWeapon: projectile_scene root is not a Projectile node.")
		return

	projectile.global_position = global_position + muzzle_offset.rotated(global_rotation)
	projectile.direction = direction
	projectile.damage = damage
	projectile.source_body = get_parent() as Node2D

	var level: Node = get_tree().current_scene
	if level != null:
		level.add_child(projectile)

	_show_muzzle_flash()
	_play_fire_audio()


func _show_muzzle_flash() -> void:
	if _muzzle_flash == null:
		return
	_muzzle_flash.visible = true
	_flash_timer = MUZZLE_FLASH_DURATION


func _ensure_fire_audio() -> void:
	if _fire_audio != null:
		return
	_fire_audio = AudioStreamPlayer2D.new()
	_fire_audio.name = "FireAudio"
	_fire_audio.stream = AudioLibrary.get_blaster_shot()
	_fire_audio.volume_db = -4.0
	_fire_audio.bus = AudioManager.BUS_SFX
	_fire_audio.max_distance = 1000.0
	add_child(_fire_audio)


func _play_fire_audio() -> void:
	if _fire_audio == null:
		return
	_fire_audio.stop()
	if _fire_audio.stream == null:
		_fire_audio.stream = AudioLibrary.get_blaster_shot()
	_fire_audio.play()
