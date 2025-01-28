/// @description Step
var player = global.player;

if (infectious && is_existing_instance(player) && get_distance_to_instance(player) <= 4) {
	with (player) {
		infected_timer += PLAYER_INFECTED_TIMER;
		bug_sound_timer = 12;
		play_sound(snd_red_bug_start, true);
	}
}