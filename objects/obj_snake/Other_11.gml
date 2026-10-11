/// @description End Step
var _move_speed = get_random_chance_out_of(SNAKE_MOVE_FREQUENCY) ? 2 : 1;
var _prev_dir = dir, _prev_image_xscale = image_xscale;
move_snake(_move_speed);
	
if (get_random_chance_out_of(SNAKE_HISS_FREQUENCY)) { play_sound(snd_hiss, false); }

if (_prev_dir == dir) { image_xscale = -_prev_image_xscale; }
else { image_xscale = 1; image_yscale = 1; image_angle = dir * -90; }
	
event_inherited();
