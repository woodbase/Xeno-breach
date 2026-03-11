## NavigationZone — marks a region as passable for enemy navigation.
##
## Add NavigationZone nodes to a level scene (directly, or inside a
## [RoomTemplate]) to describe where enemies are allowed to walk.  This node
## wraps a [NavigationRegion2D] child and provides a lightweight AABB helper
## ([method contains_point]) used by [LevelBase.is_position_navigable].
##
## Configure the NavigationPolygon on the child [NavigationRegion2D] in the
## Godot editor to match the actual walkable polygon.  Set
## [member zone_half_extents] to the AABB of that polygon so that
## [method contains_point] returns accurate results without a full polygon test.
class_name NavigationZone
extends Node2D

## Human-readable label used in debug output.
@export var zone_id: String = ""

## Half-extents of the axis-aligned bounding rectangle for this zone (local
## space, in pixels).  Should match the bounding box of the NavigationPolygon
## assigned to the child [NavigationRegion2D].
@export var zone_half_extents: Vector2 = Vector2(512.0, 320.0)

@onready var _nav_region: NavigationRegion2D = get_node_or_null("NavigationRegion2D") as NavigationRegion2D


## Returns true when [param world_pos] is inside the AABB approximation of
## this zone.  For a precise polygon-boundary check use Godot's
## NavigationServer2D API with [method get_navigation_region].
func contains_point(world_pos: Vector2) -> bool:
	var local_pos: Vector2 = to_local(world_pos)
	return (
		abs(local_pos.x) <= zone_half_extents.x
		and abs(local_pos.y) <= zone_half_extents.y
	)


## Returns the child [NavigationRegion2D], or null if not present.
func get_navigation_region() -> NavigationRegion2D:
	return _nav_region


## Convenience: assign a [NavigationPolygon] to the child NavigationRegion2D.
## Does nothing when no NavigationRegion2D child exists.
func set_polygon(polygon: NavigationPolygon) -> void:
	if _nav_region == null:
		push_warning("NavigationZone: no NavigationRegion2D child found.")
		return
	_nav_region.navigation_polygon = polygon
