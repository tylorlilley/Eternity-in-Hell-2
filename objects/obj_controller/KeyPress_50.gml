/// @description Test Mode - Remove 100 Seconds
if (global.is_test_mode) {
	time_remaining -= 100;
	// Once time is up the player dies, killed by the clock (obj_controller), or by the mirror in a hall of mirrors
	if (is_time_up()) {
		killed_by = (current_room.has_hall_of_mirrors) ? obj_mirror : obj_controller;
		global.player.dead = true;
		play_sound(snd_lose, false); 
	}
}