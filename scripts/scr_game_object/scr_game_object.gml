/// @function								get_distance_to_instance(instance);
/// @param		{index} instance			The instance whose distance away from the calling instance is to be calculated
function get_distance_to_instance(instance) {
	if (!is_existing_instance(instance)) { return -1; }
	if (id == instance) { return 0; }

	return point_distance(x, y, instance.x, instance.y);//sqrt((sqr(instance.x - x) + sqr(instance.y - y)));
}

/// @function								is_instance_at_coordinates(x_pos, y_pos, instance);
/// @param		{real}  x_pos				The x value to check against the instance's x value
/// @param		{real}  y_pos				The y value to check against the instance's y value
/// @param		{index} instance			The instance whos positional coordinates are being checked
function is_instance_at_coordinates(x_pos, y_pos, instance) {
	return (instance && (instance.x == x_pos && instance.y == y_pos))
}

/// @function								is_direction_toward(dir, obj);
/// @param		{direction} dir				The direction from the calling instance to check whether the player is in or not
/// @param		{instance} obj				The object to check for the direction of
function is_direction_toward(dir, obj) {
	return ((y > obj.y && dir == directions.up) ||
	        (x < obj.x && dir == directions.right) ||
	        (y < obj.y && dir == directions.down) ||
	        (x > obj.x && dir == directions.left));
}

/// @function								turn_to_face_player();
function turn_to_face_player() {
	if (is_direction_toward(1, global.player)) { image_xscale = -1; }
	else { image_xscale = 1; }
}

/// @function  							teleport_near_player();
function teleport_near_player() {
	play_sound(snd_flicker, false);

	do {
	    var x_pos = (8*irandom(3));
	    var y_pos = (8*irandom(3));
	    if (get_coin_flip()) { x_pos *= -1; }
	    if (get_coin_flip()) { y_pos *= -1; }
	    x = global.player.x + x_pos;
	    y = global.player.y + y_pos;
	}
	until (get_distance_to_instance(global.player) >= 24 && !is_outside_room(x,y));
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
		if (current_solid != id && (!carrying_special_staff || (current_solid.object_index != obj_wall && current_solid.object_index != obj_column))) { return true; }
	}
	return false;
}

/// @function								is_lava_at_position(x_pos, y_pos);
/// @param		{int} x_pos					The x coordinate of the position
/// @param		{int} y_pos					The y coordinate of the position
function is_lava_at_position(x_pos, y_pos) {
	if ((object_index == obj_hands || object_index == obj_player) && is_carrying_item(obj_staff)) { return false; }
	
	var death_at_position = instance_place_all(x_pos, y_pos, obj_death);
	while (array_length(death_at_position) > 0) {
		var death = array_random_pop(death_at_position);
		if (death.object_index == obj_death) { return true; }
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
	
	// Set up general variables for blocking the given direction
	var blocked_by_room_boundry = is_outside_room(x_pos, y_pos);
	var blocked_by_death = (!ignore_death && is_lava_at_position(x_pos, y_pos));
	var blocked_by_solid = (!ignore_solid && is_solid_at_position(x_pos, y_pos));
	
	// The player is allowed to move outside the room while not on any solid
	if (object_index == obj_player && !place_meeting(x, y, obj_solid)) { blocked_by_room_boundry = false; }
	
	// return whether the direction is blocked
	return (!blocked_by_room_boundry && !blocked_by_solid && !blocked_by_death);
}

/// @function								is_outside_room(x_pos, y_pos);
/// @param		{int}	x_pos				The x position to check
/// @param		{int}	y_pos				The y position to check
function is_outside_room(x_pos, y_pos) {
	return (x_pos <= 0 || x_pos >= room_width || y_pos <= 0 || y_pos >= room_height);
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
	if (dir == directions.up) { y -= 8; } 
	else if (dir == directions.right) { x += 8; image_xscale = -1; }
	else if (dir == directions.down) { y += 8; }
	else if (dir == directions.left) { x -= 8; image_xscale = 1; }
	
	if (object_is_ancestor(object_index, obj_enemy)) { 
		check_for_player_collision();
		if (!corporeal) { make_noise = false; }
	}
	
	if (make_noise) {
		var snd = snd_walk;
		if (is_covered_at_each_quadrant_by(obj_lava)) { snd = snd_splash; }
		else if (is_covered_at_each_quadrant_by(obj_solid)) { snd = snd_thud; }
		play_sound(snd, false); 
	}
	

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
	var dir = directions.none, x_pos = global.player.x_prev, y_pos = global.player.y_prev;
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
	image_angle = irandom(3) * 90;
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
	
	for (var i = 0; i <= 3; i+= 1;) {
        var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);
		presence_at_quadrant[i] = instance_position(x_pos, y_pos, obj_index);
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
	var presence_at_quadrant = (obj_index == obj_lava) ? get_lava_at_each_quadrant() : get_instance_at_each_quadrant(obj_index);
	
	return (
		is_existing_instance(presence_at_quadrant[0]) &&
		is_existing_instance(presence_at_quadrant[1]) &&
		is_existing_instance(presence_at_quadrant[2]) &&
		is_existing_instance(presence_at_quadrant[3])
	);
}

/// @function								move_towards_coordinates(obj_index);
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
		enemies_at_position = instance_place_all(x, y, obj_enemy);
		while (array_length(enemies_at_position) > 0) {
			var enemy = array_random_pop(enemies_at_position);
			if (enemy.corporeal && is_instance_at_coordinates(x, y, enemy)) { pressed = true; break; }
		}
	}
	
	return pressed;
}

/// @function								get_sprite_to_use();
function get_sprite_to_use(regular_sprite) {
	if (!global.FARM_MODE) { return regular_sprite; }
	
	switch (regular_sprite) {
		/// Tiles
		case spr_collectable: { return spr_collectable_farmer; }
		case spr_bones: { return spr_bones_farmer; }
		case spr_cross: { return spr_cross_farmer; }
		case spr_giant_wurm: { return spr_giant_wurm_farmer; }
		case spr_portcullis: { return spr_portcullis_farmer; }
		/// Enemies
		case spr_skeleton: { return spr_skeleton_farmer; }
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
	}
	
	return regular_sprite;
}