if (can_process_this_frame()) {
	event_inherited();

	if (are_all_collectables_collected() || instance_number(obj_echo_spot) > 0) { image_speed = get_one_unit_of_game_time(); }
	else { image_index = 0; image_speed = 0; }
	if (is_instance_at_coordinates(x, y, global.player)) {
		with (global.player) {
			if (is_carrying_item(obj_heart) && are_all_collectables_collected()) { global.controller.completion_amount += 1; play_sound(snd_win, false); instance_destroy(other.id); }
			else { with (obj_echo_spot) { play_sound(snd_impact, false); instance_destroy(); } }
		}
	}
}
