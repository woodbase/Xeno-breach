## RoomTemplate — self-contained modular room segment for level composition.
##
## Drop multiple RoomTemplate instances into a level scene to compose the
## arena layout from reusable pieces.  Each room owns:
##   • A [Polygon2D] floor visual updated at runtime from [member floor_half_extents].
##   • Auto-generated boundary [StaticBody2D] walls (collision layer 4).
##   • A [Node2D] container named SpawnPoints whose [Marker2D] children are
##     exposed to [WaveSpawner] via [method get_spawn_points].
##   • An optional [NavigationRegion2D] defining the walkable area.
##
## Retrieve spawn points via [method get_spawn_points] or let
## [LevelBase.get_room_spawn_points] aggregate them across all rooms.
class_name RoomTemplate
extends Node2D

## Unique identifier for this room.  Used for logging and save-state purposes.
@export var room_id: String = ""

## Half-extents of the room's rectangular floor area (local space, in pixels).
## Walls and the floor visual are rebuilt whenever this value changes in
## [method _ready].
@export var floor_half_extents: Vector2 = Vector2(320.0, 180.0)

## Tint of the floor [Polygon2D].  Replace with a textured material in production.
@export var floor_color: Color = Color(0.15, 0.15, 0.22, 1.0)

## Thickness of the generated boundary walls in pixels.
@export_range(8.0, 64.0, 1.0) var wall_thickness: float = 16.0

@onready var _spawn_points_container: Node2D = get_node_or_null("SpawnPoints") as Node2D
@onready var _navigation_region: NavigationRegion2D = get_node_or_null("NavigationRegion2D") as NavigationRegion2D
@onready var _walls_container: Node2D = get_node_or_null("Walls") as Node2D
@onready var _floor_polygon: Polygon2D = get_node_or_null("Floor") as Polygon2D


func _ready() -> void:
	_update_floor_visual()
	_build_boundary_walls()


# ── Floor visual ──────────────────────────────────────────────────────────────

func _update_floor_visual() -> void:
	if _floor_polygon == null:
		return
	var w: float = floor_half_extents.x
	var h: float = floor_half_extents.y
	_floor_polygon.polygon = PackedVector2Array([
		Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h),
	])
	_floor_polygon.color = floor_color


# ── Boundary walls ────────────────────────────────────────────────────────────

## Rebuild the four boundary [StaticBody2D] walls inside the Walls container.
## Existing wall children are removed first to avoid duplicates on re-entry.
func _build_boundary_walls() -> void:
	if _walls_container == null:
		return
	for child: Node in _walls_container.get_children():
		child.queue_free()
	var w: float = floor_half_extents.x
	var h: float = floor_half_extents.y
	var t: float = wall_thickness
	_make_wall("NorthWall", Vector2(0.0, -(h + t * 0.5)), Vector2((w + t) * 2.0, t))
	_make_wall("SouthWall", Vector2(0.0, h + t * 0.5), Vector2((w + t) * 2.0, t))
	_make_wall("WestWall", Vector2(-(w + t * 0.5), 0.0), Vector2(t, h * 2.0))
	_make_wall("EastWall", Vector2(w + t * 0.5, 0.0), Vector2(t, h * 2.0))


func _make_wall(wall_name: String, pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = wall_name
	body.position = pos
	body.collision_layer = 4
	body.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	body.add_child(shape_node)
	_walls_container.add_child(body)


# ── Spawn points ──────────────────────────────────────────────────────────────

## Returns all [Marker2D] (and generic [Node2D]) children of the SpawnPoints
## container.  Returns an empty array when the container is absent.
func get_spawn_points() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if _spawn_points_container == null:
		return result
	for child: Node in _spawn_points_container.get_children():
		var marker := child as Node2D
		if marker != null:
			result.append(marker)
	return result


# ── Navigation ────────────────────────────────────────────────────────────────

## Returns the [NavigationRegion2D] owned by this room, or null when absent.
## Configure its [NavigationPolygon] in the editor to define the walkable area.
func get_navigation_region() -> NavigationRegion2D:
	return _navigation_region


# ── Bounds query ──────────────────────────────────────────────────────────────

## Returns true when [param world_pos] lies within this room's rectangular
## floor area (based on [member floor_half_extents]).
func contains_point(world_pos: Vector2) -> bool:
	var local_pos: Vector2 = to_local(world_pos)
	return (
		abs(local_pos.x) <= floor_half_extents.x
		and abs(local_pos.y) <= floor_half_extents.y
	)
