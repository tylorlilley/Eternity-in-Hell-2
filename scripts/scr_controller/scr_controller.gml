/// @function								restart_game();
function restart_game() {
	// Destroy all instances in this room and in every other room, then go back to the title screen
	with all { instance_destroy(); }
	for (var i = 0; i < array_length(game_rooms); i++) {
		room_instance_clear(game_rooms[i].room_reference);
	}
	room_goto(rm_title);
}

/// @function								create_room_lists();
function create_room_lists() {
	rooms_with_no_exits = array_create(0); 
	rooms_with_one_exit = array_create(0); 
	rooms_with_two_opposite_exits = array_create(0);
	rooms_with_two_perpendicular_exits = array_create(0); 
	rooms_with_three_exits = array_create(0); 
	rooms_with_four_exits = array_create(0);
	
	for (var i = room_first; i <= room_last; i++) {
		var room_to_add = i, room_name = room_get_name(room_to_add);
		
		if (room_name = "rm_start" || room_name = "rm_finish" || room_name = "rm_title") { continue; }
		if (difficulty_for_room_reference(room_to_add) > global.difficulty) { continue; }
		
		if (string_pos("one_exit", room_name) != 0) { array_push(rooms_with_one_exit, room_to_add); }
		else if (string_pos("two_opposite_exits", room_name) != 0) { array_push(rooms_with_two_opposite_exits, room_to_add); }
		else if (string_pos("two_perpendicular_exits", room_name) != 0) { array_push(rooms_with_two_perpendicular_exits, room_to_add); }
		else if (string_pos("three_exits", room_name) != 0) { array_push(rooms_with_three_exits, room_to_add); }
		else if (string_pos("four_exits", room_name) != 0) { array_push(rooms_with_four_exits, room_to_add); }
	}
}
		
/// @function								initialize_game_variables();
function initialize_game_variables() {
	display_reset(0, false);
	layer_force_draw_depth(true,0);
	game_set_speed(60, gamespeed_fps);
	
	// Set up global shortcut references
	global.controller = id;
	global.player = noone;

	// Initialize room probability constants
	NUMBER_OF_EXITS_PROBABILITY = 9;
	HAS_STAIRS_PROBABILITY = 5;
	HAS_COLLECTABLE_PROBABILITY = get_probability_for_difficulty([4, 3, 3, 3, 2]);
	HAS_ITEM_PROBABILITY =  get_probability_for_difficulty([6, 12, 11, 10, 8]); // This happens only after the get stairs fails, so its combined with 4/5
	TRAP_CHEST_PROBABILITY = get_probability_for_difficulty([0, 0, 0, 24, 12])  // This happens only after the get item fails, so its combined with that probability
	HAS_KEY_PROBABILITY = get_probability_for_difficulty([10, 8, 6, 5, 4]);
	HAS_PORTCULLIS_PROBABILITY = get_probability_for_difficulty([0, 0, 20, 8, 4]);
	MISLEADING_ROOM_PROBABILITY = get_probability_for_difficulty([0, 0, 0, 24, 12]);
	LOCKED_DOOR_PROBABILITY = get_probability_for_difficulty([0, 8, 6, 5, 4]);
	PRE_LIT_PROBABILITY = get_probability_for_difficulty([1, 4, 6, 8, 12]);
	SPECIAL_ITEM_PROBABILITY = get_probability_for_difficulty([0, 24, 20, 18, 16]);
	SPECIAL_ITEM_LIMIT = global.difficulty;
	
	// Initilize room start probability constants
	ROOM_KEY_IN_CHEST_PROBABILITY = 3;
	DIRT_PROBABILITY = get_probability_for_difficulty([0, 16, 20, 24, 28]);
	NOSE_PROBABILITY = get_probability_for_difficulty([0, 0, 3, 2, 1]);
	PHANTOM_PROBABILITY = get_probability_for_difficulty([0, 5, 4, 3, 2]);
	SPIDER_PROBABILITY = get_probability_for_difficulty([0, 4, 2, 2, 1]);
	HANDS_PROBABILITY = get_probability_for_difficulty([0, 0, 12, 8, 4]);
	SNAKE_PROBABILITY =  get_probability_for_difficulty([0, 0, 24, 16, 8]);
	EYES_PROBABILITY =  get_probability_for_difficulty([0, 0, 0, 64, 46]);
	FAST_SKELETON_PROBABILITY = get_probability_for_difficulty([0, 0, 16, 14, 12]);
	TRAP_BONES_PROBABILITY = get_probability_for_difficulty([0, 36, 30, 28, 24]);
	MOVING_COLLECTABLE_PROBABILITY = get_probability_for_difficulty([0, 0, 32, 28, 24]);

	// Initialize map drawing constants
	FARM_MODE = global.FARM_MODE;
	MAX_WALKING_DEPTH = 16 * global.difficulty;
	MINIMUM_NUMBER_OF_ROOMS = get_probability_for_difficulty([4, 8, 12, 14, 15]);
	ADDITIONAL_ROOMS = 3 * global.difficulty;
	MAX_MAP_DRAW_DISTANCE = 8;
	MINIMUM_COLLECTABLES_ROOMS = MINIMUM_NUMBER_OF_ROOMS / 4;

	// Initialize lighting constants
	DIMMING_RATE = 8;
	LANTERN_LIGHT_RANGE = 14;
	TORCH_LIGHT_RANGE = 11;
	PLAYER_LIGHT_RANGE = 6;
	
	// Initilaize other gameplay constants
	BUSH_RUSTLE_PROBABILITY = 2056;
	BUSH_RUSTLE_FREQUENCY = 16;
	SKELETON_MOVE_FREQUENCY = 12;
	FAST_SKELETON_MOVE_FREQUENCY = 4;
	SNAKE_HISS_FREQUENCY = 32;
	SNAKE_MOVE_FREQUENCY = 4;
	BLOOD_REPLACEMENT_PROBABILITY = 32;
	CORPSE_REPLACEMENT_PROBABILITY = 1024;
	TRAP_RANGE = 40;
	BOMB_DUB_PROBABILITY = 64
	BLOCK_ITEM_PROBABILITY = get_probability_for_difficulty([0, 64, 32, 30, 28]);
	NOSE_SELF_DESTRUCT_PROBABILITY = get_probability_for_difficulty([0, 0, 0, 256, 128]);
	RESPAWN_FREQUENCY = 40;

	// Initialize score constants and variables
	FRAMES_TO_WAIT_BEFORE_PROCESSING = 6;
	FRAMES_TO_WAIT_UPON_ENTERING_ROOM = 2;
	MAX_TORCH_TIME_TO_REMAIN_LIT = get_probability_for_difficulty([100, 75, 65, 60, 50]); // minutes * 60 = total seconds for torch to remain lit
	TIME_PROVIDED_PER_ROOM = get_probability_for_difficulty([40, 38, 34, 30, 28]);
	TIME_PROVIDED_PER_EASY_ROOM = -5;
	TIME_PROVIDED_PER_HARD_ROOM = 15;
	TIME_PROVIDED_PER_DEAD_END = 10;
	TIME_PROVIDED_PER_COLLECTABLE = get_probability_for_difficulty([40, 25, 20, 16, 12]);
	TIME_PROVIEDED_PER_LOCK = 15;
	TOTAL_COMPLETION_AMOUNT = 4;
	//INITIAL_SCORE = 6+(20*60); // minutes * 60 = total seconds for game to run
	time_remaining = 1;
	time_provided = 1;
	
	// initialize room list values
	game_rooms = array_create(0);
	mapped_rooms = array_create(0);
	rooms_with_collectables = array_create(0);
	rooms_with_key = array_create(0);
	spawned_items = array_create(0);
	spawned_special_items = array_create(0);

	// initialize game state values
	current_room = noone;
	last_hole = noone;
	start_room = noone;
	total_number_of_rooms_with_collectables = 0;
	//rooms_with_collectables_collected = 0;
	//spawned_special_items = array_create(0);
	death_timer = 0;
	completion_amount = 0;
	sounds_to_play = array_create(0);
	carried_heart = false;
	current_score = 0;

	// initialize room transition values
	bg_color = make_color_rgb(20, 20, 20);
	number_of_frames_since_game_began = 0;
	entered_from_stairs = true;
	entered_from_spawn = true;
	blackout = true;
	transition = directions.respawn;
	transition_hole = noone;
	clear_inputs_for_next_frame();
}

/// @function								get_one_unit_of_game_time();
function get_one_unit_of_game_time() {
	return (global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING/game_get_speed(gamespeed_fps));
}

/// @function								is_game_won();
function is_game_won() {
	return (global.controller.completion_amount >= global.controller.TOTAL_COMPLETION_AMOUNT);
}

/// @function								is_game_lost();
function is_game_lost() {
	return (global.player.dead || is_time_up());
}

/// @function								is_time_up();
function is_time_up() {
	return (ceil(global.controller.time_remaining) <= 0 || (global.player.dead && global.controller.death_timer == 0));
}

/// @function								are_all_collectables_collected();
function are_all_collectables_collected() {
	return (array_length(global.controller.rooms_with_collectables) == 0);
}

/// @function								transition_to_room(new_room);
function transition_to_room(new_room) {
	// Set room transition variables
	entered_from_stairs = (transition >= 4);
	entered_from_spawn = (transition > 4);
			
	// Play transition sound
	if (transition == 5) { play_sound(snd_win, false); }
	else if (transition == 4) { play_sound(snd_stairs, false); }
	else { play_sound(snd_move, false); }
	
	// Change room
	new_room.go_to_room();
}

/// @function								can_process_this_frame();
function can_process_this_frame() {
	return (global.controller.transition == noone && global.controller.number_of_frames_since_game_began % global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING == 0);
}

/// @function								set_up_inputs_for_next_frame();
function set_up_inputs_for_next_frame() {
	key_up = key_up || keyboard_check(vk_up);
	key_down = key_down || keyboard_check(vk_down);
	key_left = key_left || keyboard_check(vk_left);
	key_right = key_right || keyboard_check(vk_right);
	key_space = key_space|| keyboard_check(vk_space);
	key_enter = key_enter|| keyboard_check(vk_enter);
	key_z = key_z || keyboard_check(ord("Z"));
	key_x = key_x || keyboard_check(ord("X"));
	
	key_up_pressed = key_up_pressed || keyboard_check_pressed(vk_up);
	key_down_pressed = key_down_pressed || keyboard_check_pressed(vk_down);
	key_left_pressed = key_left_pressed || keyboard_check_pressed(vk_left);
	key_right_pressed = key_right_pressed || keyboard_check_pressed(vk_right);
	key_space_pressed = key_space_pressed || keyboard_check_pressed(vk_space);
	key_enter_pressed = key_enter_pressed || keyboard_check_pressed(vk_enter);
	key_z_pressed  = key_z_pressed || keyboard_check_pressed (ord("Z"));
	key_x_pressed  = key_x_pressed || keyboard_check_pressed (ord("X"));
	
	key_up_released = key_up_released || keyboard_check_released(vk_up);
	key_down_released = key_down_released || keyboard_check_released(vk_down);
	key_left_released = key_left_released || keyboard_check_released(vk_left);
	key_right_released = key_right_released || keyboard_check_released(vk_right);	
	key_space_released = key_space_released || keyboard_check_released(vk_space);
	key_enter_released = key_enter_released || keyboard_check_released(vk_enter);
	key_z_released = key_z_released || keyboard_check(ord("Z"));
	key_x_released = key_x_released || keyboard_check(ord("X"));
}

/// @function								clear_inputs_for_next_frame();
function clear_inputs_for_next_frame() {
	key_up = false;
	key_down = false;
	key_left = false;
	key_right = false;
	key_space = false;
	key_enter = false;
	key_z = false;
	key_x = false;
	
	key_up_pressed = false;
	key_down_pressed = false;
	key_left_pressed = false;
	key_right_pressed = false;
	key_space_pressed = false;
	key_enter_pressed = false;
	key_z_pressed = false;
	key_x_pressed = false;
	
	key_up_released = false;
	key_down_released = false;
	key_left_released = false;
	key_right_released = false;
	key_space_released = false;
	key_enter_released = false;
	key_z_released = false;
	key_x_released = false;
}


/// @function								game_room_start();
function game_room_start() {
	var stairs_spot = instance_find(obj_stairs_spot, 0);
	audio_stop_sound( snd_dread );

	// Reposition player
	switch (transition) {
		case directions.up: { global.player.y = room_height-8; global.player.x = room_width/2; break; }
		case directions.right: { global.player.x = 8; global.player.y = room_height/2; break; }
		case directions.down: { global.player.y = 8; global.player.x = room_width/2; break; }
		case directions.left: { global.player.x = room_width-8; global.player.y = room_height/2; break; }
	}
	
	// Move player to current position
	move_player(4);
	
	// First Time Setup	
	if (!current_room.visited) {    
		// Flip game object positions as necesarry
		if (current_room.flip_horizontal) { flip_room_contents_horizontally(); }
		if (current_room.flip_vertical) { flip_room_contents_vertically(); }
		if (current_room.rotate != -1) { rotate_room_contents_around_room_center(current_room.rotate); }
		with obj_game_object { image_angle = 0; }
		with obj_placeholder { image_angle = 0; }
		
		// Update enemies in room to reflect new x, y position as initial position
		with (obj_item) {
			xstart = x;
			ystart = y;
		}
		with (obj_enemy) {
			xstart = x;
			ystart = y;
		}
		with (obj_giant_worm_body) {
			xstart = x;
			ystart = y;
		}
		with (obj_giant_worm_head) { connect_segments(); }
		
		// Create key in room if it should exist
		var key_in_chest = current_room.has_special_item;
		if (current_room.has_keys > 0) {
			if (!current_room.stairs_spot_obj && get_random_chance_out_of(ROOM_KEY_IN_CHEST_PROBABILITY)) { 	
				key_in_chest = true;
				current_room.item_type = obj_key;
				current_room.stairs_spot_obj = obj_chest;
			}
			else {
				with get_random_instance(obj_collectable_spot) {
					instance_create(x, y, obj_key);
					instance_destroy();
				} 
			}
		}
		
		// Create portcullis button if it should exist
		for (var i = 0; i < 4; i++) {
			if (current_room.locked_exits[i] != noone) { current_room.has_portcullis = false; break; }
		}
		if (current_room.has_portcullis) {
			// Set up spots where button could spawn
			var possible_spots = array_create(0);
			if (current_room.stairs_spot_obj == noone) { array_push(possible_spots, stairs_spot); }
			if (!current_room.has_collectables || (current_room.has_keys == 0 || key_in_chest)) { 
				with (obj_collectable_spot) { array_push(possible_spots, id); }
			}
			
			// Determine if button can spawn, and if so, spawn it in a possible spot
			if (array_length(possible_spots) == 0) { current_room.has_portcullis = false; }
			else {
				var button_spot = array_pop(possible_spots);
				instance_create(button_spot.x, button_spot.y, obj_dirt);
					
				if (button_spot == stairs_spot) { current_room.stairs_spot_obj = obj_button; }
				else {
					with button_spot {
						instance_create(x, y, obj_button);
						instance_destroy();
					}
				}
				
				while (array_length(possible_spots) > 0) {
					var button_spot = array_pop(possible_spots);
					instance_create(button_spot.x, button_spot.y, obj_dirt);
				}
			}
		}
    
		// Check each of the four exits
		for (var i = 0; i < 4; i++) {
		    var x_pos = 0;
		    var y_pos = 0;
        
		    if (i == 0) { x_pos = room_width/2; y_pos = 8; }
		    if (i == 1) { x_pos = room_width-8; y_pos = room_height/2; }
		    if (i == 2) { x_pos = room_width/2; y_pos = room_height-8; }
		    if (i == 3) { x_pos = 8; y_pos = room_height/2; }
		    var door = instance_position(x_pos, y_pos, obj_door);
        
			// Create locked exits if they should exist
		    var exit_to_create_door_for = current_room.locked_exits[i];
		    if (exit_to_create_door_for != noone) {
		        if (door == noone) { door = instance_create(x_pos, y_pos, obj_door); }
		        door.door_for_exit = exit_to_create_door_for;
		        door.locked = exit_to_create_door_for.locked;
		    }
			
			// Create portcullis doors if they should exist
			else if (current_room.has_portcullis && current_room.exits[i]) { instance_create(x_pos, y_pos, obj_portcullis); }
			
			// Create blocked exists if they should exist
			var x_pos_1 = 0, y_pos_1 = 0, x_pos_2 = 0, y_pos_2 = 0;
				
			if (i == 0) { x_pos_1 = (room_width/2)-8; y_pos_1 = 8; x_pos_2 = (room_width/2)+8; y_pos_2 = 8; }
			if (i == 1) { x_pos_1 = room_width-8; y_pos_1 = room_height/2-8; x_pos_2 = room_width-8; y_pos_2 =  room_height/2+8; }
			if (i == 2) { x_pos_1 = (room_width/2)-8; y_pos_1 = room_height-8; x_pos_2 = (room_width/2)+8; y_pos_2 = room_height-8; }
			if (i == 3) { x_pos_1 = 8; y_pos_1 = room_height/2-8; x_pos_2 = 8; y_pos_2 =  room_height/2+8; }
					
			if (!current_room.exits[i] && !place_meeting(x_pos, y_pos, obj_solid)) {   
				instance_create(x_pos_1, y_pos_1, obj_wall);
				instance_create(x_pos_2, y_pos_2, obj_wall);
			}
		}
	
		// Create room's stairs_spot object
		if (current_room.stairs_spot_obj != noone) {
		    instance_create(stairs_spot.x, stairs_spot.y, current_room.stairs_spot_obj);
		}
    
		// Create collectables in room if they should exist
		if (current_room.has_collectables) {
		    with obj_collectable_spot { 
				var new_collectable = instance_create(x, y, obj_collectable);
				if (get_random_chance_out_of(global.controller.MOVING_COLLECTABLE_PROBABILITY)) { new_collectable.moving = true; }
				instance_destroy(); 
			}
			if (instance_number(obj_collectable) == 0) { 
				// This should never happen if every room has 2+ collectable spots
				current_room.has_collectables = false;
				array_remove(rooms_with_collectables, array_get_index(rooms_with_collectables, current_room));
			}
		}
	
		// Remove lit status from room if it shouldn't exist
		if (current_room.lit) { 
			if (instance_number(obj_lantern) == 0) { current_room.lit = false; }
			else { with obj_lantern { light_torch(noone, false); } }
		}
		else
		{
			// If room is unlit but has the potential to be lit, consider spawning phantom
			if (instance_number(obj_lantern) > 0 && instance_number(obj_eyes) == 0 && get_random_chance_out_of(PHANTOM_PROBABILITY)) {
				instance_create(8, 8, obj_phantom);
			}
		}
		
		// If room has lava, consider spawning nose
		if (instance_number(obj_lava) > 0) { 
			if (get_random_chance_out_of(NOSE_PROBABILITY)) { instance_create(8, 8, obj_nose); }
			if (get_random_chance_out_of(NOSE_PROBABILITY*2)) { instance_create(8, 8, obj_nose); }
			if (get_random_chance_out_of(NOSE_PROBABILITY*3)) { instance_create(8, 8, obj_nose); }
		}
		
		// If room has mouth, spawn more mouths
		var target_number_of_mouths = instance_number(obj_mouth) * (1+global.difficulty);
		while (instance_number(obj_mouth) < target_number_of_mouths) { instance_create(x, y, obj_mouth); }
	
		// Mark room as one that has been visited at some point during this game
		current_room.visited = true;
		array_push(mapped_rooms, current_room);
		
		// Spawn some dirt
		var dirt_to_spawn = irandom(global.controller.DIRT_PROBABILITY*2) - global.controller.DIRT_PROBABILITY;
		for (var i = 0; i < dirt_to_spawn; i++) { spawn_dirt(); }
		
		// Usurp some skeletons
		with (obj_skeleton) {
			var usurped = noone;
			if (get_random_chance_out_of(global.controller.EYES_PROBABILITY) && global.difficulty >= difficulties.hard && instance_number(obj_phantom) == 0 && instance_number(obj_eyes) == 0) { usurped = obj_eyes; }
			else if (get_random_chance_out_of(global.controller.SNAKE_PROBABILITY) && global.difficulty >= difficulties.hard) { usurped = obj_snake; }
			else if (get_random_chance_out_of(global.controller.FAST_SKELETON_PROBABILITY) && global.difficulty >= difficulties.medium) { skeleton_speed = global.controller.FAST_SKELETON_MOVE_FREQUENCY; image_speed = 1; }
			if (usurped != noone) { instance_create(x, y, usurped); instance_destroy(); }
		}
	}

	// Every Time Setup
	//background_id = layer_background_get_id(layer_get_id("Background"));
	//layer_background_blend( background_id, bg_color);
	for (var i = 0; i < array_length(game_rooms); i++) { game_rooms[i].distance_to_current_room = 9999; }
	with current_room { calculate_distance_to_current_room(0); }

	// Change position if necessary
	if entered_from_stairs {
		if (transition_hole == noone) {
			global.player.x = stairs_spot.x;
			global.player.y = stairs_spot.y;
		}
		else {
			global.player.x = transition_hole.connected_hole.x;
			global.player.y = transition_hole.connected_hole.y;
		}
	}

	// Move character into position
	move_player(4);

	// Add a small pause when entering a room
	global.player.pause_movement = FRAMES_TO_WAIT_UPON_ENTERING_ROOM;

	// Set initial lighting to darkness
	with obj_game_object { image_blend = global.controller.bg_color; }
	
	// Run room start event for specific objects
	with (obj_bumper) {
		xstart = global.player.x;
		ystart = global.player.y;
			
		switch (global.controller.transition) {		
			case directions.up: { ystart -= 32; break; }
			case directions.right: { xstart += 32; break; }
			case directions.down: { ystart += 32; break; }
			case directions.left: { xstart -= 32; break; }
			default: { 
				teleport_near_player();
				xstart = x;
				ystart = y;
				break; 
			}
		}
	}
	with (obj_bush) { occupier = noone; occupied = false; }
	with (obj_bones) { if (!is_solid_at_position(x, y)) { trap = (get_random_chance_out_of(global.controller.TRAP_BONES_PROBABILITY)); } }
	with (obj_stairs) { active = false; }
	with (obj_hole) { active = false; }
	with (obj_door) { 
		if (door_for_exit != noone) {
			locked = ( door_for_exit.locked);
			if (door_for_exit.destroyed) { instance_destroy(); }
		}
		if (place_meeting(x, y, global.player)) { open_door(); }
	}
	
	//// Destroy instances that shouldn't persist after leaving the room
	with (obj_echo) { instance_destroy(); }
	with (obj_fireball) { instance_destroy(); }
	with (obj_bomb) { 
		if (holder == noone && fuse_timer > 0) {
			if (special) { fuse_timer = 0; } 
			else { instance_destroy(); }
		}
	}
	with (obj_meat) {
		if (holder == noone || holder.object_index == obj_hands) { 
			if (!special) {
				instance_create(x, y, obj_bones); 
				instance_destroy();
			}
			else {
				// If special, kill any enemies that were eating the meat
				with (obj_enemy) { if (corporeal && place_meeting(x, y, other.id)) { kill_enemy(noone); } }
			}
		} 
	}
	
	//// Reset instances to their start positions
	with (obj_block) { x = starting_spot.x; y = starting_spot.y; }
	with (obj_item) { x = xstart; y = ystart; }
	with (obj_enemy) { if (object_index != obj_hands && object_index != obj_statue) { instance_create(xstart, ystart, object_index); instance_destroy(); } }
	with (obj_giant_worm_body) {
		var new_worm_body = instance_create(xstart, ystart, object_index);
		new_worm_body.xstart = xstart;
		new_worm_body.ystart = ystart;
		new_worm_body.image_blend = global.controller.bg_color;
		instance_destroy(id, false);
	}
	with (obj_giant_worm_head) { connect_segments(); }
	with (obj_echo_spot) {
		if (global.controller.entered_from_stairs && global.controller.current_room == global.controller.start_room) { instance_destroy(id, false); }
		else {
			play_sound(snd_echo, false); 
			spawn_timer = 128;
			moves = array_create(0);
			x = global.player.x;
			y = global.player.y;
		}
	}
	
	//// If room has dropped item, consider spawning hands
	if (instance_number(obj_item) > 0) {
		// Set up list of items that could cause hands to spawn
		var potential_items = array_create(0);
		with (obj_item) { if (holder == noone && can_pick_up && object_index != obj_heart && object_index != obj_meat && !is_solid_at_position(x, y) && !place_meeting(x, y, obj_hands)) { 
			array_push(potential_items, id); } 
		}
		// Spawn a hand on each potential item if probability is met
		for (var i = 0; i < array_length(potential_items); i++) {
			var potential_item = potential_items[i];
			if (!entered_from_spawn && get_random_chance_out_of(HANDS_PROBABILITY)) { 
				var new_hands = instance_create(potential_item.x, potential_item.y, obj_hands);
				new_hands.target_item = potential_item;
				new_hands.right_hand_item = potential_item;
				new_hands.xstart = potential_item.x;
				new_hands.ystart = potential_item.y;
			}
		}
	}
	with (obj_hands) {
		x = xstart;
		y = ystart;
		activated = false;
		visible = false;
		
		if (right_hand_item == noone) { instance_destroy(); }
		else {
			target_item = right_hand_item;
			put_down_item(right_hand_item, false);
			target_item.holder = id;
			right_hand_item = target_item;
		}
	}
	
	/// If room has lava, consider spawning nose
	if (instance_number(obj_lava) > 0 && get_random_chance_out_of(NOSE_PROBABILITY*4)) { instance_create(8, 8, obj_nose); }
	
	//// Make sure player is in proper position after room start code has run
	move_player(4);
}

/// @function								set_up_locks_and_keys();
function set_up_locks_and_keys(keyless_rooms) {
	var total_rooms = array_length(game_rooms), visited_all_rooms = is_current_map_possible();
	while (!visited_all_rooms) {
		//break;
		var number_of_keys = total_rooms - (array_length(keyless_rooms)+1);
		var number_of_locked_exits = array_length(locked_exits);
	
	    // Add an additional key somewhere
	    if (array_length(keyless_rooms) > 0 && (array_length(locked_exits) == 0 || number_of_keys <= number_of_locked_exits*1.5)) {
			var room_to_add_key_to = array_random_pop(keyless_rooms);
			with (room_to_add_key_to) { set_up_room_key(); }
			//show_debug_message("NUMBER OF KEYS +1");
	    }
	
	    // Remove one of the locked doors and reset all rooms to have no keys
	    else if (array_length(locked_exits) > 0) {
	        with array_random_pop(locked_exits) { remove(); }
			for (var i = 0; i < total_rooms; i++) {
			    if (game_rooms[i].has_keys > 0) { game_rooms[i].has_keys = 0; array_push(keyless_rooms, game_rooms[i]); }
			}
			rooms_with_key = array_create(0);
			//show_debug_message("KEYS RESET; NUMBER OF LOCKS -1");
	    }
		else {
			// Should never need to reach this clause
			show_debug_message("WARNING: lock generation screwed up.");
			reset_map_generation();
		}
	
		visited_all_rooms = is_current_map_possible();
	}
	
	return keyless_rooms;
}

/// @function								reset_map_generation();
function reset_map_generation() {
	global.seed += 1;
	if (global.seed > 99999999) { global.seed = 0; }
	instance_destroy();
	room_restart();
}

/// @function								spawn_dirt();
function spawn_dirt() {
	var x_pos = irandom(room_width/8) * 8, y_pos = irandom(room_height/8) * 8
	with (instance_create(x_pos, y_pos, obj_dirt)) {
		if (is_covered_at_each_quadrant_by(obj_lava) || 
			is_covered_at_each_quadrant_by(obj_solid) ||
			is_covered_at_each_quadrant_by(obj_statue) ||
			is_covered_at_each_quadrant_by(obj_stairs) ||
			is_covered_at_each_quadrant_by(obj_bush) ||
			is_covered_at_each_quadrant_by(obj_cross) ||
			is_covered_at_each_quadrant_by(obj_lantern)) { 
				instance_destroy(id, false); 
		}
	}
}

/// @function								get_current_score()
function get_current_score() {
	with (global.controller) {
		var collectables_collected = total_number_of_rooms_with_collectables - array_length(rooms_with_collectables);
		var percentage_of_collectables_collected = floor(100*(collectables_collected/total_number_of_rooms_with_collectables));
		var percentage_of_time_remaining = (is_game_won()) ? 100*(time_remaining / time_provided) : 0;
		var percentage_of_victory = floor(100*(completion_amount/TOTAL_COMPLETION_AMOUNT))
		var percentage_of_rooms_mapped = floor(100*(array_length(mapped_rooms)/array_length(game_rooms)))
		current_score = floor(percentage_of_collectables_collected + percentage_of_victory + percentage_of_time_remaining + percentage_of_rooms_mapped)/4;
	}
	return global.controller.current_score;  
}

/// @function								get_best_score_string(difficulty);
///	@param		{array} probabilities		A 5 position array containing the probabilities for each difficulty
function get_probability_for_difficulty(probability_list) {
	return probability_list[global.difficulty];
}

/// @function								get_direction_input(key_pressed_only)
/// @param		{bool} key_pressed_only		Whether to only count if the key has been pressed this frame
function get_direction_input(key_pressed_only) {
	// Return no input if player is dead or looking at map
	if (global.player.dead || global.controller.key_space) { return noone; }
	
	// Starting with the previous direction, check each direction for inputs
	var possible_directions = array_create(0);
	for (var i = 0; i < 4; i++) {
		var current_dir = (i+global.player.dir_prev) % 4;
		
		// For the player object, skip directions that block movement
		// This allows doors, chests, blocks, etc. to evaluate ignoring blocking objects
		// so that they can be pushed and opened even when against a wall
		if (object_index == obj_player && !can_move_in_direction(current_dir, false, true)) { continue; }
		
		if current_dir == directions.up &&
			global.controller.key_up && 
			!global.controller.key_down &&
			(global.controller.key_up_pressed || !global.controller.key_up_released) &&
			(!key_pressed_only || global.controller.key_up_pressed) { 
				array_push(possible_directions, directions.up); 
		}
		else if current_dir == directions.down &&
				global.controller.key_down && 
				!global.controller.key_up &&
				(global.controller.key_down_pressed || !global.controller.key_down_released) &&
				(!key_pressed_only || global.controller.key_down_pressed) { 
					array_push(possible_directions, directions.down);  
		}
		else if current_dir == directions.left &&
				global.controller.key_left && 
				!global.controller.key_right &&
				(global.controller.key_left_pressed || !global.controller.key_left_released) &&
				(!key_pressed_only || global.controller.key_left_pressed) { 
					array_push(possible_directions, directions.left); 
		}
		else if current_dir == directions.right &&
				global.controller.key_right && 
				!global.controller.key_left &&
				(global.controller.key_right_pressed || !global.controller.key_right_released) && 
				(!key_pressed_only || global.controller.key_right_pressed) { 
					array_push(possible_directions, directions.right); 
		}
	}
	
	if (array_length(possible_directions) == 0) { return noone; }
	return possible_directions[0];
}