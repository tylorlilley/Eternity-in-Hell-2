event_inherited();

start_depth = LAVA_DEPTH;
part_obj_index = obj_lava_part;

// Set up lighting variables
lighting_distance = LAVA_LIGHT_RANGE;
intensity = 0.125 + irandom(0.35-0.125);
maximum_intensity = 1;
minimum_intensity = 0;

// Set up lava edge tiles
lava_edge_sprite_index = spr_lava_edge;
lava_edge_image_indexes = [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]];
lava_edge_image_xscales = [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]];
lava_edge_visible = [[false, false, false, false], [false, false, false, false], [false, false, false, false], [false, false, false, false]];
