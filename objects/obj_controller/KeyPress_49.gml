/// @description Test Mode - Complete Game
if (global.is_test_mode) {
	completion_amount = TOTAL_COMPLETION_AMOUNT;
	with (global.player) {
		global.controller.final_player_right_hand_item = (is_existing_instance(right_hand_item)) ? right_hand_item.object_index : noone;
		global.controller.final_player_left_hand_item = (is_existing_instance(left_hand_item)) ? left_hand_item.object_index : noone;
	}
	play_sound(snd_win, false); 
}