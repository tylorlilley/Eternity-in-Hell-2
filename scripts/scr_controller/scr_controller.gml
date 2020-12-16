// global values used to represent the four cardinal directions and the "direction" of coming to/from the stairs
enum directions {
	up,
	right,
	down,
	left,
	stairs
}

/// @function								initialize_game_variables();
function initialize_game_variables() {
	// Set draw depth for all layers to 0
	layer_force_draw_depth(true,0);	
	
	// Set the global game speed
	game_set_speed(60, gamespeed_fps);
	gc_enable(false);
	
	// Set up global shortcut references
	global.controller = self;
	global.player = noone;

	// Initialize room probability constants
	NUMBER_OF_EXITS_PROBABILITIES = array(10, 80, 10, 0);
	HAS_STAIRS_PROBABILITY = 20;
	HAS_COLLECTABLE_PROBABILITY = 30;
	HAS_KEY_PROBABILITY = 0;
	HAS_ITEM_PROBABILITY = 10;

	// Initialize map drawing constants
	MAX_WALKING_DEPTH = 666;
	MINIMUM_NUMBER_OF_ROOMS = 32;
	LOCKED_DOOR_PROBABILITY = 6;
	TEST_MODE = false;
	MAX_MAP_DRAW_DISTANCE = 8;

	// Initialize lighting constants and variables
	DIMMING_RATE = 8;
	LANTERN_LIGHT_RANGE = 14;
	TORCH_LIGHT_RANGE = 11;
	PLAYER_LIGHT_RANGE = 6;

	// Initialize score constants and variables
	FRAMES_TO_WAIT_BEFORE_PROCESSING = 6;
	FRAMES_TO_WAIT_UPON_ENTERING_ROOM = 2;
	MAX_TORCH_TIME_TO_REMAIN_LIT = 1*60 // minutes * 60 = total seconds for torch to remain lit
	INITIAL_SCORE = 6+(15*60); // minutes * 60 = total seconds for game to run
	points = INITIAL_SCORE;

	// initialize game state values
	rooms_with_collectables = 0;
	rooms_with_collectables_collected = 0;

	// initialize room transition values
	bg_color = make_color_rgb(20, 20, 20);
	number_of_frames_since_game_began = 0;
	entered_from_stairs = true;
	blackout = false;
	transition = noone;
	clear_inputs_for_next_frame();
}

/// @function								game_has_been_won();
function game_has_been_won() {
	return (global.controller.rooms_with_collectables_collected >= global.controller.rooms_with_collectables);
}

/// @function								game_has_been_lost();
function game_has_been_lost() {
	return (global.player.dead || game_has_timed_out());
}

/// @function								game_has_timed_out();
function game_has_timed_out() {
	return (floor(global.controller.points) <= 0);
}

/// @function								transition_to_room();
function transition_to_room() {
	// Set room transition variables
	entered_from_stairs = (transition == 4);
	current_room = current_room.adj_rooms[transition]; 
			
	// Play transition sound
	if (transition == 4) { audio_play_sound( snd_stairs, 10, false ); }
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
	room_goto(current_room.room_reference);
	blackout = false;
	transition = noone;
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