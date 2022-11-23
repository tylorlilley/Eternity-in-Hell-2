// global values used to represent the four cardinal directions and the "direction" of coming to/from the stairs
enum directions {
	up,
	right,
	down,
	left,
	stairs,
	respawn
}

// global variables to represent the various game difficulty settings
enum difficulties {
	DO_NOT_USE,
	easy,
	medium,
	hard,
	very_hard
}

// global variables to represent the various seed options
enum seed_options {
	same,
	rand,
	specified
}

// Setup global variables for title screen
global.difficulty = difficulties.medium;
global.seed_option = seed_options.rand;
global.seed = noone;
global.FARM_MODE = false;
global.can_access_farmer_mode = true;