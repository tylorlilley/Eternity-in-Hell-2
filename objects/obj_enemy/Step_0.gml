if (process_this_frame()) {
	event_inherited();
	
	// Flicker sprite if corporeal
	if (!corporeal) {
		visible = (global.controller.number_of_frames_since_game_began mod (global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING * 2) == 0);
	}
	else {
		// Destroy self if completely covered by lava
		if (consumed_by_lava) {
			var lava_at_quadrant = get_presence_at_each_quadrant(obj_lava);
			if (lava_at_quadrant[0] && lava_at_quadrant[1] && lava_at_quadrant[2] && lava_at_quadrant[3]) {
				play_sound(snd_extinguish, true);
				kill_enemy();
			}
		}
	}
	// Destroy self if completely covered by solids
	if (consumed_by_block && visible) {
		var solid_at_quadrant = get_presence_at_each_quadrant(obj_solid);
		if (solid_at_quadrant[0] && solid_at_quadrant[1] && solid_at_quadrant[2] && solid_at_quadrant[3]) {
			kill_enemy();
		}
	}
}
