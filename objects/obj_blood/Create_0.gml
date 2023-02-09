event_inherited();

randomize_image(3);
depth = BLOOD_DEPTH;

if (get_random_chance_out_of(CORPSE_REPLACEMENT_PROBABILITY)) { 
	instance_create(x, y, obj_player_corpse);
	instance_destroy();
}