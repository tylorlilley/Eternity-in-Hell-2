if (process_this_frame()) {
	event_inherited();
	
	// Flicker sprite if corporeal
	if (!killable_by_sword) {
		visible = (global.controller.number_of_frames_since_game_began mod (global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING * 2) == 0);
	}
	else {
		// Destroy self if completely covered by lava
		if (consumed_by_lava && lava_at_all_quadrants()) {
			play_sound(snd_extinguish, true);
			kill_enemy();
		}
	}
	// Fidget Sprite if Eating Meat
	if (meat_eater) {
		var dropped_meat = noone;
		with (obj_meat) { if (carried == noone) { dropped_meat = self; } }
		if (dropped_meat != noone || instance_position(x, y, obj_player_corpse)) {
			if (get_random_chance_out_of(4)) { play_sound(snd_walk, false); image_xscale *= -1; }
		}
	}
	// Destroy self if completely covered by solids
	if (lethal) {
		if (consumed_by_block) {
			var solid_at_quadrant = get_presence_at_each_quadrant(obj_solid);
			if (solid_at_quadrant[0] && solid_at_quadrant[1] && solid_at_quadrant[2] && solid_at_quadrant[3]) {
				kill_enemy();
			}
		}
		// Destroy self if hit by fireball
		if (consumed_by_fireball && instance_place(x, y, obj_fireball)) {
			play_sound(snd_extinguish, true);
			kill_enemy();
		}
	}
}
