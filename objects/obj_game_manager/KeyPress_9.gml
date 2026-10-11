// In test mode, start seed testing: end the current game and start a new one with the next seed. Each seed's game then
// passes once it is running, and this object's End Step event moves on to the following seed
if (global.is_test_mode) {
	global.is_seed_testing_mode = true;
	with (obj_controller) { restart_game(); }
	global.seed++;
	write_debug_message("TRY SEED - " + string(global.seed));
	room_goto(rm_start);
}
