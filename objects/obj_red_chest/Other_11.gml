/// @description Step
var _controller = global.controller, _player = global.player, _closed_this_frame = false;
var _push_direction = get_direction_pushed_against();

if (!closed && _push_direction != directions.none) {
	if (_player.lost_left_hand && _player.lost_right_hand) {
		kill_player(object_index);
		play_sound(snd_crunch, false);
		_closed_this_frame = true;
		image_index = 0;
	}
	else {
		var _occupied_hands = [];
		if (is_existing_instance(_player.right_hand_item) && !_player.lost_right_hand) { array_push(_occupied_hands, directions.right); } 
		if (is_existing_instance(_player.left_hand_item) && !_player.lost_left_hand) { array_push(_occupied_hands, directions.left); }
		array_shuffle(_occupied_hands);
		
		if (array_length(_occupied_hands) == 0) { play_sound(snd_locked, false); }
		else {
			play_sound(snd_crunch, false);
			_closed_this_frame = true;
			image_index = 0;
	
			var _chosen_hand = array_pop(_occupied_hands);
			var _old_item = (_chosen_hand == directions.right) ? _player.right_hand_item : _player.left_hand_item;
			with (_player) { 
				play_sound(snd_infect_player, true); 
				put_down_item(_old_item, true, true); 
			}
			_controller.current_room.add_to_instances_at_map_positions(id);
			contents_obj = _old_item.object_index;
			if (_chosen_hand == directions.right) { _player.lost_right_hand = true; }
			else if (_chosen_hand == directions.left) { _player.lost_left_hand = true; }
			with _old_item { instance_destroy(); }
			_controller.evaluation_manager.increment_evaluation_variable("red_chest_room_solved");
		}
	}
}

event_inherited();

if (_closed_this_frame) { closed = true; }