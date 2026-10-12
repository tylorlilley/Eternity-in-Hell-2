/// @function								initialize_tile();
function initialize_tile() {
	// Set up the solid for each quadrant of this wall
	for (var _quadrant = 0; _quadrant < 4; _quadrant++;) {
		var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);

		parts[_quadrant] = instance_create(_x_pos, _y_pos, part_obj_index);
		with (parts[_quadrant]) { creator = other.id; }
	}
}

/// @function								initialize_door();
function initialize_door() { 
	// Create a half wall in each direction of this door that needs it
	for (var _dir = directions.up; _dir < directions.stairs; _dir++;) {
		var _x_offset = 0, _y_offset = 0;
		switch (_dir) {
			case directions.up: { _y_offset -= 8; break; }
			case directions.down: { _y_offset += 8; break; }
			case directions.left: { _x_offset -= 8; break; }
			case directions.right: { _x_offset += 8; break; }
		}
		
		if (!place_meeting(x+(2*_x_offset), y+(2*_y_offset), obj_wall) || place_meeting(x+_x_offset, y+_y_offset, obj_wall)) { continue; }

		// Create a half wall in this direction
		var _wall = instance_create(x+_x_offset, y+_y_offset, obj_wall_part);
		with (_wall) {
			initialize_tile();
			for (var _quadrant = 0; _quadrant < directions.stairs; _quadrant++;) {
				var _solid_at_quadrant = parts[_quadrant];
				if (!is_existing_instance(_solid_at_quadrant)) { continue; }
				
				var _dist_to_solid = point_distance(other.x, other.y, _solid_at_quadrant.x, _solid_at_quadrant.y);
				if (_dist_to_solid > 8) { continue; }

				with (_solid_at_quadrant) { instance_destroy(); }
				parts[_quadrant] = noone;
			}
		}
	}
}

/// @function								destroy_lava_at_position(_x_pos, _y_pos);
/// @param		{real} _x_pos				The x position of the quadrant to destroy
/// @param		{real} _y_pos				The y position of the quadrant to destroy
function destroy_lava_at_position(_x_pos, _y_pos) {
	for (var _quadrant = 0; _quadrant < 4; _quadrant++;) {
	    if (is_instance_at_coordinates(_x_pos, _y_pos, parts[_quadrant])) {
	        with parts[_quadrant] { 
				mark_current_room_for_grid_update();
				instance_destroy(); 
			}
			parts[_quadrant] = noone;
			return true;
	    }
	}
	
	return false;
}

/// @ function								consume_lava(require_all);
/// @param		{bool} _require_all			Only consume whole chunks of lava at once
function consume_lava(_require_all) {
	var _lava_at_quadrant = get_instance_at_each_quadrant(obj_lava_part);
	if (!_require_all || is_covered_at_each_quadrant_by(obj_lava)) {
		var _consumed = false;
		for (var _quadrant = 0; _quadrant < 4; _quadrant++) {
			var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);
			
			with _lava_at_quadrant[_quadrant].creator { 
				_consumed = destroy_lava_at_position(_x_pos, _y_pos) || _consumed;
			}
		}
		
		if (_consumed) {
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
function set_up_lava_edge_visibility(_first_time_setup) {
	var _edge_type = global.lava_edge_type, _is_wavy_edge_type = (_edge_type == lava_edge_types.wavy_still || _edge_type == lava_edge_types.wavy_animated)
	if (_edge_type == lava_edge_types.none) { lava_edge_visible = [[false, false, false, false], [false, false, false, false], [false, false, false, false], [false, false, false, false]]; return; }
	else if (_first_time_setup) { lava_edge_sprite_index = (_is_wavy_edge_type) ? spr_lava_edge3 : spr_lava_edge; }
	
	mask_index = spr_collectable;
	for (var _quadrant = 0; _quadrant < 4; _quadrant++) {
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			if (_first_time_setup) { 
				var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);
				
				if (!_is_wavy_edge_type) {
					lava_edge_image_indexes[_quadrant][_dir] = irandom(7);
					lava_edge_image_xscales[_quadrant][_dir] = (get_coin_flip()) ? 1 : -1;
				}
				else {
					lava_edge_image_indexes[_quadrant][_dir] = (((_x_pos-4)/8) % 4) + (((_y_pos-4)/8) % 4) % 7;
					lava_edge_image_xscales[_quadrant][_dir] = 1;
				}
			
				// Skip edges within the lava object on first time setup
				if ((_quadrant == 0 && (_dir == directions.right || _dir == directions.down)) ||
					(_quadrant == 1 && (_dir == directions.left || _dir == directions.down)) ||
					(_quadrant == 2 && (_dir == directions.right || _dir == directions.up)) ||
					(_quadrant == 3 && (_dir == directions.left || _dir == directions.up))) {
					continue; 
				}
			}
			
			var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);
			switch (_dir) {
				case directions.up: { _y_pos -= 8; break; }
				case directions.right: { _x_pos += 8; break; }
				case directions.down: { _y_pos += 8; break; }
				case directions.left: { _x_pos -= 8; break; }
			}
			
			lava_edge_visible[_quadrant][_dir] = !is_lava_at_position(_x_pos, _y_pos);
			if (!is_existing_instance(parts[_quadrant])) { lava_edge_visible[_quadrant][_dir] = false; }
		}
	}
	mask_index = -1;
}

/// @function  							open_door();
function open_door() {
	image_index = 1;

	with closed { instance_destroy(); }
	closed = noone;
	depth = CROSS_DEPTH;
	
	mark_current_room_for_grid_update();
	
	if (door_for_exit != -1 && door_for_exit.exit_type == exit_types.locked_doors) {
		door_for_exit.unlock();
		with (global.player) { 
			play_sound(snd_mana, true);
			with (get_carried_item(obj_key)) { if (!special) { instance_destroy(); } }
			increment_run_stat("unlocked_doors");
		}
	}
}

/// @function							close_door();
function close_door() {
	image_index = 0;
	
	closed = instance_create(x, y, obj_solid);
	closed.visible = false;
	depth = SOLID_DEPTH;
	
	mark_current_room_for_grid_update();
}

/// @function							open_portcullis();
function open_portcullis() {
	door_for_exit.open_portcullis();
	stuck_open = true;
	open_door();
}

/// @function								break_heart_case();
///	@param		{bool}	  destroy_self		Whether to flash the screen or not
function break_heart_case(_has_screen_flash) {
	instance_create(x, y, obj_dirt);
	var _new_plate = instance_create(x, y, obj_heart_plate);
	var _new_heart = instance_create(x, y, obj_heart);
	_new_heart.image_index = image_index;
	global.controller.current_room.add_to_instances_at_map_positions(_new_heart);
	instance_destroy();
	
	if (_has_screen_flash) { with (_new_plate) { screen_flash(); } }
}