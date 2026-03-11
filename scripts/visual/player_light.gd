## PlayerLight — soft PointLight2D attached to the player for local illumination.
##
## Add a node with this script as a child of the [Player] CharacterBody2D.
## It automatically builds a procedural radial gradient texture so no external
## asset is needed.  The light follows the player because it is parented to it.
class_name PlayerLight
extends PointLight2D


func _ready() -> void:
	texture = _make_radial_texture()
	texture_scale = 3.2
	color = Color(0.65, 0.75, 1.0, 1.0)
	energy = 1.1


# ── Texture factory ───────────────────────────────────────────────────────────

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
