if (process_this_frame()) {
	event_inherited();

	if (activated) { check_for_player_collision(); }
}
