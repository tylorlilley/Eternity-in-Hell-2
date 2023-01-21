event_inherited();

randomize_image(3);
depth = 7;

if (get_random_chance_out_of(global.controller.CORPSE_REPLACEMENT_PROBABILITY)) { 
	instance_create_depth(x, y, 0, obj_player_corpse);
	instance_destroy();
}