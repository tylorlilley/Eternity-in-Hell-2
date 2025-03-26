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
	very_hard,
	ALL
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

enum graphics_modes {
	standard,
	farmer,
	unknown
}

// Setup generic arrays
global.difficulties_array = [difficulties.easy, difficulties.medium, difficulties.hard, difficulties.very_hard];
global.death_types_array = [
	obj_controller,
	obj_bomb,
	obj_lava,
	obj_bones,
	obj_skeleton,
	obj_fast_skeleton,
	obj_fat_skeleton,
	obj_snake,
	obj_eyes,
	obj_mouth,
	obj_bumper_old,
	obj_floater,
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
	obj_red_chest,
	obj_chest,
	obj_player
];
global.available_items = [
	[obj_key],
	[obj_key, obj_torch, obj_sword, obj_map],
	[obj_key, obj_torch, obj_sword, obj_map, obj_rosary, obj_staff, obj_bomb, obj_compass],
	[obj_key, obj_torch, obj_sword, obj_map, obj_rosary, obj_staff, obj_bomb, obj_compass, obj_meat, obj_shovel, obj_clock],
	[obj_key, obj_torch, obj_sword, obj_map, obj_rosary, obj_staff, obj_bomb, obj_compass, obj_meat, obj_shovel, obj_clock],
	[obj_key, obj_torch, obj_sword, obj_map, obj_rosary, obj_staff, obj_bomb, obj_compass, obj_meat, obj_shovel, obj_clock],
];
global.special_rooms = [
	rm_four_exits_24, // Hall of Mirrors
	rm_four_exits_23, // Hall of Mirrors
	rm_four_exits_22, // Giant Eye
	rm_one_exit_27, // Giant Eye
	rm_three_exits_30, // Giant Eye
	rm_one_exit_22, // Echo
	rm_one_exit_30, // Red Chest
	rm_one_exit_23, // Gudetama
];
global.item_sprites = [
	spr_key, spr_torch, 
	spr_sword, 
	spr_map, 
	spr_rosary, 
	spr_staff, 
	spr_bomb, 
	spr_meat, 
	spr_shovel, 
	spr_clock, 
	spr_heart, 
	spr_heart_farmer, 
	spr_meat_farmer, 
	spr_sword_farmer, 
	spr_bomb_farmer, 
	spr_clock_farmer 
];
global.regular_enemy_sprites = [
	spr_skeleton, 
	spr_fast_skeleton, 
	spr_fat_skeleton, 
	spr_fire_skeleton, 
	spr_living_block, 
	spr_spider, 
	spr_mouth, 
	spr_bumper, 
	spr_phantom, 
	spr_hands, 
	spr_nose, 
	spr_eyes, 
	spr_ears,
	spr_skeleton_farmer, 
	spr_fast_skeleton_farmer, 
	spr_fat_skeleton_farmer, 
	spr_fire_skeleton_farmer, 
	spr_living_block_farmer, 
	spr_spider_farmer, 
	spr_mouth_farmer, 
	spr_bumper_farmer, 
	spr_phantom_farmer, 
	spr_hands_farmer, 
	spr_nose_farmer, 
	spr_eyes_farmer, 
	spr_ears_farmer
];
global.rotational_enemy_sprites = [
	spr_cockroach, 
	spr_fountain, 
	spr_statue, 
	spr_snake, 
	spr_cockroach_farmer, 
	spr_fountain_farmer, 
	spr_snake_farmer
];
global.shuffled_item_sprites = array_get_duplicate(global.item_sprites);
global.shuffled_regular_enemy_sprites = array_get_duplicate(global.regular_enemy_sprites);
global.shuffled_rotational_enemy_sprites = array_get_duplicate(global.rotational_enemy_sprites);

// Setup global game type options
global.bg_color = make_color_rgb(0, 0, 0);
global.is_test_mode = false;
global.is_seed_testing_mode = false;
global.has_seed_test_passed = false;

// Setup global variables for title screen
global.difficulty = get_setting("difficulty", difficulties.easy);
if (global.difficulty > get_max_difficulty()) { global.difficulty = get_max_difficulty(); }
if (global.difficulty <= difficulties.DO_NOT_USE) { global.difficulty = difficulties.easy; }
global.graphics_mode = get_setting_for_difficulty("graphics_mode", global.difficulty, graphics_modes.standard)
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

// Setup global variables for prepartion screen
global.player_left_hand_item = get_setting_for_difficulty("last_player_left_hand_item", global.difficulty, obj_torch);
global.player_right_hand_item = get_setting_for_difficulty("last_player_right_hand_item", global.difficulty, noone);

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