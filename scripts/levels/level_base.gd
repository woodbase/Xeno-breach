## LevelBase — reusable foundation for all level scenes.
##
## Extend this class in place of Node2D for new levels to inherit:
##   • Automatic [RoomTemplate] and [NavigationZone] collection from the scene tree.
##   • Aggregated spawn-point list from all RoomTemplate children.
##   • Shared level-transition helpers (next level / main menu).
##   • Lifecycle signals and virtual hooks consumed by concrete level scripts.
##
## Concrete levels override [method _on_level_ready] for their own
## initialisation; [method _ready] must not be overridden — call
## [code]super._ready()[/code] if you must keep a [method _ready] override.
class_name LevelBase
extends Node2D

## Emitted once the level has fully initialised and gameplay has begun.
signal level_started

## Emitted when all waves are cleared and the level is considered won.
signal level_completed

## Emitted when all players have died.
signal level_failed

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const VICTORY_SCREEN_SCENE_PATH: String = "res://scenes/ui/victory_screen.tscn"

## Enable verbose balance-tuning output to the Godot output panel.
@export var debug_telemetry_enabled: bool = false

## Optional path to the next level scene.  Leave blank to trigger
## [method _on_no_next_level] (shows the victory state by default).
@export_file("*.tscn") var next_level_scene_path: String = ""

var _rooms: Array[RoomTemplate] = []
var _navigation_zones: Array[NavigationZone] = []
var _transitioning: bool = false


func _ready() -> void:
	_collect_rooms()
	_collect_navigation_zones()
	_on_level_ready()


## Override in subclass to run level-specific initialisation.
## Called after [method _collect_rooms] and [method _collect_navigation_zones]
## have already populated the internal lists.
func _on_level_ready() -> void:
	pass


# ── Room management ───────────────────────────────────────────────────────────

func _collect_rooms() -> void:
	_rooms.clear()
	_walk_tree_for_rooms(self)


func _walk_tree_for_rooms(node: Node) -> void:
	for child: Node in node.get_children():
		var room := child as RoomTemplate
		if room != null:
			_rooms.append(room)
		else:
			_walk_tree_for_rooms(child)


## All [RoomTemplate] nodes found in this level's scene tree.
func get_rooms() -> Array[RoomTemplate]:
	return _rooms.duplicate()


## Aggregated spawn points from every [RoomTemplate] registered in this level.
## Returns an empty array when no rooms are present.
func get_room_spawn_points() -> Array[Node2D]:
	var points: Array[Node2D] = []
	for room: RoomTemplate in _rooms:
		points.append_array(room.get_spawn_points())
	return points


# ── Navigation zones ──────────────────────────────────────────────────────────

func _collect_navigation_zones() -> void:
	_navigation_zones.clear()
	_walk_tree_for_nav_zones(self)


func _walk_tree_for_nav_zones(node: Node) -> void:
	for child: Node in node.get_children():
		var zone := child as NavigationZone
		if zone != null:
			_navigation_zones.append(zone)
		else:
			_walk_tree_for_nav_zones(child)


## All [NavigationZone] nodes found in this level's scene tree.
func get_navigation_zones() -> Array[NavigationZone]:
	return _navigation_zones.duplicate()


## Returns true when [param world_pos] lies inside any registered
## [NavigationZone].  Uses each zone's [method NavigationZone.contains_point].
func is_position_navigable(world_pos: Vector2) -> bool:
	for zone: NavigationZone in _navigation_zones:
		if zone.contains_point(world_pos):
			return true
	return false


# ── Level transitions ─────────────────────────────────────────────────────────

## Transition to the scene at [member next_level_scene_path].
## Shows the [VictoryScreen] first, then continues to the next level.
## Falls back to [method _on_no_next_level] when no path is set or the file
## does not exist.
func go_to_next_level() -> void:
	if _transitioning:
		return
	if not next_level_scene_path.is_empty():
		if ResourceLoader.exists(next_level_scene_path):
			_transitioning = true
			get_tree().paused = false
			GameStateManager.next_level_scene_path = next_level_scene_path
			GameStateManager.change_state(GameStateManager.State.VICTORY)
			get_tree().change_scene_to_file(VICTORY_SCREEN_SCENE_PATH)
			return
		else:
			push_warning("LevelBase: next_level_scene_path not found: %s" % next_level_scene_path)
	_on_no_next_level()


## Called by [method go_to_next_level] when no valid next-level path is set.
## Default behaviour emits [signal level_completed] and sets the VICTORY state.
## Override in subclass for custom end-of-level flow.
func _on_no_next_level() -> void:
	GameStateManager.change_state(GameStateManager.State.VICTORY)
	level_completed.emit()


## Transition back to the main menu scene.
func go_to_main_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_tree().paused = false
	GameStateManager.change_state(GameStateManager.State.MAIN_MENU)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
