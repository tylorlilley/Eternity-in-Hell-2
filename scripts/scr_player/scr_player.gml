/// @function								move_player(dir);
/// @param		{direction} dir				The direction to move the player instance
function move_player(dir) {
	with global.player {
		// Move player
		if (dir != directions.stairs) {
			image_index += 1;
			if (image_index > 1) { image_index = 0; }
			move_in_direction(dir, true);
			with (obj_echo_spot) { array_push(moves, dir); }
		}
		// Move carried items
		if (right_hand_item != noone) {
			set_instance_to_same_position(right_hand_item);
			if (is_carrying_item_in_right_hand(obj_torch)) { set_instance_to_same_position(right_hand_item.light_source); }
		}
		if (left_hand_item != noone) {
			set_instance_to_same_position(left_hand_item);
			if (is_carrying_item_in_left_hand(obj_torch)) { set_instance_to_same_position(left_hand_item.light_source); }
		}
	}
}

/// @function								pick_up_or_put_down_item(dir);
/// @param		{direction} dir				The directional slot to pick up or drop an item into or from
function pick_up_or_put_down_item(dir) {
	var carried_item = noone
	if (dir == directions.right) { carried_item = right_hand_item; }
	else if (dir == directions.left) { carried_item = left_hand_item; }
	
	if (carried_item != noone) { put_down_item(carried_item, true); }
	else {
		// Cycle through the items you could be possibly picking up
		var dropped_items = instance_place_all(x, y, obj_item);
		while (array_length(dropped_items) > 0) {
			var dropped_item = array_random_pop(dropped_items);
			if (dropped_item && dropped_item.holder == noone && dropped_item.can_pick_up && is_instance_at_coordinates(x, y, dropped_item)) {
				pick_up_item(dropped_item, true, dir); 
				return true;
			}
		}
		return false;
	}
}

/// @function								pick_up_item(item, make_noise, dir);
/// @param		{instance} item				The item to pick up
/// @param		{boolean} make_noise		Whether or not to make a noise as part of picking up the item.
/// @param		{direction} dir				The hand this item is being picked up with
function pick_up_item(item, make_noise, dir) {
	if (make_noise) { play_sound(snd_pickup, true); }
	
	if (dir == directions.right) { right_hand_item = item; item.image_xscale = -1; }
	else if (dir == directions.left) { left_hand_item = item; item.image_xscale =1; }
	
	with (item) { become_carried(other.id); }
}

/// @function								put_down_item(dir);
/// @param		{instance} item				The item to pick up
/// @param		{boolean} make_noise		Whether or not to make a noise as part of picking up the item.
function put_down_item(item, make_noise) {
	if (make_noise) { play_sound(snd_putdown, true); }
	
	if (right_hand_item == item) { right_hand_item = noone; }
	else if (left_hand_item == item) { left_hand_item = noone; }
	
	with item { become_dropped(other.id); }
}

/// @function								get_carried_item(dir);
/// @param		{index} obj_index			The object type to check the carried items for
function get_carried_item(obj_index) {
	var carried_item = noone;
	if (is_carrying_item_in_right_hand(obj_index)) { carried_item = right_hand_item; }
	if (is_carrying_item_in_left_hand(obj_index) && (carried_item == noone || left_hand_item.special)) { carried_item = left_hand_item; }
	return carried_item;
}

/// @function								is_carrying_item(obj_index);
/// @param		{index} obj_index			The object type to check the carried items for
function is_carrying_item(obj_index) {
	return (is_carrying_item_in_right_hand(obj_index) || is_carrying_item_in_left_hand(obj_index));
}

/// @function								is_carrying_item_in_right_hand(obj_index);
/// @param		{index} obj_index			The object type to check the carried items for
function is_carrying_item_in_right_hand(obj_index) {
	return (right_hand_item != noone && right_hand_item.object_index == obj_index);
}

/// @function								is_carrying_item_in_left_hand(obj_index);
/// @param		{index} obj_index			The object type to check the carried items for
function is_carrying_item_in_left_hand(obj_index) {
	return (left_hand_item != noone && left_hand_item.object_index == obj_index);
}

/// @function								is_carrying_special_item(dir);
/// @param		{index} obj_index			The object type to check the carried items for
function is_carrying_special_item(obj_index) {
	var item = get_carried_item(obj_index)
	return (item != noone && item.special);
}

/// @function								create_item_in_hand(dir, obj_index);
/// @param		{direction} dir				The directional slot to pick up or drop an item into or from
/// @param		{index} obj_index			The type of item to create in hand
function create_item_in_hand(dir, obj_index) {
	with (global.player) {
		var new_item = instance_create_depth(x, y, -5, obj_index)
		
		if (dir == directions.right) { right_hand_item = new_item; new_item.image_xscale = -1; }
		else if (dir == directions.left) { left_hand_item = new_item; new_item.image_xscale =1; }
		
		with (new_item) {
			// Become carried
			holder = other.id;
			persistent = other.persistent;
			depth = -10;
		}
		
		return new_item;
	}
}

/// @function								kill_player();
function kill_player() {
	// Set variables to mark death
	global.player.dead = true;
	global.controller.death_timer = global.controller.RESPAWN_FREQUENCY;
	play_sound(snd_lose, true);
	with (obj_echo_spot) { instance_destroy(); }
}

/// @function								put_down_all_items()
function put_down_all_items() {
	put_down_item(right_hand_item, false);
	put_down_item(left_hand_item, false);
}

/// @function								get_direction_input(key_pressed_only)
/// @param		{bool} key_pressed_only		Whether to only count if the key has been pressed this frame
function get_direction_input(key_pressed_only) {
	// Return no input if player is dead or looking at map
	if (global.player.dead || global.controller.key_space) { return noone; }
	
	// Starting with the previous direction, check each direction for inputs
	var possible_directions = array_create(0);
	for (var i = 0; i < 4; i++) {
		var current_dir = (i+global.player.dir_prev) % 4;
		
		// For the player object, skip directions that block movement
		// This allows doors, chests, blocks, etc. to evaluate ignoring blocking objects
		// so that they can be pushed and opened even when against a wall
		if (object_index == obj_player && !can_move_in_direction(current_dir, false, true)) { continue; }
		
		if current_dir == directions.up &&
			global.controller.key_up && 
			!global.controller.key_down &&
			(global.controller.key_up_pressed || !global.controller.key_up_released) &&
			(!key_pressed_only || global.controller.key_up_pressed) { 
				array_push(possible_directions, directions.up); 
		}
		else if current_dir == directions.down &&
				global.controller.key_down && 
				!global.controller.key_up &&
				(global.controller.key_down_pressed || !global.controller.key_down_released) &&
				(!key_pressed_only || global.controller.key_down_pressed) { 
					array_push(possible_directions, directions.down);  
		}
		else if current_dir == directions.left &&
				global.controller.key_left && 
				!global.controller.key_right &&
				(global.controller.key_left_pressed || !global.controller.key_left_released) &&
				(!key_pressed_only || global.controller.key_left_pressed) { 
					array_push(possible_directions, directions.left); 
		}
		else if current_dir == directions.right &&
				global.controller.key_right && 
				!global.controller.key_left &&
				(global.controller.key_right_pressed || !global.controller.key_right_released) && 
				(!key_pressed_only || global.controller.key_right_pressed) { 
					array_push(possible_directions, directions.right); 
		}
	}
	
	if (array_length(possible_directions) == 0) { return noone; }
	return possible_directions[0];
}

/// @function					can_drop_item(item)
/// @param		{inst} item		The item you are trying to drop
function can_drop_item(item) {
	if (item == noone) { return true; }
	if (is_outside_room(x, y)) { return false; }
	if (item.object_index == obj_shovel) { return can_make_hole(); }
	else { return (!place_meeting(x, y, obj_solid)); }
}

/// @function					can_make_hole()
function can_make_hole() {
	return (!place_meeting(x, y, obj_solid) &&
			!place_meeting(x, y, obj_door) &&
			!place_meeting(x, y, obj_stairs) &&
			!place_meeting(x, y, obj_lava) &&
			!place_meeting(x, y, obj_lantern) &&
			!place_meeting(x, y, obj_cross) &&
			!place_meeting(x, y, obj_bush) &&
			!place_meeting(x, y, obj_hole) &&
			!place_meeting(x, y, obj_block_spot));
}

/// @function				draw_staff_box();
function draw_staff_box() {
	if (is_carrying_item(obj_staff)) {
		var lava_at_quadrant = get_instance_at_each_quadrant(obj_lava), wall_at_quadrant = get_instance_at_each_quadrant(obj_wall), column_at_quadrant = get_instance_at_each_quadrant(obj_column);
		for (var i = 0; i <= 3; i +=1;) {
			var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

			if (lava_at_quadrant[i] != noone || wall_at_quadrant[i] != noone || column_at_quadrant[i] != noone) {
			    draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1);
			}
		}
	}
}