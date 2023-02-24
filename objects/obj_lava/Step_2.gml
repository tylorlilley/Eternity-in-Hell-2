event_inherited();

if (can_process_this_frame()) {
	var paths = instance_place_all(x, y, obj_path);
	
	while (array_length(paths) > 0) {
		var path = array_pop(paths);
		if (path.image_blend > image_blend) { path.image_blend = image_blend; }
	}
}
