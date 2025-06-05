/// @description Step
if (can_process_this_frame()) {
	var dir = directions.none;
	if (infectious) { 
		dir = irandom(16) > 3 ? directions.none : move_towards_meat_or_player(false, false); 
	}
	else { dir = run_away_from_player(false, true, false); }
	
	switch (dir) {
		case directions.up: { y += 4; break; }
		case directions.right: { x -= 4; break; }
		case directions.down: { y -= 4; break; }
		case directions.left: { x += 4; break; }
	}
	if (dir != directions.none) { 
		image_angle = 90 * dir; 
		image_index += 1;
		if (image_index > 3) { image_index = 0; }
	}
	image_xscale = 1;

	event_inherited();
	var crushed_by_player = get_distance_to_instance(global.player) <= 4;
	var killed_by_lava = instance_place(x, y, obj_death);
	if (crushed_by_player ||killed_by_lava || is_solid_at_position(x, y)) {
		instance_destroy();
		if (!killed_by_lava) { play_sound(snd_thud, false); }
		if (crushed_by_player) {
			global.controller.evaluation_manager.increment_evaluation_variable("crushed_bugs");
		}
	}
}

