/// @description Test Mode - Remove Remaining Time
if (global.is_test_mode) {
	time_remaining -= 100;
	if (is_time_up()) {
		killed_by = (current_room.has_hall_of_mirrors) ? obj_mirror : obj_controller;
		global.player.dead = true;
		play_sound(snd_lose, false); 
	}
}