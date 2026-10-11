// Shader constants
#macro INVERTED_COLORS_ALPHA 0.5 // Drawing with this alpha makes the shader swap white and red

// Map generation. Here and below, a chance is one in the macro's value (see get_random_chance_out_of), and 0 means
// never. A list holds one value per difficulty, in the order [unused, easy, medium, hard, very hard] (see
// get_probability_for_difficulty).
#macro MAX_SEED 99999999 // Largest seed a player can pick, and the range of the random seeds generation picks

#macro AVERAGE_NUMBER_OF_ROOM_EXITS (20/9) // Generation links adjacent rooms until they average this many cardinal exits
#macro STAIRS_PROBABILITY 5 // Chance a new room joins the map by stairs instead of a cardinal exit
#macro NO_CARDINAL_EXIT_ROOM_PROBABILITY get_probability_for_difficulty([0, 12, 8, 6, 4]) // Chance a room joined by stairs can only be reached by stairs, so it's combined with STAIRS_PROBABILITY
#macro LOCKED_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 12, 10, 6]) // Chance a visible chest is locked (one with a special item always is)
#macro CHEST_PROBABILITY get_probability_for_difficulty([6, 5, 4, 3, 2]) // Chance each room that can have a chest gets one, once the special rooms and the guaranteed chest have theirs
#macro SPECIAL_ITEM_PROBABILITY get_probability_for_difficulty([0, 7, 3, 3, 2]) // Rolled for each special item SPECIAL_ITEM_LIMIT allows beyond the special rooms' own
#macro SPECIAL_ITEM_LIMIT get_probability_for_difficulty([0, 1, 1, 2, 3]) // Most special items a map can have, counting the one in each special room
#macro TRAP_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 0, 8, 4]) // Chance a room's basic chest is a trap, so it's combined with the chance of the chest
#macro HIDDEN_CHEST_PROBABILITY get_probability_for_difficulty([0, 2, 2, 1, 1]) // Chance a new chest is hidden, rolled only in an unlit room with lanterns and no phantom
#macro COLLECTABLE_PROBABILITY get_probability_for_difficulty([4, 3, 3, 3, 2]) // Chance each room other than the start and heart rooms has collectables
#macro PORTCULLIS_PROBABILITY get_probability_for_difficulty([0, 0, 12, 8, 6]) // Chance an eligible room becomes a portcullis trap room
#macro MISLEADING_EXITS_PROBABILITY get_probability_for_difficulty([0, 0, 12, 6, 4]) // Chance a room's layout shows one exit more or fewer than the room has, rolled again for each further one
#macro ILLUSION_WALL_PROBABILITY get_probability_for_difficulty([0, 0, 0, 32, 16]) // Chance a cardinal exit gets illusion walls, rolled from each room it links, but never for an exit to the start room
#macro LOCKED_DOOR_PROBABILITY get_probability_for_difficulty([0, 16, 12, 10, 8]) // Each cardinal exit rolls at half this value, so exits are locked twice as often as it suggests
#macro OPEN_DOOR_PROBABILITY get_probability_for_difficulty([0, 32, 24, 12, 8]) // Rolled at double this value from each room an exit links, so about one in this per exit
#macro PRE_LIT_PROBABILITY get_probability_for_difficulty([1, 4, 6, 8, 12]) // Chance a room with lanterns starts with them lit
#macro KEY_IN_CHEST_PROBABILITY 3 // Chance a key for a lock goes in a chest instead of on a key spot
#macro BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 8, 2, 1]) // Only rolled once bombs can stand in for keys
#macro CHEST_ON_STAIRS_SPOT_PROBABILITY get_probability_for_difficulty([0, 16, 8, 4, 3]) // Chance a room without stairs puts its chest or encased heart on the stairs spot instead of the chest spot
#macro SPECIAL_ROOM_LIMIT get_probability_for_difficulty([0, 0, 0, 1, 2]) // Most special rooms a map can have, each of a different special room type
#macro SPECIAL_ROOM_PROBABILITY get_probability_for_difficulty([0, 0, 0, 8, 6]) // Rolled once for each special room SPECIAL_ROOM_LIMIT allows
#macro SPECIAL_MAP_SHAPE_PROBABILITY get_probability_for_difficulty([0, 0, 0, 0, 0]) // Chance of a long, straight map, a shape generation doesn't build yet

// Room contents, rolled for each room during map generation or each time the player enters it
#macro COLUMN_FOUNTAIN_PROBABILITY get_probability_for_difficulty([0, 0, 128, 96, 48]) // Chance each column is replaced by a fountain
#macro STATUE_FOUNTAIN_PROBABILITY get_probability_for_difficulty([0, 0, 64, 32, 24]) // Chance each statue, a trap chest's included, is a fountain instead
#macro BUG_PROBABILITY get_probability_for_difficulty([512, 256, 112, 48, 24]) // Chance each dirt patch, bush or pile of bones hides a bug
#macro RED_BUG_PROBABILITY get_probability_for_difficulty([0, 0, 0, 12, 8]) // Chance a bug is an infectious red bug
#macro DIRT_PROBABILITY get_probability_for_difficulty([0, 16, 20, 24, 28]) // Not a chance: the most dirt patches a room spawns, and it spawns none about half the time
#macro NOSE_PROBABILITY get_probability_for_difficulty([0, 0, 4, 3, 2]) // Rolled at four times this value each time the player enters a room with lava
#macro FIRE_SKELETON_IN_LAVA_PROBABILITY get_probability_for_difficulty([0, 0, 0, 48, 32]) // Rolled each time the player enters a room with lava, if no nose spawns
#macro PHANTOM_PROBABILITY get_probability_for_difficulty([0, 4, 3, 3, 2]) // Only rolled for a room with lanterns that doesn't start lit
#macro FLOATER_PROBABILITY get_probability_for_difficulty([0, 0, 32, 24, 16]) // Only rolled for a room without a phantom
#macro HANDS_PROBABILITY get_probability_for_difficulty([0, 0, 12, 8, 4]) // Chance, on entering a room, that hands come for each item lying in it
#macro SAME_SKELETON_TYPE_PROBABILITY get_probability_for_difficulty([0, 0, 0, 32, 24]) // Chance every skeleton on the map is the same type
#macro EYES_PROBABILITY get_probability_for_difficulty([0, 0, 0, 0, 40]) // Chance a room swaps one skeleton spot's enemy for eyes, only when nothing else in it chases or shoots at the player
#macro TRAP_BONES_PROBABILITY get_probability_for_difficulty([0, 32, 28, 24, 18]) // Chance each pile of bones is a trap that rises as a skeleton
#macro MOVING_COLLECTABLE_PROBABILITY get_probability_for_difficulty([0, 0, 24, 18, 16]) // Chance one of a room's collectables moves
#macro SKIP_COLLECTABLE_SPAWN_PROBABILITY 0 // Chance each collectable spot after the first stays empty (0, so never)
#macro MOUTHS_PER_MOUTH (1+global.difficulty) // Mouths that spawn for each mouth in a room's layout

// Room grid, map size and difficulty scores
#macro GRID_SIZE 8 // Side length in pixels of one cell of a room's path finding grids
#macro MINIMUM_NUMBER_OF_ROOMS get_probability_for_difficulty([4, 8, 12, 15, 18]) // Fewest rooms a map has
#macro MAX_NUMBER_OF_ROOMS get_probability_for_difficulty([8, 12, 18, 22, 24]) // Most rooms a map has
#macro MAP_DIFFICULTY_SCORE_TARGET get_probability_for_difficulty([0, 2, 8.5, 21, 33]) // Rooms are added until the map's difficulty score reaches this, up to MAX_NUMBER_OF_ROOMS. It's about what a map of MINIMUM_NUMBER_OF_ROOMS scores on average, so about half of maps stop at the minimum and a map of easier rooms grows toward the maximum
#macro ROOM_DIFFICULTY_SCORE_MAX 8 // Generation skips any roll that would take the threats rolled into a room past this (see GameRoom.would_exceed_max_difficulty)
#macro LAYOUT_DIFFICULTY_SCORE_LIMIT get_probability_for_difficulty([0, 1.5, 2.2, infinity, infinity]) // A layout appears from the lowest difficulty whose limits its difficulty and time scores fit in (see RoomLayout.determine_minimum_difficulty), and infinity means no limit. The limits give each difficulty about as many layouts as room_converter.rb sorts into it
#macro LAYOUT_TIME_SCORE_LIMIT get_probability_for_difficulty([0, 0.1, 0.5, infinity, infinity]) // The same kind of limit for a layout's time score, the time a room with the layout costs on top of walking

// Lighting and screen flash. A light's range is counted in steps of DIMMING_RATE pixels, and its light fades out over
// that many steps
#macro DIMMING_RATE 8 // Distance in pixels over which a light dims by one step
#macro LANTERN_LIGHT_RANGE get_probability_for_difficulty([0, 16, 14, 13, 12]) // Range of a lit lantern's light
#macro TORCH_LIGHT_RANGE get_probability_for_difficulty([0, 13, 12, 11, 10]) // Range of a lit torch's light, doubled for a special torch
#macro PLAYER_LIGHT_RANGE get_probability_for_difficulty([0, 8, 7, 7, 6]) // Range of the player's own light, before a rosary or a held torch adds to it
#macro SCREEN_FLASH_DURATION 6 // Steps a screen flash takes to fade out
#macro LAVA_LIGHT_RANGE 4 // Range of the dim glow of lava, statues and fire skeletons, and of a magic beam's light
#macro FIREBALL_LIGHT_RANGE 3 // Range of the light a fireball gives off
	
// Gameplay. A step is one game update, which happens once every FRAMES_TO_WAIT_BEFORE_PROCESSING frames. An enemy's move
// frequency is how rarely it moves: each step it rolls a whole number from 0 up to the frequency and moves only if the
// roll is a cardinal direction (0 to 3), so a larger frequency means fewer moves.
#macro FRAMES_TO_WAIT_BEFORE_PROCESSING 6 // Frames between steps: objects update only once every this many frames, except projectiles (see can_process_this_frame)
#macro FRAMES_FOR_HEART_THUMP 12 // Steps in one heartbeat, three of which are the thump (see is_thump_frame)
#macro JUST_THE_WIND_PROBABILITY 2056 // Chance each step that a bush rustles on its own, as if in the wind
#macro BUSH_RUSTLE_FREQUENCY 16 // Chance each step that a bush rustles while an enemy stands in it
#macro SKELETON_MOVE_TOWARDS_PLAYER_FREQUENCY get_probability_for_difficulty([0, 64, 48, 32, 24]) // Chance a skeleton that moves follows its path toward the player, which it always does for dropped meat
#macro FAT_SKELETON_MOVE_FREQUENCY 48 // Move frequency of a fat skeleton
#macro SKELETON_MOVE_FREQUENCY 12 // Move frequency of a standard skeleton or fire skeleton (a cultist uses four times this)
#macro COCKROACH_HUNT_MOVE_FREQUENCY 6 // Move frequency of a cockroach hunting the player in a dark room
#macro FAST_SKELETON_MOVE_FREQUENCY 4 // Move frequency of a fast skeleton, and of a cockroach standing in light
#macro SNAKE_MOVE_FREQUENCY 4 // Chance each step that a snake moves twice instead of once
#macro SNAKE_HISS_FREQUENCY 40 // Chance each step that a snake hisses
#macro BLOOD_REPLACEMENT_PROBABILITY 32 // Chance a pile of bones is blood instead, rolled when it's created
#macro CORPSE_REPLACEMENT_PROBABILITY 1024 // Chance blood is a player's corpse instead, rolled when it's created
#macro CORPSE_DISINTEGRATE_PROBABILITY 8 // Chance each player's corpse in a room crumbles away when the player enters the room
#macro CORPSE_HEADLESS_PROBABILITY 16 // Chance a player's corpse is missing its head, and the same for each of its hands
#macro TRAP_RANGE 40 // Distance in pixels at which the player sets off traps and ambushers such as trap bones, mouths and hands
#macro BOMB_DUD_PROBABILITY 64 // Chance a plain bomb whose fuse runs out is a dud that can be lit again
#macro BLOCK_ITEM_PROBABILITY get_probability_for_difficulty([0, 0, 256, 128, 64]) // Chance each block spot hides an item or bones under its block
#macro NOSE_SELF_DESTRUCT_PROBABILITY get_probability_for_difficulty([0, 0, 0, 256, 128]) // Chance a nose or fire skeleton explodes instead of shooting
#macro RESPAWN_FREQUENCY 40 // Steps from a death until a rosary revives the player or the game ends, and until hands that held a rosary come back
#macro ECHO_SPAWN_FREQUENCY 64 // Steps between the echoes an echo generator spawns
#macro PLAYER_INFECTED_TIMER 64 // Moves of scrambled controls a red bug adds when it dies next to the player
#macro LIVING_BLOCK_PROBABILITY get_probability_for_difficulty([0, 0, 128, 64, 32]) // Chance each block spot's block comes alive

// Room entry delay, torch burn time and game completion
#macro FRAMES_TO_WAIT_UPON_ENTERING_ROOM 2 // Steps the player can't move for after entering a room
#macro MAX_TORCH_TIME_TO_REMAIN_LIT get_probability_for_difficulty([100, 80, 70, 65, 65]) // Seconds a freshly lit torch or lantern burns before it goes out, unless it's special
#macro TOTAL_COMPLETION_AMOUNT 4 // Milestones that win the game: entering the encased heart's room, collecting every collectable, carrying the heart and bringing it to the cross

// Depth constants: an instance with a lower depth is drawn in front of one with a higher depth
#macro PROJECTILE_DEPTH -300
#macro CARRIED_ITEM_DEPTH -250
#macro INCORPOREAL_ENEMY_DEPTH -225 // Enemies without a body, such as phantoms and floaters, and hands carrying a special staff
#macro GIANT_WORM_DEPTH -200 // A giant worm's head and body, and the parts of a giant eye
#macro FLOATING_ENEMY_DEPTH -25 // Enemies with a body that float, such as ears
#macro BUSH_DEPTH -20 // A bush, which hides whatever it covers
#macro PLAYER_DEPTH -10
#macro HANDS_WITH_STAFF_DEPTH -4 // Hands carrying a plain staff
#macro ILLUSION_WALL_DEPTH -2
#macro PUSH_BLOCK_DEPTH -1
#macro SOLID_DEPTH -1
#macro STANDARD_DEPTH 0 // The usual depth of an enemy standing on the ground
#macro DROPPED_ITEM_DEPTH 1
#macro COLLECTABLE_DEPTH 2
#macro SWORD_IN_GROUND_DEPTH 3
#macro CORPSE_DEPTH 4 // A player's corpse, and the player once dead
#macro BONES_DEPTH 5
#macro CROSS_DEPTH 6 // The cross, the heart plate, lanterns and open doors
#macro MOUTH_DEPTH 7
#macro DIRT_OVER_LAVA_DEPTH 11 // A path tile where a block filled in lava, drawn above the lava
#macro LAVA_DEPTH 12
#macro BLOOD_DEPTH 13
#macro BUTTON_DEPTH 14
#macro STAIRS_DEPTH 15
#macro DIRT_DEPTH 20 // Dirt patches and path tiles
#macro MIRROR_DEPTH 30 // Mirrors, the furthest back of these

// Default settings, used when no setting is saved and when the player resets their settings
#macro FULLSCREEN_DEFAULT true
#macro WINDOW_BORDER_DEFAULT false // Whether the game window has a border
#macro WINDOW_SCALING_DEFAULT 2 // Window size as a multiple of the game's native resolution
#macro INPUT_DEFAULT inputs.keyboard_default // Input style the game starts with (see the inputs enum)
#macro CAN_SCREEN_FLASH_DEFAULT true // Whether screen flashes are allowed
#macro GAME_COLOR_FADE_DEFAULT 10 // Lowest brightness, out of 100, that the game color can fade to, so it still shows in the dark
#macro GAME_COLOR_STRING_DEFAULT "FF0000" // The game color (red) as an RRGGBB hex string
#macro LAVA_EDGE_TYPE_DEFAULT  lava_edge_types.wavy_animated // How the edges of lava are drawn (see the lava_edge_types enum)
#macro PLAYER_OUTLINE_DEFAULT false // Whether an outline is drawn around the player