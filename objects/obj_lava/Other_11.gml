/// @description Step
event_inherited();

// Update lighting information
update_lava_lighting();

// Update edge image information
var _edge_type = global.lava_edge_type;
if (_edge_type == lava_edge_types.fuzzy_animated || _edge_type == lava_edge_types.wavy_animated) {
	for (var _quadrant = 0; _quadrant < 4; _quadrant++) {
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			if (_edge_type == lava_edge_types.wavy_animated) {
				lava_edge_image_indexes[_quadrant][_dir] += 1;
				if ((lava_edge_image_indexes[_quadrant][_dir]) > 7) { lava_edge_image_indexes[_quadrant][_dir] = 0; }
			}
			if (_edge_type == lava_edge_types.fuzzy_animated) {
				lava_edge_image_indexes[_quadrant][_dir] = irandom(7);
				lava_edge_image_xscales[_quadrant][_dir] = (get_coin_flip()) ? 1 : -1;
			}
		}
	}
}
	
// Randomize visual
rotate_sprite_to_random_angle();
flip_sprite_at_random(true);