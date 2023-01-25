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

// global variables to represent the various input styles
enum inputs {
	keyboard_wasd,
	keyboard_default,
	gamepad
}

// Setup global variables for title screen
global.difficulty = difficulties.easy;
global.seed_option = seed_options.rand;
global.seed = noone;
global.FARM_MODE = false;
global.TEST_MODE = false;
global.can_access_farmer_mode = false;

// Setup generic arrays

global.difficulties_array = [1, 2, 3, 4];
global.death_types_array = [
	obj_controller,
	obj_bomb,
	obj_lava,
	obj_bones,
	obj_skeleton,
	obj_mouth,
	obj_bumper,
	obj_phantom,
	obj_spider,
	obj_statue,
	obj_giant_worm_body,
	obj_snake,
	obj_nose,
	obj_hands,
	obj_ears,
	obj_eyes,
	obj_echo,
]

// Set up drawing surface variables
global.input = inputs.keyboard_default;
set_max_window_size();
set_window_size();
determine_gamepad();
