// Shader constants
#macro INVERTED_COLORS_ALPHA 0.5

// Initialize room probability constants
#macro MAX_SEED 99999999

#macro AVERAGE_NUMBER_OF_ROOM_EXITS (20/9)
#macro STAIRS_PROBABILITY 5 
#macro NO_CARDINAL_EXIT_ROOM_PROBABILITY get_probability_for_difficulty([0, 12, 8, 6, 4]) // This happens only after the stairs probability succeeds, so its combined with 1/5
#macro LOCKED_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 12, 10, 6])
#macro CHEST_PROBABILITY get_probability_for_difficulty([6, 5, 4, 3, 2]) // This happens only after the stairs probability fails, so its combined with 4/5
//#macro SPECIAL_ITEM_PROBABILITY get_probability_for_difficulty([0, 9, 8, 7, 6]) // This is only called after a room has a chest, so this is combined with that probability. It's also affected by the special item limit
#macro SPECIAL_ITEM_PROBABILITY get_probability_for_difficulty([0, 7, 3, 3, 2])
#macro SPECIAL_ITEM_LIMIT get_probability_for_difficulty([0, 1, 1, 2, 3])
#macro TRAP_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 0, 8, 4])  // This happens only after the chest probability succeeds, so its combined with that probability.
#macro HIDDEN_CHEST_PROBABILITY get_probability_for_difficulty([0, 2, 2, 1, 1])  // This happens only after the chest probability succeeds, so its combined with that probability. Also, only appears in non-lit lantern rooms, so combined with that too
#macro COLLECTABLE_PROBABILITY get_probability_for_difficulty([4, 3, 3, 3, 2]) 
#macro PORTCULLIS_PROBABILITY get_probability_for_difficulty([0, 0, 12, 8, 6]) 
#macro MISLEADING_EXITS_PROBABILITY get_probability_for_difficulty([0, 0, 12, 6, 4])
#macro ILLUSION_WALL_PROBABILITY get_probability_for_difficulty([0, 0, 0, 32, 16])
#macro LOCKED_DOOR_PROBABILITY get_probability_for_difficulty([0, 16, 12, 10, 8]) // Because each exit is checked by the room on either side, this actually happens twice as often
#macro OPEN_DOOR_PROBABILITY get_probability_for_difficulty([0, 32, 24, 12, 8])
#macro PRE_LIT_PROBABILITY get_probability_for_difficulty([1, 4, 6, 8, 12]) 
#macro KEY_IN_CHEST_PROBABILITY 3
#macro BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 8, 2, 1])
#macro CHEST_ON_STAIRS_SPOT_PROBABILITY get_probability_for_difficulty([0, 16, 8, 4, 3])
#macro SPECIAL_ROOM_LIMIT get_probability_for_difficulty([0, 0, 0, 1, 2])
//#macro SPECIAL_ROOM_PROBABILITY get_probability_for_difficulty([0, 0, 0, 64, 32])
#macro SPECIAL_ROOM_PROBABILITY get_probability_for_difficulty([0, 0, 0, 8, 6])
#macro SPECIAL_MAP_SHAPE_PROBABILITY get_probability_for_difficulty([0, 0, 0, 0, 0])

// Initilize room start probability constants
#macro COLUMN_FOUNTAIN_PROBABILITY get_probability_for_difficulty([0, 0, 128, 96, 48])
#macro STATUE_FOUNTAIN_PROBABILITY get_probability_for_difficulty([0, 0, 64, 32, 24])
#macro BUG_PROBABILITY get_probability_for_difficulty([512, 256, 112, 48, 24])
#macro RED_BUG_PROBABILITY get_probability_for_difficulty([0, 0, 0, 12, 8])
#macro DIRT_PROBABILITY get_probability_for_difficulty([0, 16, 20, 24, 28]) 
#macro NOSE_PROBABILITY get_probability_for_difficulty([0, 0, 4, 3, 2]) // multiplied by 4 for check at every room enter
#macro FIRE_SKELETON_IN_LAVA_PROBABILITY get_probability_for_difficulty([0, 0, 0, 48, 32])
#macro PHANTOM_PROBABILITY get_probability_for_difficulty([0, 4, 3, 3, 2])  // Only occurs if room has lanterns AND not pre-lit AND no hidden chest
#macro FLOATER_PROBABILITY get_probability_for_difficulty([0, 0, 32, 24, 16])
#macro HANDS_PROBABILITY get_probability_for_difficulty([0, 0, 12, 8, 4])
#macro SAME_SKELETON_TYPE_PROBABILITY get_probability_for_difficulty([0, 0, 0, 32, 24])
#macro EYES_PROBABILITY get_probability_for_difficulty([0, 0, 0, 0, 40]) 
#macro TRAP_BONES_PROBABILITY get_probability_for_difficulty([0, 32, 28, 24, 18]) //get_probability_for_difficulty([0, 32, 24, 22, 18]) 
#macro MOVING_COLLECTABLE_PROBABILITY get_probability_for_difficulty([0, 0, 24, 18, 16]) 
#macro SKIP_COLLECTABLE_SPAWN_PROBABILITY 0// UNUSED get_probability_for_difficulty([0, 0, 12, 8, 6])
#macro MOUTHS_PER_MOUTH (1+global.difficulty)

// Initialize map drawing constants
#macro GRID_SIZE 8
#macro MINIMUM_NUMBER_OF_ROOMS get_probability_for_difficulty([4, 8, 12, 15, 18])
#macro MAX_NUMBER_OF_ROOMS get_probability_for_difficulty([8, 12, 18, 22, 24]) //[12, 16, 24, 28, 32])
#macro MAP_DIFFICULTY_SCORE_TARGET get_probability_for_difficulty([0, 2, 8.5, 21, 33]) // Rooms are added until the map's difficulty score reaches this, up to MAX_NUMBER_OF_ROOMS. It's about what a map of MINIMUM_NUMBER_OF_ROOMS scores on average, so about half of maps stop at the minimum and a map of easier rooms grows toward the maximum
#macro ROOM_DIFFICULTY_SCORE_MAX 8 // Generation skips any roll that would take the threats rolled into a room past this (see GameRoom.would_exceed_max_difficulty)
#macro LAYOUT_DIFFICULTY_SCORE_LIMIT get_probability_for_difficulty([0, 1.5, 2.2, infinity, infinity]) // A layout appears from the lowest difficulty whose limits its difficulty and time scores fit in (see RoomLayout.determine_minimum_difficulty). These keep about as many layouts on each difficulty as the ruby script's difficulties did
#macro LAYOUT_TIME_SCORE_LIMIT get_probability_for_difficulty([0, 0.1, 0.5, infinity, infinity])
//#macro MAX_MAP_DRAW_DISTANCE 8 

// Initialize lighting constants
#macro DIMMING_RATE 8 
#macro LANTERN_LIGHT_RANGE get_probability_for_difficulty([0, 16, 14, 13, 12])//14 
#macro TORCH_LIGHT_RANGE get_probability_for_difficulty([0, 13, 12, 11, 10])//11 
#macro PLAYER_LIGHT_RANGE get_probability_for_difficulty([0, 8, 7, 7, 6])//6 
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
#macro SKELETON_MOVE_TOWARDS_PLAYER_FREQUENCY get_probability_for_difficulty([0, 64, 48, 32, 24])
#macro FAT_SKELETON_MOVE_FREQUENCY 48
#macro SKELETON_MOVE_FREQUENCY 12 
#macro COCKROACH_HUNT_MOVE_FREQUENCY 6 
#macro FAST_SKELETON_MOVE_FREQUENCY 4 
#macro SNAKE_MOVE_FREQUENCY 4 
#macro SNAKE_HISS_FREQUENCY 40 //32 
#macro BLOOD_REPLACEMENT_PROBABILITY 32 
#macro CORPSE_REPLACEMENT_PROBABILITY 1024 
#macro CORPSE_DISINTEGRATE_PROBABILITY 8
#macro CORPSE_HEADLESS_PROBABILITY 16
#macro TRAP_RANGE 40 
#macro BOMB_DUD_PROBABILITY 64
#macro BLOCK_ITEM_PROBABILITY get_probability_for_difficulty([0, 0, 256, 128, 64]) 
#macro NOSE_SELF_DESTRUCT_PROBABILITY get_probability_for_difficulty([0, 0, 0, 256, 128]) 
#macro RESPAWN_FREQUENCY 40 
#macro ECHO_SPAWN_FREQUENCY 64 
#macro PLAYER_INFECTED_TIMER 64
#macro LIVING_BLOCK_PROBABILITY get_probability_for_difficulty([0, 0, 128, 64, 32]) 

// Initialize score constants and variables
#macro FRAMES_TO_WAIT_UPON_ENTERING_ROOM 2 
#macro MAX_TORCH_TIME_TO_REMAIN_LIT get_probability_for_difficulty([100, 80, 70, 65, 65])//get_probability_for_difficulty([100, 75, 65, 60, 50])  // minutes * 60 total seconds for torch to remain lit
#macro TOTAL_COMPLETION_AMOUNT 4 

// Depth Constants
#macro PROJECTILE_DEPTH -300
#macro CARRIED_ITEM_DEPTH -250
#macro INCORPOREAL_ENEMY_DEPTH -225
#macro GIANT_WORM_DEPTH -200
#macro FLOATING_ENEMY_DEPTH -25
#macro BUSH_DEPTH -20
#macro PLAYER_DEPTH -10
#macro HANDS_WITH_STAFF_DEPTH -4
#macro ILLUSION_WALL_DEPTH -2 // -1
#macro PUSH_BLOCK_DEPTH -1 // -30
#macro SOLID_DEPTH -1
#macro STANDARD_DEPTH 0
#macro DROPPED_ITEM_DEPTH 1
#macro COLLECTABLE_DEPTH 2
#macro SWORD_IN_GROUND_DEPTH 3
#macro CORPSE_DEPTH 4
#macro BONES_DEPTH 5
#macro CROSS_DEPTH 6
#macro MOUTH_DEPTH 7
//#macro BLOOD_DEPTH 8
//#macro BUTTON_DEPTH 9
//#macro STAIRS_DEPTH 10
#macro DIRT_OVER_LAVA_DEPTH 11
#macro LAVA_DEPTH 12
#macro BLOOD_DEPTH 13
#macro BUTTON_DEPTH 14
#macro STAIRS_DEPTH 15
#macro DIRT_DEPTH 20
#macro MIRROR_DEPTH 30

// Default Setting Constants
#macro FULLSCREEN_DEFAULT true
#macro WINDOW_BORDER_DEFAULT false
#macro WINDOW_SCALING_DEFAULT 2
#macro INPUT_DEFAULT inputs.keyboard_default
#macro CAN_SCREEN_FLASH_DEFUALT true
#macro GAME_COLOR_FADE_DEFAULT 10
#macro GAME_COLOR_STRING_DEFAULT "FF0000"
#macro LAVA_EDGE_TYPE_DEFAULT  lava_edge_types.wavy_animated
#macro PLAYER_OUTLINE_DEFAULT false