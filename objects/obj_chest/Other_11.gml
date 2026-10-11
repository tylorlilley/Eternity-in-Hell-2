/// @description Step
event_inherited();
	
// The player opens a closed chest by pushing against it, once they've unlocked it with a key if it's locked
if closed {
	var _controller = global.controller, _player = global.player;
	var _push_direction = get_direction_pushed_against(), _carrying_key = false, _carrying_lit_torch = false;
	with (_player) { _carrying_key = is_carrying_item(obj_key); _carrying_lit_torch = is_carrying_lit_torch(false); }
	if (locked) { image_index = 2; }
	if (_push_direction != directions.none) {
		if (locked && !_carrying_key) { play_sound(snd_locked, false); }
		// Unlock it with the player's key, which is used up unless it's special
		else if (locked) {
			locked = false;
			image_index = 0;
			with (global.player) { 
				play_sound(snd_mana, true);
				with (get_carried_item(obj_key)) { if (!special) { instance_destroy(); } }
				_controller.evaluation_manager.increment_evaluation_variable("unlocked_chests");
			}
		}
		else {
			// Set up which inventory slots are available
			var _free_hands = [];
			if (!is_existing_instance(_player.right_hand_item) && !_player.lost_right_hand) { array_push(_free_hands, directions.right); } 
			if (!is_existing_instance(_player.left_hand_item) && !_player.lost_left_hand) { array_push(_free_hands, directions.left); } 
			
			// Try to open the chest. With no free hand its item drops at the player's feet, so it stays shut while they stand in
			// a solid.
			if (array_length(_free_hands) == 0 && place_meeting(_player.x, _player.y, obj_solid)) { play_sound(snd_locked, false); }
			else {
				closed = false;
				image_index = 1;
				// A trapped chest turns into a statue facing the player, or a fountain
				if (contents_obj == obj_statue) {
					_controller.evaluation_manager.increment_evaluation_variable("trapped_chests_opened");
					play_sound(snd_skeletonrise, true);
					var _statue = instance_create(x, y, obj_statue);
					_statue.dir = get_opposite_dir(_push_direction);
					_statue.image_angle = _statue.dir * -90;
					_statue.shoot_timer += 2;
					_statue.trap = true;
					instance_destroy();
				}
				else if(contents_obj == obj_fountain) {
					_controller.evaluation_manager.increment_evaluation_variable("trapped_chests_opened");
					play_sound(snd_skeletonrise, true);
					var _fountain = instance_create(x, y, obj_fountain);
					_fountain.shoot_timer += 2;
					_fountain.trap = true;
					instance_destroy();
				}
				else if (contents_obj != -1) { 
					_controller.evaluation_manager.increment_evaluation_variable("chests_opened");
					_controller.current_room.remove_from_instances_at_map_positions(id);
					
					with (_player) {
						play_sound(snd_open, true);
						play_sound(snd_pickup, false);
					}
					
					// Put the item in a random free hand, or drop it at the player's feet when they have none
					var _new_item = noone;
					if (array_length(_free_hands) == 0) { 
						_new_item = instance_create(_player.x, _player.y, contents_obj);
						with (_new_item) { become_dropped(id); }
						if (contents_obj == obj_bomb && _carrying_lit_torch) {
							_controller.evaluation_manager.increment_evaluation_variable("chests_opened_lit_bombs");
						}
					}
					else {
						_new_item = create_item_in_hand(array_random_pop(_free_hands), contents_obj);
					}
					
					if (contents_is_special) { with _new_item { make_item_special(); } }
				}
			}
		}
	}
}
