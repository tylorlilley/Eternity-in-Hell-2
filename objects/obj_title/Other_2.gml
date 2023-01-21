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
global.difficulty = difficulties.easy;
global.seed_option = seed_options.rand;
global.seed = noone;
global.FARM_MODE = false;
global.TEST_MODE = false;
global.can_access_farmer_mode = false;

// Setup generic arrays

global.difficulties_array = array_create(0);
array_push(global.difficulties_array, difficulties.easy);
array_push(global.difficulties_array, difficulties.medium); // Medium Only
array_push(global.difficulties_array, difficulties.hard);
array_push(global.difficulties_array, difficulties.very_hard);

global.death_types_array = array_create(0);
// Easy 
array_push(global.death_types_array, obj_controller);
array_push(global.death_types_array, obj_bomb); // Medium Only
array_push(global.death_types_array, obj_lava);
array_push(global.death_types_array, obj_bones);
array_push(global.death_types_array, obj_skeleton);
array_push(global.death_types_array, obj_mouth);
array_push(global.death_types_array, obj_bumper);
array_push(global.death_types_array, obj_phantom);
// Medium
array_push(global.death_types_array, obj_spider); // Currently Medium Only
array_push(global.death_types_array, obj_statue); // Currently Medium Only
array_push(global.death_types_array, obj_giant_worm_body);
array_push(global.death_types_array, obj_snake);
array_push(global.death_types_array, obj_nose);
array_push(global.death_types_array, obj_hands);
array_push(global.death_types_array, obj_ears);
// Hard
array_push(global.death_types_array, obj_eyes);
array_push(global.death_types_array, obj_echo);

