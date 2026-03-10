## Unit tests for LevelBase, RoomTemplate, NavigationZone, and SpawnRegion.
extends Node

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_run_all()
	print("LevelArchitecture tests: %d passed, %d failed." % [_passed, _failed])


func _run_all() -> void:
	test_room_template_get_spawn_points_empty()
	test_room_template_get_spawn_points_with_markers()
	test_room_template_contains_point_inside()
	test_room_template_contains_point_outside()
	test_room_template_contains_point_on_boundary()
	test_navigation_zone_contains_point_inside()
	test_navigation_zone_contains_point_outside()
	test_navigation_zone_contains_point_on_boundary()
	test_spawn_region_get_random_position_in_bounds()
	test_spawn_region_contains_point_inside()
	test_spawn_region_contains_point_outside()
	test_spawn_region_build_marker_grid_2x3()
	test_spawn_region_build_marker_grid_1x1()
	test_spawn_region_build_marker_grid_clamps_zero()
	test_spawn_region_clear_markers()
	test_level_base_collects_rooms()
	test_level_base_collects_nested_rooms()
	test_level_base_collects_navigation_zones()
	test_level_base_get_room_spawn_points_empty()
	test_level_base_get_room_spawn_points_aggregated()
	test_level_base_is_position_navigable_true()
	test_level_base_is_position_navigable_false()
	test_level_base_is_position_navigable_no_zones()
	test_level_base_applies_biome_to_lighting()


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % name)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % name)


# ── RoomTemplate tests ────────────────────────────────────────────────────────

func test_room_template_get_spawn_points_empty() -> void:
	var room := RoomTemplate.new()
	add_child(room)
	_assert(room.get_spawn_points().is_empty(),
		"RoomTemplate.get_spawn_points() returns [] with no SpawnPoints child")
	room.queue_free()


func test_room_template_get_spawn_points_with_markers() -> void:
	var room := RoomTemplate.new()
	var container := Node2D.new()
	container.name = "SpawnPoints"
	room.add_child(container)
	var m1 := Marker2D.new()
	var m2 := Marker2D.new()
	container.add_child(m1)
	container.add_child(m2)
	add_child(room)
	_assert(room.get_spawn_points().size() == 2,
		"RoomTemplate.get_spawn_points() returns 2 markers")
	room.queue_free()


func test_room_template_contains_point_inside() -> void:
	var room := RoomTemplate.new()
	room.floor_half_extents = Vector2(200.0, 100.0)
	add_child(room)
	_assert(room.contains_point(Vector2(100.0, 50.0)),
		"RoomTemplate.contains_point() true for interior point")
	room.queue_free()


func test_room_template_contains_point_outside() -> void:
	var room := RoomTemplate.new()
	room.floor_half_extents = Vector2(200.0, 100.0)
	add_child(room)
	_assert(not room.contains_point(Vector2(300.0, 0.0)),
		"RoomTemplate.contains_point() false for exterior point")
	room.queue_free()


func test_room_template_contains_point_on_boundary() -> void:
	var room := RoomTemplate.new()
	room.floor_half_extents = Vector2(200.0, 100.0)
	add_child(room)
	_assert(room.contains_point(Vector2(200.0, 100.0)),
		"RoomTemplate.contains_point() true for point exactly on boundary")
	room.queue_free()


# ── NavigationZone tests ──────────────────────────────────────────────────────

func test_navigation_zone_contains_point_inside() -> void:
	var zone := NavigationZone.new()
	zone.zone_half_extents = Vector2(256.0, 144.0)
	add_child(zone)
	_assert(zone.contains_point(Vector2(100.0, 50.0)),
		"NavigationZone.contains_point() true for interior point")
	zone.queue_free()


func test_navigation_zone_contains_point_outside() -> void:
	var zone := NavigationZone.new()
	zone.zone_half_extents = Vector2(256.0, 144.0)
	add_child(zone)
	_assert(not zone.contains_point(Vector2(400.0, 0.0)),
		"NavigationZone.contains_point() false for exterior point")
	zone.queue_free()


func test_navigation_zone_contains_point_on_boundary() -> void:
	var zone := NavigationZone.new()
	zone.zone_half_extents = Vector2(256.0, 144.0)
	add_child(zone)
	_assert(zone.contains_point(Vector2(256.0, 144.0)),
		"NavigationZone.contains_point() true for point exactly on boundary")
	zone.queue_free()


# ── SpawnRegion tests ─────────────────────────────────────────────────────────

func test_spawn_region_get_random_position_in_bounds() -> void:
	var region := SpawnRegion.new()
	region.half_extents = Vector2(100.0, 80.0)
	add_child(region)
	var pos: Vector2 = region.get_random_position()
	var local_pos: Vector2 = region.to_local(pos)
	_assert(
		abs(local_pos.x) <= 100.0 and abs(local_pos.y) <= 80.0,
		"SpawnRegion.get_random_position() returns position within bounds"
	)
	region.queue_free()


func test_spawn_region_contains_point_inside() -> void:
	var region := SpawnRegion.new()
	region.half_extents = Vector2(100.0, 80.0)
	add_child(region)
	_assert(region.contains_point(Vector2(50.0, 40.0)),
		"SpawnRegion.contains_point() true for interior point")
	region.queue_free()


func test_spawn_region_contains_point_outside() -> void:
	var region := SpawnRegion.new()
	region.half_extents = Vector2(100.0, 80.0)
	add_child(region)
	_assert(not region.contains_point(Vector2(150.0, 0.0)),
		"SpawnRegion.contains_point() false for exterior point")
	region.queue_free()


func test_spawn_region_build_marker_grid_2x3() -> void:
	var region := SpawnRegion.new()
	region.half_extents = Vector2(100.0, 80.0)
	add_child(region)
	var markers := region.build_marker_grid(2, 3)
	_assert(markers.size() == 6,
		"SpawnRegion.build_marker_grid(2, 3) generates 6 markers")
	region.queue_free()


func test_spawn_region_build_marker_grid_1x1() -> void:
	var region := SpawnRegion.new()
	region.half_extents = Vector2(50.0, 50.0)
	add_child(region)
	var markers := region.build_marker_grid(1, 1)
	_assert(markers.size() == 1,
		"SpawnRegion.build_marker_grid(1, 1) generates 1 marker")
	region.queue_free()


func test_spawn_region_build_marker_grid_clamps_zero() -> void:
	var region := SpawnRegion.new()
	region.half_extents = Vector2(50.0, 50.0)
	add_child(region)
	var markers := region.build_marker_grid(0, 0)
	_assert(markers.size() == 1,
		"SpawnRegion.build_marker_grid(0, 0) clamps to at least 1×1 = 1 marker")
	region.queue_free()


func test_spawn_region_clear_markers() -> void:
	var region := SpawnRegion.new()
	region.half_extents = Vector2(100.0, 80.0)
	add_child(region)
	region.build_marker_grid(2, 2)
	region.clear_markers()
	_assert(region.get_child_count() == 0,
		"SpawnRegion.clear_markers() removes all Marker2D children")
	region.queue_free()


# ── LevelBase tests ───────────────────────────────────────────────────────────

func test_level_base_collects_rooms() -> void:
	var level := LevelBase.new()
	var room1 := RoomTemplate.new()
	var room2 := RoomTemplate.new()
	level.add_child(room1)
	level.add_child(room2)
	add_child(level)
	_assert(level.get_rooms().size() == 2,
		"LevelBase._collect_rooms() finds 2 room templates")
	level.queue_free()


func test_level_base_collects_nested_rooms() -> void:
	var level := LevelBase.new()
	var container := Node2D.new()
	var room := RoomTemplate.new()
	container.add_child(room)
	level.add_child(container)
	add_child(level)
	_assert(level.get_rooms().size() == 1,
		"LevelBase._collect_rooms() finds rooms nested inside a plain Node2D")
	level.queue_free()


func test_level_base_collects_navigation_zones() -> void:
	var level := LevelBase.new()
	var zone1 := NavigationZone.new()
	var zone2 := NavigationZone.new()
	level.add_child(zone1)
	level.add_child(zone2)
	add_child(level)
	_assert(level.get_navigation_zones().size() == 2,
		"LevelBase._collect_navigation_zones() finds 2 zones")
	level.queue_free()


func test_level_base_get_room_spawn_points_empty() -> void:
	var level := LevelBase.new()
	add_child(level)
	_assert(level.get_room_spawn_points().is_empty(),
		"LevelBase.get_room_spawn_points() returns [] when no rooms are present")
	level.queue_free()


func test_level_base_get_room_spawn_points_aggregated() -> void:
	var level := LevelBase.new()
	var room := RoomTemplate.new()
	var container := Node2D.new()
	container.name = "SpawnPoints"
	room.add_child(container)
	var m1 := Marker2D.new()
	var m2 := Marker2D.new()
	container.add_child(m1)
	container.add_child(m2)
	level.add_child(room)
	add_child(level)
	_assert(level.get_room_spawn_points().size() == 2,
		"LevelBase.get_room_spawn_points() returns 2 points from a single room")
	level.queue_free()


func test_level_base_is_position_navigable_true() -> void:
	var level := LevelBase.new()
	var zone := NavigationZone.new()
	zone.zone_half_extents = Vector2(200.0, 200.0)
	level.add_child(zone)
	add_child(level)
	_assert(level.is_position_navigable(Vector2(50.0, 50.0)),
		"LevelBase.is_position_navigable() true when position is inside a zone")
	level.queue_free()


func test_level_base_is_position_navigable_false() -> void:
	var level := LevelBase.new()
	var zone := NavigationZone.new()
	zone.zone_half_extents = Vector2(100.0, 100.0)
	level.add_child(zone)
	add_child(level)
	_assert(not level.is_position_navigable(Vector2(500.0, 500.0)),
		"LevelBase.is_position_navigable() false when position is outside all zones")
	level.queue_free()


func test_level_base_is_position_navigable_no_zones() -> void:
	var level := LevelBase.new()
	add_child(level)
	_assert(not level.is_position_navigable(Vector2(0.0, 0.0)),
		"LevelBase.is_position_navigable() false when no navigation zones are registered")
	level.queue_free()


func test_level_base_applies_biome_to_lighting() -> void:
	var level := LevelBase.new()
	var lighting := LevelLighting.new()
	var biome := BiomeProfile.new()
	biome.ambient_color = Color(0.12, 0.34, 0.56, 1.0)
	level.biome_profile = biome
	level.add_child(lighting)
	add_child(level)
	_assert(
		lighting.biome_profile == biome and lighting.ambient_color == biome.ambient_color,
		"LevelBase applies biome profile to LevelLighting nodes"
	)
	level.queue_free()
