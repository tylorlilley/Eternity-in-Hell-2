if (can_process_this_frame()) {
	event_inherited();
	
	if closed {
		var push_direction = get_direction_pushed_against();
		if (push_direction != directions.none) {
			// Set up which inventory slots are available
			var free_hands = array_create(0);
			if (!is_existing_instance(global.player.right_hand_item)) { array_push(free_hands, directions.right); } 
			if (!is_existing_instance(global.player.left_hand_item)) { array_push(free_hands, directions.left); } 
			
			// Try to open the chest
			if (array_length(free_hands) == 0 && place_meeting(global.player.x, global.player.y, obj_solid)) { play_sound(snd_locked, false); }
			else {
				closed = false;
				image_index = 1;
				if (contents_obj == obj_statue) {
					play_sound(snd_skeletonrise, true);
					var statue = instance_create(x, y, obj_statue);
					statue.dir = get_opposite_dir(push_direction);
					instance_destroy();
				}
				else if (contents_obj != -1) { 
					var new_item = noone;
					with (global.player) {
						play_sound(snd_open, true);
						play_sound(snd_pickup, false);
					}
					if (array_length(free_hands) == 0) { 
						new_item = instance_create(global.player.x, global.player.y, contents_obj);
					}
					else {
						new_item = create_item_in_hand(array_random_pop(free_hands), contents_obj);
					}
					if (global.controller.current_room.has_special_item) { with new_item { make_item_special(); } }
				}
			}
			
			//ds_list_destroy(free_hands);
		}
		else if (contents_obj == -1) { 
			closed = false;
			image_index = 1;
		}
	}
}
