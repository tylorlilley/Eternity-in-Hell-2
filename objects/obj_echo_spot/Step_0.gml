event_inherited();

if (spawn_timer > 0) { 
	spawn_timer -= 1;
	if (spawn_timer == 0) { 
		if (array_length(moves) > 1) {
			var echo = instance_create_depth(x, y, 0, obj_echo);
			echo.generator = id;
			play_sound(initialized ? snd_announce : snd_echo, false);
			initialized = true;
			spawn_timer = 128+56;
		}
		else { spawn_timer = 16; }
	}
}