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

	// Initialize map drawing constants
	MINIMUM_NUMBER_OF_ROOMS = 30;
	LOCKED_DOOR_PROBABILITY = 15;
	TEST_MODE = false;
	MAX_MAP_DRAW_DISTANCE = 8;

	// Initialize lighting constants and variables
	DIMMING_RATE = 8;
	LANTERN_LIGHT_RANGE = 14;
	TORCH_LIGHT_RANGE = 11;
	PLAYER_LIGHT_RANGE = 6;

	// Initialize score constants and variables
	FRAMES_TO_WAIT_UPON_ENTERING_ROOM = 0.2;
	MAX_TORCH_TIME_TO_REMAIN_LIT = 1*60 // minutes * 60 = total seconds for torch to remain lit
	INITIAL_SCORE = 1+(15*60); // minutes * 60 = total seconds for game to run
	points = INITIAL_SCORE;

	// Initialize controller values
	number_of_frames_since_game_began = 0;

	// initialize game state values
	rooms_with_collectables = 0;
	rooms_with_collectables_collected = 0;
	collected_keys = 0;

	// initialize room transition values
	entered_from_stairs = true;
	blackout = noone;
	transition = false;
}

/// @function								game_has_been_won();
function game_has_been_won() {
	return (global.controller.rooms_with_collectables_collected >= global.controller.rooms_with_collectables);
}

/// @function								game_has_been_lost();
function game_has_been_lost() {
	return (floor(global.controller.points) <= 0);
}

/// @function								transition_to_room(dir);
/// @param		{direction} dir				The direction in which the player is moving when leaving the current room
function transition_to_room(dir) {
	// Play transition sound
	if (dir == 4) { audio_play_sound( snd_stairs, 10, false ); }
	else { audio_play_sound( snd_move, 10, false ); }
	
	// Reposition player
	switch (dir) {
		case 0: { global.player.y = room_height-8; break; }
		case 1: { global.player.x = 8; break; }
		case 2: { global.player.y = 8; break; }
		case 3: { global.player.x = room_width-8; break; }
	}

	// Change Rooms
	global.controller.blackout = dir;
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
			var x_prev = x - room_width/2;
			var y_prev = y - room_height/2;
			
			x = ((x_prev * dcos(angle)) - (y_prev * dsin(angle))) + room_width/2;
			y = ((y_prev * dcos(angle)) + (x_prev * dsin(angle))) + room_height/2;
		}
	}
	with obj_placeholder {
		var x_prev = x - room_width/2;
		var y_prev = y - room_height/2;
			
		x = ((x_prev * dcos(angle)) - (y_prev * dsin(angle))) + room_width/2;
		y = ((y_prev * dcos(angle)) + (x_prev * dsin(angle))) + room_height/2;
	}
}