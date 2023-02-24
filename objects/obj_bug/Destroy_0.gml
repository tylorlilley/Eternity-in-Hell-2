var player = global.player;

if (infectious && is_existing_instance(player) && get_distance_to_instance(player) <= 4) {
	with (player) {
		infected_timer += PLAYER_INFECTED_TIMER;
		play_sound(snd_infect_player, true);
	}
}