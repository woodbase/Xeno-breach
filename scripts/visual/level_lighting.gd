## LevelLighting — procedural 2D lighting rig for level scenes.
##
## Add a [LevelLighting] node anywhere in a level scene (recommended: at the
## root level, after environmental geometry).  On [method _ready] it will:
##
##   1. Insert a [CanvasModulate] sibling to darken the world canvas, creating
##      an atmospheric sci-fi facility feel.
##   2. Spawn coloured [PointLight2D] nodes for each configured position:
##      - Emergency lights (red) near wall light-strips.
##      - Terminal glows (cyan) near research terminals.
##      - A single soft ambient fill for the centre of the arena.
##
## All textures are generated procedurally from a [GradientTexture2D] so no
## external texture assets are required.
class_name LevelLighting
extends Node2D

@export var biome_profile: BiomeProfile:
	set(value):
		_biome_profile = value
		if is_inside_tree():
			_apply_biome_profile()
	get:
		return _biome_profile

## Global dark tint applied to the world canvas via [CanvasModulate].
## Reducing alpha makes the effect lighter; values near zero produce a
## near-black scene that relies entirely on local lights.
@export var ambient_color: Color = Color(0.32, 0.32, 0.42, 1.0)

## World-space positions where red emergency PointLight2D nodes are placed.
@export var emergency_light_positions: Array[Vector2] = []

## World-space positions where cyan terminal PointLight2D nodes are placed.
@export var terminal_light_positions: Array[Vector2] = []

## Optional world-space position for a single dim ambient fill light.
## Leave at (0,0) if [member ambient_fill_enabled] is false.
@export var ambient_fill_enabled: bool = true
@export var ambient_fill_position: Vector2 = Vector2.ZERO
@export var ambient_fill_color: Color = Color(0.45, 0.45, 0.65, 1.0)

@export var emergency_light_color: Color = Color(1.0, 0.18, 0.1, 1.0)
@export var terminal_light_color: Color = Color(0.1, 0.85, 0.95, 1.0)

var _biome_profile: BiomeProfile = null


func _ready() -> void:
	_apply_biome_profile()
	_add_canvas_modulate()
	var tex: GradientTexture2D = _make_radial_texture()
	_spawn_emergency_lights(tex)
	_spawn_terminal_lights(tex)
	if ambient_fill_enabled:
		_spawn_ambient_fill(tex)


# ── Canvas modulate ───────────────────────────────────────────────────────────

func _add_canvas_modulate() -> void:
	var mod := CanvasModulate.new()
	mod.name = "WorldLight"
	mod.color = ambient_color
	add_child(mod)


# ── Light spawning ────────────────────────────────────────────────────────────

func _spawn_emergency_lights(tex: GradientTexture2D) -> void:
	for pos: Vector2 in emergency_light_positions:
		var light := PointLight2D.new()
		light.texture = tex
		light.texture_scale = 1.6
		light.color = emergency_light_color
		light.energy = 1.3
		light.position = pos
		add_child(light)


func _spawn_terminal_lights(tex: GradientTexture2D) -> void:
	for pos: Vector2 in terminal_light_positions:
		var light := PointLight2D.new()
		light.texture = tex
		light.texture_scale = 0.9
		light.color = terminal_light_color
		light.energy = 0.9
		light.position = pos
		add_child(light)


func _spawn_ambient_fill(tex: GradientTexture2D) -> void:
	var light := PointLight2D.new()
	light.texture = tex
	light.texture_scale = 10.0
	light.color = ambient_fill_color
	light.energy = 0.4
	light.position = ambient_fill_position
	add_child(light)


# ── Texture factory ───────────────────────────────────────────────────────────

## Creates a soft radial gradient texture suitable for use with [PointLight2D].
## The texture fades from opaque white at the centre to transparent black at
## the edge, which produces a smooth falloff in ADD blend mode.
func _make_radial_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0, 0, 0, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	return tex


func _apply_biome_profile() -> void:
	if _biome_profile == null:
		return
	ambient_color = _biome_profile.ambient_color
	emergency_light_color = _biome_profile.emergency_light_color
	terminal_light_color = _biome_profile.terminal_light_color
	ambient_fill_color = _biome_profile.ambient_fill_color
