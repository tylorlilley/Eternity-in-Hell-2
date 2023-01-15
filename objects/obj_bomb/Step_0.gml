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
			var torch = instance_place(x, y, obj_torch);
			if (torch != noone && torch.light_source != noone) {
				play_sound(snd_torchlight, true);
				fuse_timer = 4*irandom_range(5,8);
			}
		}
		
		// Blow up bombs dropped in lava
		var player_at_quadrant = get_presence_at_each_quadrant(global.player);
		if (lava_at_all_quadrants() && (get_carried_item_of_type(obj_amulet) == noone || (player_at_quadrant[0] == noone && player_at_quadrant[1] == noone && player_at_quadrant[2] == noone && player_at_quadrant[3] == noone))) {
			explode(!special);
		}
	}
}

event_inherited();
