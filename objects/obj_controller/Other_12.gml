/// @description End Step
if (transition == directions.none && !blackout && global.is_test_mode && global.is_seed_testing_mode) { global.has_seed_test_passed = true; }
if (grid_update_timer > 0) {
	grid_update_timer -= 1;
	if grid_update_timer == 0 { current_room.reset_room_lava_grid(); }
}