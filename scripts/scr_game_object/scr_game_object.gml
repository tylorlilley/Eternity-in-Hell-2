/// @function								get_distance_to_instance(_instance);
/// @param		{index} _instance			The instance whose distance away from the calling instance is to be calculated
function get_distance_to_instance(_instance) {
	if (!is_existing_instance(_instance)) { return -1; }
	if (id == _instance) { return 0; }

	return point_distance(x, y, _instance.x, _instance.y);
}

/// @function								is_instance_at_coordinates(_x_pos, _y_pos, _instance);
/// @param		{real}  _x_pos				The x value to check against the instance's x value
/// @param		{real}  _y_pos				The y value to check against the instance's y value
/// @param		{index} _instance			The instance whos positional coordinates are being checked
function is_instance_at_coordinates(_x_pos, _y_pos, _instance) {
	return (is_existing_instance(_instance) && (_instance.x == _x_pos && _instance.y == _y_pos))
}

/// @function								is_direction_towards(_dir, obj);
/// @param		{direction} _dir				The direction from the calling instance to check whether the given instance
/// @param		{instance} obj				The object to check for the direction of
function is_direction_towards(_dir, _inst) {
	return ((y > _inst.y && _dir == directions.up) ||
	        (x < _inst.x && _dir == directions.right) ||
	        (y < _inst.y && _dir == directions.down) ||
	        (x > _inst.x && _dir == directions.left));
}

/// @function								turn_to_face_player();
function turn_to_face_player() {
	var _target = get_dropped_meat();
	if (!is_existing_instance(_target)) { _target = global.player; }
	if (is_direction_towards(1, _target)) { image_xscale = -1; }
	else { image_xscale = 1; }
}

/// @function  							teleport_near_player();
function teleport_near_player() {
	var _target = get_dropped_meat(), _attempts = 0;
	if (!is_existing_instance(_target)) { _target = global.player; }
	
	play_sound(snd_flicker, false);

	do {
	    var _x_pos = (8*get_random_cardinal_dir());
	    var _y_pos = (8*get_random_cardinal_dir());
	    if (get_coin_flip()) { _x_pos *= -1; }
	    if (get_coin_flip()) { _y_pos *= -1; }
	    x = _target.x + _x_pos;
	    y = _target.y + _y_pos;
		_attempts += 1;
	}
	until (_attempts > 100 || (get_distance_to_instance(_target) >= 24 && !is_outside_room(x,y)));
}


/// @function								can_move_in_direction(_dir, _ignore_solid);
/// @param		{direction}	_dir				The direction to check whether the calling instance can move in
/// @param		{boolean} _ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} _ignore_death		Whether to ignore objects that cause death or not when performing this check
function can_move_in_direction(_dir, _ignore_solid, _ignore_death) {
	if (!_ignore_solid && is_solid_at_position(x, y)) { return false; }
	else { return (is_direction_free(_dir, _ignore_solid, _ignore_death)); }
}

/// @function								is_solid_at_position(_x_pos, _y_pos);
/// @param		{int} _x_pos					The x coordinate of the position
/// @param		{int} _y_pos					The y coordinate of the position
function is_solid_at_position(_x_pos, _y_pos) {
	var _solids = instance_place_all(_x_pos, _y_pos, obj_solid), _carrying_special_staff = false;
	if (object_index == obj_hands || object_index == obj_player) { _carrying_special_staff = is_carrying_special_item(obj_staff); }
	
	for (var _i = 0; _i < array_length(_solids); _i++) {
		var _current_solid = _solids[_i];
		if (_current_solid != id && (!_carrying_special_staff || (_current_solid.object_index != obj_solid_part && _current_solid.object_index != obj_wall && _current_solid.object_index != obj_column && _current_solid.object_index != obj_mirror))) { return true; }
	}
	return false;
}

/// @function								is_lava_at_position(_x_pos, _y_pos);
/// @param		{int} _x_pos					The x coordinate of the position
/// @param		{int} _y_pos					The y coordinate of the position
function is_lava_at_position(_x_pos, _y_pos) {
	if ((object_index == obj_hands || object_index == obj_player) && is_carrying_item(obj_staff)) { return false; }
	
	var _lava_parts_at_position = instance_place_all(_x_pos, _y_pos, obj_lava_part);
	while (array_length(_lava_parts_at_position) > 0) {
		var _lava_part_creator = array_random_pop(_lava_parts_at_position).creator;
		if (!is_existing_instance(_lava_part_creator) || _lava_part_creator.id != id) { return true; }
	}
	return false;
}

/// @function								is_direction_free(_dir, _ignore_solid);
/// @param		{direction}	_dir				The direction to check whether the calling instance can move in
/// @param		{boolean} _ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} _ignore_death		Whether to ignore objects that cause death or not when performing this check
function is_direction_free(_dir, _ignore_solid, _ignore_death) {
	var _x_pos = x, _y_pos = y;
	switch (_dir) {
		case directions.up: { _y_pos -= 8; break; }
		case directions.right: { _x_pos += 8; break; }
		case directions.down: { _y_pos += 8; break; }
		case directions.left: { _x_pos -= 8; break; }
		default: { return false; }
	}
	
	// Return as not free if blocked by room border
	var _blocked = is_on_room_border(_x_pos, _y_pos);
	if (!object_is_ancestor(object_index, obj_enemy) || can_move_on_border) { _blocked = false; }
	if (_blocked) { return false; }
	
	// Return as not free if blocked by room boundry
	_blocked = is_outside_room(_x_pos, _y_pos);
	if (object_index == obj_player && !place_meeting(x, y, obj_solid)) { _blocked = false; }
	if (_blocked) { return false; }
	
	// Return as not free if blocked by lava
	_blocked = (!_ignore_death && is_lava_at_position(_x_pos, _y_pos));
	if (_blocked) { return false; }
	
	// Return as not free if blocked by solid
	_blocked = (!_ignore_solid && is_solid_at_position(_x_pos, _y_pos));
	if (_blocked) { return false; }
	
	// return as free if not blocked by anything
	return true;
}

/// @function								is_outside_room(_x_pos, _y_pos);
/// @param		{int}	_x_pos				The x position to check
/// @param		{int}	_y_pos				The y position to check
function is_outside_room(_x_pos, _y_pos) {
	return (_x_pos <= 0 || _x_pos >= room_width || _y_pos <= 0 || _y_pos >= room_height);
}

/// @function								is_on_room_border(_x_pos, _y_pos);
/// @param		{int}	_x_pos				The x position to check
/// @param		{int}	_y_pos				The y position to check
function is_on_room_border(_x_pos, _y_pos) {
	var _target_exit_spots = instance_place_all(_x_pos, _y_pos, obj_exit_spot);
	if (array_length(_target_exit_spots) == 0) { return false; }
	
	// Check if target pos is on a type of exit spot this isn't already on
	var _on_exit_spots = instance_place_all(x, y, obj_exit_spot), _on_exit_types = [];
	while (array_length(_on_exit_spots) > 0) {
		var _next_exit_spot = array_pop(_on_exit_spots);
		array_push(_on_exit_types, _next_exit_spot.object_index);
	}
	var _on_border = false;
		while (array_length(_target_exit_spots) > 0) {
		var _next_exit_spot = array_pop(_target_exit_spots);
		if (!array_contains(_on_exit_types, _next_exit_spot.object_index)) { _on_border = true; break; }
	}

	return (_on_border);
}


/// @function								can_move_in_direction_and_reach(_dir, _ignore_solid);
/// @param		{direction}	_dir				The direction to check whether the calling instance can move in
/// @param		{index}	_target_instance		The instance we are trying to reach by moving in this direction
/// @param		{boolean} _ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} _ignore_death		Whether to ignore objects that cause death or not when performing this check
function can_move_in_direction_and_reach(_dir, _target_instance, _ignore_solid, _ignore_death) {
	if (!activated || !is_existing_instance(_target_instance)) { return false; }
	
	// Determine Move Directions
	var _x_change = 0, _y_change = 0;
	if (_dir == directions.up) { _y_change -= 8; } 
	else if (_dir == directions.right) { _x_change += 8; }
	else if (_dir == directions.down) { _y_change += 8; }
	else if (_dir == directions.left) { _x_change -= 8; }

	// Try Reaching Target in This Direction
    var _original_x = x, _original_y = y, _reached = false;
    var _max_steps = room_width div 8;   // can never need more than one room's width

    for (var _step = 0; _step < _max_steps; _step++) {
        if (!can_move_in_direction(_dir, _ignore_solid, _ignore_death)) { break; }
        x += _x_change;
        y += _y_change;
        if (is_instance_at_coordinates(x, y, _target_instance)) { _reached = true; break; }
    }

    x = _original_x;
    y = _original_y;
    return _reached;
}


/// @function								move_in_direction(_dir);
/// @param		{direction} _dir				The direction in which to move the calling instance
/// @param		{boolean} _make_noise		Whether or not to play a movement sound
function move_in_direction(_dir, _make_noise) {
	// Update position
	if (_dir == directions.up) { y -= 8; } 
	else if (_dir == directions.right) { x += 8; image_xscale = -1; }
	else if (_dir == directions.down) { y += 8; }
	else if (_dir == directions.left) { x -= 8; image_xscale = 1; }
	
	// Update image
	image_index += 1;
	if (image_index > 1) { image_index = 0; }
	
	if (object_is_ancestor(object_index, obj_enemy)) { 
		check_for_player_collision();
		if (floating && object_index != obj_hands) { _make_noise = false; }
	}
	
	// Make movement noises
	if (_make_noise) {
		var _snd = snd_walk;
		if (instance_place(x, y, obj_solid)) { _snd = snd_thud; play_sound(_snd, false); }
		if (instance_place(x, y, obj_lava_part)) { 
			_snd = snd_splash; 
			if (y > instance_place(x, y, obj_lava_part).y && !instance_place(x, y+8, obj_lava_part)) { _snd = snd_walk; }
			if (_snd == snd_splash) { play_sound(_snd, false); } // A step on the lava's lower edge is a footstep, which plays below
		}
		if (instance_place(x, y, obj_illusion_wall)) { _snd = snd_flicker; play_sound(_snd, false); }
		if (_snd == snd_walk) { play_sound(_snd, false); }
	}
	
	// Update mp_grids
	var _is_solid = (object_is_ancestor(object_index, obj_solid) || object_is_ancestor(object_index, obj_giant_worm_body));
	if (_is_solid) { mark_current_room_for_grid_update(); }
}


/// @function								set_instance_to_same_position(_instance);
/// @param		{index} _instance			The instance to set to the same position as the calling instance
function set_instance_to_same_position(_instance) {
	with _instance { 
	    x = other.x; 
	    y = other.y;
	}
}

/// @function								get_direction_pushed_against();
function get_direction_pushed_against() {
	var _dir = directions.none, _player = global.player, _x_pos = _player.x, _y_pos = _player.y;
	
	if (is_existing_instance(_player.moved_by)) { 
		return directions.none; 
	}
	
	_dir = get_direction_input(true);
	if (_dir == directions.none) { return _dir; }
	
	switch (_dir) {
		case directions.up: { _y_pos -= 16; break; }
		case directions.right: { _x_pos += 16; break; }
		case directions.down: { _y_pos += 16; break; }
		case directions.left: { _x_pos -= 16; break; }
	}
	
	if (!is_instance_at_coordinates(_x_pos, _y_pos, id)) { 
		_dir = directions.none; 
	}
	
	return _dir;
}

/// @function								rotate_sprite_to_random_angle();
function rotate_sprite_to_random_angle() {
	image_angle = get_random_cardinal_dir() * 90;
}

/// @function								flip_sprite_at_random(_flip_vertical);
/// @param		{boolean} _flip_vertical		Whether or not to also randomly flip the sprite vertically
function flip_sprite_at_random(_flip_vertical) {
	image_xscale = get_coin_flip() ? 1 : -1;
	if (_flip_vertical) { image_yscale = (get_coin_flip()) ? 1 : -1; }
}

/// @function								get_instance_at_each_quadrant(_obj_index);
///	@param		{index} _obj_index			The object type to return the presence of in each quadrant
function get_instance_at_each_quadrant(_obj_index) {
	var _presence_at_quadrant = [noone, noone, noone, noone];
	
	for (var _quadrant = 0; _quadrant < 4; _quadrant++;) {
        var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);
		_presence_at_quadrant[_quadrant] = instance_position(_x_pos, _y_pos, _obj_index);
    }
	
	return _presence_at_quadrant;
}

/// @function								is_covered_at_each_quadrant_by(_obj_index);
///	@param		{index} _obj_index			The object type to check the presence of in each quadrant
function is_covered_at_each_quadrant_by(_obj_index) {
	// Checking for lava is a special case, because the full lava object stays and blacks out
	// certain quadrants with individual quadrant death boxes due to the way blocks can destroy
	// multiple different lava's quadrants at once. Thus we need to use a special method that
	// Takes that into account.
	var _presence_at_quadrant = (_obj_index == obj_lava) ? get_instance_at_each_quadrant(obj_lava_part) : get_instance_at_each_quadrant(_obj_index);
	
	return (
		is_existing_instance(_presence_at_quadrant[0]) &&
		is_existing_instance(_presence_at_quadrant[1]) &&
		is_existing_instance(_presence_at_quadrant[2]) &&
		is_existing_instance(_presence_at_quadrant[3])
	);
}

/// @function								move_towards_coordinates(_target_x, _target_y, _ignore_solid, _ignore_death);
///	@param		{int} _target_x				The x position to be moving towards
///	@param		{int} _target_y				The y position to be moving towards
/// @param		{boolean} _ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} _ignore_death		Whether to ignore objects that cause death or not when performing this check
function move_towards_coordinates(_target_x, _target_y, _ignore_solid, _ignore_death) {	
	var _move_dir = get_random_possible_direction(_target_x, _target_y, _ignore_solid, _ignore_death);
	if (_move_dir != directions.none) { move_in_direction(_move_dir, true); }
	
	return _move_dir;
}

/// @function								get_random_possible_direction(obj_index);
///	@param		{int} _target_x				The x position to be moving towards
///	@param		{int} _target_y				The y position to be moving towards
/// @param		{boolean} _ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} _ignore_death		Whether to ignore objects that cause death or not when performing this check
function get_random_possible_direction(_target_x, _target_y, _ignore_solid, _ignore_death) {
	// Determine which directions are free to move in
	var _can_move_up = can_move_in_direction(directions.up, _ignore_solid, _ignore_death);
	var _can_move_right = can_move_in_direction(directions.right, _ignore_solid, _ignore_death);
	var _can_move_left = can_move_in_direction(directions.left, _ignore_solid, _ignore_death);
	var _can_move_down = can_move_in_direction(directions.down, _ignore_solid, _ignore_death);
	
	// Determine which directions one should move in to get closer to target
	var _possible_directions = [];
	if (y > _target_y && _can_move_up) { array_push(_possible_directions, directions.up); }
	if (x < _target_x && _can_move_right) { array_push(_possible_directions, directions.right); }
	if (y < _target_y && _can_move_down) { array_push(_possible_directions, directions.down); }
	if (x > _target_x && _can_move_left) { array_push(_possible_directions, directions.left); }
	
	// Return a random direction from among those possible
	var _move_dir = array_length(_possible_directions) > 0 ? array_random_get(_possible_directions) : directions.none;
	return _move_dir;
}

/// @function								randomize_image(_max_image_index);
///	@param		{int} _max_image_index		The max image_index value possible for this object's sprite
function randomize_image(_max_image_index) {
	image_index = irandom(_max_image_index);
	flip_sprite_at_random(true);
	rotate_sprite_to_random_angle();
}

/// @function								singleton_instance();
function singleton_instance() {
	if (instance_number(object_index) > 1) { instance_destroy(); }
}

/// @function								can_press_button();
function can_press_button() {	
	var _pressed = is_covered_at_each_quadrant_by(obj_solid) || is_instance_at_coordinates(x, y, global.player);
	if (!_pressed) { 
		var _enemies_at_position = instance_place_all(x, y, obj_enemy);
		while (array_length(_enemies_at_position) > 0) {
			var _enemy = array_random_pop(_enemies_at_position);
			if (!_enemy.floating && is_instance_at_coordinates(x, y, _enemy)) { _pressed = true; break; }
		}
	}
	
	return _pressed;
}

/// @function              get_sprite_shuffle_flip(_spr);
/// @description           Deterministic per-sprite coin flip, stable across resource reordering.
function get_sprite_shuffle_flip(_spr) {
    static cache = ds_map_create();
    static cache_seed = noone;

    // The flips depend on the seed, so a game with a new seed starts a new cache
    if (cache_seed != global.seed) {
        ds_map_clear(cache);
        cache_seed = global.seed;
    }
    if (ds_map_exists(cache, _spr)) { return cache[? _spr]; }

    var _nm = sprite_get_name(_spr), _hash = 0;
	for (var _i = 1; _i <= string_length(_nm); _i++) {
	    _hash = (_hash * 31 + ord(string_char_at(_nm, _i))) & 0x7FFFFFFF;
	}

    var _result = (((global.seed + _hash) % 2) == 0);
    cache[? _spr] = _result;
    return _result;
}

/// @function								get_sprite_to_use();
function get_sprite_to_use(_regular_sprite, _for_menu = false) {
	if (global.graphics_mode == graphics_modes.standard) { return _regular_sprite; }
	if (global.graphics_mode == graphics_modes.unknown) {
		if (_for_menu) { return _regular_sprite; } 
		var _chosen_sprite = noone;
		
		// Randomize Item Sprite
		if (array_contains(global.item_sprites, _regular_sprite)) {
			var _original_pos = array_get_index(global.item_sprites, _regular_sprite);
			_chosen_sprite = global.shuffled_item_sprites[_original_pos];
		}
		
		// Randomize Regular Enemy Sprite
		else if (array_contains(global.regular_enemy_sprites, _regular_sprite)) {
			var _original_pos = array_get_index(global.regular_enemy_sprites, _regular_sprite);
			_chosen_sprite = global.shuffled_regular_enemy_sprites[_original_pos];
		}
		
		// Randomize Rotational Enemy Sprites
		else if (array_contains(global.rotational_enemy_sprites, _regular_sprite)) {
			var _original_pos = array_get_index(global.rotational_enemy_sprites, _regular_sprite);
			_chosen_sprite = global.shuffled_rotational_enemy_sprites[_original_pos];
		}
		
		if (_chosen_sprite != noone) { return _chosen_sprite; }
		else if (get_sprite_shuffle_flip(_regular_sprite)) { return _regular_sprite; }
	}
	
	// Get Farmer Version of Regular Sprite
	static farmer_sprite_translation_map = -1;
	if (farmer_sprite_translation_map == -1) {
		farmer_sprite_translation_map = ds_map_create();
		/// Tiles
		ds_map_add(farmer_sprite_translation_map, spr_collectable, spr_collectable_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_bones, spr_bones_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_cross, spr_cross_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_inverted_cross, spr_inverted_cross_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_giant_wurm, spr_giant_wurm_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_block, spr_block_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_block_tile2, spr_block_tile_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_magic_beam, spr_magic_beam_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_red_chest, spr_red_chest_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_portcullis, spr_portcullis_farmer);
		
		/// Enemies
		ds_map_add(farmer_sprite_translation_map, spr_gudetama, spr_gudetama_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_skeleton, spr_skeleton_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_cockroach, spr_cockroach_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_fire_skeleton, spr_fire_skeleton_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_invisible_skeleton, spr_invisible_skeleton_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_fast_skeleton, spr_fast_skeleton_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_fat_skeleton, spr_fat_skeleton_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_living_block, spr_living_block_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_spider, spr_spider_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_mouth, spr_mouth_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_bumper, spr_bumper_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_snake, spr_snake_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_phantom, spr_phantom_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_hands, spr_hands_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_nose, spr_nose_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_statue, spr_statue_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_eyes, spr_eyes_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_ears, spr_ears_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_giant_eye, spr_giant_eye_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_giant_eye_pupil, spr_giant_eye_pupil_farmer);
		
		/// Items
		ds_map_add(farmer_sprite_translation_map, spr_sword, spr_sword_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_meat, spr_meat_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_bomb, spr_bomb_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_heart, spr_heart_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_clock, spr_clock_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_clock_sand, spr_clock_sand_farmer);
	}
	if (ds_map_exists(farmer_sprite_translation_map, _regular_sprite)) { return farmer_sprite_translation_map[? _regular_sprite]; }
	return _regular_sprite;
}

/// @function								get_room_map_position(_inst);
/// @param		{id} _inst					The instance id to return a room map position for
function get_room_map_position(_inst) {
	// Set up room map positions
	var _x_pos = 1, _y_pos = 1;
	if (_inst.y < room_height/2-16) { _y_pos = 0; }
	else if (_inst.y > room_height/2+16) { _y_pos = 2; }
	if (_inst.x < room_width/2-16) { _x_pos = 0; }
	else if (_inst.x > room_width/2+16) { _x_pos = 2; }
	
	return [_x_pos, _y_pos]
}

/// @function								flicker_sprite_under_instance(_inst);
/// @param		{id} _inst					The instance id to check for a collision with
function flicker_sprite_under_instance(_inst) {
	var _blink_frame = is_blink_frame();
	if (!_blink_frame || !instance_place(x, y, _inst)) { return false; }
	
	if (object_index == obj_lava_part) { part_visible = false; }
	else if (object_index == obj_solid_part) { part_visible = false; }
	//else if (object_index == obj_illusion_part) { part_visible = false; }
	else { visible = false; }
	
	return true;
}

/// @function								draw_reflection_in_mirrors();
function draw_reflection_in_mirrors() {
	var _valid_obj = (
		object_index == obj_player || 
		object_index == obj_collectable ||
		object_is_ancestor(object_index, obj_enemy) || 
		object_is_ancestor(object_index, obj_item)
	);
		
	if (_valid_obj && !object_is_ancestor(object_index, obj_solid) && instance_number(obj_mirror) > 0 && !instance_place(x, y, obj_mirror)) {
		var _potential_mirrors = ds_list_create();
		for (var _i = directions.up; _i < 8; _i++) {
			var _reflect_carried_item = false;
			if (object_is_ancestor(object_index, obj_item) && is_existing_instance(holder) && (holder.object_index != obj_hands || holder.activated)) {
				_reflect_carried_item = true;
			}
			var _carried_x_offset = (image_xscale * -8), _carried_y_offset = (_reflect_carried_item) ? draw_y_offset : 0;
			var _x_to_use = (_reflect_carried_item) ? x+_carried_x_offset : x, _y_to_use = y;
			var _x_pos = _x_to_use, _y_pos = _y_to_use, _x_pos_offset = 0, _y_pos_offset = 0;
			switch (_i) {
				case 0: { _x_pos = 0; _y_pos_offset -= abs(sprite_height/4); break; }
				case 1: { _x_pos = 0; _y_pos_offset += abs(sprite_height/4); break; }
				case 2: { _y_pos = 0; _x_pos_offset -= abs(sprite_width/4); break; }
				case 3: { _y_pos = 0; _x_pos_offset += abs(sprite_width/4); break; }
				case 4: { _x_pos = room_width; _y_pos_offset -= abs(sprite_height/4); break; }
				case 5: { _x_pos = room_width; _y_pos_offset += abs(sprite_height/4); break; }
				case 6: { _y_pos = room_height; _x_pos_offset -= abs(sprite_width/4); break; }
				case 7: { _y_pos = room_height; _x_pos_offset += abs(sprite_width/4); break; }
			}
			var _closest_solids = [];

			// Get closest mirrors
			ds_list_clear(_potential_mirrors);
			var _num_of_objects = collision_rectangle_list(_x_to_use+_x_pos_offset-1, _y_to_use+_y_pos_offset-1, _x_pos+_x_pos_offset+1, _y_pos+_y_pos_offset+1, obj_solid, false, true, _potential_mirrors, true);
			var _minimum_distance_to_obj = 999;
			for (var _j = 0; _j < _num_of_objects; _j++) {
				var _current_object = ds_list_find_value(_potential_mirrors, _j);
				if (!is_existing_instance(_current_object)) { continue; }
				
				var _distance_to_obj = point_distance(_x_to_use, _y_to_use, _current_object.x, _current_object.y)
				if (_distance_to_obj < _minimum_distance_to_obj) { _closest_solids = []; }
				if (_distance_to_obj <= _minimum_distance_to_obj) { 
					_minimum_distance_to_obj = _distance_to_obj;
					array_push(_closest_solids, _current_object);
				}
			}
			
			// Create reflections for closest mirrors
			for (var _j = 0; _j < array_length(_closest_solids); _j++) {
				var _closest_solid = _closest_solids[_j], _flipped_x_scale = image_xscale;
				if (!is_existing_instance(_closest_solid) || _closest_solid.object_index != obj_mirror) { break; }

				var _x_offset = 0, _y_offset = 0, _refl_width = abs(sprite_width), _refl_height = abs(sprite_height);
				var _x_dif = _closest_solid.x-_x_to_use, _y_dif = _closest_solid.y-y;
				var _refl_blend = (colour_get_value(_closest_solid.image_blend) < colour_get_value(image_blend)) ? _closest_solid.image_blend : image_blend;
				_x_pos = _closest_solid.x-(_flipped_x_scale*abs(sprite_width))/2;
				_y_pos = _closest_solid.y-(image_yscale*abs(sprite_height))/2;

				if (abs(_y_dif) < abs(_closest_solid.sprite_height) && _y_to_use < _closest_solid.y) { _refl_height /= 2; _y_offset += _refl_height; _y_pos += (abs(sprite_width)-abs(_closest_solid.sprite_width))/2; }
				else if (abs(_y_dif) < abs(_closest_solid.sprite_height) && _y_to_use > _closest_solid.y) { _refl_height /= 2; _y_pos += abs(_closest_solid.sprite_height/2); }
				else if (abs(_x_dif) < abs(_closest_solid.sprite_width) && _x_to_use < _closest_solid.x) { 
					if (_flipped_x_scale == 1) { _refl_width /= 2; _x_offset += _refl_width; _x_pos += (abs(sprite_width)-abs(_closest_solid.sprite_width))/2; }
					else { _refl_width /= 2; _x_pos -= abs(_closest_solid.sprite_width/2); }
				}
				else if (abs(_x_dif) < abs(_closest_solid.sprite_width) && _x_to_use > _closest_solid.x) {
					if (_flipped_x_scale == -1) { _refl_width /= 2; _x_offset += _refl_width; _x_pos += (abs(sprite_width)-abs(_closest_solid.sprite_width))/2; }
					else { _refl_width /= 2; _x_pos += abs(_closest_solid.sprite_width/2); }
				}
				
				// Draw Reflection
				if (_reflect_carried_item) {
					var _carried_item_x_offset = _flipped_x_scale * 8;
					_refl_height += _carried_y_offset;
					_y_offset -= _carried_y_offset
					_y_pos -= _carried_y_offset;
					if (abs(_y_dif) >= abs(_closest_solid.sprite_height)) {
						_x_pos += _carried_item_x_offset
					}
					else {
						_refl_width = abs(sprite_width/2)
						_x_offset = _refl_width;
						_x_pos = _closest_solid.x;
						if (y != _closest_solid.y) {
							_refl_height = abs((y-abs(sprite_height/2)-_carried_y_offset) - (_closest_solid.y-abs(_closest_solid.sprite_height/2)));
							_y_offset = 0;
							_y_pos = (y > _closest_solid.y) ? _closest_solid.y-_carried_y_offset+abs(_closest_solid.sprite_height/2)-_refl_height : _closest_solid.y-_carried_y_offset-abs(_closest_solid.sprite_height/2);
						}
					}
					
					draw_while_carried(_x_pos, _y_pos, _x_offset, _y_offset, _refl_width, _refl_height, _flipped_x_scale, _refl_blend, false);
				}
				else {
					draw_sprite_part_ext(sprite_index, image_index, _x_offset, _y_offset, _refl_width, _refl_height, _x_pos, _y_pos, _flipped_x_scale, image_yscale, _refl_blend, image_alpha);
					if (object_index == obj_player || object_index == obj_echo) {
						draw_player_left_hand(_x_pos, _y_pos, _x_offset, _y_offset, _refl_width, _refl_height, _flipped_x_scale, _refl_blend);
						draw_player_right_hand(_x_pos, _y_pos, _x_offset, _y_offset, _refl_width, _refl_height, _flipped_x_scale, _refl_blend);
						draw_player_hat(_x_pos, _y_pos, _x_offset, _y_offset, _refl_width, _refl_height, _flipped_x_scale, _refl_blend);
					}
				}
			}
		}
		ds_list_destroy(_potential_mirrors);
	}
}