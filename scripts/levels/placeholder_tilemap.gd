## Builds a simple placeholder tilemap in code so art can be swapped in later.
class_name PlaceholderTilemap
extends TileMap

@export var source_texture: Texture2D = null
@export_range(16, 128, 1) var tile_size_px: int = 64
@export_range(8, 120, 1) var map_width_tiles: int = 40
@export_range(8, 120, 1) var map_height_tiles: int = 24
@export var use_procedural_tile: bool = true
@export var floor_base_color: Color = Color(0.12, 0.13, 0.16, 1.0)
@export var floor_rim_color: Color = Color(0.22, 0.24, 0.28, 1.0)
@export var floor_detail_color: Color = Color(0.46, 0.52, 0.6, 0.85)


func _ready() -> void:
	if tile_set == null:
		tile_set = _create_tileset()
	if tile_set == null or tile_set.get_source_count() == 0:
		return
	_build_floor()


func _create_tileset() -> TileSet:
	var texture: Texture2D = source_texture
	if texture == null and use_procedural_tile:
		texture = _make_panel_texture()
	if texture == null:
		push_warning("PlaceholderTilemap: source_texture is not set. Assign a texture in the Inspector or enable procedural tiles to make the tilemap visible.")
		return TileSet.new()
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(tile_size_px, tile_size_px)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
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


func _make_panel_texture() -> Texture2D:
	var image := Image.create(tile_size_px, tile_size_px, false, Image.FORMAT_RGBA8)
	image.fill(floor_base_color)
	image.lock()

	for x: int in range(tile_size_px):
		image.set_pixel(x, 0, floor_rim_color)
		image.set_pixel(x, tile_size_px - 1, floor_rim_color)
	for y: int in range(tile_size_px):
		image.set_pixel(0, y, floor_rim_color)
		image.set_pixel(tile_size_px - 1, y, floor_rim_color)

	var inset: int = clampi(tile_size_px / 6, 2, tile_size_px / 2)
	for x: int in range(inset, tile_size_px - inset):
		image.set_pixel(x, inset, floor_detail_color)
		image.set_pixel(x, tile_size_px - inset - 1, floor_detail_color)
	for y: int in range(inset, tile_size_px - inset):
		image.set_pixel(inset, y, floor_detail_color)
		image.set_pixel(tile_size_px - inset - 1, y, floor_detail_color)

	var cross_step: int = max(4, tile_size_px / 4)
	for n: int in range(cross_step, tile_size_px - cross_step, cross_step):
		for x: int in range(1, tile_size_px - 1):
			image.set_pixel(x, n, floor_detail_color)
			image.set_pixel(n, x, floor_detail_color)

	image.unlock()
	return ImageTexture.create_from_image(image)
