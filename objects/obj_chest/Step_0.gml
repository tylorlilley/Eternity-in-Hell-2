if (can_process_this_frame()) {
	event_inherited();
	
	if closed {
		var push_direction = get_direction_pushed_against();
		if (push_direction != noone) {
			// Set up which inventory slots are available
			var free_hands = array_create(0);
			if (global.player.right_hand_item == noone) { array_push(free_hands, directions.right); } 
			if (global.player.left_hand_item == noone) { array_push(free_hands, directions.left); } 
			
			// Try to open the chest
			if (array_length(free_hands) == 0 && place_meeting(global.player.x, global.player.y, obj_solid)) { play_sound(snd_locked, false); }
			else {
				closed = false;
				image_index = 1;
				if (contents != noone) { 
					var new_item = noone;
					with (global.player) {
						play_sound(snd_open, true);
						play_sound(snd_pickup, false);
					}
					if (array_length(free_hands) == 0) { 
						new_item = instance_create(global.player.x, global.player.y, contents);
					}
					else {
						new_item = create_item_in_hand(array_random_pop(free_hands), contents);
					}
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
