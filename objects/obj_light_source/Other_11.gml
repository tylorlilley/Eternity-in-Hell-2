/// @description Step
// A flickering light's distance shifts by -1, 0 or 1 dimming steps from its range at random, every game step
if (is_flickering_light_source) { flicker = floor((-24 + irandom(50))/25); }
lighting_distance = (lighting_range + flicker);
	
event_inherited();
