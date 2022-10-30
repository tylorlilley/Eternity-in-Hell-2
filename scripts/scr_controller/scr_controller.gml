// global values used to represent the four cardinal directions and the "direction" of coming to/from the stairs
enum directions {
	up,
	right,
	down,
	left,
	stairs,
	respawn
}

/// @function								restart_game();
function restart_game() {
	// Destroy all instances in this room and in every other room, then go back to the title screen
	with all { instance_destroy(); }
	for (var i = 0; i < array_length(game_rooms); i++) {
		room_instance_clear(game_rooms[i].room_reference);
	}
	room_goto(rm_title);
}

/// @function								create_room_lists();
function create_room_lists() {
	rooms_with_no_exits = array_create(0); 
	array_push(rooms_with_no_exits, rm_no_exits_1);
	rooms_with_one_exit = array_create(0); 
	array_push(rooms_with_one_exit, rm_one_exit_1, rm_one_exit_2, rm_one_exit_3, rm_one_exit_4, rm_one_exit_5, rm_one_exit_6, rm_one_exit_7, rm_one_exit_8, rm_one_exit_9, rm_one_exit_10, rm_one_exit_11, rm_one_exit_12, rm_one_exit_13, rm_one_exit_14, rm_one_exit_15, rm_one_exit_16, rm_one_exit_17, rm_one_exit_18);
	rooms_with_two_opposite_exits = array_create(0);
	array_push(rooms_with_two_opposite_exits, rm_two_opposite_exits_1, rm_two_opposite_exits_2, rm_two_opposite_exits_3, rm_two_opposite_exits_4, rm_two_opposite_exits_5, rm_two_opposite_exits_6, rm_two_opposite_exits_7, rm_two_opposite_exits_8, rm_two_opposite_exits_9, rm_two_opposite_exits_10, rm_two_opposite_exits_11, rm_two_opposite_exits_12, rm_two_opposite_exits_13, rm_two_opposite_exits_14, rm_two_opposite_exits_15, rm_two_opposite_exits_16);
	rooms_with_two_perpendicular_exits = array_create(0); 
	array_push(rooms_with_two_perpendicular_exits, rm_two_perpendicular_exits_1, rm_two_perpendicular_exits_2, rm_two_perpendicular_exits_3, rm_two_perpendicular_exits_4, rm_two_perpendicular_exits_5, rm_two_perpendicular_exits_6, rm_two_perpendicular_exits_7, rm_two_perpendicular_exits_8, rm_two_perpendicular_exits_9, rm_two_perpendicular_exits_10, rm_two_perpendicular_exits_11, rm_two_perpendicular_exits_12, rm_two_perpendicular_exits_13, rm_two_perpendicular_exits_14, rm_two_perpendicular_exits_15, rm_two_perpendicular_exits_16);
	rooms_with_three_exits = array_create(0); 
	array_push(rooms_with_three_exits, rm_three_exits_1, rm_three_exits_2, rm_three_exits_3, rm_three_exits_4, rm_three_exits_5, rm_three_exits_6, rm_three_exits_7, rm_three_exits_8, rm_three_exits_9, rm_three_exits_10, rm_three_exits_11, rm_three_exits_12, rm_three_exits_13, rm_three_exits_14, rm_three_exits_15, rm_three_exits_16, rm_three_exits_17);
	rooms_with_four_exits = array_create(0); 
	array_push(rooms_with_four_exits, rm_four_exits_1, rm_four_exits_2, rm_four_exits_3, rm_four_exits_4, rm_four_exits_5, rm_four_exits_6, rm_four_exits_7, rm_four_exits_8, rm_four_exits_9, rm_four_exits_10, rm_four_exits_11, rm_four_exits_12);
}

/// @function								initialize_game_variables();
function initialize_game_variables() {
	display_reset(0, false);
	layer_force_draw_depth(true,0);
	game_set_speed(60, gamespeed_fps);
	
	// Set up global shortcut references
	global.controller = id;
	global.player = noone;

	// Initialize room probability constants
	NUMBER_OF_EXITS_PROBABILITIES = [10, 80, 10, 0];
	LOCKED_DOOR_PROBABILITY = 5;
	HAS_STAIRS_PROBABILITY = 20;
	HAS_COLLECTABLE_PROBABILITY = 30;
	HAS_KEY_PROBABILITY = 10;
	HAS_ITEM_PROBABILITY = 20;
	SPECIAL_ITEM_PROBABILITY = 4;

	// Initialize map drawing constants
	TEST_MODE = true;
	MAX_WALKING_DEPTH = 255;
	MINIMUM_NUMBER_OF_ROOMS = 32;
	ADDITIONAL_ROOMS = 16;
	MAX_MAP_DRAW_DISTANCE = 8;

	// Initialize lighting constants and variables
	DIMMING_RATE = 8;
	LANTERN_LIGHT_RANGE = 14;
	TORCH_LIGHT_RANGE = 11;
	PLAYER_LIGHT_RANGE = 6;

	// Initialize score constants and variables
	FRAMES_TO_WAIT_BEFORE_PROCESSING = 6;
	FRAMES_TO_WAIT_UPON_ENTERING_ROOM = 2;
	MAX_TORCH_TIME_TO_REMAIN_LIT = 60; // minutes * 60 = total seconds for torch to remain lit
	TIME_PROVIDED_PER_ROOM = 30;
	TIME_PROVIEDED_PER_LOCK = 10;
	TOTAL_COMPLETION_AMOUNT = 4;
	//INITIAL_SCORE = 6+(20*60); // minutes * 60 = total seconds for game to run
	time_remaining = 1;
	time_provided = 1;
	
	// initialize room list values
	game_rooms = array_create(0);
	rooms_with_collectables = array_create(0);
	rooms_with_torch = array_create(0);
	rooms_with_key = array_create(0);
	rooms_with_sword = array_create(0);
	rooms_with_map = array_create(0);
	rooms_with_rosary = array_create(0);

	// initialize game state values
	current_room = noone;
	start_room = noone;
	total_number_of_rooms_with_collectables = 0;
	//rooms_with_collectables_collected = 0;
	//spawned_special_items = array_create(0);
	death_timer = 0;
	completion_amount = 0;

	// initialize room transition values
	bg_color = make_color_rgb(20, 20, 20);
	number_of_frames_since_game_began = 0;
	entered_from_stairs = true;
	blackout = true;
	transition = directions.respawn;
	clear_inputs_for_next_frame();
}

/// @function								one_unit_of_game_time();
function one_unit_of_game_time() {
	return (global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING/game_get_speed(gamespeed_fps));
}

/// @function								game_has_been_won();
function game_has_been_won() {
	return (global.controller.completion_amount >= global.controller.TOTAL_COMPLETION_AMOUNT);
}

/// @function								game_has_been_lost();
function game_has_been_lost() {
	return (global.player.dead || game_has_timed_out());
}

/// @function								game_has_timed_out();
function game_has_timed_out() {
	return (ceil(global.controller.time_remaining) <= 0 || (global.player.dead && global.controller.death_timer == 0));
}

/// @function								game_has_timed_out();
function game_progress_has_been_completed() {
	return (array_length(global.controller.rooms_with_collectables) == 0);
}

/// @function								transition_to_room(new_room);
function transition_to_room(new_room) {
	// Set room transition variables
	entered_from_stairs = (transition >= 4);
			
	// Play transition sound
	if (transition == 5) { audio_play_sound( snd_win, 10, false ); }
	else if (transition == 4) { audio_play_sound( snd_stairs, 10, false ); }
	else { audio_play_sound( snd_move, 10, false ); }
	
	// Reposition player
	switch (transition) {
		case directions.up: { global.player.y = room_height-8; global.player.x = room_width/2; break; }
		case directions.right: { global.player.x = 8; global.player.y = room_height/2; break; }
		case directions.down: { global.player.y = 8; global.player.x = room_width/2; break; }
		case directions.left: { global.player.x = room_width-8; global.player.y = room_height/2; break; }
	}
	
	// Move player to current position
	move_player(4);
	
	// Change room
	new_room.go_to_room();
}

/// @function					flip_room_contents_horizontally();
function flip_room_contents_horizontally() {
	with obj_game_object {
	    if (object_index != obj_player) { x = room_width - x; }
	}
	with obj_placeholder {
		x = room_width - x;
	}
}

/// @function				flip_room_contents_vertically();
function flip_room_contents_vertically() {
	with obj_game_object {
	    if (object_index != obj_player) { y = room_height - y; }
	}
	with obj_placeholder {
		y = room_height - y;
	}
}

/// @function									rotate_room_contents_around_room_center(direction_to_face);
/// @param		{direction}	direction_to_face	The direction in which the room should face once rotated
function rotate_room_contents_around_room_center(direction_to_face) {
	var angle = direction_to_face * 90;
	
	with obj_game_object {
	    if (object_index != obj_player) { 
			image_angle = 0;
			var x_prev = x - room_width/2;
			var y_prev = y - room_height/2;
			
			x = ((x_prev * dcos(angle)) - (y_prev * dsin(angle))) + room_width/2;
			y = ((y_prev * dcos(angle)) + (x_prev * dsin(angle))) + room_height/2;
			if (!place_snapped(4, 4)) { move_snap(4, 4); }
		}
	}
	with obj_placeholder {
		image_angle = 0;
		var x_prev = x - room_width/2;
		var y_prev = y - room_height/2;
			
		x = ((x_prev * dcos(angle)) - (y_prev * dsin(angle))) + room_width/2;
		y = ((y_prev * dcos(angle)) + (x_prev * dsin(angle))) + room_height/2;
		if (!place_snapped(4, 4)) { move_snap(4, 4); }
	}
}

/// @function								process_this_frame();
function process_this_frame() {
	return (!global.controller.transition && global.controller.number_of_frames_since_game_began % global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING == 0);
}

/// @function								get_inputs_for_next_frame();
function get_inputs_for_next_frame() {
	key_up = key_up || keyboard_check(vk_up);
	key_down = key_down || keyboard_check(vk_down);
	key_left = key_left || keyboard_check(vk_left);
	key_right = key_right || keyboard_check(vk_right);
	key_space = key_space|| keyboard_check(vk_space);
	key_enter = key_enter|| keyboard_check(vk_enter);
	key_z = key_z || keyboard_check(ord("Z"));
	key_x = key_x || keyboard_check(ord("X"));
	
	key_up_pressed = key_up_pressed || keyboard_check_pressed(vk_up);
	key_down_pressed = key_down_pressed || keyboard_check_pressed(vk_down);
	key_left_pressed = key_left_pressed || keyboard_check_pressed(vk_left);
	key_right_pressed = key_right_pressed || keyboard_check_pressed(vk_right);
	key_space_pressed = key_space_pressed || keyboard_check_pressed(vk_space);
	key_enter_pressed = key_enter_pressed || keyboard_check_pressed(vk_enter);
	key_z_pressed  = key_z_pressed || keyboard_check_pressed (ord("Z"));
	key_x_pressed  = key_x_pressed || keyboard_check_pressed (ord("X"));
	
	key_up_released = key_up_released || keyboard_check_released(vk_up);
	key_down_released = key_down_released || keyboard_check_released(vk_down);
	key_left_released = key_left_released || keyboard_check_released(vk_left);
	key_right_released = key_right_released || keyboard_check_released(vk_right);	
	key_space_released = key_space_released || keyboard_check_released(vk_space);
	key_enter_released = key_enter_released || keyboard_check_released(vk_enter);
	key_z_released = key_z_released || keyboard_check(ord("Z"));
	key_x_released = key_x_released || keyboard_check(ord("X"));
}

/// @function								clear_inputs_for_next_frame();
function clear_inputs_for_next_frame() {
	key_up = false;
	key_down = false;
	key_left = false;
	key_right = false;
	key_space = false;
	key_enter = false;
	key_z = false;
	key_x = false;
	
	key_up_pressed = false;
	key_down_pressed = false;
	key_left_pressed = false;
	key_right_pressed = false;
	key_space_pressed = false;
	key_enter_pressed = false;
	key_z_pressed = false;
	key_x_pressed = false;
	
	key_up_released = false;
	key_down_released = false;
	key_left_released = false;
	key_right_released = false;
	key_space_released = false;
	key_enter_released = false;
	key_z_released = false;
	key_x_released = false;
}


/// @function								game_room_start();
function game_room_start() {
	var stairs_spot = instance_find(obj_stairs_spot, 0);
	audio_stop_sound( snd_dread );
	
	// First Time Setup	
	if (!current_room.visited) {    
		// Flip game object positions as necesarry
		if (current_room.flip_horizontal) { flip_room_contents_horizontally(); }
		if (current_room.flip_vertical) { flip_room_contents_vertically(); }
		if (current_room.rotate != -1) { rotate_room_contents_around_room_center(current_room.rotate); }
		with obj_game_object { image_angle = 0; }
		with obj_placeholder { image_angle = 0; }
		
		// Update enemies in room to reflect new x, y position as initial position
		with (obj_enemy) {
			xstart = x;
			ystart = y;
		}
		with (obj_giant_worm_body) {
			xstart = x;
			ystart = y;
		}
    
		// Create locked exits if they should exist
		for (var i = 0; i < 4; i++) {
		    var x_pos = 0;
		    var y_pos = 0;
        
		    if (i == 0) { x_pos = room_width/2; y_pos = 8; }
		    if (i == 1) { x_pos = room_width-8; y_pos = room_height/2; }
		    if (i == 2) { x_pos = room_width/2; y_pos = room_height-8; }
		    if (i == 3) { x_pos = 8; y_pos = room_height/2; }
		    var door = instance_position(x_pos, y_pos, obj_door);
        
		    var exit_to_create_door_for = current_room.locked_exits[i];
		    if (exit_to_create_door_for) {   
		        if !door { door = instance_create_depth(x_pos, y_pos, 0, obj_door); }
		        door.door_for_exit = exit_to_create_door_for;
		        door.locked = exit_to_create_door_for.locked;
		    }
		}
		
		// Create key in room if it should exist
		if (current_room.has_key) {
			if (!current_room.stairs_spot_obj && get_random_chance_out_of(3)) { 	
				current_room.item_type = obj_key;
				current_room.stairs_spot_obj = obj_chest
			}
			else { 
				with get_random_instance(obj_collectable_spot) {
					var new_key = instance_create_depth(x, y, 4, obj_key);
					with new_key { if (global.controller.current_room.item_type == noone && global.controller.current_room.has_special_item) { make_item_special(); } }
					instance_destroy();
				} 
			}
		}
	
		// Create room's stairs_spot object
		if (current_room.stairs_spot_obj) {
		    instance_create_depth(stairs_spot.x, stairs_spot.y, 5, current_room.stairs_spot_obj);
		}
    
		// Create collectables in room if they should exist
		if (current_room.has_collectables) {
		    with obj_collectable_spot { instance_create_depth(x, y, 0, obj_collectable); instance_destroy(); }
			if (instance_number(obj_collectable) == 0) { 
				// This should never happen if every room has 2+ collectable spots
				current_room.has_collectables = false;
				array_remove(rooms_with_collectables, array_find_index(rooms_with_collectables, current_room));
			}
		}
	
		// Remove lit status from room if it shouldn't exist
		if (current_room.lit) { 
			if (instance_number(obj_lantern) == 0) { current_room.lit = false; }
			else { with obj_lantern { light_torch(noone, false); } }
		}
		else
		{
			// If room is unlit but has the potential to be lit, consider spawning phantom
			if (instance_number(obj_lantern) > 0 && get_random_chance_out_of(4)) {
				instance_create_depth(0, 0, 0, obj_phantom);
			}
		}
		
		// Teleport mouth to empty space
		with (obj_mouth) { teleport_to_empty_space(); }
		
		// If room has lava, consider spawning phantom
		if (instance_number(obj_lava) > 0 && get_random_chance_out_of(1)) { 
			if (get_random_chance_out_of(9)) { instance_create_depth(0, 0, 0, obj_nose); }
			if (get_random_chance_out_of(9)) { instance_create_depth(0, 0, 0, obj_nose); }
			if (get_random_chance_out_of(9)) { instance_create_depth(0, 0, 0, obj_nose); }
		}
	
		// Mark room as one that has been visited at some point during this game
		current_room.visited = true;
	}

	// Every Time Setup
	background_id = layer_background_get_id(layer_get_id("Background"));
	layer_background_blend( background_id, bg_color);
	for (var i = 0; i < array_length(game_rooms); i++) { game_rooms[i].distance_to_current_room = 9999; }
	with current_room { calculate_distance_to_current(0); }

	// Change position if necessary
	if entered_from_stairs {
		global.player.x = stairs_spot.x
		global.player.y = stairs_spot.y
	}

	// Move character into position
	move_player(4);

	// Add a small pause when entering a room
	global.player.pause_movement = FRAMES_TO_WAIT_UPON_ENTERING_ROOM;

	// Set initial lighting to darkness
	with obj_game_object { image_blend = global.controller.bg_color; }
	
	// Run room start event for specific objects
	with (obj_enemy) { x = xstart; y = ystart; }
	with (obj_giant_worm_body) { x = xstart; y = ystart; }
	with (obj_giant_worm_head) { connect_segments(); }
	with (obj_stairs) { active = false; }
	with (obj_block) { x = starting_spot.x; y = starting_spot.y; }
	with (obj_door) { locked = (door_for_exit && door_for_exit.locked); }
	with (obj_bones) { if (!instance_place(x, y, obj_solid)) { trap = (get_random_chance_out_of(31)); } }
	with (obj_worm) { dir = -1; audio_play_sound_for_object_only_once(snd_hiss); }
	with (obj_mouth) { audio_play_sound_for_object_only_once(snd_squelch); teleport_to_empty_space(); }
	with (obj_eyes) { audio_play_sound_for_object_only_once(snd_flicker); }
	with (obj_bumper) { lethal = false; trap = true; visible = false; }
	with (obj_nose) { teleport_to_lava(); }
	with (obj_spider) {
		lethal = get_random_chance_out_of(2);
		if global.controller.entered_from_stairs { lethal = false; }

		WAITING = 0;
		SCREECHING = 1;
		ATTACKING = 2;
		state = WAITING;
		dir = -1;
	}
	with (obj_phantom) {
		visible = false;
		lethal = false;

		if (global.controller.current_room.lit) { instance_destroy(); }
		else if (global.controller.entered_from_stairs) { spawn_timer = -1; }
		else { 
			audio_play_sound( snd_dread, 10, false ); 
			spawn_timer = 15*instance_number(obj_lantern);
			x = global.player.x;
			y = global.player.y;
		}
	}

}