if (process_this_frame()) {
	event_inherited();
	
	if closed {
		var push_direction = pushed_against_by_player(true);
		if (push_direction != noone) {
			// Set up which inventory slots are available
			var free_hands = ds_list_create();
			for (var i = 1; i <= 3; i += 2;) {
				if (!global.player.carried_items[i]) { 
					ds_list_add(free_hands, i); 
				}
			}
			// Try to open the chest
			if (ds_list_size(free_hands) == 0) { audio_play_sound( snd_locked, 10, false ); }
			else { 
				closed = false;
				image_index = 1;
				if (contents != noone) { 
					audio_play_sound(snd_open, 10, false);
					audio_play_sound(snd_pickup, 10, false);
					var new_item = create_item_in_hand(ds_list_pop_random_value(free_hands), contents);
					if (special) { with new_item { make_item_special(); } }
				}
			}
			
			ds_list_destroy(free_hands);
		}
		else if (contents == noone) { 
			closed = false;
			image_index = 1;
		}
	}
}
