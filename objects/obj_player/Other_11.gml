/// @description Step
dir_prev = dir;
if (dir_prev == directions.none) { dir_prev = get_random_carindal_dir(); }
	
// Spawn Bugs in nearby dirt and bushes
with (obj_player_corpse) { 
	if (has_bug && get_distance_to_instance(other) <= TRAP_RANGE) {
		instance_create(x, y, obj_bug);
		instance_create(x, y, obj_bug);
		has_bug = false;
	}
}
with (obj_bones) { 
	if (has_bug && get_distance_to_instance(other) <= TRAP_RANGE) {
		instance_create(x, y, obj_bug);
		has_bug = false;
	}
}
with (obj_dirt) { 
	if (has_bug && get_distance_to_instance(other) <= TRAP_RANGE) {
		instance_create(x, y, obj_bug);
		has_bug = false;
	}
}
with (obj_bush) { 
	if (has_bug && get_distance_to_instance(other) <= TRAP_RANGE) {
		instance_create(x, y, obj_bug);
		has_bug = false;
	}
}

if (!dead && is_solid_at_position(x, y)) {
	var killed_by_obj = instance_place(x, y, obj_solid).object_index;
	killed_by_obj = (killed_by_obj == obj_giant_worm_head) ? obj_giant_worm_body : killed_by_obj;
	play_sound(snd_crunch, false);
	kill_player(killed_by_obj);
}
	
if (!dead && !is_game_won() && !is_game_lost()) {   
	// Get input from player
	var game_manager = global.game_manager;
	dir = get_direction_input(false);
		
	// Deal with being infected
	var reduce_infection = false;
	if (infected_timer > 0) {
		bug_image_index += 1;
		if (bug_image_index >= 4) { bug_image_index = 0; }
		if (dir == get_direction_input(true)) { reduce_infection = true; }
		dir = irandom(3);
	}
		
	// Handle movement pause
	if (pause_movement > 0) { pause_movement -= 1; }
	else {
		// Handle inventory management
		if (game_manager.key_z_pressed) { 
			if (!can_drop_item(left_hand_item)) { play_sound(snd_locked, false); visible = true; }
			else { pick_up_or_put_down_item(directions.left); visible = true; }
		}
		if (game_manager.key_x_pressed) { 
			if (!can_drop_item(right_hand_item)) { play_sound(snd_locked, false); visible = true; }
			else { pick_up_or_put_down_item(directions.right); visible = true; }
		}
			
		// Move player in chosen direction if possible
		if (!is_existing_instance(moved_by) && dir != directions.none && can_move_in_direction(dir, false, true)) { 
			move_player(dir); 
			moved_by = id;
			visible = true;
			if (reduce_infection) { infected_timer -= 1; }
		}
	}
		
	// Increase lighting range if carrying a rosary
	light.lighting_range = PLAYER_LIGHT_RANGE;
	if (is_carrying_item(obj_rosary)) { light.lighting_range += (is_carrying_special_item(obj_rosary)) ? 2 : 1; }
	is_flickering_light_source = false;
		
	// Increase lighting range if carrying two torches
	if (is_carrying_lit_torch(true)) { 
			if (light.lighting_range < right_hand_item.light_source.lighting_range+4) { 
				light.lighting_range = right_hand_item.light_source.lighting_range+4;
				light.is_flickering_light_source = true;
			}
			if (light.lighting_range < left_hand_item.light_source.lighting_range+4) { 
				light.lighting_range = left_hand_item.light_source.lighting_range+4;
				light.is_flickering_light_source = true;
			}
	}
    
	// Transition to new room depending on player position
	var controller = global.controller;
	with (instance_place(x, y, obj_stairs)) {
		if (active && is_instance_at_coordinates(x, y, other) && connected_exit.get_connected_room(controller.current_room) != -1) { 
			controller.transition = directions.stairs; 
			controller.transitioning_exit = connected_exit;
			controller.transitioning_stairs = id;
		}
	}
	if (controller.transition == directions.none) {
		if x < 0 { controller.transition = directions.left; }
		else if x > room_width { controller.transition = directions.right; }
		else if y < 0 { controller.transition = directions.up; }
		else if y > room_height { controller.transition = directions.down; }
		if (controller.transition < directions.stairs) {
			controller.transitioning_exit = controller.current_room.exits[controller.transition];
		}
	}
}
else if (dead) { image_index = 2; }

event_inherited();
