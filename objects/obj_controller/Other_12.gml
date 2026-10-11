/// @description End Step
// In seed testing mode, a seed passes once its game has started and the player is in a room, not changing rooms
if (transition == directions.none && !blackout && global.is_test_mode && global.is_seed_testing_mode) { global.has_seed_test_passed = true; }
// Rebuild the current room's path grids once the countdown set by mark_current_room_for_grid_update runs out
if (grid_update_timer > 0) {
	grid_update_timer -= 1;
	if grid_update_timer == 0 { current_room.rebuild_room_grids(); }
}