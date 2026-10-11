/// @description Step
// Remember last step's direction (a random cardinal one if there was none), which get_direction_input checks first
dir_prev = dir;
if (dir_prev == directions.none) { dir_prev = get_random_cardinal_dir(); }

// Release the bugs hiding in nearby player corpses (two each), bones, dirt and bushes
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
		var _bug = instance_create(x, y, obj_bug);
		has_bug = false;
		// The dirt over a button always hides a plain bug, never an infectious red one
		if (is_existing_instance(_bug) && no_special_bug) {
			_bug.infectious = false;
			_bug.sprite_index = spr_bug;
			no_special_bug = false;
		}
	}
}
with (obj_bush) { 
	if (has_bug && get_distance_to_instance(other) <= TRAP_RANGE) {
		instance_create(x, y, obj_bug);
		has_bug = false;
	}
}

// Anything solid on the player's spot crushes them, with a giant worm's head counted as its body
if (!dead && is_solid_at_position(x, y)) {
	var _killed_by_obj = instance_place(x, y, obj_solid).object_index;
	_killed_by_obj = (_killed_by_obj == obj_giant_worm_head) ? obj_giant_worm_body : _killed_by_obj;
	play_sound(snd_crunch, false);
	kill_player(_killed_by_obj);
}
	
if (!dead && !is_game_won() && !is_game_lost()) {   
	// Get input from player
	var _game_manager = global.game_manager;
	dir = get_direction_input(_game_manager.key_shift);
	
	// While infected, animate the red bug on the player and repeat its sound
	if (infected_timer > 0) {
		bug_image_index += 1;
		bug_sound_timer -= 1;
		if (bug_image_index >= 4) { bug_image_index = 0; }
		if (bug_sound_timer == 0) { play_sound(snd_red_bug, false); bug_sound_timer = 16; }
	}
		
	// Wait out the movement pause after entering a room
	if (pause_movement > 0) { pause_movement -= 1; }
	else {
		// Update crouch sprite
		sprite_index = (_game_manager.key_shift) ? get_sprite_to_use(spr_player_no_hands_crouch) : get_sprite_to_use(spr_player_no_hands);
	
		// Z and X pick up or put down an item with the left and right hand. A lost hand, or an item that can't be put
		// down, plays the locked sound. Acting shows the player again if they're hidden after stairs or a respawn.
		if (_game_manager.key_z_pressed) { 
			if (lost_left_hand || !can_drop_item(left_hand_item)) { play_sound(snd_locked, false); visible = true; }
			else { pick_up_or_put_down_item(directions.left); visible = true; }
		}
		if (_game_manager.key_x_pressed) { 
			if (lost_right_hand || !can_drop_item(right_hand_item)) { play_sound(snd_locked, false); visible = true; }
			else { pick_up_or_put_down_item(directions.right); visible = true; }
		}
			
		// Move the player in the chosen direction if possible, unless something already moved them this input
		// frame. Each move counts down an infection.
		if (!is_existing_instance(moved_by) && dir != directions.none && can_move_in_direction(dir, false, true)) {
			move_player(dir); 
			moved_by = id;
			visible = true;
			if (infected_timer > 0) { 
				infected_timer -= 1;
				if (infected_timer == 0) { play_sound(snd_red_bug_end, false); }
			}
			
		}
	}
		
	// Reset the player's light, then widen it if they carry a rosary (more for a special one)
	light.lighting_range = PLAYER_LIGHT_RANGE;
	if (is_carrying_item(obj_rosary)) { light.lighting_range += (is_carrying_special_item(obj_rosary)) ? 2 : 1; }
	light.is_flickering_light_source = false;
		
	// A lit torch in each hand makes the player's light flicker and reach 4 past the stronger torch's, if that's wider
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
    
	// Start a room transition when the player stands on active stairs whose exit links this room, or steps off an edge
	var _controller = global.controller;
	with (instance_place(x, y, obj_stairs)) {
		if (active && is_instance_at_coordinates(x, y, other) && connected_exit.get_connected_room(_controller.current_room) != -1) { 
			_controller.transition = directions.stairs; 
			_controller.transitioning_exit = connected_exit;
			_controller.transitioning_stairs = id;
		}
	}
	if (_controller.transition == directions.none) {
		if x < 0 { _controller.transition = directions.left; }
		else if x > room_width { _controller.transition = directions.right; }
		else if y < 0 { _controller.transition = directions.up; }
		else if y > room_height { _controller.transition = directions.down; }
		if (_controller.transition < directions.stairs) {
			_controller.transitioning_exit = _controller.current_room.exits[_controller.transition];
		}
	}
}
else if (dead) { image_index = 2; }

event_inherited();
