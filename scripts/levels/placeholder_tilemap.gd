## Builds a simple placeholder tilemap in code so art can be swapped in later.
class_name PlaceholderTilemap
extends TileMap

@export var source_texture: Texture2D = preload("res://assets/environment/space_station.png")
@export_range(16, 128, 1) var tile_size_px: int = 64
@export_range(8, 120, 1) var map_width_tiles: int = 40
@export_range(8, 120, 1) var map_height_tiles: int = 24


func _ready() -> void:
	if tile_set == null:
		tile_set = _create_tileset()
	_build_floor()


func _create_tileset() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(tile_size_px, tile_size_px)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = source_texture
	atlas.texture_region_size = Vector2i(tile_size_px, tile_size_px)
	atlas.create_tile(Vector2i.ZERO)

	tiles.add_source(atlas, 0)
	return tiles


func _build_floor() -> void:
	clear_layer(0)
	var half_width: int = map_width_tiles / 2
	var half_height: int = map_height_tiles / 2
	for x: int in range(-half_width, half_width):
		for y: int in range(-half_height, half_height):
			set_cell(0, Vector2i(x, y), 0, Vector2i.ZERO)
