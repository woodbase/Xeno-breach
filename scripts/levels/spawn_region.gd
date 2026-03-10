## SpawnRegion — rectangular area within which enemies may be spawned.
##
## Use SpawnRegion nodes as an alternative to fixed [Marker2D] spawn points
## when you want enemies to appear anywhere within a defined area rather than
## at a single position.
##
## Usage with [WaveSpawner]:
##   Build concrete spawn positions with [method get_random_position] and wrap
##   each result in a temporary [Marker2D], or use [method build_marker_grid]
##   once in [code]_ready[/code] to generate a reusable grid of markers that
##   can be passed directly to [WaveSpawner.spawn_points].
##
## Usage with [RoomTemplate]:
##   SpawnRegion nodes placed inside a RoomTemplate's SpawnPoints container are
##   treated as regular Node2D spawn points; their [code]global_position[/code]
##   (centre of the region) is used unless the level script explicitly calls
##   [method get_random_position].
class_name SpawnRegion
extends Node2D

## Half-extents of the spawn rectangle in local space (pixels).
@export var half_extents: Vector2 = Vector2(64.0, 64.0)

## Debug tint drawn by the editor helper to distinguish regions visually.
@export var debug_color: Color = Color(0.2, 0.7, 1.0, 0.25)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## Returns a uniformly-distributed random [Vector2] in world space inside
## this region's rectangle.
func get_random_position() -> Vector2:
	var local_x: float = _rng.randf_range(-half_extents.x, half_extents.x)
	var local_y: float = _rng.randf_range(-half_extents.y, half_extents.y)
	return global_position + Vector2(local_x, local_y)


## Returns true when [param world_pos] lies inside this region's rectangle.
func contains_point(world_pos: Vector2) -> bool:
	var local_pos: Vector2 = to_local(world_pos)
	return abs(local_pos.x) <= half_extents.x and abs(local_pos.y) <= half_extents.y


## Populates this node with evenly-distributed [Marker2D] children arranged in
## a [param grid_cols] × [param grid_rows] grid spanning the full region.
## Returns the generated markers.  Call [method clear_markers] first to avoid
## duplicates when rebuilding the grid at runtime.
func build_marker_grid(grid_cols: int, grid_rows: int) -> Array[Node2D]:
	var result: Array[Node2D] = []
	grid_cols = maxi(1, grid_cols)
	grid_rows = maxi(1, grid_rows)
	var step_x: float = half_extents.x * 2.0 / float(grid_cols)
	var step_y: float = half_extents.y * 2.0 / float(grid_rows)
	var start_x: float = -half_extents.x + step_x * 0.5
	var start_y: float = -half_extents.y + step_y * 0.5
	for col: int in grid_cols:
		for row: int in grid_rows:
			var marker := Marker2D.new()
			marker.position = Vector2(start_x + col * step_x, start_y + row * step_y)
			add_child(marker)
			result.append(marker)
	return result


## Removes all [Marker2D] children previously added by [method build_marker_grid].
func clear_markers() -> void:
	for child: Node in get_children():
		if child is Marker2D:
			child.queue_free()
