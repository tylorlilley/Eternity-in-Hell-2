/// @function								move_player(dir);
/// @param		{direction} dir				The direction to move the player instance
function move_player(dir) {
	var player = global.player, game_manager = global.game_manager;
	if (dir == directions.none) { return; }
	
	with (player) {
		// Move player
		if (dir != directions.stairs) {
			image_index += 1;
			if (image_index > 1) { image_index = 0; }
			move_in_direction(dir, true);
			with (obj_echo_generator) { array_push(moves, dir); }
		}
		// Move light source
		set_instance_to_same_position(light);
		
		// Move carried items
		if (is_existing_instance(right_hand_item)) {
			set_instance_to_same_position(right_hand_item);
			if (is_carrying_item_in_right_hand(obj_torch)) { set_instance_to_same_position(right_hand_item.light_source); }
		}
		if (is_existing_instance(left_hand_item)) {
			set_instance_to_same_position(left_hand_item);
			if (is_carrying_item_in_left_hand(obj_torch)) { set_instance_to_same_position(left_hand_item.light_source); }
		}
		
		// Move Outline
		if (is_existing_instance(outline)) { set_instance_to_same_position(outline); }
	}
	
	var direction_pressed = (game_manager.key_up_pressed || 
							game_manager.key_down_pressed || 
							game_manager.key_right_pressed || 
							game_manager.key_left_pressed);
	
	// Update the spiders state
	with (obj_spider) { try_to_see_player(); }
	
	// Update the eyes postition
	with (obj_eyes) {
		var target = get_dropped_meat();
		if (!is_existing_instance(target)) {
			target = player;
			
			if (activated) {
				if (direction_pressed ||
					game_manager.key_up || 
					game_manager.key_down || 
					game_manager.key_left || 
					game_manager.key_right) {
						blink_amount = irandom_range(12, 32);
						target_x = target.x;
						target_y = target.y;
						set_automatic_target_path();
						move_towards_coordinates_on_path(false, false, 2);
						if (target_path != noone) { play_sound(snd_thud, false); }
						if (image_index != 1 && direction_pressed) { play_sound(snd_eyes, true); }
						image_index = 1;
				}
			}
		}
		turn_to_face_player();
	}
				
	// Update the bumper position
	if (direction_pressed) {
		with (obj_bumper) {
			teleport_near_player();
			turn_to_face_player();
		}
	}
}

/// @function								pick_up_or_put_down_item(dir);
/// @param		{direction} dir				The directional slot to pick up or drop an item into or from
function pick_up_or_put_down_item(dir) {
	var carried_item = noone
	if (dir == directions.right) { carried_item = right_hand_item; }
	else if (dir == directions.left) { carried_item = left_hand_item; }
	
	if (is_existing_instance(carried_item)) { put_down_item(carried_item, true, true); }
	else {
		// Cycle through the items you could be possibly picking up
		var dropped_items = instance_place_all(x, y, obj_item), 
		while (array_length(dropped_items) > 0) {
			var dropped_item = array_random_pop(dropped_items);
			if (is_existing_instance(dropped_item) && !is_existing_instance(dropped_item.holder) && dropped_item.can_pick_up && is_instance_at_coordinates(x, y, dropped_item)) {
				pick_up_item(dropped_item, true, dir);
				return dropped_item;
			}
		}
		var corpses = instance_place_all(x, y, obj_player_corpse);
		while (array_length(corpses) > 0) {
			var corpse = array_random_pop(corpses);
			if (is_existing_instance(corpse) && is_instance_at_coordinates(x, y, corpse) && !corpse.headless) {
				var new_item = create_item_in_hand(dir, obj_meat);
				corpse.headless = true;
				play_sound(snd_crunch, true);
				return new_item;
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
	else if (dir == directions.left) { left_hand_item = item; item.image_xscale = 1; }
	
	with (item) { become_carried(other.id); }
}

/// @function								put_down_item(item, make_noise, dropped);
/// @param		{instance} item				The item to pick up
/// @param		{boolean} make_noise		Whether or not to make a noise as part of putting down the item.
/// @param		{boolean} dropped			Whether or not this item is being dropped and not destroyed
function put_down_item(item, make_noise, dropped) {
	if (make_noise) { play_sound(snd_putdown, true); }
	
	if (right_hand_item == item) { right_hand_item = noone; }
	else if (left_hand_item == item) { left_hand_item = noone; }
	
	if (dropped) { with item { become_dropped(other.id); } }
}

/// @function								get_carried_item(dir);
/// @param		{index} obj_index			The object type to check the carried items for
function get_carried_item(obj_index) {
	var carried_item = noone;
	if (is_carrying_item_in_right_hand(obj_index)) { carried_item = right_hand_item; }
	if (is_carrying_item_in_left_hand(obj_index) && (!is_existing_instance(carried_item) || left_hand_item.special)) { carried_item = left_hand_item; }
	return carried_item;
}


/// @function								get_carried_lit_torch();
function get_carried_lit_torch() {
	var lit_torch = noone;
	
	if (is_carrying_item_in_right_hand(obj_torch) && is_existing_instance(right_hand_item.light_source)) { lit_torch = right_hand_item; }
	if (is_carrying_item_in_left_hand(obj_torch) && is_existing_instance(left_hand_item.light_source)) {
		if (lit_torch == noone) { lit_torch = left_hand_item; }
		else if (left_hand_item.special || lit_torch.time_to_remain_lit < left_hand_item.time_to_remain_lit) { lit_torch = left_hand_item; }
	}
	
	return lit_torch;
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

/// @function								is_carrying_lit_torch(require_both);
/// @param		{bool} require_both			Whether to require a lit torch in both hands or not
function is_carrying_lit_torch(require_both) {
	var right_hand_lit_torch = false, left_hand_lit_torch = false;
	
	right_hand_lit_torch = (is_carrying_item_in_right_hand(obj_torch) && is_existing_instance(right_hand_item.light_source));
	left_hand_lit_torch = (is_carrying_item_in_left_hand(obj_torch) && is_existing_instance(left_hand_item.light_source));
	
	if (require_both) { return (right_hand_lit_torch && left_hand_lit_torch); }
	else { return (right_hand_lit_torch || left_hand_lit_torch); }
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
	var player = global.player, controller = global.controller;
	if (global.controller.blackout || global.controller.transition != directions.none) { return false; }
	
	if (!player.dead) {
		// Set variables to mark death
		player.depth = CORPSE_DEPTH;
		player.dead = true;
		controller.death_timer = RESPAWN_FREQUENCY;
		controller.death_count += 1;
		play_sound(snd_lose, true);
		with (obj_echo_generator) { instance_destroy(); }
		
		// Put down carried items other than rosary
		with (player) {
			if (is_existing_instance(right_hand_item) && right_hand_item.object_index != obj_rosary) { put_down_item(right_hand_item, false, true); }
			if (is_existing_instance(left_hand_item) && left_hand_item.object_index != obj_rosary) { put_down_item(left_hand_item, false, true); }
		}
		
		controller.killed_by = (killed_by_obj == -1) ? other.object_index : killed_by_obj;
		if (player.infected_timer > 0 && controller.time_remaining > 0) { controller.killed_by = obj_bug; }
		update_death_log(controller.killed_by, global.difficulty);
	}
	return true;
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
	if (is_carrying_item(obj_staff)) { draw_self(); }
}

/// @function				draw_player_hat();
function draw_player_hat() {
	if (global.is_farm_mode) { draw_sprite_ext(spr_player_farmer, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha); }
}

/// @function				draw_player_worm();
function draw_player_worm() {
	if (infected_timer > 0 && !dead) { draw_sprite_ext(spr_bug_red, bug_image_index, x, y-10+image_index, image_xscale, image_yscale, image_angle, image_blend, image_alpha); }
}

/// @function				snap_player_to_position(dir);
/// @param		{dir} dir	The direction to snap the player opposite to
function snap_player_to_position(dir) {
	var player = global.player;
	player.moved_by = id;
	player.x = x;
	player.y = y;
	switch (dir) {
		case directions.up: { player.y += 16; break; }
		case directions.down: { player.y -= 16; break; }
		case directions.left: { player.x += 16; break; }
		case directions.right: { player.x -= 16; break; }
	}
}

/// @function						draw_player();
function draw_player() {
	// Draw box over lava or staff solids
	draw_staff_box();

	// Draw main sprite
	event_inherited();

	// Draw Hands
	if ((image_xscale == 1 && is_existing_instance(left_hand_item)) || (image_xscale == -1 && is_existing_instance(right_hand_item))) {
		draw_sprite_ext(spr_player_left_hand, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	if ((image_xscale == -1 && is_existing_instance(left_hand_item)) || (image_xscale == 1 && is_existing_instance(right_hand_item))) {
		draw_sprite_ext(spr_player_right_hand, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}

	// Draw hat in farm mode
	draw_player_hat();

	// Draw worm if infected
	draw_player_worm();
}