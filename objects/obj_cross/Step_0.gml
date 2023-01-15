if (process_this_frame()) {
	event_inherited();

	if (game_progress_has_been_completed() || instance_number(obj_echo_spot) > 0) { image_speed = one_unit_of_game_time(); }
	else { image_index = 0; image_speed = 0; }
	if (instance_at_coordinates(x, y, global.player)) {
		if (get_carried_item_of_type(obj_heart) && game_progress_has_been_completed()) { global.controller.completion_amount += 1; play_sound(snd_win, false); instance_destroy(); }
		else { with (obj_echo_spot) { play_sound(snd_impact, false); instance_destroy(); } }
	}
}
