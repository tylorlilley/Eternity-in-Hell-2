/// @description End Step
event_inherited();

depth = start_depth;
for (var quadrant = 0; quadrant < array_length(parts); quadrant++;) {
	if (!is_existing_instance(parts[quadrant]) || !parts[quadrant].part_visible) { depth = BG_DEPTH; break; }
}
