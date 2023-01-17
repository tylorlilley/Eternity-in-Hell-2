if (process_this_frame()) {
	event_inherited();

	if (lethal) { check_for_player_collision(); }
}
