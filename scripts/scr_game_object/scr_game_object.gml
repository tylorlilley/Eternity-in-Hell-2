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

/// @function								is_direction_toward_player(dir);
/// @param		{direction} dir				The direction from the calling instance to check whether the player is in or not
function is_direction_toward_player(dir) {
	return ((y > global.player.y && dir == directions.up) ||
	        (x < global.player.x && dir == directions.right) ||
	        (y < global.player.y && dir == directions.down) ||
	        (x > global.player.x && dir == directions.left));
}

/// @function								turn_to_face_player();
function turn_to_face_player() {
	if (is_direction_toward_player(1)) { image_xscale = -1; }
	else { image_xscale = 1; }
}

/// @function  							teleport_near_player();
function teleport_near_player() {
	audio_play_sound( snd_flicker, 10, false );

	do {
	    var x_pos = (8*irandom(3));
	    var y_pos = (8*irandom(3));
	    if (get_random_chance_out_of(2)) { x_pos *= -1; }
	    if (get_random_chance_out_of(2)) { y_pos *= -1; }
	    x = global.player.x + x_pos;
	    y = global.player.y + y_pos;
	}
	until (distance_to_instance(global.player) >= 24 && y >= 0 && y <= room_height && x >= 0 && x <= room_width);
}


/// @function								can_move_in_direction(dir, ignore_solid);
/// @param		{direction}	dir				The direction to check whether the calling instance can move in
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function can_move_in_direction(dir, ignore_solid, ignore_death) {
	return (!global.controller.key_space && (ignore_solid || !instance_place(x, y, obj_solid)) && 
	    ((dir == directions.up && (ignore_death || !instance_place(x, y-8, obj_death)) && (ignore_solid || !instance_place(x, y-8, obj_solid)) && (object_index == obj_player || y-8 > 0)) ||
	    (dir == directions.down && (ignore_death || !instance_place(x, y+8, obj_death)) && (ignore_solid || !instance_place(x, y+8, obj_solid)) && (object_index == obj_player || y+8 < room_height)) ||
	    (dir == directions.left && (ignore_death || !instance_place(x-8, y, obj_death)) && (ignore_solid || !instance_place(x-8, y, obj_solid)) && (object_index == obj_player || x-8 > 0)) ||
	    (dir == directions.right && (ignore_death || !instance_place(x+8, y, obj_death))&& (ignore_solid || !instance_place(x+8, y, obj_solid)) && (object_index == obj_player || x+8 < room_width))));
}

/// @function								can_move_in_direction(dir, ignore_solid);
/// @param		{direction}	dir				The direction to check whether the calling instance can move in
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function can_move_worm_in_direction(dir, ignore_solid, ignore_death) {
	return (!global.controller.key_space &&
	    ((dir == directions.up && (ignore_death || !instance_place(x, y-8, obj_death)) && (ignore_solid || !instance_place(x, y-8, obj_solid)) && (object_index == obj_player || y-8 > 0)) ||
	    (dir == directions.down && (ignore_death || !instance_place(x, y+8, obj_death)) && (ignore_solid || !instance_place(x, y+8, obj_solid)) && (object_index == obj_player || y+8 < room_height)) ||
	    (dir == directions.left && (ignore_death || !instance_place(x-8, y, obj_death)) && (ignore_solid || !instance_place(x-8, y, obj_solid)) && (object_index == obj_player || x-8 > 0)) ||
	    (dir == directions.right && (ignore_death || !instance_place(x+8, y, obj_death))&& (ignore_solid || !instance_place(x+8, y, obj_solid)) && (object_index == obj_player || x+8 < room_width))));
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
/// @param		{boolean} play_sound		Whether or not to play a movement sound
function move_in_direction(dir, play_sound) {
	if (play_sound) { audio_play_sound( snd_walk, 10, false ); }
	
	if (dir == directions.up) { y -= 8; } 
	if (dir == directions.right) { x += 8; image_xscale = -1; }
	if (dir == directions.down) { y += 8; }
	if (dir == directions.left) { x -= 8; image_xscale = 1; }
}


/// @function								set_instance_to_same_position(instance);
/// @param		{index} instance			The instance to set to the same position as the calling instance
function set_instance_to_same_position(instance) {
	with instance { 
	    x = other.x; 
	    y = other.y; 
	    image_xscale = other.image_xscale; 
	}
}

/// @function								audio_play_sound_for_object_only_once();
/// @param		{index} sound_to_play		The sound to play only once
function audio_play_sound_for_object_only_once(sound_to_play) {
	if ((instance_number(object_index) > 0) && instance_find(object_index, 0).id == id) { audio_play_sound( sound_to_play, 10, false ); }
}

/// @function								pushed_against_by_player(key_pressed_only);
function pushed_against_by_player(key_pressed_only) {
	if (global.player.dead) { return noone; }
	if (instance_at_coordinates(global.player.x_prev, global.player.y_prev-16, self) && (global.controller.key_up_pressed || (!key_pressed_only && global.controller.key_up))) { return directions.up; }
	else if (instance_at_coordinates(global.player.x_prev, global.player.y_prev+16, self) && (global.controller.key_down_pressed || (!key_pressed_only && global.controller.key_down))) { return directions.down; }
	else if (instance_at_coordinates(global.player.x_prev-16, global.player.y_prev, self) && (global.controller.key_left_pressed || (!key_pressed_only && global.controller.key_left))) { return directions.left; }
	else if (instance_at_coordinates(global.player.x_prev+16, global.player.y_prev, self) && (global.controller.key_right_pressed || (!key_pressed_only && global.controller.key_right))) { return directions.right; }
	else { return noone; }
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

/// @function								get_presence_at_each_quadrant(obj_index);
///	@param		{index} obj_index			The object type to check the presence of in each quadrant
function move_towards_coordinates(target_x, target_y) {
	var x_dif = abs(x - target_x), y_dif = abs(y - target_y), move_dir = noone;
	if (x_dif > y_dif) {
		if (x < target_x) { move_dir = directions.right; }
		if (x > target_x) { move_dir = directions.left; }
	}
	else if (y_dif < x_dif) {
		if (y < target_y) { move_dir = directions.down; }
		if (y > target_y) { move_dir = directions.up; }
	}
	else {
		if (x_dif >= 8 && y_dif >= 8) {
			if (get_random_chance_out_of(2)) {
				if (y < target_y) { move_dir = directions.down; }
				if (y > target_y) { move_dir = directions.up; }
			}
			else {
				if (x < target_x) { move_dir = directions.right; }
				if (x > target_x) { move_dir = directions.left; }
			}
		}
	}
	
	move_in_direction(move_dir, false);
}
