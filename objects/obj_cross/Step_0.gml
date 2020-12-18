if (process_this_frame()) {
	event_inherited();

	if (image_speed == 0 && game_progress_has_been_completed()) { image_speed = global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING/game_get_speed(gamespeed_fps); }
	if (get_carried_item_of_type(obj_heart) && instance_at_coordinates(x, y, global.player)) { global.controller.game_won = true; audio_play_sound(snd_win, 10, false); instance_destroy(); }
}
