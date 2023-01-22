if (can_process_this_frame()) {
	event_inherited();

	if (!active) { active = !place_meeting(x, y, global.player); }
}
