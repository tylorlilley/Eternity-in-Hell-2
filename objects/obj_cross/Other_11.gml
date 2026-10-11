/// @description Step
var _player = global.player;
event_inherited();

// Animate once every collectable is collected, or while the room has an echo generator
if (are_all_collectables_collected() || instance_number(obj_echo_generator) > 0) { image_speed = get_one_unit_of_game_time(); }
else { image_index = 0; image_speed = 0; }
// Bringing the heart to the cross once every collectable is collected wins the game, remembering the player's items.
// Otherwise, stepping on it destroys the echo generator, which solves an inverted cross room.
if (is_instance_at_coordinates(x, y, _player)) {
	with (_player) {
		var _heart = get_carried_item(obj_heart);
		if (instance_exists(_heart) && are_all_collectables_collected()) { 
			global.controller.completion_amount += 1;
			global.controller.final_player_right_hand_item = (is_existing_instance(right_hand_item)) ? right_hand_item.object_index : noone;
			global.controller.final_player_left_hand_item = (is_existing_instance(left_hand_item)) ? left_hand_item.object_index : noone;
			play_sound(snd_win, false); 
			if (_heart.special) {
				global.controller.evaluation_manager.increment_evaluation_variable("special_heart_victory");
			}
			instance_destroy(other.id);
		}
		else { 
			with (obj_echo_generator) { 
				global.controller.evaluation_manager.increment_evaluation_variable("inverted_cross_room_solved");
				play_sound(snd_impact, false); 
				instance_destroy(); 
			} 
		}
	}
}

// The cross starts hidden, and appears as soon as the player isn't standing on it
if (!visible && !place_meeting(x, y, obj_player)) {
	visible = true;
	play_sound(snd_move, false);
}