event_inherited();

// A path tile, left where a block fills in lava (see obj_block). It starts at the depth of dirt, turned and flipped at
// random; the block then moves it above the lava and copies its own turn and flip onto it
depth = DIRT_DEPTH;
rotate_sprite_to_random_angle();
flip_sprite_at_random(true);
