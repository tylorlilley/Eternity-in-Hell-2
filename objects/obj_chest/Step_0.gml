if (process_this_frame()) {
	event_inherited();
	
	if closed {
		var push_direction = pushed_against_by_player(true);
		if (push_direction != noone) {
			// Set up which inventory slots are available
			var free_hands = array_create(0);
			for (var i = 1; i <= 3; i += 2;) {
				if (!global.player.carried_items[i]) { 
					array_push(free_hands, i); 
				}
			}
			// Try to open the chest
			if (array_length(free_hands) == 0) { audio_play_sound( snd_locked, 10, false ); }
			else { 
				closed = false;
				image_index = 1;
				if (contents != noone) { 
					audio_play_sound(snd_open, 10, false);
					audio_play_sound(snd_pickup, 10, false);
					var new_item = create_item_in_hand(array_random_pop(free_hands), contents);
					if (special) { with new_item { make_item_special(); } }
				}
			}
			
			//ds_list_destroy(free_hands);
		}
		else if (contents == noone) { 
			closed = false;
			image_index = 1;
		}
	}
}
