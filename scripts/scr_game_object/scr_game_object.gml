/// @function								distance_to_instance(instance);
/// @param		{index} instance			The instance whose distance away from the calling instance is to be calculated
function distance_to_instance(instance) {
	if (!instance_exists(instance)) { return -1; }
	if (self.id == instance.id) { return 0; }

	return sqrt((sqr(instance.x - x) + sqr(instance.y - y)));
}

/// @function								instance_at_coordinates(x_pos, y_pos, instance);
/// @param		{real}  x_pos				The x value to check against the instance's x value
/// @param		{real}  y_pos				The y value to check against the instance's y value
/// @param		{index} instance			The instance whos positional coordinates are being checked
function instance_at_coordinates(x_pos, y_pos, instance) {
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
	    if (get_random_chance_out_of(2)) { x_pos *= -1; }
	    if (get_random_chance_out_of(2)) { y_pos *= -1; }
	    x = global.player.x + x_pos;
	    y = global.player.y + y_pos;
	}
	until (distance_to_instance(global.player) >= 24 && !position_is_outside_room(x,y));
}


/// @function								can_move_in_direction(dir, ignore_solid);
/// @param		{direction}	dir				The direction to check whether the calling instance can move in
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function can_move_in_direction(dir, ignore_solid, ignore_death) {
	return ((object_index != obj_player || !global.controller.key_space) && direction_is_free(dir, ignore_solid, ignore_death));
}

/// @function								direction_is_free(dir, ignore_solid);
/// @param		{direction}	dir				The direction to check whether the calling instance can move in
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function direction_is_free(dir, ignore_solid, ignore_death) {
	var x_pos = x, y_pos = y;
	switch (dir) {
		case directions.up: { y_pos -= 8; break; }
		case directions.right: { x_pos += 8; break; }
		case directions.down: { y_pos += 8; break; }
		case directions.left: { x_pos -= 8; break; }
		default: { return false; }
	}
	
	// Set up general variables for blocking the given direction
	var blocked_by_room_boundry = position_is_outside_room(x_pos, y_pos);
	var blocked_by_solid = (!ignore_solid && instance_place(x_pos, y_pos, obj_solid));
	var blocked_by_death = (!ignore_death && instance_place(x_pos, y_pos, obj_death) && instance_place(x_pos, y_pos, obj_death).lava);
	
	if (object_index == obj_player) {
		// Allow player to not be blocked by walls and columns if they are carrying the special amulet
		var carried_amulet = get_carried_item_of_type(obj_amulet);
		var has_special_amulet = (carried_amulet != noone && carried_amulet.special);
		
		if (has_special_amulet) {
			blocked_by_solid = false;
			var blocking_solids = instance_place_all(x_pos, y_pos, obj_solid);
			while (array_length(blocking_solids) > 0) {
				var current_solid = array_random_pop(blocking_solids);
				if (current_solid.object_index != obj_wall && current_solid.object_index != obj_column) {
					blocked_by_solid = true;
					break;
				}
			}
		}
		
		// Allow the player to move outside the room if they aren't currently on a solid object
		if (!instance_place(x, y, obj_solid)) { blocked_by_room_boundry = false; }
	}
	
	// return whether the direction is blocked
	return (!blocked_by_room_boundry && !blocked_by_solid && !blocked_by_death);
}

/// @function								position_is_outside_room(x_pos, y_pos);
/// @param		{int}	x_pos				The x position to check
/// @param		{int}	y_pos				The y position to check
function position_is_outside_room(x_pos, y_pos) {
	return (x_pos <= 0 || x_pos >= room_width || y_pos <= 0 || y_pos >= room_height);
}

/// @function								can_move_in_direction_and_reach(dir, ignore_solid);
/// @param		{direction}	dir				The direction to check whether the calling instance can move in
/// @param		{index}	target_instance		The instance we are trying to reach by moving in this direction
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function can_move_in_direction_and_reach(dir, target_instance, ignore_solid, ignore_death) {
	var original_x = x, original_y = y, can_reach_target = false;
	
	while(can_move_in_direction(dir, ignore_solid, ignore_death) && !can_reach_target) {
		move_in_direction(dir, false);
		if (instance_at_coordinates(x, y, target_instance)) { can_reach_target = true; }
	}
	
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
	
	if (make_noise) {
		var snd = snd_walk, lava_at_quadrant = lava_at_position(), solid_at_quadrant = get_presence_at_each_quadrant(obj_solid);
		if (lava_at_quadrant[0] != noone || lava_at_quadrant[1] != noone || lava_at_quadrant[2] != noone || lava_at_quadrant[3] != noone) { snd = snd_splash; }
		else if (solid_at_quadrant[0] != noone || solid_at_quadrant[1] != noone || solid_at_quadrant[2] != noone || solid_at_quadrant[3] != noone) { snd = snd_thud; }
		play_sound(snd, false); 
	}
	
	if (object_get_parent(self) == obj_enemy) { check_for_player_collision(); }
}


/// @function								set_instance_to_same_position(instance);
/// @param		{index} instance			The instance to set to the same position as the calling instance
function set_instance_to_same_position(instance) {
	with instance { 
	    x = other.x; 
	    y = other.y; 
	    //image_xscale = other.image_xscale; 
	}
}

/// @function								pushed_against_by_player();
function pushed_against_by_player() {
	var dir = noone, x_pos = global.player.x_prev, y_pos = global.player.y_prev;
	dir = get_direction_input(true);
	if (dir == noone) { return dir; }
	
	switch (dir) {
		case directions.up: { y_pos -= 16; break; }
		case directions.right: { x_pos += 16; break; }
		case directions.down: { y_pos += 16; break; }
		case directions.left: { x_pos -= 16; break; }
	}
	
	if (!instance_at_coordinates(x_pos, y_pos, self)) { 
		dir = noone; 
	}
	
	return dir;
}

/// @function								rotate_sprite_to_random_angle();
function rotate_sprite_to_random_angle() {
	image_angle = irandom(3) * 90;
}

/// @function								flip_sprite_at_random();
/// @param		{boolean} flip_vertical		Whether or not to also randomly flip the sprite vertically
function flip_sprite_at_random(flip_vertical) {
	image_xscale = get_random_chance_out_of(2) ? 1 : -1;
	if (flip_vertical) { image_yscale = get_random_chance_out_of(2) ? 1 : -1; }
}

/// @function								get_presence_at_each_quadrant(obj_index);
///	@param		{index} obj_index			The object type to check the presence of in each quadrant
function get_presence_at_each_quadrant(obj_index) {
	var presence_at_quadrant =[noone, noone, noone, noone];
	
	for (var i = 0; i <= 3; i+= 1;) {
        var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);
       presence_at_quadrant[i] = instance_position(x_pos, y_pos, obj_index);
    }
	
	return presence_at_quadrant;
}

/// @function								move_towards_coordinates(obj_index);
///	@param		{int} target_x				The x position to be moving toward
///	@param		{int} target_y				The y position to be moving toward
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function move_towards_coordinates(target_x, target_y, ignore_solid, ignore_death) {
	var move_dir = get_random_possible_direction(target_x, target_y, ignore_solid, ignore_death);
	if (move_dir != noone) { move_in_direction(move_dir, true); }
	
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
	var move_dir = array_length(possible_directions) > 0 ? array_random_get(possible_directions) : noone;
	return move_dir;
}

/// @function								randomize_image(max_image_index);
///	@param		{int} max_image_index		The max image_index value possible for this object's sprite
function randomize_image(max_image_index) {
	image_speed = 0;
	image_index = irandom(max_image_index);
	flip_sprite_at_random(true);
	rotate_sprite_to_random_angle();
}

/// @function								singleton_instance();
function singleton_instance() {
	if (instance_number(object_index) > 1) { instance_destroy(); }
}

/// @function								press_button();
function can_press_button() {	
	var enemy = instance_position(x, y, obj_enemy), block = instance_position(x, y, obj_solid);
	
	return (
		(enemy && enemy.killable_by_sword && instance_at_coordinates(x, y, enemy)) || 
		instance_at_coordinates(x, y, global.player) || 
		(block && instance_at_coordinates(x, y, block))
	);
}