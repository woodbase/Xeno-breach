## Builds a simple placeholder tilemap in code so art can be swapped in later.
class_name PlaceholderTilemap
extends TileMap

@export var source_texture: Texture2D
@export_range(16, 128, 1) var tile_size_px: int = 64
@export_range(8, 120, 1) var map_width_tiles: int = 40
@export_range(8, 120, 1) var map_height_tiles: int = 24


func _ready() -> void:
	if tile_set == null:
		tile_set = _create_tileset()
	_build_floor()


func _create_tileset() -> TileSet:
	if source_texture == null:
		push_warning("PlaceholderTilemap: source_texture is not set. Assign a texture in the Inspector to make the tilemap visible.")
		return TileSet.new()
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
	var start_x: int = -map_width_tiles / 2
	var end_x: int = start_x + map_width_tiles
	var start_y: int = -map_height_tiles / 2
	var end_y: int = start_y + map_height_tiles
	for x: int in range(start_x, end_x):
		for y: int in range(start_y, end_y):
			set_cell(0, Vector2i(x, y), 0, Vector2i.ZERO)
