/// @description End Step
event_inherited();

depth = SOLID_DEPTH;
for (var quadrant = 0; quadrant < array_length(parts); quadrant++;) {
	if (!parts[quadrant].illusion_visible) { depth = BG_DEPTH; break; }
}
