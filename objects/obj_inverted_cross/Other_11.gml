/// @description Step
// When the player steps on it, it is replaced by an echo generator (its echoes repeat the player's moves) and dirt
if (is_existing_instance(global.player) && x == global.player.x && y == global.player.y) { 
	instance_create(x, y, obj_echo_generator); 
	instance_create(x, y, obj_dirt); 
	play_sound(snd_echo, true);
	screen_flash();
	instance_destroy();
}
