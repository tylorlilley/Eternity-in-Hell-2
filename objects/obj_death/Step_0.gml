if (process_this_frame()) {
	event_inherited();

	if (lethal &&  instance_place(x, y, global.player) != noone && !global.player.dead) {
		check_for_player_collision();
	}
}
