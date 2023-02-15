// Play the relevant sounds
array_unique_ext(sounds_to_play);
while (array_length(sounds_to_play) > 0) {
	var sound_to_play = array_pop(sounds_to_play);
	audio_play_sound(sound_to_play, 10, false);
}

if (global.is_test_mode && global.seed_testing_mode && global.test_passed) {
	global.test_passed = false;
	with (obj_controller) { restart_game(); }
	global.seed++;
	update_setting("last_seed", global.seed);
	show_debug_message("TRY SEED - " + string(global.seed));
	if global.seed == MAX_SEED { show_debug_message("ALL SEEDS CLEARED"); }
	else { room_goto(rm_start); }
}