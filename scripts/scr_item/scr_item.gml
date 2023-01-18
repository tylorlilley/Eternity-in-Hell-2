/// @function								draw_while_carried();
/// @param		{real} y_offset				How vertically displaced rom the player's origin should this should be drawn
/// @param		{direction} dir				The hand this item is being held in
function draw_while_carried(y_offset, dir) {
	var x_scale = (dir == directions.left) ? image_xscale : -image_xscale;
	var x_offset = (dir == directions.left) ? 8 : -24;

	draw_sprite_ext(sprite_index, image_index, x-sprite_width+(x_scale*x_offset),y+y_offset, x_scale, image_yscale, image_angle, image_blend, image_alpha);
}

/// @function								pick_up_item(dir, make_noise, new_holder);
/// @param		{direction} dir				The hand this item is being picked up with
/// @param		{boolean} make_noise		Whether or not to make a noise as part of picking up the item.
/// @param		{boolean} new_holder		The instance to begin holding the item.
function pick_up_item(dir, make_noise, new_holder) {
	if (make_noise) { play_sound(snd_pickup, true); }
	holder = new_holder
	holder.carried_items[dir] = id;
	persistent = holder.persistent;
	image_xscale = (dir == directions.left) ? 1 : -1;
	carried = dir;
	depth = -10;
	if (has_been_carried) {
			if (object_index == obj_bomb) {
				if (fuse_timer != 0) { play_sound(snd_hiss, false); }
				fuse_timer = 0; 
			}
			if (object_index == obj_shovel && can_make_hole()) {
				play_sound(snd_shovel, true);
				if (damaged) { instance_destroy(); }
				else if (!special) { damaged = true; }
				var new_hole = instance_create_depth(x, y, 0, obj_hole);
				if (global.controller.last_hole == noone) { global.controller.last_hole = new_hole; }
				else { 
					new_hole.connected_hole = global.controller.last_hole; 
					global.controller.last_hole.connected_hole = new_hole;
					global.controller.last_hole = noone;
				}
			}
	}
	else {
		has_been_carried = true;
		if (holder == global.player) {
			if (object_index == obj_key) { global.controller.current_room.has_key = false; }
			else if (object_index == obj_heart) { global.controller.completion_amount += 1; }
		}
	}

}

/// @function								drop_item();
/// @param		{direction} dir				The hand this item is being dropped out of
function drop_item(dir, make_noise) {	
	if (make_noise) { 
		play_sound(snd_putdown, true);
		if (object_index == obj_shovel) { play_sound(snd_shovel, true); }
	}
		
	if (holder) { 
		holder.carried_items[dir] = noone;
		x = holder.x;
		y = holder.y;
		holder = noone;
	}
	carried = noone;
	persistent = false;
	depth = 2;
	
	//image_xscale = (dir == directions.left) ? image_xscale : -image_xscale;
}

/// @function								make_item_special();
function make_item_special() {
	special = true;
	image_index = 1;
	if (object_index == obj_torch) { 
		image_index = 0;
		lighting_range = global.controller.TORCH_LIGHT_RANGE*2;
		sprite_index = spr_special_torch; 
	}
}

/// @function								thump();
function thump() {
	thump_timer -= 1;
	if (thump_timer == 3) { play_sound(snd_thump, false); image_index = 1; }
	if (thump_timer == 0) { thump_timer = 12; image_index = 0; }
}

/// @function								get_random_item_type();
function get_random_item_type() {
	var available_item_types = (global.difficulty == difficulties.easy) ? 2 : 5;
	if (global.difficulty > difficulties.medium) { available_item_types += 3; }

	switch (irandom(available_item_types)) {
		case 0: { return obj_torch; }
		case 1: { return obj_sword; }
		case 2: { return obj_map; }
		case 3: { return obj_rosary; }
		case 4: { return obj_staff; }
		case 5: { return obj_bomb; }
		case 6: { return obj_meat; }
		case 7: { return obj_shovel; }
		case 8: { return obj_clock; }
	}
}