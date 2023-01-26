/// @function								draw_while_carried();
function draw_while_carried() {
	if (!is_existing_instance(holder)) { return; }
	
	var x_offset = image_xscale * -8;

	draw_sprite_ext(sprite_index, image_index, x+x_offset, y+draw_y_offset, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}

/// @function								become_carried(new_holder);
/// @param		{boolean} new_holder		The instance to begin holding the item.
function become_carried(new_holder) {
	// Become carried
	holder = new_holder;
	persistent = new_holder.persistent;
	depth = -5;
	
	// Perform individual item pick-up actions
	switch (object_index) {
		case obj_key: { if (holder == global.player) { global.controller.current_room.has_keys -= 1; } break; }
		case obj_bomb: { defuse_bomb(); break; }
		case obj_shovel: { dig_hole(); break; }
		case obj_heart: { mark_heart_carried(); break; }
	}
}

/// @function								become_dropped(dropper);
/// @param		{inst} dropper				The instance dropping this item
function become_dropped(dropper) {
	// Perform individual item drop actions
	switch (object_index) {
		case obj_key: { if (dropper == global.player) { global.controller.current_room.has_keys += 1; } break; }
		case obj_meat: { with (obj_spider) { if (activated) { play_sound(snd_lose, false); } } break; }
		case obj_shovel: { dropped_by_digger = true; break; }
	}
	
	// Become dropped
	holder = noone;
	persistent = false;
	depth = 1;
	x = dropper.x;
	y = dropper.y;
	
	// Perform individual actions based on dropper
	if (dropper == global.player) {
		xstart = x;
		ystart = y;
	}
	
	// Alert interested obj_hands to come grab it
	with (obj_hands) { 
		if (dropper != id && activated && !is_carrying_item(obj_meat) && (!is_existing_instance(right_hand_item) || dropper == global.player)) { target_item = other.id; } 
	}
}

/// @function								make_item_special();
function make_item_special() {
	special = true;
	image_index = 1;
	if (object_index == obj_torch) { 
		image_index = 0;
		lighting_range = global.controller.TORCH_LIGHT_RANGE*2;
		sprite_index = get_sprite_to_use(spr_special_torch); 
	}
}

/// @function								defuse_bomb();
function defuse_bomb() {
	if (fuse_timer != 0) { play_sound(snd_fuse, false); }
	fuse_timer = 0; 
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
			!place_meeting(x, y, obj_hole) &&
			!place_meeting(x, y, obj_block_spot));
}

/// @function								dig_hole();
function dig_hole() {
	if (can_dig_hole() && dropped_by_digger) {
		play_sound(snd_shovel, true);
		if (!special) { damaged += 1; }
		var new_hole = instance_create(x, y, obj_hole);
		if (!is_existing_instance(global.controller.last_hole)) { global.controller.last_hole = new_hole; }
		else { 
			new_hole.connected_hole = global.controller.last_hole; 
			global.controller.last_hole.connected_hole = new_hole;
			global.controller.last_hole = noone;
		}
	}
}

/// @function								thump();
function thump() {
	thump_timer -= 1;
	if (thump_timer == 3) { play_sound(snd_thump, false); image_index = 1; }
	if (thump_timer == 0) { thump_timer = 12; image_index = 0; }
}

/// @function								mark_heart_carried();
function mark_heart_carried() {
	if (!global.controller.carried_heart && holder == global.player) { 
		global.controller.completion_amount += 1;
		global.controller.carried_heart = true;
	}
}

/// @function								get_dropped_meat();
function get_dropped_meat() {
	var dropped_meat = noone
	with (obj_meat) { if (!is_existing_instance(holder)) { dropped_meat = id; } }
	return dropped_meat;
}

/// @function								get_random_item_obj(special_item, include_key);
/// @param		{bool} special_item			Whether to check against the spawned specialitems or not
/// @param		{bool} include_key			Whether to include the key in what can be returned or not
function get_random_item_obj(special_item, include_key) {
	var array_to_check = (special_item) ? global.controller.spawned_special_items : global.controller.spawned_items;
	var available_item_objs = (global.difficulty == difficulties.easy) ? 2 : 5;
	if (global.difficulty > difficulties.medium) { available_item_objs += 3; }
	var chosen_item_obj = noone;
	
	// Decide which item to spawn based on previous item spawns
	while (chosen_item_obj == noone) {
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
			
		var spawned_item_count = array_count_occurances(array_to_check, chosen_item_obj);
			
		if (special_item && spawned_item_count >= 1) { chosen_item_obj = noone; }
		else if (chosen_item_obj == obj_map && spawned_item_count >= 1) { chosen_item_obj = noone; } 
		else if (chosen_item_obj == obj_staff && spawned_item_count >= 1) { chosen_item_obj = noone; } 
		else if (chosen_item_obj == obj_torch && spawned_item_count >= 2) { chosen_item_obj = noone; } 
		else if (chosen_item_obj == obj_clock && spawned_item_count >= 2) { chosen_item_obj = noone; } 
		else if (chosen_item_obj == obj_shovel && spawned_item_count >= 2) { chosen_item_obj = noone; } 
	}
	
	return chosen_item_obj;
}
