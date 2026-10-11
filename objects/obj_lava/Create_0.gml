event_inherited();

depth = LAVA_DEPTH;
// The kind of part that fills each of its four quadrants, which kills whatever touches it
part_obj_index = obj_lava_part;

// Lava glows as a dim, flickering light source
initialize_lava_lighting()

// How the edge on each side of each quadrant looks, indexed by quadrant then side: the sprite, each edge's frame and
// flip, and whether it shows. Room setup fills these in (see set_up_lava_edge_visibility)
lava_edge_sprite_index = spr_lava_edge;
lava_edge_image_indexes = [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]];
lava_edge_image_xscales = [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]];
lava_edge_visible = [[false, false, false, false], [false, false, false, false], [false, false, false, false], [false, false, false, false]];
