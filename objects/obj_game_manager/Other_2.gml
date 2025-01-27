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
global.difficulty = get_setting("difficulty", difficulties.easy);
global.seed_option = get_setting("seed_option", seed_options.rand);
global.seed = get_setting("last_seed", noone);

// Setup global variables for options
global.fullscreen = get_setting("fullscreen", FULLSCREEN_DEFAULT);
global.window_scaling = get_setting("window_size", WINDOW_SCALING_DEFAULT);
global.window_border = get_setting("window_border", WINDOW_BORDER_DEFAULT);
global.input = get_setting("input", INPUT_DEFAULT);
global.can_screen_flash = get_setting("can_screen_flash", CAN_SCREEN_FLASH_DEFUALT);
global.lava_edge_type = get_setting("lava_edge_type", LAVA_EDGE_TYPE_DEFAULT);
global.game_color_fade = get_setting("game_color_fade", GAME_COLOR_FADE_DEFAULT);
global.game_color_string = get_setting("game_color", GAME_COLOR_STRING_DEFAULT);
global.player_outline =  get_setting("player_outline", PLAYER_OUTLINE_DEFAULT);

// Setup global game type options
global.bg_color = make_color_rgb(0, 0, 0);
global.is_farm_mode = get_setting("extra_mode", false);
global.is_test_mode = false;
global.is_seed_testing_mode = false;
global.has_seed_test_passed = false;

// Setup generic arrays
global.difficulties_array = [difficulties.easy, difficulties.medium, difficulties.hard, difficulties.very_hard];
global.death_types_array = [
	obj_controller,
	obj_bomb,
	obj_lava,
	obj_bones,
	obj_skeleton,
	obj_fast_skeleton,
	obj_snake,
	obj_eyes,
	obj_mouth,
	obj_bumper,
	obj_phantom,
	obj_spider,
	obj_statue,
	obj_giant_worm_body,
	obj_nose,
	obj_hands,
	obj_ears,
	obj_echo,
	obj_gudetama,
	obj_bug,
	obj_mirror,
	obj_giant_eye,
	obj_living_block,
	obj_fountain,
	obj_fire_skeleton,
	obj_cockroach,
	obj_cultist,
];

global.available_items = [
	[obj_key],
	[obj_key, obj_torch, obj_sword, obj_map],
	[obj_key, obj_torch, obj_sword, obj_map, obj_rosary, obj_staff, obj_bomb],
	[obj_key, obj_torch, obj_sword, obj_map, obj_rosary, obj_staff, obj_bomb, obj_meat, obj_shovel, obj_clock],
	[obj_key, obj_torch, obj_sword, obj_map, obj_rosary, obj_staff, obj_bomb, obj_meat, obj_shovel, obj_clock],
];

// Set controls and set up drawing surface variables
global.player = noone;
resize_timer = 0;
set_max_window_size();
set_window_size();
set_game_color();
determine_gamepad();
prev_axislv_value = 0;
prev_axislh_value = 0;

application_surface_draw_enable(false);
gameframe_can_resize = false;
gameframe_can_input = true;
gameframe_caption_font = ft_hud;
gameframe_caption_icon = spr_icon;
gameframe_alpha = 1;
gameframe_border_width = 1;
gameframe_caption_height_normal = (os_type == os_windows) ? 27 : 0;
gameframe_offset = (os_type == os_windows) ? 4 : 0;