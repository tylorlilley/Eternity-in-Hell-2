/// @description Step
event_inherited();

visible = true;
flicker_sprite_under_instance(global.player);
flicker_sprite_under_instance(obj_enemy);
flicker_sprite_under_instance(obj_fireball);
	
/*
else if (get_random_chance_out_of(ILLUSION_WALL_FLICKER_FREQUENCY)) { visible = false; play_sound(snd_flicker, false); }
else { visible = true; }
*/