event_inherited();
depth = LAVA_DEPTH;

// Set up single death box for normal use case
death_box = global.game_manager; 
if (global.controller != noone) {
	death_box = instance_create(x, y, obj_death);
	death_box.creator = id;
	death_boxes = noone;
}

// Set up lava edge tiles
var edge_type = global.lava_edge_type;
if (edge_type != lava_edge_types.none) {
	lava_edge_sprite_index = spr_lava_edge;
	lava_edge_image_indexes = [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]];
	lava_edge_image_xscales = [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]];
	lava_edge_visible = [[false, false, false, false], [false, false, false, false], [false, false, false, false], [false, false, false, false]];
	
	
	if (edge_type == lava_edge_types.wavy_still || edge_type == lava_edge_types.wavy_animated) {
		for (var quadrant = 0; quadrant < 4; quadrant++) {
			for (var dir = 0; dir < 4; dir++) {
				
			}
		}
	}
}
