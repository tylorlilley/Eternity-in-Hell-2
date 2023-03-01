// Initialize room probability constants
#macro MAX_SEED 99999999
//#macro NUMBER_OF_EXITS_PROBABILITY 9
#macro AVERAGE_NUMBER_OF_ROOM_EXITS (20/9)
#macro STAIRS_PROBABILITY 5 
#macro NO_CARDINAL_EXIT_ROOM_PROBABILITY get_probability_for_difficulty([0, 12, 8, 6, 4]) // This happens only after the stairs probability succeeds, so its combined with 1/5
#macro LOCKED_CHEST_PROBABILITY get_probability_for_difficulty([0, 24, 12, 10, 6])
#macro CHEST_PROBABILITY get_probability_for_difficulty([6, 5, 4, 3, 2]) // This happens only after the stairs probability fails, so its combined with 4/5
#macro TRAP_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 0, 12, 8])  // This happens only after the chest probability succeeds, so its combined with that probability.
#macro HIDDEN_CHEST_PROBABILITY 1//get_probability_for_difficulty([0, 2, 2, 2, 1])  // This happens only after the chest probability succeeds, so its combined with that probability. Also, only appears in non-lit lantern rooms, so combined with that too
#macro COLLECTABLE_PROBABILITY get_probability_for_difficulty([4, 3, 3, 3, 2]) 
#macro PORTCULLIS_PROBABILITY 1//get_probability_for_difficulty([0, 0, 12, 6, 2]) 
#macro MISLEADING_EXITS_PROBABILITY get_probability_for_difficulty([0, 0, 12, 6, 4])
#macro ILLUSION_WALL_PROBABILITY get_probability_for_difficulty([0, 0, 0, 24, 12])
#macro LOCKED_DOOR_PROBABILITY get_probability_for_difficulty([0, 16, 12, 10, 8]) // Because each exit is checked by the room on either side, this actually happens twice as often
#macro OPEN_DOOR_PROBABILITY get_probability_for_difficulty([0, 32, 24, 12, 8])
#macro PRE_LIT_PROBABILITY get_probability_for_difficulty([1, 4, 6, 8, 12]) 
#macro SPECIAL_ITEM_PROBABILITY get_probability_for_difficulty([0, 24, 16, 12, 8]) 
#macro SPECIAL_ITEM_LIMIT get_probability_for_difficulty([0, 1, 1, 2, 3])
#macro KEY_IN_CHEST_PROBABILITY 3
#macro BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 8, 2, 1])
#macro USE_CHEST_SPOT_PROBABILITY get_probability_for_difficulty([0, 16, 8, 4, 3])
	
// Initilize room start probability constants
#macro BUG_PROBABILITY get_probability_for_difficulty([512, 256, 112, 48, 24])
#macro RED_BUG_PROBABILITY get_probability_for_difficulty([0, 0, 0, 12, 6])
#macro DIRT_PROBABILITY get_probability_for_difficulty([0, 16, 20, 24, 28]) 
#macro NOSE_PROBABILITY get_probability_for_difficulty([0, 0, 4, 3, 2]) 
#macro PHANTOM_PROBABILITY get_probability_for_difficulty([0, 2, 2, 1, 1])  // Only occurs if room has lanterns AND not pre-lit AND no hidden chest
//#macro SPIDER_PROBABILITY get_probability_for_difficulty([0, 3, 3, 2, 1]) 
#macro HANDS_PROBABILITY get_probability_for_difficulty([0, 0, 8, 4, 3])
#macro SNAKE_PROBABILITY get_probability_for_difficulty([0, 0, 24, 16, 8]) 
#macro EYES_PROBABILITY get_probability_for_difficulty([0, 0, 0, 64, 46]) 
#macro FAST_SKELETON_PROBABILITY get_probability_for_difficulty([0, 0, 16, 14, 12]) 
#macro TRAP_BONES_PROBABILITY get_probability_for_difficulty([0, 36, 30, 28, 24]) 
#macro MOVING_COLLECTABLE_PROBABILITY get_probability_for_difficulty([0, 0, 32, 28, 24]) 
#macro MOUTHS_PER_MOUTH (1+global.difficulty)

// Initialize map drawing constants
#macro GRID_SIZE 8
//#macro MAX_WALKING_DEPTH get_probability_for_difficulty([16, 16, 32, 48, 56]) 
#macro MINIMUM_NUMBER_OF_ROOMS get_probability_for_difficulty([4, 8, 12, 15, 18])
#macro MAXIMUM_NUMBER_OF_ROOMS get_probability_for_difficulty([8, 12, 15, 18, 24])
//#macro ADDITIONAL_ROOMS get_probability_for_difficulty([3, 3, 6, 9, 12]) 
#macro MINIMUM_COLLECTABLES_ROOMS get_probability_for_difficulty([1, 2, 3, 4, 5]) 
//#macro MAX_MAP_DRAW_DISTANCE 8 

// Initialize lighting constants
#macro DIMMING_RATE 8 
#macro LANTERN_LIGHT_RANGE 14 
#macro TORCH_LIGHT_RANGE 11 
#macro PLAYER_LIGHT_RANGE 6 
//#macro LAVA_LIGHT_RANGE 18  // This one is in pixels and not steps of 8 pixels
#macro SCREEN_FLASH_DURATION 6 
#macro LAVA_LIGHT_RANGE 4
#macro FIREBALL_LIGHT_RANGE 3
	
// Initilaize other gameplay constants
#macro FRAMES_TO_WAIT_BEFORE_PROCESSING 6
#macro FRAMES_FOR_HEART_THUMP 12
#macro JUST_THE_WIND_PROBABILITY 2056 
#macro BUSH_RUSTLE_FREQUENCY 16
//#macro ILLUSION_WALL_FLICKER_FREQUENCY 256
#macro SKELETON_MOVE_FREQUENCY 12 
#macro FAST_SKELETON_MOVE_FREQUENCY 4 
#macro SNAKE_HISS_FREQUENCY 32 
#macro SNAKE_MOVE_FREQUENCY 4 
#macro BLOOD_REPLACEMENT_PROBABILITY 32 
#macro CORPSE_REPLACEMENT_PROBABILITY 1024 
#macro CORPSE_DISINTEGRATE_PROBABILITY 8
#macro CORPSE_HEADLESS_PROBABILITY 16
#macro TRAP_RANGE 40 
#macro BOMB_DUD_PROBABILITY 64
#macro BLOCK_ITEM_PROBABILITY get_probability_for_difficulty([0, 64, 32, 30, 28]) 
#macro NOSE_SELF_DESTRUCT_PROBABILITY get_probability_for_difficulty([0, 0, 0, 256, 128]) 
#macro RESPAWN_FREQUENCY 40 
#macro ECHO_SPAWN_FREQUENCY 64 
#macro PLAYER_INFECTED_TIMER 48

// Initialize score constants and variables
#macro FRAMES_TO_WAIT_UPON_ENTERING_ROOM 2 
#macro MAX_TORCH_TIME_TO_REMAIN_LIT get_probability_for_difficulty([100, 75, 65, 60, 50])  // minutes * 60 total seconds for torch to remain lit
#macro TIME_PROVIDED_PER_ROOM get_probability_for_difficulty([40, 38, 34, 30, 28]) 
#macro TIME_PROVIDED_PER_EASY_ROOM -5 
#macro TIME_PROVIDED_PER_HARD_ROOM 15 
#macro TIME_PROVIDED_PER_DEAD_END 10 
#macro TIME_PROVIDED_PER_COLLECTABLE get_probability_for_difficulty([40, 25, 20, 16, 12]) 
#macro TIME_PROVIEDED_PER_LOCK 15
#macro TIME_PROVIEDED_PER_ILLUSION_WALL 15
#macro TIME_PROVIEDED_PER_PORTCULLIS 15
#macro TOTAL_COMPLETION_AMOUNT 4 

// Depth Constants
#macro FIREBALL_DEPTH -300
#macro CARRIED_ITEM_DEPTH -250
#macro INCORPOREAL_ENEMY_DEPTH -225
#macro GIANT_WORM_DEPTH -200
#macro PUSH_BLOCK_DEPTH -30
#macro FLOATING_ENEMY_DEPTH -25
#macro BUSH_DEPTH -20
#macro PLAYER_DEPTH -10
#macro HANDS_WITH_STAFF_DEPTH -4
#macro SOLID_DEPTH -1
#macro STANDARD_DEPTH 0
#macro DROPPED_ITEM_DEPTH 1
#macro COLLECTABLE_DEPTH 2
#macro SWORD_IN_GROUND_DEPTH 3
#macro CORPSE_DEPTH 4
#macro BONES_DEPTH 5
#macro CROSS_DEPTH 6
#macro MOUTH_DEPTH 7
#macro BLOOD_DEPTH 8
#macro BUTTON_DEPTH 9
#macro STAIRS_DEPTH 10
#macro DIRT_OVER_LAVA_DEPTH 11
#macro LAVA_DEPTH 12
#macro DIRT_DEPTH 20

// Default Setting Constants
#macro FULLSCREEN_DEFAULT true
#macro WINDOW_BORDER_DEFAULT (os_type != os_windows)
#macro WINDOW_SCALING_DEFAULT 2
#macro INPUT_DEFAULT inputs.keyboard_default
#macro CAN_SCREEN_FLASH_DEFUALT true
#macro GAME_COLOR_FADE_DEFAULT 10
#macro GAME_COLOR_STRING_DEFAULT "FF0000"
#macro LAVA_EDGE_TYPE_DEFAULT  lava_edge_types.wavy_animated
#macro PLAYER_OUTLINE_DEFAULT false