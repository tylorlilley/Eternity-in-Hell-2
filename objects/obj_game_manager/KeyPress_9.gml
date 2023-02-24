//screen_save("shot_"+string(global.seed)+".png")

if (global.is_test_mode) {
	global.is_seed_testing_mode = true;
	with (obj_controller) { restart_game(); }
	global.seed++;
	show_debug_message("TRY SEED - " + string(global.seed));
	room_goto(rm_start);
}