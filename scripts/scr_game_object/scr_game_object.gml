/// @function get_distance_to_instance(_instance)
/// @description The distance from the calling instance to another instance
/// @param {Id.Instance} _instance The instance to measure the distance to
/// @returns {real} The distance in pixels, 0 for the calling instance itself, or -1 if the instance doesn't exist
function get_distance_to_instance(_instance) {
	if (!is_existing_instance(_instance)) { return -1; }
	if (id == _instance) { return 0; }

	return point_distance(x, y, _instance.x, _instance.y);
}

/// @function is_instance_at_coordinates(_x_pos, _y_pos, _instance)
/// @description Whether an instance exists and is at exactly a given position
/// @param {real} _x_pos The x position to compare with the instance's x
/// @param {real} _y_pos The y position to compare with the instance's y
/// @param {Id.Instance} _instance The instance to check
/// @returns {bool} False if the instance doesn't exist
function is_instance_at_coordinates(_x_pos, _y_pos, _instance) {
	return (is_existing_instance(_instance) && (_instance.x == _x_pos && _instance.y == _y_pos))
}

/// @function is_direction_towards(_dir, _inst)
/// @description Whether another instance lies in a direction from the calling instance. Only that direction's axis is
///	compared, so an instance above and to the right of the calling instance is towards both up and right.
/// @param {real} _dir The direction to check (see directions)
/// @param {Id.Instance} _inst The instance to look for in that direction
/// @returns {bool} Always false for a direction other than up, right, down or left
function is_direction_towards(_dir, _inst) {
	return ((y > _inst.y && _dir == directions.up) ||
	        (x < _inst.x && _dir == directions.right) ||
	        (y < _inst.y && _dir == directions.down) ||
	        (x > _inst.x && _dir == directions.left));
}

/// @function turn_to_face_player()
/// @description Turns the calling instance to face the most recently dropped meat if there is any, and the player
///	otherwise. Its sprite faces left at an image_xscale of 1, so a target on its right sets it to -1.
function turn_to_face_player() {
	var _target = get_dropped_meat();
	if (!is_existing_instance(_target)) { _target = global.player; }
	if (is_direction_towards(1, _target)) { image_xscale = -1; }
	else { image_xscale = 1; }
}

/// @function teleport_near_player()
/// @description Teleports the calling instance to a random position near the most recently dropped meat if there is
///	any, and near the player otherwise, with a flicker sound. The position is within 24 pixels of the target on each
///	axis in steps of 8, at least 24 pixels from it and inside the room. It gives up after 101 tries and stays at the
///	last position tried.
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


/// @function can_move_in_direction(_dir, _ignore_solid, _ignore_death)
/// @description Whether the calling instance can take one step in a direction. Unless solids are ignored, it can't move
///	at all while it is inside a solid, and otherwise the step must be free (see is_direction_free).
/// @param {real} _dir The direction to check (see directions)
/// @param {bool} _ignore_solid Whether to ignore solid objects in the way, and the solid the calling instance is inside
/// @param {bool} _ignore_death Whether to ignore objects that cause death (lava)
/// @returns {bool}
function can_move_in_direction(_dir, _ignore_solid, _ignore_death) {
	if (!_ignore_solid && is_solid_at_position(x, y)) { return false; }
	else { return (is_direction_free(_dir, _ignore_solid, _ignore_death)); }
}

/// @function is_solid_at_position(_x_pos, _y_pos)
/// @description Whether the calling instance would overlap a solid other than itself at a position. The player and the
///	hands ignore walls, solid parts, columns and mirrors while carrying a special staff.
/// @param {real} _x_pos The x position to check
/// @param {real} _y_pos The y position to check
/// @returns {bool}
function is_solid_at_position(_x_pos, _y_pos) {
	var _solids = instance_place_all(_x_pos, _y_pos, obj_solid), _carrying_special_staff = false;
	if (object_index == obj_hands || object_index == obj_player) { _carrying_special_staff = is_carrying_special_item(obj_staff); }
	
	for (var _i = 0; _i < array_length(_solids); _i++) {
		var _current_solid = _solids[_i];
		if (_current_solid != id && (!_carrying_special_staff || (_current_solid.object_index != obj_solid_part && _current_solid.object_index != obj_wall && _current_solid.object_index != obj_column && _current_solid.object_index != obj_mirror))) { return true; }
	}
	return false;
}

/// @function is_lava_at_position(_x_pos, _y_pos)
/// @description Whether the calling instance would overlap lava at a position. Lava that the calling instance created
///	itself doesn't count, and the player and hands carrying a staff can cross lava.
/// @param {real} _x_pos The x position to check
/// @param {real} _y_pos The y position to check
/// @returns {bool}
function is_lava_at_position(_x_pos, _y_pos) {
	if ((object_index == obj_hands || object_index == obj_player) && is_carrying_item(obj_staff)) { return false; }
	
	var _lava_parts_at_position = instance_place_all(_x_pos, _y_pos, obj_lava_part);
	while (array_length(_lava_parts_at_position) > 0) {
		var _lava_part_creator = array_random_pop(_lava_parts_at_position).creator;
		if (!is_existing_instance(_lava_part_creator) || _lava_part_creator.id != id) { return true; }
	}
	return false;
}

/// @function is_direction_free(_dir, _ignore_solid, _ignore_death)
/// @description Whether the calling instance can take a step of 8 pixels in a direction without being stopped. A step
///	is stopped by the room border (for enemies that can't move on it), by the edge of the room (unless the calling
///	instance is a player who isn't inside a solid), by lava and by solids.
/// @param {real} _dir The direction to step in (see directions)
/// @param {bool} _ignore_solid Whether solid objects don't stop the step
/// @param {bool} _ignore_death Whether objects that cause death (lava) don't stop the step
/// @returns {bool} Whether the step is free, which is always false for a direction other than up, right, down or left
function is_direction_free(_dir, _ignore_solid, _ignore_death) {
	var _x_pos = x, _y_pos = y;
	switch (_dir) {
		case directions.up: { _y_pos -= 8; break; }
		case directions.right: { _x_pos += 8; break; }
		case directions.down: { _y_pos += 8; break; }
		case directions.left: { _x_pos -= 8; break; }
		default: { return false; }
	}
	
	// Return as not free if blocked by the room border, which only stops enemies that can't move on it
	var _blocked = is_on_room_border(_x_pos, _y_pos);
	if (!object_is_ancestor(object_index, obj_enemy) || can_move_on_border) { _blocked = false; }
	if (_blocked) { return false; }
	
	// Return as not free if blocked by the edge of the room, which the player can cross unless it is inside a solid
	_blocked = is_outside_room(_x_pos, _y_pos);
	if (object_index == obj_player && !place_meeting(x, y, obj_solid)) { _blocked = false; }
	if (_blocked) { return false; }
	
	// Return as not free if blocked by lava
	_blocked = (!_ignore_death && is_lava_at_position(_x_pos, _y_pos));
	if (_blocked) { return false; }
	
	// Return as not free if blocked by solid
	_blocked = (!_ignore_solid && is_solid_at_position(_x_pos, _y_pos));
	if (_blocked) { return false; }
	
	// Return as free if not blocked by anything
	return true;
}

/// @function is_outside_room(_x_pos, _y_pos)
/// @description Whether a position is on the edge of the room or beyond it
/// @param {real} _x_pos The x position to check
/// @param {real} _y_pos The y position to check
/// @returns {bool}
function is_outside_room(_x_pos, _y_pos) {
	return (_x_pos <= 0 || _x_pos >= room_width || _y_pos <= 0 || _y_pos >= room_height);
}

/// @function is_on_room_border(_x_pos, _y_pos)
/// @description Whether a position is on a room exit spot (a spot on the room's edge where a cardinal exit can be) of a
///	kind that the calling instance isn't already standing on, so stepping there would reach the room's border
/// @param {real} _x_pos The x position to check
/// @param {real} _y_pos The y position to check
/// @returns {bool}
function is_on_room_border(_x_pos, _y_pos) {
	var _target_exit_spots = instance_place_all(_x_pos, _y_pos, obj_exit_spot);
	if (array_length(_target_exit_spots) == 0) { return false; }
	
	// Collect the kinds of exit spot the calling instance is on, then look for a kind at the target that isn't among them
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


/// @function can_move_in_direction_and_reach(_dir, _target_instance, _ignore_solid, _ignore_death)
/// @description Whether the calling instance can reach another instance by stepping straight in a direction, with every
///	step free. The steps are only tried out: the calling instance ends up where it started.
/// @param {real} _dir The direction to step in (see directions)
/// @param {Id.Instance} _target_instance The instance to reach by stepping in that direction
/// @param {bool} _ignore_solid Whether to ignore solid objects in the way
/// @param {bool} _ignore_death Whether to ignore objects that cause death (lava)
/// @returns {bool} False if the calling instance isn't activated, the target doesn't exist or a blocked step comes first
function can_move_in_direction_and_reach(_dir, _target_instance, _ignore_solid, _ignore_death) {
	if (!activated || !is_existing_instance(_target_instance)) { return false; }
	
	// Work out how far one step in this direction moves the calling instance
	var _x_change = 0, _y_change = 0;
	if (_dir == directions.up) { _y_change -= 8; } 
	else if (_dir == directions.right) { _x_change += 8; }
	else if (_dir == directions.down) { _y_change += 8; }
	else if (_dir == directions.left) { _x_change -= 8; }

	// Try to reach the target by stepping in this direction, then put the calling instance back where it started
    var _original_x = x, _original_y = y, _reached = false;
    var _max_steps = room_width div 8;   // Enough steps to cross the room, which is the most a straight walk can need

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


/// @function move_in_direction(_dir, _make_noise)
/// @description Moves the calling instance one step of 8 pixels in a direction, without checking that the way is free.
///	It turns to face a sideways move, switches to its other animation frame, has an enemy check whether it has touched
///	the player, plays a sound for what it lands on, and has the room's path grids rebuilt when a solid moves.
/// @param {real} _dir The direction to move in (see directions)
/// @param {bool} _make_noise Whether to play a movement sound, which floating enemies other than hands never do
function move_in_direction(_dir, _make_noise) {
	// Step in the direction, turning to face a sideways move
	if (_dir == directions.up) { y -= 8; } 
	else if (_dir == directions.right) { x += 8; image_xscale = -1; }
	else if (_dir == directions.down) { y += 8; }
	else if (_dir == directions.left) { x -= 8; image_xscale = 1; }
	
	// Switch to the other animation frame
	image_index += 1;
	if (image_index > 1) { image_index = 0; }
	
	if (object_is_ancestor(object_index, obj_enemy)) { 
		check_for_player_collision();
		if (floating && object_index != obj_hands) { _make_noise = false; }
	}
	
	// Make movement noises: a thud in a solid, a splash in lava, a flicker in an illusion wall, or a step otherwise
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
	
	// Have the room's path grids (mp_grids) rebuilt when a solid or a giant worm's body moves
	var _is_solid = (object_is_ancestor(object_index, obj_solid) || object_is_ancestor(object_index, obj_giant_worm_body));
	if (_is_solid) { mark_current_room_for_grid_update(); }
}


/// @function set_instance_to_same_position(_instance)
/// @description Moves another instance to the calling instance's position
/// @param {Id.Instance} _instance The instance to move
function set_instance_to_same_position(_instance) {
	with _instance { 
	    x = other.x; 
	    y = other.y;
	}
}

/// @function get_direction_pushed_against()
/// @description The direction the player is pushing the calling instance in, which blocks, doors, chests and the like
///	react to. That is the direction the player just pressed, if the calling instance is 16 pixels away from the player
///	in it and nothing else has moved the player this frame.
/// @returns {real} The direction pushed in (see directions), or directions.none if the player isn't pushing against it
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

/// @function rotate_sprite_to_random_angle()
/// @description Rotates the calling instance's sprite to a random right angle: 0, 90, 180 or 270 degrees
function rotate_sprite_to_random_angle() {
	image_angle = get_random_cardinal_dir() * 90;
}

/// @function flip_sprite_at_random(_flip_vertical)
/// @description Randomly flips the calling instance's sprite horizontally, and vertically too if asked
/// @param {bool} _flip_vertical Whether to also flip the sprite vertically at random
function flip_sprite_at_random(_flip_vertical) {
	image_xscale = get_coin_flip() ? 1 : -1;
	if (_flip_vertical) { image_yscale = (get_coin_flip()) ? 1 : -1; }
}

/// @function get_instance_at_each_quadrant(_obj_index)
/// @description Finds the instance of an object at each of the four quadrants of the calling instance's cell
/// @param {Asset.GMObject} _obj_index The object to look for in each quadrant
/// @returns {array} Four instances, one per quadrant (see get_quadrant_x_pos), with noone where a quadrant has none
function get_instance_at_each_quadrant(_obj_index) {
	var _presence_at_quadrant = [noone, noone, noone, noone];
	
	for (var _quadrant = 0; _quadrant < 4; _quadrant++;) {
        var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);
		_presence_at_quadrant[_quadrant] = instance_position(_x_pos, _y_pos, _obj_index);
    }
	
	return _presence_at_quadrant;
}

/// @function is_covered_at_each_quadrant_by(_obj_index)
/// @description Whether an object has an instance at each of the four quadrants of the calling instance's cell. For
///	obj_lava it looks at the lava parts instead, which show which of a lava tile's quadrants are left.
/// @param {Asset.GMObject} _obj_index The object to look for in every quadrant
/// @returns {bool}
function is_covered_at_each_quadrant_by(_obj_index) {
	// Lava is a special case. A lava tile (obj_lava) stays in place after some of its quadrants are destroyed, because a
	// pushed block can destroy quadrants of several lava tiles at once, so check the lava parts that are left instead
	var _presence_at_quadrant = (_obj_index == obj_lava) ? get_instance_at_each_quadrant(obj_lava_part) : get_instance_at_each_quadrant(_obj_index);
	
	return (
		is_existing_instance(_presence_at_quadrant[0]) &&
		is_existing_instance(_presence_at_quadrant[1]) &&
		is_existing_instance(_presence_at_quadrant[2]) &&
		is_existing_instance(_presence_at_quadrant[3])
	);
}

/// @function move_towards_coordinates(_target_x, _target_y, _ignore_solid, _ignore_death)
/// @description Moves the calling instance one step toward a position, with movement sounds, in a random one of the
///	directions that get it closer and are free to move in
/// @param {real} _target_x The x position to move toward
/// @param {real} _target_y The y position to move toward
/// @param {bool} _ignore_solid Whether to ignore solid objects when checking which directions are free
/// @param {bool} _ignore_death Whether to ignore objects that cause death (lava) when checking which directions are free
/// @returns {real} The direction it moved in (see directions), or directions.none if it couldn't move
function move_towards_coordinates(_target_x, _target_y, _ignore_solid, _ignore_death) {	
	var _move_dir = get_random_possible_direction(_target_x, _target_y, _ignore_solid, _ignore_death);
	if (_move_dir != directions.none) { move_in_direction(_move_dir, true); }
	
	return _move_dir;
}

/// @function get_random_possible_direction(_target_x, _target_y, _ignore_solid, _ignore_death)
/// @description Picks at random one of the directions that both get the calling instance closer to a position and are
///	free to move in
/// @param {real} _target_x The x position to move toward
/// @param {real} _target_y The y position to move toward
/// @param {bool} _ignore_solid Whether to ignore solid objects when checking which directions are free
/// @param {bool} _ignore_death Whether to ignore objects that cause death (lava) when checking which directions are free
/// @returns {real} The direction picked (see directions), or directions.none if no direction both gets closer and is free
function get_random_possible_direction(_target_x, _target_y, _ignore_solid, _ignore_death) {
	// Determine which directions are free to move in
	var _can_move_up = can_move_in_direction(directions.up, _ignore_solid, _ignore_death);
	var _can_move_right = can_move_in_direction(directions.right, _ignore_solid, _ignore_death);
	var _can_move_left = can_move_in_direction(directions.left, _ignore_solid, _ignore_death);
	var _can_move_down = can_move_in_direction(directions.down, _ignore_solid, _ignore_death);
	
	// Determine which of the free directions get closer to the target
	var _possible_directions = [];
	if (y > _target_y && _can_move_up) { array_push(_possible_directions, directions.up); }
	if (x < _target_x && _can_move_right) { array_push(_possible_directions, directions.right); }
	if (y < _target_y && _can_move_down) { array_push(_possible_directions, directions.down); }
	if (x > _target_x && _can_move_left) { array_push(_possible_directions, directions.left); }
	
	// Return a random direction from among those possible
	var _move_dir = array_length(_possible_directions) > 0 ? array_random_get(_possible_directions) : directions.none;
	return _move_dir;
}

/// @function randomize_image(_max_image_index)
/// @description Gives the calling instance a random look: a random frame of its sprite, flipped horizontally and
///	vertically at random, and rotated to a random right angle
/// @param {real} _max_image_index The highest image_index to pick from, which is the index of the sprite's last frame
function randomize_image(_max_image_index) {
	image_index = irandom(_max_image_index);
	flip_sprite_at_random(true);
	rotate_sprite_to_random_angle();
}

/// @function singleton_instance()
/// @description Keeps an object to a single instance: destroys the calling instance if its object has more than one
///	instance, so a duplicate removes itself when it calls this, as in its Create event
function singleton_instance() {
	if (instance_number(object_index) > 1) { instance_destroy(); }
}

/// @function can_press_button()
/// @description Whether something is pressing the calling button down: a solid covering all four of its quadrants, such
///	as a block, the player standing on it, or an enemy standing on it that isn't floating
/// @returns {bool}
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

/// @function get_sprite_shuffle_flip(_spr)
/// @description A coin flip for a sprite that comes out the same every time for the same sprite and game seed, and
///	doesn't change if the project's resources are reordered, because it comes from a hash of the sprite's name. The
///	result is cached for each sprite.
/// @param {Asset.GMSprite} _spr The sprite to flip the coin for
/// @returns {bool} The result of the coin flip
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

/// @function get_sprite_to_use(_regular_sprite, [_for_menu])
/// @description Picks the sprite to draw for the current graphics mode. Standard mode uses the regular sprite, and
///	farmer mode uses its farmer version if it has one. Unknown mode swaps an item or enemy sprite for the one shuffled
///	into its place, and keeps any other sprite regular or gives it its farmer version, by a coin flip that stays the
///	same for the sprite and seed.
/// @param {Asset.GMSprite} _regular_sprite The sprite to use in standard mode
/// @param {bool} [_for_menu] Whether the sprite is for a menu, where unknown mode doesn't change it (false by default)
/// @returns {Asset.GMSprite} The sprite to draw, which is the regular sprite when the mode has no other version of it
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
	
	// Get the farmer version of the regular sprite, building the lookup map the first time
	static farmer_sprite_translation_map = -1;
	if (farmer_sprite_translation_map == -1) {
		farmer_sprite_translation_map = ds_map_create();
		// Tiles
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
		
		// Enemies
		ds_map_add(farmer_sprite_translation_map, spr_gudetama, spr_gudetama_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_skeleton, spr_skeleton_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_cockroach, spr_cockroach_farmer);
		ds_map_add(farmer_sprite_translation_map, spr_fire_skeleton, spr_fire_skeleton_farmer);
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
		
		// Items
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

/// @function get_room_map_position(_inst)
/// @description Which part of the room an instance is in, as a position on a three by three grid that the map uses to
///	draw it. The middle part is within 16 pixels of the room's center.
/// @param {Id.Instance} _inst The instance to locate
/// @returns {array} The column and row as [x, y], each 0 (left or top), 1 (middle) or 2 (right or bottom)
function get_room_map_position(_inst) {
	// Each axis starts in the middle (1), and becomes 0 or 2 when the instance is more than 16 pixels from the center
	var _x_pos = 1, _y_pos = 1;
	if (_inst.y < room_height/2-16) { _y_pos = 0; }
	else if (_inst.y > room_height/2+16) { _y_pos = 2; }
	if (_inst.x < room_width/2-16) { _x_pos = 0; }
	else if (_inst.x > room_width/2+16) { _x_pos = 2; }
	
	return [_x_pos, _y_pos]
}

/// @function flicker_sprite_under_instance(_inst)
/// @description Hides the calling instance's sprite on blink frames while it overlaps another instance, so it seems to
///	flicker. A staff uses it to make the lava under its holder flicker, and the walls too when the staff is special. A
///	lava part or solid part is hidden through its part_visible flag, and any other instance through visible.
/// @param {Id.Instance} _inst The instance whose overlap to check
/// @returns {bool} Whether the sprite was hidden, which needs a blink frame and an overlap
function flicker_sprite_under_instance(_inst) {
	var _blink_frame = is_blink_frame();
	if (!_blink_frame || !instance_place(x, y, _inst)) { return false; }
	
	if (object_index == obj_lava_part) { part_visible = false; }
	else if (object_index == obj_solid_part) { part_visible = false; }
	else { visible = false; }
	
	return true;
}

/// @function draw_reflection_in_mirrors()
/// @description Draws the calling instance's reflection on the mirrors in line with it. Only the player, collectables,
///	enemies and items are reflected, and not those that are solid or standing on a mirror. Two lines run from the
///	instance toward each of the room's four edges, offset a quarter of the sprite's size to either side of its center,
///	and a mirror that is the closest solid along a line has the sprite drawn on it (half of it where the instance is
///	half in line with the mirror). A carried item is drawn the way it is carried, and the player and its echo also get
///	their hands and hat.
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

			// Find the closest solids along this line, which reflect the instance only if they are mirrors
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
			
			// Draw a reflection in each of the closest solids, stopping at the first one that isn't a mirror
			for (var _j = 0; _j < array_length(_closest_solids); _j++) {
				var _closest_solid = _closest_solids[_j], _flipped_x_scale = image_xscale;
				if (!is_existing_instance(_closest_solid) || _closest_solid.object_index != obj_mirror) { break; }

				var _x_offset = 0, _y_offset = 0, _refl_width = abs(sprite_width), _refl_height = abs(sprite_height);
				var _x_pos = _closest_solid.x-(_flipped_x_scale*abs(sprite_width))/2, _y_pos = _closest_solid.y-(image_yscale*abs(sprite_height))/2, _x_dif = _closest_solid.x-_x_to_use, _y_dif = _closest_solid.y-y;
				var _refl_blend = (colour_get_value(_closest_solid.image_blend) < colour_get_value(image_blend)) ? _closest_solid.image_blend : image_blend;

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
				
				// Draw the reflection: a carried item the way it is carried, anything else as its own sprite
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