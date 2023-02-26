/// @description End Step
event_inherited();
	
if (headless && image_index == 2) { image_index = 3; }
	
if (is_covered_at_each_quadrant_by(obj_solid)) {
	play_sound(snd_crunch, true);
	instance_destroy(); 
}
