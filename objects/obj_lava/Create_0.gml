event_inherited();

depth = LAVA_DEPTH;
part_obj_index = obj_lava_part;

// Set up lighting variables
initialize_lava_lighting()

// Set up lava edge tiles
lava_edge_sprite_index = spr_lava_edge;
lava_edge_image_indexes = [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]];
lava_edge_image_xscales = [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]];
lava_edge_visible = [[false, false, false, false], [false, false, false, false], [false, false, false, false], [false, false, false, false]];

//set_up_lava_edge_visibility(true);