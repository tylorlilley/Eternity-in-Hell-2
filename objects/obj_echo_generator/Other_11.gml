/// @description Step

event_inherited();

if (!spawning) { spawning = (array_length(moves) > 1); }
else if (spawn_timer > 0) { 
	spawn_timer -= 1;
	if (spawn_timer == 0) {
		var echo = instance_create(x, y, obj_echo);
		echo.generator = id;
		play_sound(snd_echo_spawn, false);
		spawn_timer = ECHO_SPAWN_FREQUENCY;
	}
}