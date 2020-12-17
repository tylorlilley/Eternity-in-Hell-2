if (process_this_frame()) {
	event_inherited();

	if (interact_with_torches()) { light_lantern(false); }
}
