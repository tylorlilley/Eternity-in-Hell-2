
var player = global.player;

if (infectious && is_existing_instance(player) && get_distance_to_instance(player) <= 4) {
	global.controller.evaluation_manager.increment_evaluation_variable("times_infected");
	with (player) {
		infected_timer += PLAYER_INFECTED_TIMER;
		bug_sound_timer = 12;
		play_sound(snd_red_bug_start, true);
	}
}