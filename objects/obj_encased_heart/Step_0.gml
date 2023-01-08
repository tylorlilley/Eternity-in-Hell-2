if (process_this_frame()) {
event_inherited();

	if (game_progress_has_been_completed()) {
		var new_heart = instance_create_depth(x, y, 4, obj_heart);
		new_heart.image_index = image_index;
		new_heart.image_speed = image_speed;
		new_heart.thump_timer = thump_timer;
		instance_destroy();
	}
	thump();
}