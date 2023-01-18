if process_this_frame() {
	if (!carried) {
		if (fuse_timer > 0) {
			fuse_timer -= 1;
			if (fuse_timer % 4 == 0) { 
				if (fuse_timer != 0) { play_sound(snd_tick, false); visible = false; } 
			}
			else { visible = true; }
			if (fuse_timer == 0) {
				if (!special && get_random_chance_out_of(64)) { play_sound(snd_move, false); }
				else { explode(!special); instance_create_depth(x, y, 0, obj_dirt); }
			}
		}
		else { 
			visible = true; 
			// Light bomb fuses with torches
			var torches_at_position = instance_place_all(x, y, obj_torch);
			while (array_length(torches_at_position) > 0) {
				var torch = array_random_pop(torches_at_position);
				if (torch.light_source != noone && instance_at_coordinates(x, y, torch)) {
					play_sound(snd_torchlight, true);
					fuse_timer = 4*irandom_range(5,8);
					break;
				}
			}
		}
		
		// Blow up bombs dropped in lava
		if (is_covered_at_each_quadrant_by(obj_lava) && (get_carried_item_of_type(obj_staff) == noone || !instance_at_coordinates(x, y, global.player))) {
			explode(!special);
		}
	}
}

event_inherited();
