if (process_this_frame()) {
	event_inherited();

	if (game_progress_has_been_completed()) {
		var new_heart = instance_create_depth(x, y, 0, obj_heart);
		new_heart.image_index = image_index;
		new_heart.thump_timer = thump_timer;
		play_sound(snd_shatter, true);
		instance_destroy();
	}

	var push_direction = get_direction_pushed_against();
	if (push_direction != noone) { play_sound(snd_locked, false); }
	
	thump();
}