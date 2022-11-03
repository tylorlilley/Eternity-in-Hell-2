if (process_this_frame()) {
	event_inherited();

	if (image_speed == 0 && game_progress_has_been_completed()) { image_speed = one_unit_of_game_time(); }
	if (instance_at_coordinates(x, y, global.player)) {
		if (get_carried_item_of_type(obj_heart)) { global.controller.completion_amount += 1; play_sound(snd_win, false); instance_destroy(); }
		else { with (obj_echo_spot) { play_sound(snd_impact, false); instance_destroy(); } }
	}
}
