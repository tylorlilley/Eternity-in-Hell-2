/// @description Step

event_inherited();

// It starts spawning once it has recorded more than one player move for the echoes to repeat. After that, it spawns an
// echo at its own position each time the timer runs out
if (!spawning) { spawning = (array_length(moves) > 1); }
else if (spawn_timer > 0) { 
	spawn_timer -= 1;
	if (spawn_timer == 0) {
		var _echo = instance_create(x, y, obj_echo);
		_echo.generator = id;
		play_sound(snd_echo_spawn, false);
		spawn_timer = ECHO_SPAWN_FREQUENCY;
	}
}