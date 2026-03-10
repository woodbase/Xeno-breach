## Tests for the Mission / Quest Architecture system.
##
## Validates:
##   • MissionObjective base class and concrete types
##   • Mission runtime tracking
##   • MissionManager singleton functionality
##   • Event triggers and completion tracking

extends GutTest


# ── MissionObjective tests ────────────────────────────────────────────────────

func test_mission_objective_basic_completion() -> void:
	var obj: MissionObjective = MissionObjective.new("Test objective", 5)

	assert_eq(obj.description, "Test objective", "Description should match")
	assert_eq(obj.target_progress, 5, "Target should be 5")
	assert_eq(obj.current_progress, 0, "Progress should start at 0")
	assert_false(obj.is_completed, "Should not be completed initially")

	obj.report_progress(3)
	assert_eq(obj.current_progress, 3, "Progress should be 3")
	assert_false(obj.is_completed, "Should not be completed at 3/5")

	obj.report_progress(5)
	assert_eq(obj.current_progress, 5, "Progress should be 5")
	assert_true(obj.is_completed, "Should be completed at 5/5")


func test_mission_objective_increment_progress() -> void:
	var obj: MissionObjective = MissionObjective.new("Test", 3)

	obj.increment_progress()
	assert_eq(obj.current_progress, 1, "Should increment to 1")

	obj.increment_progress(2)
	assert_eq(obj.current_progress, 3, "Should increment to 3")
	assert_true(obj.is_completed, "Should complete at target")


func test_mission_objective_progress_signal() -> void:
	var obj: MissionObjective = MissionObjective.new("Test", 5)
	watch_signals(obj)

	obj.report_progress(2)
	assert_signal_emitted(obj, "progress_changed", "Should emit progress_changed")

	obj.report_progress(5)
	assert_signal_emitted(obj, "completed", "Should emit completed")


# ── KillEnemyObjective tests ──────────────────────────────────────────────────

func test_kill_enemy_objective_without_type_filter() -> void:
	var obj: KillEnemyObjective = KillEnemyObjective.new("Kill 3 enemies", 3)

	obj.report_kill("xeno_crawler")
	assert_eq(obj.current_progress, 1, "Should count first kill")

	obj.report_kill("enemy_brute")
	assert_eq(obj.current_progress, 2, "Should count different enemy type")

	obj.report_kill("enemy_striker")
	assert_eq(obj.current_progress, 3, "Should count third kill")
	assert_true(obj.is_completed, "Should complete at 3 kills")


func test_kill_enemy_objective_with_type_filter() -> void:
	var obj: KillEnemyObjective = KillEnemyObjective.new("Kill 2 crawlers", 2, "xeno_crawler")

	obj.report_kill("xeno_crawler")
	assert_eq(obj.current_progress, 1, "Should count matching type")

	obj.report_kill("enemy_brute")
	assert_eq(obj.current_progress, 1, "Should NOT count different type")

	obj.report_kill("xeno_crawler")
	assert_eq(obj.current_progress, 2, "Should count second matching kill")
	assert_true(obj.is_completed, "Should complete")


# ── ReachAreaObjective tests ──────────────────────────────────────────────────

func test_reach_area_objective() -> void:
	var obj: ReachAreaObjective = ReachAreaObjective.new("Reach extraction", Vector2(500, 500), 100.0)

	obj.check_player_position(Vector2(100, 100))
	assert_false(obj.is_completed, "Should not complete far from target")

	obj.check_player_position(Vector2(450, 450))
	assert_false(obj.is_completed, "Should not complete just outside radius")

	obj.check_player_position(Vector2(520, 480))
	assert_true(obj.is_completed, "Should complete within radius")


# ── ActivateTerminalObjective tests ───────────────────────────────────────────

func test_activate_terminal_objective() -> void:
	var obj: ActivateTerminalObjective = ActivateTerminalObjective.new("Activate terminal", "terminal_alpha")

	obj.report_activation("terminal_beta")
	assert_false(obj.is_completed, "Should not complete with wrong ID")

	obj.report_activation("terminal_alpha")
	assert_true(obj.is_completed, "Should complete with correct ID")


# ── RetrieveItemObjective tests ───────────────────────────────────────────────

func test_retrieve_item_objective() -> void:
	var obj: RetrieveItemObjective = RetrieveItemObjective.new("Retrieve keycard", "keycard_red")

	obj.report_retrieval("keycard_blue")
	assert_false(obj.is_completed, "Should not complete with wrong item")

	obj.report_retrieval("keycard_red")
	assert_true(obj.is_completed, "Should complete with correct item")


# ── Mission tests ─────────────────────────────────────────────────────────────

func test_mission_creation() -> void:
	var mission: Mission = Mission.new()
	mission.mission_id = "test_mission_1"
	mission.mission_name = "Test Mission"
	mission.mission_description = "A test mission"
	mission.reward_score = 100

	assert_eq(mission.mission_id, "test_mission_1", "ID should match")
	assert_eq(mission.current_state, Mission.State.INACTIVE, "Should start inactive")
	assert_eq(mission.objectives.size(), 0, "Should have no objectives initially")


func test_mission_with_objectives() -> void:
	var mission: Mission = Mission.new()
	mission.mission_id = "test_mission_2"

	var obj1: MissionObjective = MissionObjective.new("Objective 1", 1)
	var obj2: MissionObjective = MissionObjective.new("Objective 2", 1)

	mission.add_objective(obj1)
	mission.add_objective(obj2)

	assert_eq(mission.objectives.size(), 2, "Should have 2 objectives")

	mission.start()
	assert_eq(mission.current_state, Mission.State.ACTIVE, "Should be active after start")

	obj1.complete()
	assert_false(mission.current_state == Mission.State.COMPLETED, "Should not complete with 1/2 objectives")

	obj2.complete()
	assert_eq(mission.current_state, Mission.State.COMPLETED, "Should complete with 2/2 objectives")


func test_mission_completion_signal() -> void:
	var mission: Mission = Mission.new()
	mission.mission_id = "test_mission_3"

	var obj: MissionObjective = MissionObjective.new("Complete me", 1)
	mission.add_objective(obj)

	watch_signals(mission)
	mission.start()
	assert_signal_emitted(mission, "state_changed", "Should emit state_changed on start")

	obj.complete()
	assert_signal_emitted(mission, "objective_completed", "Should emit objective_completed")
	assert_signal_emitted(mission, "completed", "Should emit completed")


func test_mission_progress_ratio() -> void:
	var mission: Mission = Mission.new()

	var obj1: MissionObjective = MissionObjective.new("Obj 1", 1)
	var obj2: MissionObjective = MissionObjective.new("Obj 2", 1)
	var obj3: MissionObjective = MissionObjective.new("Obj 3", 1)

	mission.add_objective(obj1)
	mission.add_objective(obj2)
	mission.add_objective(obj3)

	assert_almost_eq(mission.get_progress_ratio(), 0.0, 0.01, "Should be 0% at start")

	obj1.complete()
	assert_almost_eq(mission.get_progress_ratio(), 0.333, 0.01, "Should be ~33% after 1/3")

	obj2.complete()
	assert_almost_eq(mission.get_progress_ratio(), 0.666, 0.01, "Should be ~66% after 2/3")

	obj3.complete()
	assert_almost_eq(mission.get_progress_ratio(), 1.0, 0.01, "Should be 100% when complete")


# ── MissionData tests ─────────────────────────────────────────────────────────

func test_mission_data_creation() -> void:
	var data: MissionData = MissionData.new()
	data.mission_id = "mission_alpha"
	data.mission_name = "Alpha Mission"
	data.mission_description = "First mission"
	data.reward_score = 500

	var mission: Mission = data.create_mission_instance()

	assert_eq(mission.mission_id, "mission_alpha", "ID should transfer")
	assert_eq(mission.mission_name, "Alpha Mission", "Name should transfer")
	assert_eq(mission.reward_score, 500, "Reward should transfer")


# ── MissionManager tests ──────────────────────────────────────────────────────

func test_mission_manager_start_mission() -> void:
	var data: MissionData = MissionData.new()
	data.mission_id = "manager_test_1"
	data.mission_name = "Manager Test"

	var mission: Mission = MissionManager.start_mission(data)

	assert_not_null(mission, "Should return a mission")
	assert_eq(mission.current_state, Mission.State.ACTIVE, "Mission should be active")
	assert_true(MissionManager.active_missions.has("manager_test_1"), "Should be in active missions")

	# Cleanup
	MissionManager.clear_all_missions()


func test_mission_manager_get_mission() -> void:
	var data: MissionData = MissionData.new()
	data.mission_id = "manager_test_2"

	MissionManager.start_mission(data)

	var retrieved: Mission = MissionManager.get_mission("manager_test_2")
	assert_not_null(retrieved, "Should retrieve the mission")
	assert_eq(retrieved.mission_id, "manager_test_2", "Retrieved mission should have correct ID")

	# Cleanup
	MissionManager.clear_all_missions()


func test_mission_manager_enemy_kill_tracking() -> void:
	var mission: Mission = Mission.new()
	mission.mission_id = "kill_test"

	var obj: KillEnemyObjective = KillEnemyObjective.new("Kill 2 crawlers", 2, "xeno_crawler")
	mission.add_objective(obj)

	MissionManager.start_mission_direct(mission)

	MissionManager.report_enemy_killed("xeno_crawler")
	assert_eq(obj.current_progress, 1, "Should track first kill")

	MissionManager.report_enemy_killed("xeno_crawler")
	assert_eq(obj.current_progress, 2, "Should track second kill")
	assert_true(obj.is_completed, "Objective should complete")

	# Cleanup
	MissionManager.clear_all_missions()


func test_mission_manager_terminal_activation_tracking() -> void:
	var mission: Mission = Mission.new()
	mission.mission_id = "terminal_test"

	var obj: ActivateTerminalObjective = ActivateTerminalObjective.new("Activate terminal", "term_1")
	mission.add_objective(obj)

	MissionManager.start_mission_direct(mission)

	MissionManager.report_terminal_activated("term_2")
	assert_false(obj.is_completed, "Should not complete with wrong terminal")

	MissionManager.report_terminal_activated("term_1")
	assert_true(obj.is_completed, "Should complete with correct terminal")

	# Cleanup
	MissionManager.clear_all_missions()


func test_mission_manager_item_retrieval_tracking() -> void:
	var mission: Mission = Mission.new()
	mission.mission_id = "item_test"

	var obj: RetrieveItemObjective = RetrieveItemObjective.new("Get keycard", "keycard_1")
	mission.add_objective(obj)

	MissionManager.start_mission_direct(mission)

	MissionManager.report_item_retrieved("keycard_2")
	assert_false(obj.is_completed, "Should not complete with wrong item")

	MissionManager.report_item_retrieved("keycard_1")
	assert_true(obj.is_completed, "Should complete with correct item")

	# Cleanup
	MissionManager.clear_all_missions()


func test_mission_manager_player_position_tracking() -> void:
	var mission: Mission = Mission.new()
	mission.mission_id = "reach_test"

	var obj: ReachAreaObjective = ReachAreaObjective.new("Reach area", Vector2(500, 500), 50.0)
	mission.add_objective(obj)

	MissionManager.start_mission_direct(mission)

	MissionManager.check_player_position(Vector2(100, 100))
	assert_false(obj.is_completed, "Should not complete far away")

	MissionManager.check_player_position(Vector2(510, 490))
	assert_true(obj.is_completed, "Should complete within radius")

	# Cleanup
	MissionManager.clear_all_missions()


func test_mission_manager_clear_all_missions() -> void:
	var data1: MissionData = MissionData.new()
	data1.mission_id = "clear_test_1"
	var data2: MissionData = MissionData.new()
	data2.mission_id = "clear_test_2"

	MissionManager.start_mission(data1)
	MissionManager.start_mission(data2)

	assert_eq(MissionManager.active_missions.size(), 2, "Should have 2 active missions")

	MissionManager.clear_all_missions()
	assert_eq(MissionManager.active_missions.size(), 0, "Should have no active missions after clear")


func test_mission_manager_signals() -> void:
	watch_signals(MissionManager)

	var data: MissionData = MissionData.new()
	data.mission_id = "signal_test"

	var mission: Mission = MissionManager.start_mission(data)
	assert_signal_emitted(MissionManager, "mission_started", "Should emit mission_started")

	var obj: MissionObjective = MissionObjective.new("Complete", 1)
	mission.add_objective(obj)

	obj.complete()
	assert_signal_emitted(MissionManager, "objective_completed", "Should emit objective_completed")
	assert_signal_emitted(MissionManager, "mission_completed", "Should emit mission_completed")

	# Cleanup
	MissionManager.clear_all_missions()
