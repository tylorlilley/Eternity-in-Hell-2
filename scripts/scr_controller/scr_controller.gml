// global values used to represent the four cardinal directions and the "direction" of coming to/from the stairs
enum directions {
	up,
	right,
	down,
	left,
	stairs
}

/// @function								obj_controller_initialize();
function obj_controller_initialize() {
	// Set draw depth for all layers to 0
	layer_force_draw_depth(true,0);	
	
	// Set the global game speed
	game_set_speed(10, gamespeed_fps);
	
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

	// initialize room setup values
	entered_from_stairs = true;
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
	global.controller.entered_from_stairs = (dir == 4);
	global.controller.current_room = global.controller.current_room.adj_rooms[dir]; 
	room_goto(global.controller.current_room.room_reference);
}
