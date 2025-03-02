/// @description Step
var controller = global.controller, player = global.player, closed_this_frame = false;
var push_direction = get_direction_pushed_against();

if (!closed && push_direction != directions.none) {
	if (player.lost_left_hand && player.lost_right_hand) {
		kill_player(object_index);
		play_sound(snd_crunch, false);
		closed_this_frame = true;
		image_index = 0;
	}
	else {
		var occupied_hands = array_create(0);
		if (is_existing_instance(player.right_hand_item) && !player.lost_right_hand) { array_push(occupied_hands, directions.right); } 
		if (is_existing_instance(player.left_hand_item) && !player.lost_left_hand) { array_push(occupied_hands, directions.left); }
		array_shuffle(occupied_hands);
		
		if (array_length(occupied_hands) == 0) { play_sound(snd_locked, false); }
		else {
			play_sound(snd_crunch, false);
			closed_this_frame = true;
			image_index = 0;
	
			var chosen_hand = array_pop(occupied_hands);
			var old_item = (chosen_hand == directions.right) ? player.right_hand_item : player.left_hand_item;
			with (player) { 
				play_sound(snd_infect_player, true); 
				put_down_item(old_item, true, true); 
			}
			controller.current_room.add_to_instances_at_map_positions(id);
			contents_obj = old_item.object_index;
			if (chosen_hand == directions.right) { player.lost_right_hand = true; }
			else if (chosen_hand == directions.left) { player.lost_left_hand = true; }
			with old_item { instance_destroy(); }
			controller.evaluation_manager.increment_evaluation_variable("red_chest_room_solved");
		}
	}
}

event_inherited();

if (closed_this_frame) { closed = true; }