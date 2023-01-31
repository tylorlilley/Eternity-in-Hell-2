if can_process_this_frame() {
	if (!is_existing_instance(holder)) {
		if (fuse_timer > 0) {
			fuse_timer -= 1;
			if (fuse_timer % 4 == 0) { 
				if (fuse_timer != 0) { play_sound(snd_tick, false); visible = false; } 
			}
			else { visible = true; }
			if (fuse_timer == 0) {
				if (!special && get_random_chance_out_of(BOMB_DUD_PROBABILITY)) { play_sound(snd_move, false); }
				else { explode(!special); instance_create(x, y, obj_dirt); }
			}
		}
		else { 
			visible = true; 
			// Light bomb fuses with torches
			var torches_at_position = instance_place_all(x, y, obj_torch);
			while (array_length(torches_at_position) > 0) {
				var torch = array_random_pop(torches_at_position);
				if (is_existing_instance(torch) && is_existing_instance(torch.light_source) && is_instance_at_coordinates(x, y, torch)) {
					play_sound(snd_torchlight, true);
					fuse_timer = 4*irandom_range(5,8);
					break;
				}
			}
		}
		
		// Blow up bombs dropped in lava
		if (is_covered_at_each_quadrant_by(obj_lava)) {
			explode(!special);
		}
	}
}

event_inherited();
