/// @function								get_distance_to_instance(instance);
/// @param		{index} instance			The instance whose distance away from the calling instance is to be calculated
function get_distance_to_instance(instance) {
	if (!is_existing_instance(instance)) { return -1; }
	if (id == instance) { return 0; }

	return point_distance(x, y, instance.x, instance.y);
}

/// @function								is_instance_at_coordinates(x_pos, y_pos, instance);
/// @param		{real}  x_pos				The x value to check against the instance's x value
/// @param		{real}  y_pos				The y value to check against the instance's y value
/// @param		{index} instance			The instance whos positional coordinates are being checked
function is_instance_at_coordinates(x_pos, y_pos, instance) {
	return (is_existing_instance(instance) && (instance.x == x_pos && instance.y == y_pos))
}

/// @function								is_direction_toward(dir, obj);
/// @param		{direction} dir				The direction from the calling instance to check whether the given instance
/// @param		{instance} obj				The object to check for the direction of
function is_direction_toward(dir, inst) {
	return ((y > inst.y && dir == directions.up) ||
	        (x < inst.x && dir == directions.right) ||
	        (y < inst.y && dir == directions.down) ||
	        (x > inst.x && dir == directions.left));
}

/// @function								turn_to_face_player();
function turn_to_face_player() {
	var target = get_dropped_meat();
	if (!is_existing_instance(target)) { target = global.player; }
	if (is_direction_toward(1, target)) { image_xscale = -1; }
	else { image_xscale = 1; }
}

/// @function  							teleport_near_player();
function teleport_near_player() {
	var target = get_dropped_meat();
	if (!is_existing_instance(target)) { target = global.player; }
	
	play_sound(snd_flicker, false);

	do {
	    var x_pos = (8*get_random_carindal_dir());
	    var y_pos = (8*get_random_carindal_dir());
	    if (get_coin_flip()) { x_pos *= -1; }
	    if (get_coin_flip()) { y_pos *= -1; }
	    x = target.x + x_pos;
	    y = target.y + y_pos;
	}
	until (get_distance_to_instance(target) >= 24 && !is_outside_room(x,y));
}


/// @function								can_move_in_direction(dir, ignore_solid);
/// @param		{direction}	dir				The direction to check whether the calling instance can move in
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function can_move_in_direction(dir, ignore_solid, ignore_death) {
	if (!ignore_solid && is_solid_at_position(x, y)) { return false; }
	else { return (is_direction_free(dir, ignore_solid, ignore_death)); }
}

/// @function								is_solid_at_position(x_pos, y_pos);
/// @param		{int} x_pos					The x coordinate of the position
/// @param		{int} y_pos					The y coordinate of the position
function is_solid_at_position(x_pos, y_pos) {
	var solids = instance_place_all(x_pos, y_pos, obj_solid), carrying_special_staff = false;
	if (object_index == obj_hands || object_index == obj_player) { carrying_special_staff = is_carrying_special_item(obj_staff); }
	
	while (array_length(solids) > 0) {
		var current_solid = array_random_pop(solids);
		if (current_solid != id && (!carrying_special_staff || (current_solid.object_index != obj_solid_part && current_solid.object_index != obj_wall && current_solid.object_index != obj_column))) { return true; }
	}
	return false;
}

/// @function								is_lava_at_position(x_pos, y_pos);
/// @param		{int} x_pos					The x coordinate of the position
/// @param		{int} y_pos					The y coordinate of the position
function is_lava_at_position(x_pos, y_pos) {
	if ((object_index == obj_hands || object_index == obj_player) && is_carrying_item(obj_staff)) { return false; }
	
	var lava_parts_at_position = instance_place_all(x_pos, y_pos, obj_lava_part);
	while (array_length(lava_parts_at_position) > 0) {
		var lava_part_creator = array_random_pop(lava_parts_at_position).creator;
		if (!is_existing_instance(lava_part_creator) || lava_part_creator.id != id) { return true; }
	}
	return false;
}

/// @function								is_direction_free(dir, ignore_solid);
/// @param		{direction}	dir				The direction to check whether the calling instance can move in
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function is_direction_free(dir, ignore_solid, ignore_death) {
	var x_pos = x, y_pos = y;
	switch (dir) {
		case directions.up: { y_pos -= 8; break; }
		case directions.right: { x_pos += 8; break; }
		case directions.down: { y_pos += 8; break; }
		case directions.left: { x_pos -= 8; break; }
		default: { return false; }
	}
	
	// Return as not free if blocked by room border
	var blocked = is_on_room_border(x_pos, y_pos);
	if (!object_is_ancestor(object_index, obj_enemy) || can_move_on_border) { blocked = false; }
	if (blocked) { return false; }
	
	// Return as not free if blocked by room boundry
	blocked = is_outside_room(x_pos, y_pos);
	if (object_index == obj_player && !place_meeting(x, y, obj_solid)) { blocked = false; }
	if (blocked) { return false; }
	
	// Return as not free if blocked by lava
	blocked = (!ignore_death && is_lava_at_position(x_pos, y_pos));
	if (blocked) { return false; }
	
	// Return as not free if blocked by solid
	blocked = (!ignore_solid && is_solid_at_position(x_pos, y_pos));
	if (blocked) { return false; }
	
	// return as free if not blocked by anything
	return true;
}

/// @function								is_outside_room(x_pos, y_pos);
/// @param		{int}	x_pos				The x position to check
/// @param		{int}	y_pos				The y position to check
function is_outside_room(x_pos, y_pos) {
	return (x_pos <= 0 || x_pos >= room_width || y_pos <= 0 || y_pos >= room_height);
}

/// @function								is_on_room_border(x_pos, y_pos);
/// @param		{int}	x_pos				The x position to check
/// @param		{int}	y_pos				The y position to check
function is_on_room_border(x_pos, y_pos) {
	var target_exit_spots = instance_place_all(x_pos, y_pos, obj_exit_spot);
	if (array_length(target_exit_spots) == 0) { return false; }
	
	// Check if target pos is on a type of exit spot this isn't already on
	var on_exit_spots = instance_place_all(x, y, obj_exit_spot), on_exit_types = array_create(0);
	while (array_length(on_exit_spots) > 0) {
		var next_exit_spot = array_pop(on_exit_spots);
		array_push(on_exit_types, next_exit_spot.object_index);
	}
	var on_border = false;
		while (array_length(target_exit_spots) > 0) {
		var next_exit_spot = array_pop(target_exit_spots);
		if (!array_contains(on_exit_types, next_exit_spot.object_index)) { on_border = true; break; }
	}

	return (on_border);
}


/// @function								can_move_in_direction_and_reach(dir, ignore_solid);
/// @param		{direction}	dir				The direction to check whether the calling instance can move in
/// @param		{index}	target_instance		The instance we are trying to reach by moving in this direction
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function can_move_in_direction_and_reach(dir, target_instance, ignore_solid, ignore_death) {
	var original_x = x, original_y = y, can_reach_target = false;
	
	activated = false;
	while(can_move_in_direction(dir, ignore_solid, ignore_death) && !can_reach_target) {
		move_in_direction(dir, false);
		if (is_instance_at_coordinates(x, y, target_instance)) { can_reach_target = true; }
	}
	activated = true;
	
	x = original_x;
	y = original_y;
	
	return can_reach_target;
}


/// @function								move_in_direction(dir);
/// @param		{direction} dir				The direction in which to move the calling instance
/// @param		{boolean} make_noise		Whether or not to play a movement sound
function move_in_direction(dir, make_noise) {
	// Update position
	if (dir == directions.up) { y -= 8; } 
	else if (dir == directions.right) { x += 8; image_xscale = -1; }
	else if (dir == directions.down) { y += 8; }
	else if (dir == directions.left) { x -= 8; image_xscale = 1; }
	
	if (object_is_ancestor(object_index, obj_enemy)) { 
		check_for_player_collision();
		if (floating && object_index != obj_hands) { make_noise = false; }
	}
	
	// Make movement noises
	if (make_noise) {
		var snd = snd_walk;
		if (instance_place(x, y, obj_solid)) { snd = snd_thud; play_sound(snd, false); }
		if (instance_place(x, y, obj_lava_part)) { snd = snd_splash; play_sound(snd, false); }
		if (instance_place(x, y, obj_illusion_wall)) { snd = snd_flicker; play_sound(snd, false); }
		if (snd == snd_walk) { play_sound(snd, false); }
	}
	
	// Update mp_grids
	var is_solid = (object_is_ancestor(object_index, obj_solid) || object_is_ancestor(object_index, obj_giant_worm_body)), current_room = global.controller.current_room;
	if (is_solid) { current_room.reset_room_solid_path_grid(); current_room.reset_room_lava_path_grid(); }
}


/// @function								set_instance_to_same_position(instance);
/// @param		{index} instance			The instance to set to the same position as the calling instance
function set_instance_to_same_position(instance) {
	with instance { 
	    x = other.x; 
	    y = other.y;
	}
}

/// @function								get_direction_pushed_against();
function get_direction_pushed_against() {
	var dir = directions.none, player = global.player, x_pos = player.x, y_pos = player.y;
	
	if (is_existing_instance(player.moved_by)) { 
		return directions.none; 
	}
	
	dir = get_direction_input(true);
	if (dir == directions.none) { return dir; }
	
	switch (dir) {
		case directions.up: { y_pos -= 16; break; }
		case directions.right: { x_pos += 16; break; }
		case directions.down: { y_pos += 16; break; }
		case directions.left: { x_pos -= 16; break; }
	}
	
	if (!is_instance_at_coordinates(x_pos, y_pos, id)) { 
		dir = directions.none; 
	}
	
	return dir;
}

/// @function								rotate_sprite_to_random_angle();
function rotate_sprite_to_random_angle() {
	image_angle = get_random_carindal_dir() * 90;
}

/// @function								flip_sprite_at_random(flip_vertical);
/// @param		{boolean} flip_vertical		Whether or not to also randomly flip the sprite vertically
function flip_sprite_at_random(flip_vertical) {
	image_xscale = get_coin_flip() ? 1 : -1;
	if (flip_vertical) { image_yscale = (get_coin_flip()) ? 1 : -1; }
}

/// @function								get_instance_at_each_quadrant(obj_index);
///	@param		{index} obj_index			The object type to return the presence of in each quadrant
function get_instance_at_each_quadrant(obj_index) {
	var presence_at_quadrant = [noone, noone, noone, noone];
	
	for (var quadrant = 0; quadrant < 4; quadrant++;) {
        var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
		presence_at_quadrant[quadrant] = instance_position(x_pos, y_pos, obj_index);
    }
	
	return presence_at_quadrant;
}

/// @function								is_covered_at_each_quadrant_by(obj_index);
///	@param		{index} obj_index			The object type to check the presence of in each quadrant
function is_covered_at_each_quadrant_by(obj_index) {
	// Checking for lava is a special case, because the full lava object stays and blacks out
	// certain quadrants with individual quadrant death boxes due to the way blocks can destroy
	// multiple different lava's quadrants at once. Thus we need to use a special method that
	// Takes that into account.
	var presence_at_quadrant = (obj_index == obj_lava) ? get_instance_at_each_quadrant(obj_lava_part) : get_instance_at_each_quadrant(obj_index);
	
	return (
		is_existing_instance(presence_at_quadrant[0]) &&
		is_existing_instance(presence_at_quadrant[1]) &&
		is_existing_instance(presence_at_quadrant[2]) &&
		is_existing_instance(presence_at_quadrant[3])
	);
}

/// @function								move_towards_coordinates(target_x, target_y, ignore_solid, ignore_death);
///	@param		{int} target_x				The x position to be moving toward
///	@param		{int} target_y				The y position to be moving toward
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function move_towards_coordinates(target_x, target_y, ignore_solid, ignore_death) {	
	var move_dir = get_random_possible_direction(target_x, target_y, ignore_solid, ignore_death);
	if (move_dir != directions.none) { move_in_direction(move_dir, true); }
	
	return move_dir;
}

/// @function								get_random_possible_direction(obj_index);
///	@param		{int} target_x				The x position to be moving toward
///	@param		{int} target_y				The y position to be moving toward
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function get_random_possible_direction(target_x, target_y, ignore_solid, ignore_death) {
	// Determine which directions are free to move in
	var can_move_up = can_move_in_direction(directions.up, ignore_solid, ignore_death);
	var can_move_right = can_move_in_direction(directions.right, ignore_solid, ignore_death);
	var can_move_left = can_move_in_direction(directions.left, ignore_solid, ignore_death);
	var can_move_down = can_move_in_direction(directions.down, ignore_solid, ignore_death);
	
	// Determine which directions one should move in to get closer to target
	var possible_directions = array_create(0);
	if (y > target_y && can_move_up) { array_push(possible_directions, directions.up); }
	if (x < target_x && can_move_right) { array_push(possible_directions, directions.right); }
	if (y < target_y && can_move_down) { array_push(possible_directions, directions.down); }
	if (x > target_x && can_move_left) { array_push(possible_directions, directions.left); }
	
	// Return a random direction from among those possible
	var move_dir = array_length(possible_directions) > 0 ? array_random_get(possible_directions) : directions.none;
	return move_dir;
}

/// @function								randomize_image(max_image_index);
///	@param		{int} max_image_index		The max image_index value possible for this object's sprite
function randomize_image(max_image_index) {
	image_index = irandom(max_image_index);
	flip_sprite_at_random(true);
	rotate_sprite_to_random_angle();
}

/// @function								singleton_instance();
function singleton_instance() {
	if (instance_number(object_index) > 1) { instance_destroy(); }
}

/// @function								can_press_button();
function can_press_button() {	
	var pressed = is_covered_at_each_quadrant_by(obj_solid) || is_instance_at_coordinates(x, y, global.player);
	if (!pressed) { 
		var enemies_at_position = instance_place_all(x, y, obj_enemy);
		while (array_length(enemies_at_position) > 0) {
			var enemy = array_random_pop(enemies_at_position);
			if (!enemy.floating && is_instance_at_coordinates(x, y, enemy)) { pressed = true; break; }
		}
	}
	
	return pressed;
}

/// @function								get_sprite_to_use();
function get_sprite_to_use(regular_sprite) {
	if (!global.is_farm_mode) { return regular_sprite; }
	
	switch (regular_sprite) {
		/// Tiles
		case spr_collectable: { return spr_collectable_farmer; }
		case spr_bones: { return spr_bones_farmer; }
		case spr_cross: { return spr_cross_farmer; }
		case spr_giant_wurm: { return spr_giant_wurm_farmer; }
		case spr_portcullis: { return spr_portcullis_farmer; }
		case spr_block: { return spr_block_farmer; }
		case spr_block_tile2: { return spr_block_tile_farmer; }
		/// Enemies
		case spr_skeleton: { return spr_skeleton_farmer; }
		case spr_cockroach: { return spr_cockroach_farmer; }
		case spr_fire_skeleton: { return spr_fire_skeleton_farmer; }
		case spr_living_block: { return spr_living_block_farmer; }
		case spr_spider: { return spr_spider_farmer; }
		case spr_mouth: { return spr_mouth_farmer; }
		case spr_bumper: { return spr_bumper_farmer; }
		case spr_snake: { return spr_snake_farmer; }
		case spr_phantom: { return spr_phantom_farmer; }
		case spr_hands: { return spr_hands_farmer; }
		case spr_nose: { return spr_nose_farmer; }
		case spr_statue: { return spr_statue_farmer; }
		case spr_eyes: { return spr_eyes_farmer; }
		case spr_ears: { return spr_ears_farmer; }
		case spr_echo: { return spr_echo_farmer; }
		/// Items
		case spr_sword: { return spr_sword_farmer; }
		case spr_sword_in_ground: { return spr_sword_in_ground_farmer; }
		case spr_meat: { return spr_meat_farmer; }
		case spr_bomb: { return spr_bomb_farmer; }
		case spr_heart: { return spr_heart_farmer; }
		case spr_clock: { return spr_clock_farmer; }
		case spr_special_clock: { return spr_special_clock_farmer; }
	}
	
	return regular_sprite;
}

/// @function								get_room_map_position(inst);
/// @param		{id} inst					The instance id to return a room map position for
function get_room_map_position(inst) {
	// Set up room map positions
	var x_pos = 1, y_pos = 1;
	if (inst.y < room_height/2-16) { y_pos = 0; }
	else if (inst.y > room_height/2+16) { y_pos = 2; }
	if (inst.x < room_width/2-16) { x_pos = 0; }
	else if (inst.x > room_width/2+16) { x_pos = 2; }
	
	return [x_pos, y_pos]
}

/// @function								flicker_sprite_under_instance(inst);
/// @param		{id} inst					The instance id to check for a collision with
function flicker_sprite_under_instance(inst) {
	var blink_frame = is_blink_frame();
	if (!blink_frame || !instance_place(x, y, inst)) { return false; }
	
	if (object_index == obj_lava_part) { part_visible = false; }
	else if (object_index == obj_solid_part) { part_visible = false; }
	else if (object_index == obj_illusion_part) { part_visible = false; }
	else { visible = false; }
	
	return true;
}