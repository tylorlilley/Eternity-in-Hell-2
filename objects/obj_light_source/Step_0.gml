if (can_process_this_frame()) {
	if (is_flickering_light_source) { flicker = floor((-24 + irandom(50))/25); }
	lighting_distance = (lighting_range + flicker);
	
	event_inherited();
}
