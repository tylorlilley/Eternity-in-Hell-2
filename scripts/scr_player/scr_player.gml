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
		if (is_existing_instance(right_hand_item)) {
			set_instance_to_same_position(right_hand_item);
			if (is_carrying_item_in_right_hand(obj_torch)) { set_instance_to_same_position(right_hand_item.light_source); }
		}
		if (is_existing_instance(left_hand_item)) {
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
	
	if (is_existing_instance(carried_item)) { put_down_item(carried_item, true); }
	else {
		// Cycle through the items you could be possibly picking up
		var dropped_items = instance_place_all(x, y, obj_item);
		while (array_length(dropped_items) > 0) {
			var dropped_item = array_random_pop(dropped_items);
			if (is_existing_instance(dropped_item) && !is_existing_instance(dropped_item.holder) && dropped_item.can_pick_up && is_instance_at_coordinates(x, y, dropped_item)) {
				pick_up_item(dropped_item, true, dir);
				break;
			}
		}
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
	if (is_carrying_item_in_left_hand(obj_index) && (!is_existing_instance(carried_item) || left_hand_item.special)) { carried_item = left_hand_item; }
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
	return (is_existing_instance(right_hand_item) && right_hand_item.object_index == obj_index);
}

/// @function								is_carrying_item_in_left_hand(obj_index);
/// @param		{index} obj_index			The object type to check the carried items for
function is_carrying_item_in_left_hand(obj_index) {
	return (is_existing_instance(left_hand_item) && left_hand_item.object_index == obj_index);
}

/// @function								is_carrying_special_item(dir);
/// @param		{index} obj_index			The object type to check the carried items for
function is_carrying_special_item(obj_index) {
	var item = get_carried_item(obj_index)
	return (is_existing_instance(item) && item.special);
}

/// @function								create_item_in_hand(dir, obj_index);
/// @param		{direction} dir				The directional slot to pick up or drop an item into or from
/// @param		{index} obj_index			The type of item to create in hand
function create_item_in_hand(dir, obj_index) {
	with (global.player) {
		var new_item = instance_create(x, y, obj_index)
		
		if (dir == directions.right) { right_hand_item = new_item; new_item.image_xscale = -1; }
		else if (dir == directions.left) { left_hand_item = new_item; new_item.image_xscale =1; }
		
		with (new_item) { become_carried(other.id); }
		return new_item;
	}
}

/// @function								kill_player(killed_by_obj);
/// @param		{obj} killed_by_obj				The object_index of the thing killing the player
function kill_player(killed_by_obj) {
	if (!global.player.dead) {
		// Set variables to mark death
		global.player.depth = 4;
		global.player.dead = true;
		global.controller.death_timer = global.controller.RESPAWN_FREQUENCY;
		play_sound(snd_lose, true);
		with (obj_echo_spot) { instance_destroy(); }
		
		// Put down carried items other than rosary
		with (global.player) {
			if (is_existing_instance(right_hand_item) && right_hand_item.object_index != obj_rosary) { put_down_item(right_hand_item, false); }
			if (is_existing_instance(left_hand_item) && left_hand_item.object_index != obj_rosary) { put_down_item(left_hand_item, false); }
		}
		
		global.controller.killed_by = (killed_by_obj == noone) ? other.object_index : killed_by_obj;
		update_death_log(global.controller.killed_by, global.difficulty);
	}
}

/// @function					can_drop_item(item)
/// @param		{inst} item		The item you are trying to drop
function can_drop_item(item) {
	if (!is_existing_instance(item)) { return true; }
	if (is_outside_room(x, y)) { return false; }
	if (item.object_index == obj_shovel) { return can_dig_hole(); }
	else { return (!place_meeting(x, y, obj_solid)); }
}

/// @function				draw_staff_box();
function draw_staff_box() {
	if (is_carrying_item(obj_staff)) {
		var lava_at_quadrant = get_instance_at_each_quadrant(obj_lava), wall_at_quadrant = get_instance_at_each_quadrant(obj_wall), column_at_quadrant = get_instance_at_each_quadrant(obj_column);
		for (var i = 0; i <= 3; i +=1;) {
			var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

			if (is_existing_instance(lava_at_quadrant[i]) || is_existing_instance(wall_at_quadrant[i]) || is_existing_instance(column_at_quadrant[i])) {
			    draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1);
			}
		}
	}
	
	draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}

/// @function				draw_player_hat();
function draw_player_hat() {
	if (global.FARM_MODE) { draw_sprite_ext(spr_player_farmer, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha); }
}

/// @function				snap_player_to_position(dir);
/// @param		{dir} dir	The direction to snap the player opposite to
function snap_player_to_position(dir) {
	global.player.moved_by = id;
	global.player.x = x;
	global.player.y = y;
	switch (dir) {
		case directions.up: { global.player.y += 16; break; }
		case directions.down: { global.player.y -= 16; break; }
		case directions.left: { global.player.x += 16; break; }
		case directions.right: { global.player.x -= 16; break; }
	}
}