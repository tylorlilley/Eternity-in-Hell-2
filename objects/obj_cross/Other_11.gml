/// @description Step
var player = global.player;
event_inherited();

if (are_all_collectables_collected() || instance_number(obj_echo_generator) > 0) { image_speed = get_one_unit_of_game_time(); }
else { image_index = 0; image_speed = 0; }
if (is_instance_at_coordinates(x, y, player)) {
	with (player) {
		if (is_carrying_item(obj_heart) && are_all_collectables_collected()) { 
			global.controller.completion_amount += 1;
			global.controller.final_player_right_hand_item = (is_existing_instance(right_hand_item)) ? right_hand_item.object_index : noone;
			global.controller.final_player_left_hand_item = (is_existing_instance(left_hand_item)) ? left_hand_item.object_index : noone;
			play_sound(snd_win, false); 
			instance_destroy(other.id);
		}
		else { 
			with (obj_echo_generator) { 
				global.controller.inverted_cross_room_solved += 1;
				write_debug_message("hall_of_mirrors_room_solved += 1", "Eval");
				play_sound(snd_impact, false); 
				instance_destroy(); 
			} 
		}
	}
}

if (!visible && !place_meeting(x, y, obj_player)) {
	visible = true;
	play_sound(snd_move, false);
}