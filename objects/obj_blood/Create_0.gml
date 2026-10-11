event_inherited();

randomize_image(3);
depth = BLOOD_DEPTH;

// Sometimes a player's corpse lies here in place of the blood
if (get_random_chance_out_of(CORPSE_REPLACEMENT_PROBABILITY)) { 
	instance_create(x, y, obj_player_corpse);
	instance_destroy();
}