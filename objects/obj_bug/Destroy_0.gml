
var player = global.player;

if (infectious && is_existing_instance(player) && get_distance_to_instance(player) <= 4) {
	global.controller.times_infected += 1;
	write_debug_message("times_infected += 1", "Eval");
	with (player) {
		infected_timer += PLAYER_INFECTED_TIMER;
		bug_sound_timer = 12;
		play_sound(snd_red_bug_start, true);
	}
}