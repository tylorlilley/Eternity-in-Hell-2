// global values used to represent the four cardinal directions and the "direction" of coming to/from the stairs
enum directions {
	up,
	right,
	down,
	left,
	stairs,
	respawn,
	none
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

// global variables to represent the various lava edge types
enum lava_edge_types {
	none,
	fuzzy_still,
	fuzzy_animated,
	wavy_still,
	wavy_animated,
}

// Setup global variables for title screen
global.is_test_mode = false;

global.difficulty = get_setting("difficulty", difficulties.easy);
global.seed_option = get_setting("seed_option", seed_options.rand);
global.seed = get_setting("last_seed", noone);
global.is_farm_mode = get_setting("extra_mode", false);

global.fullscreen = get_setting("fullscreen", true);
global.window_scaling = get_setting("window_size", 2);
global.input = get_setting("input", inputs.keyboard_default);
global.can_screen_flash = get_setting("can_screen_flash", true);
global.lava_edge_type = get_setting("lava_edge_type", lava_edge_types.fuzzy_still);
global.game_color_fade = get_setting("game_color_fade", 10);
global.game_color_string = get_setting("game_color", "FF0000");

global.bg_color = make_color_rgb(0, 0, 0);

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
window_set_fullscreen(global.fullscreen);
set_max_window_size();
set_window_size();
set_game_color();
determine_gamepad();
