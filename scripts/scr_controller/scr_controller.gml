/// @function								restart_game();
function restart_game() {
	// Destroy all instances in this room and in every other room, then go back to the title screen
	with all { if (object_index != obj_game_manager) { instance_destroy(); } }
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
		if (string_starts_with(room_name, "rm_unused") || string_starts_with(room_name, "rm_no_exits")) { continue; }
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
	
	// initialize room list values
	game_rooms = array_create(0);
	mapped_rooms = array_create(0);
	rooms_with_collectables = array_create(0);
	rooms_with_key = array_create(0);
	rooms_with_item = array_create(0); // This is only rooms with non-special, non-key, non-trap chests / items
	spawned_items = array_create(0);
	spawned_special_items = array_create(0);

	// initialize game state values
	time_remaining = 1;
	time_provided = 1;
	current_room = noone;
	last_hole = noone;
	start_room = noone;
	heart_room = noone;
	total_number_of_rooms_with_collectables = 0;
	death_timer = 0;
	completion_amount = 0;
	sounds_to_play = array_create(0);
	carried_heart = false;
	current_score = 0;
	flash_time = 0;
	death_count = 0;
	used_special_items = 0;
	total_items = 0;
	initialize_room_transition_values()
}

/// @function								initialize_room_transition_values();
function initialize_room_transition_values() {
	entered_from_stairs = true;
	entered_from_spawn = true;
	blackout = true;
	transition = directions.respawn;
	transitioned_from = noone;
}

/// @function								get_one_unit_of_game_time();
function get_one_unit_of_game_time() {
	return (FRAMES_TO_WAIT_BEFORE_PROCESSING/game_get_speed(gamespeed_fps));
}

/// @function								is_game_won();
function is_game_won() {
	var controller = global.controller;
	return (controller.completion_amount >= TOTAL_COMPLETION_AMOUNT);
}

/// @function								is_game_lost();
function is_game_lost() {
	return (global.player.dead || is_time_up());
}

/// @function								is_time_up();
function is_time_up() {
	var controller = global.controller;
	return (ceil(controller.time_remaining) <= 0 || (global.player.dead && controller.death_timer == 0));
}

/// @function								are_all_collectables_collected();
function are_all_collectables_collected() {
	return (array_length(global.controller.rooms_with_collectables) == 0);
}

/// @function								transition_to_room(new_room);
function transition_to_room(new_room) {
	// Set room transition variables
	entered_from_stairs = (transition == directions.stairs || transition == directions.respawn);
	entered_from_spawn = (transition == directions.respawn);
			
	// Play transition sound
	if (transition == directions.respawn) { play_sound(snd_win, false); }
	else if (transition == directions.stairs) { play_sound(snd_stairs, false); }
	else { play_sound(snd_move, false); }
	
	// Change room
	new_room.go_to_room(true);
}

/// @function								can_process_this_frame();
function can_process_this_frame() {
	var controller = global.controller;
	return ((!is_existing_instance(controller) || controller.transition == directions.none) && global.game_manager.number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0);
}

/// @function										game_room_start();
function game_room_start() {
	// Mark room as one that has been visited at some point in this game
	if (!current_room.visited) {
		current_room.visited = true;	
		array_push(mapped_rooms, current_room);
	}
	// Do room entry stuff
	audio_stop_all();
	reset_game_object_image_blend();
	game_room_start_reposition_player();
	game_room_start_other();
	game_room_start_destroy_instances();
	game_room_start_reposition_instances();
	game_room_start_spawn_instances();
	//game_room_start_reposition_player();
}

/// @function										reset_game_object_image_blend();
function reset_game_object_image_blend() {
	with obj_game_object { image_blend = global.bg_color; }
}

/// @function										game_room_start_reposition_player();
function game_room_start_reposition_player() {
	var player = global.player;
	switch (transition) {
		case directions.up: { player.y = room_height-8; player.x = room_width/2; break; }
		case directions.right: { player.x = 8; player.y = room_height/2; break; }
		case directions.down: { player.y = 8; player.x = room_width/2; break; }
		case directions.left: { player.x = room_width-8; player.y = room_height/2; break; }
		default: {
				var start_spot = instance_find(obj_stairs_spot, 0);
				if (transitioned_from != noone && transitioned_from.connected_to != noone) { start_spot = transitioned_from.connected_to; }
				player.x = start_spot.x;
				player.y = start_spot.y;
				break;
		}
	}
	move_player(directions.stairs);
	player.pause_movement = FRAMES_TO_WAIT_UPON_ENTERING_ROOM;
}
	
/// @function										game_room_start_other();
function game_room_start_other() {
	var player = global.player;
	
	with (obj_item) {
		if (special && is_existing_instance(holder) && holder == player && !counted) {
			other.used_special_items += 1;
			counted = true;
		}
	}
	with (obj_bumper) {
		var target = get_dropped_meat();
		if (!is_existing_instance(target)) { target = player; }
		
		xstart = target.x;
		ystart = target.y;
			
		switch (other.transition) {		
			case directions.up: { ystart -= TRAP_RANGE; break; }
			case directions.right: { xstart += TRAP_RANGE; break; }
			case directions.down: { ystart += TRAP_RANGE; break; }
			case directions.left: { xstart -= TRAP_RANGE; break; }
			default: { 
				teleport_near_player();
				xstart = x;
				ystart = y;
				break; 
			}
		}
	}
	with (obj_dirt) {
		if (!is_solid_at_position(x, y)) { 
			has_bug = get_random_chance_out_of(HAS_BUG_PROBABILITY);
		}
	}
	with (obj_bush) { 
		occupier = noone; 
		is_occupied = false;
		has_bug = get_random_chance_out_of(HAS_BUG_PROBABILITY);
	}
	with (obj_player_corpse) { has_bug = true; if (get_random_chance_out_of(CORPSE_DISINTEGRATE_PROBABILITY)) { instance_destroy(); } }
	with (obj_bones) { 
		if (!is_solid_at_position(x, y)) {
			has_bug = get_random_chance_out_of(HAS_BUG_PROBABILITY);
			trap = (get_random_chance_out_of(TRAP_BONES_PROBABILITY)); 
		} 
	}
	with (obj_stairs) { active = false; }
	with (obj_door) { 
		if (door_for_exit != noone) {
			locked = ( door_for_exit.locked);
			if (door_for_exit.destroyed) { instance_destroy(); }
		}
		if (place_meeting(x, y, player)) { open_door(); }
	}
}

/// @function										game_room_start_spawn_instances();
function game_room_start_spawn_instances() {
	//// If room has dropped item, consider spawning hands
	if (instance_number(obj_item) > 0) {
		// Set up list of items that could cause hands to spawn
		var potential_items = array_create(0);
		with (obj_item) { if (!is_existing_instance(holder) && can_pick_up && object_index != obj_heart && object_index != obj_meat && !is_solid_at_position(x, y) && !place_meeting(x, y, obj_hands)) { 
			array_push(potential_items, id); } 
		}
		// Spawn a hand on each potential item if probability is met
		for (var i = 0; i < array_length(potential_items); i++) {
			var potential_item = potential_items[i];
			if (!entered_from_spawn && get_random_chance_out_of(HANDS_PROBABILITY)) { 
				var new_hands = instance_create(potential_item.x, potential_item.y, obj_hands);
				new_hands.target_item = potential_item;
				new_hands.xstart = potential_item.x;
				new_hands.ystart = potential_item.y;
			}
		}
	}
	
	/// If room has lava, consider spawning nose
	if (instance_number(obj_lava) > 0 && get_random_chance_out_of(NOSE_PROBABILITY*4)) { instance_create(8, 8, obj_nose); }
}

/// @function										game_room_end();
function game_room_end() {
	with (obj_hands) {
		if (is_existing_instance(right_hand_item)) {
			x = xstart;
			y = ystart;
			set_instance_to_same_position(right_hand_item);
			with (right_hand_item) { image_xscale = other.image_xscale; }
			activated = false;
			visible = false;
			target_item = right_hand_item;
			put_down_item(right_hand_item, false, true);
			target_item.holder = id;
		}
		else { instance_destroy(); }
	}
}

/// @function										game_room_start_destroy_instances();
function game_room_start_destroy_instances() {
	//// Destroy instances that shouldn't persist when returning to the room
	with (obj_bug) { instance_destroy(); }
	with (obj_echo) { instance_destroy(); }
	with (obj_fireball) { instance_destroy(); }
	with (obj_bomb) { 
		if (!is_existing_instance(holder) && fuse_timer > 0) {
			if (special) { fuse_timer = 0; } 
			else { instance_destroy(); }
		}
	}
	with (obj_meat) {
		if (!is_existing_instance(holder) || holder.object_index == obj_hands) { 
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
}

/// @function										game_room_start_reposition_instances();
function game_room_start_reposition_instances() {
	//// Reset instances to their start positions when returning to the room
	with (obj_block) { x = xstart; y = ystart; }
	with (obj_item) { if (holder == noone) { x = xstart; y = ystart; } }
	with (obj_enemy) { if (object_index != obj_hands) { instance_create(xstart, ystart, object_index); instance_destroy(); } }
	with (obj_giant_worm_body) {
		var new_worm_body = instance_create(xstart, ystart, object_index);
		new_worm_body.xstart = xstart;
		new_worm_body.ystart = ystart;
		new_worm_body.image_blend = global.bg_color;
		instance_destroy(id, false);
	}
	with (obj_giant_worm_head) { connect_segments(); }
	with (obj_echo_spot) {
		if (other.entered_from_stairs && other.current_room == other.start_room) { instance_destroy(); }
		else {
			var player = global.player;
			play_sound(snd_echo, false); 
			spawn_timer = 16;
			moves = array_create(0);
			x = player.x;
			y = player.y;
		}
	}
}

/// @function										game_room_initialize();
function game_room_initialize() {
	var stairs_spot = instance_find(obj_stairs_spot, 0);
	if (stairs_spot == noone) {
		// This should never happen if every room has a stairs spot
		show_debug_message("WARNING: room with NO room to spawn stairs spot object: " + room_get_name(current_room.room_reference));
		current_room.stairs_spot_obj = -1;
	}
	
	// Flip game object positions as necesarry
	if (current_room.flip_horizontal) { flip_room_contents_horizontally(); }
	if (current_room.flip_vertical) { flip_room_contents_vertically(); }
	if (current_room.rotate != -1) { rotate_room_contents_around_room_center(current_room.rotate); }
	with obj_game_object { image_angle = 0; }
	with obj_placeholder { image_angle = 0; }
		
	// Update objects in room to reflect new x, y position as initial positions
	with (obj_block) {
		xstart = x;
		ystart = y;
	}
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
	var key_in_chest = (current_room.chest_obj == obj_key);
	if (current_room.has_key && !key_in_chest) {
		var key = noone;
		with get_random_instance(obj_collectable_spot) {
			key = instance_create(x, y, obj_key);
			instance_destroy();
		}
		current_room.add_to_instances_at_map_positions(key);
	}
		
	// Create portcullis button if it should exist
	for (var i = 0; i < 4; i++) {
		if (current_room.locked_exits[i] != noone) { current_room.has_portcullis = false; break; }
	}
	if (current_room.has_portcullis) {
		// Set up spots where button could spawn
		var possible_spots = array_create(0);
		if (current_room.stairs_spot_obj == -1) { array_push(possible_spots, stairs_spot); }
		if (!current_room.has_collectables || (!current_room.has_key || key_in_chest)) { 
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
    
	// Check each of the four exits for doors to create
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
		    if (!is_existing_instance(door)) { door = instance_create(x_pos, y_pos, obj_door); }
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
    
	// Create collectables in room if they should exist
	if (current_room.has_collectables) {
		with obj_collectable_spot { 
			var new_collectable = instance_create(x, y, obj_collectable);
			if (get_random_chance_out_of(MOVING_COLLECTABLE_PROBABILITY)) { new_collectable.moving = true; }
			instance_destroy(); 
		}
		if (instance_number(obj_collectable) == 0) { 
			// This should never happen if every room has 2+ collectable spots
			show_debug_message("WARNING: room with NO room to spawn collectables: " + room_get_name(current_room.room_reference));
			current_room.has_collectables = false;
			array_remove(rooms_with_collectables, current_room);
			total_number_of_rooms_with_collectables -= 1;
		}
	}
		
	// Set up room's chest_obj
	if (current_room.stairs_spot_obj == obj_chest && current_room.chest_obj == -1) { current_room.chest_obj = array_random_pop(spawned_items); }
	
	// Pre-light room if the room is marked as lit and spawn objects that interact with torches
	if (current_room.lit) { 
		if (instance_number(obj_lantern) == 0) { 
			// Should never need to reach this clause
			show_debug_message("WARNING: room with NO torches marked as lit: " + room_get_name(current_room.room_reference));
			current_room.lit = false; 
		}
		else { with obj_lantern { light_torch(noone, false); } }
	}
	else if (instance_number(obj_lantern) > 0) {
		// If room hsa lanterns but is not pre-lit, consider spawning phantom OR making chest hidden
		if (instance_number(obj_eyes) == 0 && get_random_chance_out_of(PHANTOM_PROBABILITY)) {
			instance_create(8, 8, obj_phantom);
		}
		else if (current_room.stairs_spot_obj == obj_chest && current_room.chest_obj != obj_statue && get_random_chance_out_of(HIDDEN_CHEST_PROBABILITY)) {
			current_room.stairs_spot_obj = obj_hidden_chest;
			current_room.has_locked_chest = false; // TODO: This causes extra key to spawn. If we move lit determination and hidden chest upstream, this can be avoided
		}
	}

	// Create room's stairs_spot object
	if (current_room.stairs_spot_obj != -1) { 
		var stairs_spot_inst = instance_create(stairs_spot.x, stairs_spot.y, current_room.stairs_spot_obj);
		if (current_room.chest_obj != obj_statue) {
			switch (stairs_spot_inst.object_index) {
				case obj_stairs:
				case obj_chest:
				case obj_hidden_chest:
				case obj_cross:
				case obj_encased_heart:{ 
					current_room.add_to_instances_at_map_positions(stairs_spot_inst);
					break;
				}
			}
		}
	}
		
	// If room has lava, consider spawning nose
	if (instance_number(obj_lava) > 0) { 
		if (get_random_chance_out_of(NOSE_PROBABILITY)) { instance_create(8, 8, obj_nose); }
		if (get_random_chance_out_of(NOSE_PROBABILITY*2)) { instance_create(8, 8, obj_nose); }
		if (get_random_chance_out_of(NOSE_PROBABILITY*3)) { instance_create(8, 8, obj_nose); }
	}
		
	// If room has mouth, spawn more mouths
	var target_number_of_mouths = instance_number(obj_mouth) * MOUTHS_PER_MOUTH;
	while (instance_number(obj_mouth) < target_number_of_mouths) { instance_create(x, y, obj_mouth); }
		
	// Spawn some dirt
	var dirt_to_spawn = irandom(DIRT_PROBABILITY*2) - DIRT_PROBABILITY;
	for (var i = 0; i < dirt_to_spawn; i++) { spawn_dirt(); }
		
	// Usurp some skeletons
	with (obj_skeleton) {
		var usurper_obj = -1;
		if (get_random_chance_out_of(EYES_PROBABILITY) && instance_number(obj_phantom) == 0 && instance_number(obj_eyes) == 0) { usurper_obj = obj_eyes; }
		else if (get_random_chance_out_of(SNAKE_PROBABILITY)) { usurper_obj = obj_snake; }
		else if (get_random_chance_out_of(FAST_SKELETON_PROBABILITY)) { skeleton_speed = FAST_SKELETON_MOVE_FREQUENCY; image_speed = 1; }
		if (usurper_obj != -1) { instance_create(x, y, usurper_obj); instance_destroy(); }
	}
		
	// Set up Lava Edge Drawing
	with (obj_lava) { set_up_lava_edge_visibility(true); }
}

/// @function								reset_map_generation();
function reset_map_generation() {
	global.seed += 1;
	if (global.seed > MAX_SEED) { global.seed = 0; }
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
	var controller = global.controller;
	with (controller) {
		var collectables_collected = total_number_of_rooms_with_collectables - array_length(rooms_with_collectables);
		var percentage_of_collectables_collected = floor(100*(collectables_collected/total_number_of_rooms_with_collectables));
		var percentage_of_time_remaining = (is_game_won()) ? 100*(time_remaining / time_provided) : 0;
		var percentage_of_victory = floor(100*(completion_amount/TOTAL_COMPLETION_AMOUNT))
		var percentage_of_rooms_mapped = floor(100*(array_length(mapped_rooms)/array_length(game_rooms)))
		var death_count_penalty = 2 * death_count;
		//var special_item_penalty = 5 * used_special_items;
		//var spawned_item_bonus = 10 - total_items;
		//if (spawned_item_bonus < 0 || !is_game_won()) { spawned_item_bonus = 0; }
		current_score = floor(percentage_of_collectables_collected + percentage_of_victory + percentage_of_time_remaining + percentage_of_rooms_mapped)/4;
		//current_score += spawned_item_bonus;
		current_score -= death_count_penalty// + special_item_penalty;
		if (current_score < 0) { current_score = 0; }
	}
	return controller.current_score;  
}

/// @function								get_probability_for_difficulty(probability_list);
///	@param		{array} probability_list	A 5 position array containing the probabilities for each difficulty
function get_probability_for_difficulty(probability_list) {
	return probability_list[global.difficulty];
}

/// @function								get_direction_input(key_pressed_only)
/// @param		{bool} key_pressed_only		Whether to only count if the key has been pressed this frame
function get_direction_input(key_pressed_only) {
	var player = global.player, game_manager = global.game_manager;
	// Return no input if player is dead or looking at map
	if (player.dead || game_manager.key_space) { return directions.none; }
	
	// Starting with the previous direction, check each direction for inputs
	var possible_directions = array_create(0);
	for (var i = 0; i < 4; i++) {
		var current_dir = (i+player.dir_prev) % 4;
		
		// For the player object, skip directions that block movement
		// This allows doors, chests, blocks, etc. to evaluate ignoring blocking objects
		// so that they can be pushed and opened even when against a wall
		if (object_index == obj_player && !can_move_in_direction(current_dir, false, true)) { continue; }
		
		if current_dir == directions.up &&
			game_manager.key_up && 
			!game_manager.key_down &&
			(game_manager.key_up_pressed || !game_manager.key_up_released) &&
			(!key_pressed_only || game_manager.key_up_pressed) { 
				array_push(possible_directions, directions.up); 
		}
		else if current_dir == directions.down &&
				game_manager.key_down && 
				!game_manager.key_up &&
				(game_manager.key_down_pressed || !game_manager.key_down_released) &&
				(!key_pressed_only || game_manager.key_down_pressed) { 
					array_push(possible_directions, directions.down);  
		}
		else if current_dir == directions.left &&
				game_manager.key_left && 
				!game_manager.key_right &&
				(game_manager.key_left_pressed || !game_manager.key_left_released) &&
				(!key_pressed_only || game_manager.key_left_pressed) { 
					array_push(possible_directions, directions.left); 
		}
		else if current_dir == directions.right &&
				game_manager.key_right && 
				!game_manager.key_left &&
				(game_manager.key_right_pressed || !game_manager.key_right_released) && 
				(!key_pressed_only || game_manager.key_right_pressed) { 
					array_push(possible_directions, directions.right); 
		}
	}
	
	if (array_length(possible_directions) == 0) { return directions.none; }
	return possible_directions[0];
}

/// @function								screen_flash();
function screen_flash() {
	if (global.can_screen_flash) {
		with (global.controller) {
			flash_time = SCREEN_FLASH_DURATION;
			global.bg_color = c_white;
		}
	}
}
