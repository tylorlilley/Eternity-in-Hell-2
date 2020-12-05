/// @description  obj_controller_initialize
function obj_controller_initialize() {

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
	fuzz_value = 0;

	// Initialize score constants and variables
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
