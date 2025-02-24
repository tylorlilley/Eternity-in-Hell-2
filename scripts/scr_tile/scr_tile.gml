/// @function								initialize_tile();
function initialize_tile() {
	// Set up the solid for each quadrant of this wall
	for (var quadrant = 0; quadrant < 4; quadrant++;) {
		var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);

		parts[quadrant] = instance_create(x_pos, y_pos, part_obj_index);
		with (parts[quadrant]) { creator = other.id; }
	}
}

/// @function								initialize_door();
function initialize_door() { 
	// Create a half wall in each direction of this door that needs it
	for (var dir = directions.up; dir < directions.stairs; dir++;) {
		var x_offset = 0, y_offset = 0, quadrants_to_delete = array_create(0);
		switch (dir) {
			case directions.up: { y_offset -= 8; quadrants_to_delete = [2, 3]; break; }
			case directions.down: { y_offset += 8; quadrants_to_delete = [0, 1]; break; }
			case directions.left: { x_offset -= 8; quadrants_to_delete = [1, 3]; break; }
			case directions.right: { x_offset += 8; quadrants_to_delete = [0, 2]; break; }
		}
		
		if (!place_meeting(x+(2*x_offset), y+(2*y_offset), obj_solid) || place_meeting(x+x_offset, y+y_offset, obj_solid)) { continue; }

		// Create a half wall in this direction
		var wall = instance_create(x+x_offset, y+y_offset, obj_wall_part);
		with (wall) {
			initialize_tile();
			for (var quadrant = 0; quadrant < directions.stairs; quadrant++;) {
				var solid_at_quadrant = parts[quadrant];
				if (!is_existing_instance(solid_at_quadrant)) { continue; }
				
				var dist_to_solid = point_distance(other.x, other.y, solid_at_quadrant.x, solid_at_quadrant.y);
				if (dist_to_solid > 8) { continue; }

				with (solid_at_quadrant) { instance_destroy(); }
				parts[quadrant] = noone;
			}
		}
	}
}

/// @function								destroy_lava_at_position(x_pos, y_pos);
/// @param		{real} x_pos				The x position of the quadrant to destroy
/// @param		{real} y_pos				The y position of the quadrant to destroy
function destroy_lava_at_position(x_pos, y_pos) {
	for (var quadrant = 0; quadrant < 4; quadrant++;) {
	    if (is_instance_at_coordinates(x_pos, y_pos, parts[quadrant])) {
	        with parts[quadrant] { 
				mp_path_grid_remove(global.controller.current_room.lava_path_grid);
				global.controller.grid_update_timer = 2;
				instance_destroy(); 
			}
			parts[quadrant] = noone;
			return true;
	    }
	}
	
	return false;
}

/// @ function								consume_lava(require_all);
/// @param		{bool} require_all			Only consume whole chunks of lava at once
function consume_lava(require_all) {
	var lava_at_quadrant = get_instance_at_each_quadrant(obj_lava_part);
	if (!require_all || is_covered_at_each_quadrant_by(obj_lava)) {
		var consumed = false;
		for (var quadrant = 0; quadrant < 4; quadrant++) {
			var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
			
			with lava_at_quadrant[quadrant].creator { 
				consumed = destroy_lava_at_position(x_pos, y_pos) || consumed;
			}
		}
		
		if (consumed) {
			play_sound(snd_splash, false);
			with (obj_lava) {
				if (get_distance_to_instance(other) <= 32) {
					//set_up_lava_edge_visibility(false);
				}
			}
			return true;
		}
	}
	return false;
}

/// @ function								set_up_lava_edge_visibility(require_all);
/// @param		{bool} visibility_only		Only change the visibility status
function set_up_lava_edge_visibility(first_time_setup) {
	var edge_type = global.lava_edge_type, is_wavy_edge_type = (edge_type == lava_edge_types.wavy_still || edge_type == lava_edge_types.wavy_animated)
	if (edge_type == lava_edge_types.none) { lava_edge_visible = [[false, false, false, false], [false, false, false, false], [false, false, false, false], [false, false, false, false]]; return; }
	else if (first_time_setup) { lava_edge_sprite_index = (is_wavy_edge_type) ? spr_lava_edge3 : spr_lava_edge; }
	
	sprite_index = spr_collectable;
	for (var quadrant = 0; quadrant < 4; quadrant++) {
		for (var dir = directions.up; dir < directions.stairs; dir++) {
			if (first_time_setup) { 
				var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
				
				if (!is_wavy_edge_type) {
					lava_edge_image_indexes[quadrant][dir] = irandom(7);
					lava_edge_image_xscales[quadrant][dir] = (get_coin_flip()) ? 1 : -1;
				}
				else {
					lava_edge_image_indexes[quadrant][dir] = (((x_pos-4)/8) % 4) + (((y_pos-4)/8) % 4) % 7;
					lava_edge_image_xscales[quadrant][dir] = 1;
				}
			
				// Skip edges within the lava object on first time setup
				if ((quadrant == 0 && (dir == directions.right || dir == directions.down)) ||
					(quadrant == 1 && (dir == directions.left || dir == directions.down)) ||
					(quadrant == 2 && (dir == directions.right || dir == directions.up)) ||
					(quadrant == 3 && (dir == directions.left || dir == directions.up))) {
					continue; 
				}
			}
			
			var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
			switch (dir) {
				case directions.up: { y_pos -= 8; break; }
				case directions.right: { x_pos += 8; break; }
				case directions.down: { y_pos += 8; break; }
				case directions.left: { x_pos -= 8; break; }
			}
			
			lava_edge_visible[quadrant][dir] = !is_lava_at_position(x_pos, y_pos);
			if (!is_existing_instance(parts[quadrant])) { lava_edge_visible[quadrant][dir] = false; }
		}
	}
	sprite_index = spr_lava;
}

/// @function  							open_door();
function open_door() {
	image_index = 1;

	with closed { instance_destroy(); }
	closed = noone;
	depth = CROSS_DEPTH;
	
	var current_room = global.controller.current_room;	
	current_room.reset_room_solid_path_grid(); 
	current_room.reset_room_lava_path_grid();
	
	if (door_for_exit != -1 && door_for_exit.has_lock) {
		door_for_exit.unlock();
		with (global.player) { 
			play_sound(snd_mana, true);
			with (get_carried_item(obj_key)) { if (!special) { instance_destroy(); } }
			global.controller.unlocked_doors += 1;
			write_debug_message("unlocked_doors += 1", "Eval"); 
		}
	}
}

/// @function							close_door();
function close_door() {
	image_index = 0;
	
	closed = instance_create(x, y, obj_solid);
	closed.visible = false;
	depth = SOLID_DEPTH;
	
	var current_room = global.controller.current_room;
	current_room.reset_room_solid_path_grid(); 
	current_room.reset_room_lava_path_grid();
}

/// @function							open_portcullis();
function open_portcullis() {
	door_for_exit.open_portcullis();
	stuck_open = true;
	open_door();
}

/// @function								break_heart_case();
///	@param		{bool}	  destroy_self		Whether to flash the screen or not
function break_heart_case(has_screen_flash) {
	instance_create(x, y, obj_dirt);
	var new_plate = instance_create(x, y, obj_heart_plate);
	var new_heart = instance_create(x, y, obj_heart);
	new_heart.image_index = image_index;
	global.controller.current_room.add_to_instances_at_map_positions(new_heart);
	instance_destroy();
	
	if (has_screen_flash) { with (new_plate) { screen_flash(); } }
}