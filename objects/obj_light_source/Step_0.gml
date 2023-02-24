if (can_process_this_frame()) {
	if (is_flickering_light_source) { flicker_value = -24 + irandom(50); }
	event_inherited();
}
