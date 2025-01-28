/// @description Step
event_inherited();
	
if closed {
	var controller = global.controller, player = global.player;
	var push_direction = get_direction_pushed_against(), carrying_key = false;
	with (player) { carrying_key = is_carrying_item(obj_key); }
	if (locked) { image_index = 2; }
	if (push_direction != directions.none) {
		if (locked && !carrying_key) { play_sound(snd_locked, false); }
		else if (locked) {
			locked = false;
			image_index = 0;
			with (global.player) { 
				play_sound(snd_mana, true);
				with (get_carried_item(obj_key)) { if (!special) { instance_destroy(); } }
			}
		}
		else {
			// Set up which inventory slots are available
			var free_hands = array_create(0);
			if (!is_existing_instance(player.right_hand_item) && !player.lost_right_hand) { array_push(free_hands, directions.right); } 
			if (!is_existing_instance(player.left_hand_item) && !player.lost_left_hand) { array_push(free_hands, directions.left); } 
			
			// Try to open the chest
			if (array_length(free_hands) == 0 && place_meeting(player.x, player.y, obj_solid)) { play_sound(snd_locked, false); }
			else {
				closed = false;
				image_index = 1;
				if (contents_obj == obj_statue) {
					play_sound(snd_skeletonrise, true);
					var statue = instance_create(x, y, obj_statue);
					statue.dir = get_opposite_dir(push_direction);
					statue.image_angle = statue.dir * -90;
					instance_destroy();
				}
				else if(contents_obj == obj_fountain) {
					play_sound(snd_skeletonrise, true);
					instance_create(x, y, obj_fountain);
					instance_destroy();
				}
				else if (contents_obj != -1) { 
					controller.current_room.remove_from_instances_at_map_positions(id);
					
					with (player) {
						play_sound(snd_open, true);
						play_sound(snd_pickup, false);
					}
					
					var new_item = noone;
					if (array_length(free_hands) == 0) { 
						new_item = instance_create(player.x, player.y, contents_obj);
						with (new_item) { become_dropped(id); }
					}
					else {
						new_item = create_item_in_hand(array_random_pop(free_hands), contents_obj);
					}
					
					if (contents_is_special) { with new_item { make_item_special(); } }
				}
			}
		}
	}
}
