if (process_this_frame()) {
	event_inherited();

	if (!active) { active = !instance_place(x, y, global.player); }
}
