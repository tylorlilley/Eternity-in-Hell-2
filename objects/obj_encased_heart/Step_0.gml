event_inherited();

if (game_progress_has_been_completed()) {
	instance_create_depth(x, y, 4, obj_heart);
	instance_destroy();
}