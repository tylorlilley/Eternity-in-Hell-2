/// @function								draw_while_carried();
function draw_while_carried(x_pos, y_pos, x_offset, y_offset, spr_width, spr_height, xscale, blend, spr = sprite_index) {
	if (!is_existing_instance(holder)) { return; }
	
	var draw_x_offset = image_xscale * -8;

	// Draw Main Item Sprite
	draw_sprite_part_ext(spr, image_index, x_offset, y_offset, spr_width, spr_height, x_pos+draw_x_offset, y_pos+draw_y_offset, xscale, image_yscale, blend, image_alpha);
	
	// Draw Clock Time & Compass Hands
	if (time_sprite_index != noone) {			
		draw_sprite_part_ext(time_sprite_index, time_image_index, x_offset, y_offset, spr_width, spr_height, x_pos+draw_x_offset, y_pos+draw_y_offset, xscale, image_yscale, blend, image_alpha);
	}
	
	// Draw Torch Lights
	if (torch_light_image_timer >= 0) { draw_sprite_part_ext(torch_light_sprite_index, torch_light_image_index, x_offset, y_offset, spr_width, spr_height, x_pos+draw_x_offset, y_pos+draw_y_offset, xscale, image_yscale, blend, image_alpha); }
}

/// @function								become_carried(new_holder);
/// @param		{boolean} new_holder		The instance to begin holding the item.
function become_carried(new_holder) {
	var controller = global.controller;
	
	// Become carried
	holder = new_holder;
	persistent = new_holder.persistent;
	depth = CARRIED_ITEM_DEPTH;
	
	// Update player map
	controller.current_room.remove_from_instances_at_map_positions(id); 
	
	// Perform individual item pick-up actions
	switch (object_index) {
		case obj_bomb: { defuse_bomb(); break; }
		case obj_shovel: { dig_hole(); break; }
		case obj_heart: { mark_heart_carried(); break; }
		case obj_meat: { array_remove(controller.dropped_meat, id); break; }
		case obj_torch: {
			if (!is_existing_instance(light_source)) {
				var other_lit_torch = noone;
				if (is_existing_instance(new_holder)) { 
					with (new_holder) { other_lit_torch = get_carried_lit_torch(); }
				}
				if (is_existing_instance(other_lit_torch) && is_existing_instance(other_lit_torch.light_source)) { light_torch(other_lit_torch, true); }
			}
			break;
		}
	}
}

/// @function								become_dropped(dropper);
/// @param		{inst} dropper				The instance dropping this item
function become_dropped(dropper) {
	var player = global.player, controller = global.controller;
	
	// Update player map
	controller.current_room.add_to_instances_at_map_positions(id); 
	
	// Perform individual item drop actions
	switch (object_index) {
		case obj_meat: { array_push(controller.dropped_meat, id); break; }
		case obj_shovel: { dropped_by_digger = (dropper.object_index == obj_player || dropper.object_index == obj_hands); break; }
		case obj_bomb: {
			if (is_existing_instance(dropper) && dropper.object_index == obj_player) {
				var light_bomb = false;
				with (dropper) { 
					if (is_carrying_lit_torch(false)) { light_bomb = true; }
				}
				if (light_bomb) { light_bomb(); }
			}
			break;
		}
	}
	
	// Become dropped
	holder = noone;
	persistent = false;
	depth = DROPPED_ITEM_DEPTH;
	x = dropper.x;
	y = dropper.y;
	
	// Perform individual actions based on dropper
	xstart = x;
	ystart = y;
	
	// Alert interested obj_hands to come grab it
	with (obj_hands) { 
		if (dropper != id && activated && !is_carrying_item(obj_meat) && (!is_existing_instance(right_hand_item) || dropper == player || object_is_ancestor(dropper.object_index, obj_item))) {
			target_item = other.id;
			target_x = target_item.x;
			target_y = target_item.y;
			if (set_automatic_target_path()) { 
				play_sound(snd_laugh, true);
			}
		} 
	}
}

/// @function								make_item_special();
function make_item_special() {
	special = true;
	image_index = 1;
	if (object_index == obj_torch) { 
		lighting_range = TORCH_LIGHT_RANGE*2;
		torch_light_sprite_index = spr_special_torch_light;
	}
}

/// @function								defuse_bomb();
function defuse_bomb() {
	if (fuse_timer != 0) { play_sound(snd_fuse, false); }
	fuse_timer = 0;
	visible = true;
}

/// @function					can_dig_hole()
function can_dig_hole() {
	return (!place_meeting(x, y, obj_bones) &&
			!place_meeting(x, y, obj_solid) &&
			!place_meeting(x, y, obj_door) &&
			!place_meeting(x, y, obj_stairs) &&
			!place_meeting(x, y, obj_lava) &&
			!place_meeting(x, y, obj_lantern) &&
			!place_meeting(x, y, obj_cross) &&
			!place_meeting(x, y, obj_bush) &&
			!place_meeting(x, y, obj_block_spot));
}

/// @function								dig_hole();
function dig_hole() {
	if (can_dig_hole() && dropped_by_digger) {
		play_sound(snd_shovel, true);
		if (!special) { damaged += 1; }
		instance_create(x, y, obj_hole);
	}
}

/// @function								thump();
function thump() {
	if (is_thump_frame()) {
		if (image_index == 0) { play_sound(snd_thump, false); image_index = 3; }
	}
	else { image_index = 1; }
}

/// @function								mark_heart_carried();
function mark_heart_carried() {
	var controller = global.controller;
	if (!controller.carried_heart && holder == global.player) { 
		controller.completion_amount += 1;
		controller.carried_heart = true;
	}
}

/// @function								get_dropped_meat();
function get_dropped_meat() {
	var dropped_meats = global.controller.dropped_meat;
	if (array_length(dropped_meats) == 0) { return noone; }
	else { return dropped_meats[array_length(dropped_meats)-1]; }
}

/// @function								get_random_item_obj(special_item, include_key);
/// @param		{bool} special_item			Whether to check against the spawned special items or not
/// @param		{bool} include_key			Whether to include the key in what can be returned or not
function get_random_item_obj(special_item, include_key) {
	/*
	var controller = global.controller, difficulty = global.difficulty;
	var available_item_objs = (difficulty == difficulties.easy) ? 2 : 5;
	if (difficulty > difficulties.medium) { available_item_objs += 3; }
	if (include_key) { available_item_objs += 1; }
	var chosen_item_obj = -1;
	*/
	
	var controller = global.controller, available_items = global.available_items[global.difficulty], var num_of_items = array_length(available_items)
	var random_pos = include_key ? irandom(num_of_items-1) : (1 + irandom(num_of_items-2));
	var total_spawned_special_items = array_length(controller.spawned_special_items);
	if (!include_key) { total_spawned_special_items += 1; }
	var chosen_item_obj = noone;
	
	if (special_item && total_spawned_special_items >= num_of_items) {
		write_debug_message("Tried to spawn a special item and failed.", "WARNING");
		return obj_torch;
	}
	
	// Decide which item to spawn based on previous item spawns
	while (chosen_item_obj == noone) {
		var chosen_item_obj = available_items[random_pos];
		var spawned_item_count = array_count_occurances(controller.spawned_items, chosen_item_obj);
		var special_item_count = array_count_occurances(controller.spawned_special_items, chosen_item_obj)
		
		if (global.player_left_hand_item == chosen_item_obj) { spawned_item_count += 1; }
		if (global.player_right_hand_item == chosen_item_obj) { spawned_item_count += 1; }
			
		// Choose a different item if too many have already spawned
		if (special_item && special_item_count > 0) ||
			!special_item && (
				(chosen_item_obj == obj_map && spawned_item_count > 0) ||
				(chosen_item_obj == obj_compass && spawned_item_count > 0) ||
				(chosen_item_obj == obj_staff && spawned_item_count > 0) ||
				(chosen_item_obj == obj_clock && spawned_item_count > 0) ||
				(chosen_item_obj == obj_shovel && spawned_item_count > 1) ||
				(chosen_item_obj == obj_torch && spawned_item_count > 1)
			) { 
				random_pos += 1;
				if (random_pos >= num_of_items) { random_pos = 0; }
				if (random_pos == 0 && !include_key) { random_pos += 1; }
				chosen_item_obj = noone;
		}
		
		/*
		var rand = irandom(available_item_objs);
		if (!include_key) { rand += 1; }

		switch (rand) {
			case 0: { chosen_item_obj = obj_key; break; }
			case 1: { chosen_item_obj = obj_torch; break; }
			case 2: { chosen_item_obj = obj_sword; break; }
			case 3: { chosen_item_obj = obj_map; break; }
			case 4: { chosen_item_obj = obj_rosary; break; }
			case 5: { chosen_item_obj = obj_staff; break; }
			case 6: { chosen_item_obj = obj_bomb; break; }
			case 7: { chosen_item_obj = obj_meat; break; }
			case 8: { chosen_item_obj = obj_shovel; break; }
			case 9: { chosen_item_obj = obj_clock; break; }
		}
		
		var special_item_count = array_count_occurances(controller.spawned_special_items, chosen_item_obj)
			
		if (special_item_count >= 1) { chosen_item_obj = -1; }
		else if (!special_item) {
			var spawned_item_count = array_count_occurances(controller.spawned_items, chosen_item_obj);
			if (chosen_item_obj == obj_map && spawned_item_count >= 1) { chosen_item_obj = -1; }
			else if (chosen_item_obj == obj_staff && spawned_item_count >= 1) { chosen_item_obj = -1; }
			else if (chosen_item_obj == obj_clock && spawned_item_count >= 2) { chosen_item_obj = -1; }
			else if (chosen_item_obj == obj_shovel && spawned_item_count >= 2) { chosen_item_obj = -1; }
			else if (chosen_item_obj == obj_torch && spawned_item_count >= 2 && array_length(controller.spawned_special_items) == 0) { chosen_item_obj = -1; }
		}
		*/
	}
	
	return chosen_item_obj;
}


/// @function								get_clock_image_index();
function get_clock_image_index() {
	var controller = global.controller;
	var time_elapsed = controller.time_provided - controller.time_remaining;
	var time_per_grain = (time_elapsed / controller.time_provided)
	var sand_image_index = floor(abs((time_per_grain*8) - (time_per_grain*3/4)));

	return sand_image_index;
}

/// @function								get_compass_image_index();
function get_compass_image_index() {
	var controller = global.controller, hands_dir = 90;
	
	if (controller.current_room.has_hall_of_mirrors) {
		// Point Towards Next Hall of Mirrors Exit
		var next_dir = controller.current_room.mirror_directions[controller.current_room.mirror_count];
		var x_pos = x, y_pos = y;
		switch (next_dir) {
			case directions.up: { y_pos -= 2; break; }
			case directions.right: { x_pos += 2; break; }
			case directions.down: { y_pos += 2; break; }
			case directions.left: { x_pos -= 2; break; }
		}
		hands_dir = point_direction(x, y, x_pos, y_pos);
	}
	else if (instance_number(obj_collectable) > 0) {
		// Point Towards Nearest Collectable in Room
		var nearest_collectable = instance_nearest(x, y, obj_collectable);
		hands_dir = point_direction(x, y, nearest_collectable.x, nearest_collectable.y);
	}
	else {
		var current_room_x = controller.current_room.virtual_x, current_room_y = controller.current_room.virtual_y;
		var target_room_x = current_room_x, target_room_y = current_room_y-1; // Default to pointing up
		
		// Point toward start room if heart is collected
		if (controller.completion_amount+1 >= TOTAL_COMPLETION_AMOUNT) {
			 target_room_x = controller.start_room.virtual_x;
			 target_room_y = controller.start_room.virtual_y;
		}
		// Point toward heart room if all collectables are collected
		else if (are_all_collectables_collected()) {
			if (instance_number(obj_encased_heart) > 0) {
				var nearest_heart = instance_nearest(x, y, obj_encased_heart);
				hands_dir = point_direction(x, y, nearest_heart.x, nearest_heart.y);
			}
			else if (instance_number(obj_heart) > 0) {
				var nearest_heart = instance_nearest(x, y, obj_heart);
				hands_dir = point_direction(x, y, nearest_heart.x, nearest_heart.y);
			}
			else {
				target_room_x = controller.heart_room.virtual_x;
				target_room_y = controller.heart_room.virtual_y;
			}
		}
		// Point towards nearest room with collectables
		else {
			var smallest_dist = 999, target_room = self;
			for (var i = 0; i < array_length(controller.rooms_with_collectables); i++) {
				var collectables_room = controller.rooms_with_collectables[i];
				var current_dist = abs(point_distance(current_room_x, current_room_y, collectables_room.virtual_x, collectables_room.virtual_y));			
				if (current_dist < smallest_dist) {
					smallest_dist = current_dist;
					target_room = collectables_room;
				}
			}
			target_room_x = target_room.virtual_x;
			target_room_y = target_room.virtual_y;
		}
		
		hands_dir = point_direction(current_room_x, current_room_y, target_room_x, target_room_y);
	}
	
	// Translate from GML dir to image_index value
	hands_dir = 360 - hands_dir;
	hands_dir += 90;
	if (hands_dir >= 360) { hands_dir -= 360; }
	var hands_image_index = round(hands_dir / 45);
	if (image_xscale == -1) { hands_image_index += (4-hands_image_index)*2; }
	if (hands_image_index >= 8) { hands_image_index -= 8; }
	return hands_image_index;
}

/// @function								light_bomb();
function light_bomb() {
	if (fuse_timer != 0) { return false; }
	
	play_sound(snd_torchlight, true);
	fuse_timer = 4*irandom_range(5,8);
	return true;
}


/// @function								get_carried_item_draw_y_offset(special_item, include_key);
/// @param		{spr} spr_index				The sprite index to get the carried y offset for
function get_carried_item_draw_y_offset(spr_index) {
	var y_offset = -2;
	
	switch (spr_index) {
		case spr_meat:
		case spr_meat_farmer:
			{ y_offset = 0; break; }
		case spr_rosary:
			{ y_offset = 2; break; }
		case spr_shovel:
			{ y_offset = -3; break; }
		case spr_staff: 
			{ y_offset = 0; break; }
		case spr_sword: 
		case spr_sword_farmer:
			{ y_offset = -6; break; }
		case spr_torch: 
			{ y_offset = -4; break; }
	}
	
	return y_offset;
}