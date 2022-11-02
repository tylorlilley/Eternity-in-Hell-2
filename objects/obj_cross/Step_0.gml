if (process_this_frame()) {
	event_inherited();

	if (image_speed == 0 && game_progress_has_been_completed()) { image_speed = one_unit_of_game_time(); }
	if (get_carried_item_of_type(obj_heart) && instance_at_coordinates(x, y, global.player)) { global.controller.completion_amount += 1; play_sound(snd_win, true); instance_destroy(); }
}
