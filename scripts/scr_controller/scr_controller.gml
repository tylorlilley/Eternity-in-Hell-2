#macro FRAMES_TO_WAIT_UPON_ENTERING_ROOM 2 

/// @function								restart_game();
function restart_game() {
	// Destroy all instances in this room and in every other room, then go back to the title screen
	play_sound(snd_stairs, false); 
	with all { if (object_index != obj_game_manager) { instance_destroy(); } }
	destroy_all_game_rooms();
	room_goto(rm_title);
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
	game_rooms = [];
	mapped_rooms = [];
	rooms_with_collectables = [];
	spawned_items = [];
	spawned_special_items = [];

	// initialize game state values
	final_time_remaining = 0;
	time_remaining = 0;
	time_provided = 0;
	current_room = noone;
	last_hole_exit = -1;
	start_room = noone;
	heart_room = noone;
	total_number_of_rooms_with_collectables = 0;
	death_timer = 0;
	completion_amount = 0;
	sounds_to_play = [];
	carried_heart = false;
	flash_time = 0;
	final_player_right_hand_item = noone;
	final_player_left_hand_item = noone;
	evaluation_pos = 0;
	killed_by = noone;
	same_skeleton_type = noone;
	initialize_room_transition_values()
	
	// Start the record of the run, kept in memory until the run ends (see scr_run_record)
	run_record = new RunRecord();
	used_item_types = [];
}

/// @function								initialize_room_transition_values();
function initialize_room_transition_values() {
	entered_from_dir = directions.respawn;
	transition = directions.respawn;
	blackout = true;
	transitioning_exit = -1;
}

/// @function								get_one_unit_of_game_time();
function get_one_unit_of_game_time() {
	return (FRAMES_TO_WAIT_BEFORE_PROCESSING/game_get_speed(gamespeed_fps));
}

/// @function								is_game_won();
function is_game_won() {
	var _controller = global.controller;
	return (!is_existing_instance(_controller) || _controller.completion_amount >= TOTAL_COMPLETION_AMOUNT);
}

/// @function								is_game_lost();
function is_game_lost() {
	var  _player = global.player;
	if (!is_existing_instance(_player)) { return false; }
	
	return (!is_existing_instance(global.controller) || _player.dead || is_time_up());
}

/// @function								is_time_up();
function is_time_up() {
	var  _player = global.player;
	if (!is_existing_instance(_player)) { return false; }
	
	var _controller = global.controller;
	return (ceil(_controller.time_remaining) <= 0 || (_player.dead && _controller.death_timer == 0));
}

/// @function								are_all_collectables_collected();
function are_all_collectables_collected() {
	return (array_length(global.controller.rooms_with_collectables) == 0);
}


/// @function								can_process_this_frame();
function can_process_this_frame() {
	var _controller = global.controller;
	return ((!is_existing_instance(_controller) || _controller.transition == directions.none) && global.game_manager.number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0);
}

/// @function										transition_to_room(_new_room);
/// @param		{GameRoom}	_new_room				The new room to transition the current room too
function transition_to_room(_new_room) {
	var _room_to_use = _new_room;
	// Set room transition variables
	entered_from_dir = get_opposite_dir(transition);
			
	// Play transition sound
	if (_new_room.has_hall_of_mirrors && !current_room.has_hall_of_mirrors) { play_sound(snd_reflection, true); }
	
	if (transition == directions.respawn) { play_sound(snd_win, false); player_appear_timer = 4; current_room.mirror_count = 0; }
	else if (transition == directions.stairs) { play_sound(snd_stairs, false); global.player.visible = false; player_appear_timer = 4; current_room.mirror_count = 0; }
	else if (current_room.has_hall_of_mirrors) {
		_room_to_use = current_room;
		if (transition == current_room.mirror_directions[current_room.mirror_count]) { 
			// Correct Transition
			if (current_room.mirror_count < 3) { 
				play_sound(snd_yes, false); 
				current_room.mirror_count += 1;
				if (get_coin_flip()) { current_room.flip_room_contents_horizontally(); }
				if (get_coin_flip()) { current_room.flip_room_contents_vertically(); }
				current_room.rotate_room_contents_around_room_center(get_random_cardinal_dir());
				set_initial_positions();
			}
			else {
				// Complete the Hall
				current_room.has_hall_of_mirrors = false;
				increment_run_stat("hall_of_mirrors_room_solved");
				with (obj_hall_of_mirrors) { instance_destroy(); }
			}
		}
		else {
			// Incorrect Transition
			play_sound(snd_locked, false); 
			current_room.mirror_count = 0;
			if (get_coin_flip()) { current_room.flip_room_contents_horizontally(); }
			if (get_coin_flip()) { current_room.flip_room_contents_vertically(); }
			current_room.rotate_room_contents_around_room_center(irandom_range(0,3));
			set_initial_positions();
		}
	}
	else {
		var _used_exit = _new_room.exits[entered_from_dir];
		if (_used_exit.exit_type == exit_types.illusion_walls && !_used_exit.has_discovered_illusion_walls) {
			_used_exit.has_discovered_illusion_walls = true;
			increment_run_stat("illusion_walls_discovered");
		}
		play_sound(snd_move, false); 
	}
	
	// Run room exit logic for instances
	game_room_end();
	
	// Update which instances are active
	current_room.deactivate_room_instances();
	_room_to_use.activate_room_instances();
	current_room = _room_to_use;
	
	// Run room start logic for room instances
	game_room_start();
	
	// Reset room transition variables
	blackout = false;
	transition = directions.none;
	transitioning_exit = -1;
}

/// @function										game_room_start();
function game_room_start() {
	// Do room entry stuff
	audio_stop_all();
	reset_game_object_image_blend();
	game_room_start_reposition_player();
	game_room_start_other();
	game_room_start_destroy_instances();
	game_room_start_reposition_instances();
	game_room_start_spawn_instances();
	
	// Mark room as one that has been visited at some point in this game
	if (!current_room.visited) {
		// Do things only on the first player visit
		if (current_room.stairs_spot_obj == obj_encased_heart) { 
			global.controller.completion_amount += 1;
		}
		
		with (obj_giant_eye) {
			increment_run_stat("giant_eye_room_visited");
			for (var _i = 0; _i < 9; _i++) {
				var _x_pos = x, _y_pos = y;
				if (_i % 3 == 0) { _x_pos -=16; }
				else if (_i % 3 == 2) { _x_pos +=16; }
				if (_i < 3) { _y_pos -=16; }
				else if (_i > 5) { _y_pos +=16; }
				var _eye_part = instance_create(_x_pos, _y_pos, obj_game_object);
				_eye_part.sprite_index = get_sprite_to_use(spr_giant_eye_part);
				_eye_part.image_index = _i;
				_eye_part.depth = GIANT_WORM_DEPTH;
				eye_parts[_i] = _eye_part;
			}
		}
		
		if (instance_number(obj_gudetama) > 0) {
			increment_run_stat("gudetama_room_visited");
		}
		else if (instance_number(obj_hall_of_mirrors) > 0) { 
			increment_run_stat("hall_of_mirrors_room_visited");
		}
		else if (instance_number(obj_red_chest) > 0) { 
			increment_run_stat("red_chest_room_visited");
		}
		else if (instance_number(obj_inverted_cross) > 0) { 
			increment_run_stat("inverted_cross_room_visited");
		}
		
			
		// Mark current room and exit as visited
		current_room.visited = true;
		array_push(mapped_rooms, current_room);
	}
	if (transitioning_exit != -1) { transitioning_exit.visited = true; }
	
	// Reset mp grids
	mark_current_room_for_grid_update();
}

/// @function										reset_game_object_image_blend();
function reset_game_object_image_blend() {
	with obj_game_object { image_blend = global.bg_color; }
}

/// @function										game_room_start_reposition_player();
function game_room_start_reposition_player() {
	var _player = global.player;
	switch (entered_from_dir) {
		case directions.stairs: {
			var _start_spot = transitioning_exit.get_connected_stairs(transitioning_stairs);	
			_player.x = _start_spot.x;
			_player.y = _start_spot.y;
			break;
		}
		case directions.respawn: {
			var _start_spot = instance_find(obj_cross, 0);
			_player.x = _start_spot.x;
			_player.y = _start_spot.y;
			break;
		}
		default: {
			_player.x = get_exit_x_pos(entered_from_dir);
			_player.y = get_exit_y_pos(entered_from_dir);
			break;
		}
	}
	move_player(directions.stairs);
	_player.pause_movement = FRAMES_TO_WAIT_UPON_ENTERING_ROOM;
}
	
/// @function										game_room_start_other();
function game_room_start_other() {
	var _player = global.player;
		
	// Create portcullis if portcullis for exit has been triggered by another room
	var _entered_through_portcullis = false;
	for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
		var _current_exit = current_room.exits[_dir]
		if (_current_exit != -1 && _current_exit.is_portcullis_triggered) {
			// Create exit doorway
			var _x_pos = get_exit_x_pos(_dir), _y_pos = get_exit_y_pos(_dir);
			if (!place_meeting(_x_pos, _y_pos, obj_portcullis)) {
				var _door = instance_create(_x_pos, _y_pos, obj_portcullis);
				_door.door_for_exit = _current_exit;
				with (_door) { 
					initialize_door(); 
					if (_current_exit.destroyed) { _current_exit.is_portcullis_triggered = false; instance_destroy(); }
				}
			}
		}
		if (_current_exit != -1  && _dir == get_opposite_dir(transition) && (_current_exit.is_portcullis_triggered || _current_exit.has_closed_portcullis_for_room(current_room))) { _entered_through_portcullis = true; }
	}
	if (!current_room.visited && !_entered_through_portcullis && instance_number(obj_portcullis) > 0) { 
		play_sound(snd_shovel, false); 
	}

	with (obj_portcullis) {
		var _exit_has_closed_portcullis = door_for_exit.has_closed_portcullis_for_room(global.controller.current_room);
		if (!_exit_has_closed_portcullis) { open_portcullis(); }
	}
	with (obj_item) {
		if (special && is_existing_instance(holder) && holder == _player && !counted) {
			increment_run_stat("used_special_items");
			counted = true;
		}
	}
	with (obj_bumper_old) {
		var _target = get_dropped_meat();
		if (!is_existing_instance(_target)) { _target = _player; }
		
		xstart = _target.x;
		ystart = _target.y;
			
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
			has_bug = get_random_chance_out_of(BUG_PROBABILITY);
		}
	}
	with (obj_button) { dirt.has_bug = true; }
	with (obj_bush) { 
		occupier = noone; 
		is_occupied = false;
		has_bug = get_random_chance_out_of(BUG_PROBABILITY);
	}
	with (obj_player_corpse) { has_bug = true; if (get_random_chance_out_of(CORPSE_DISINTEGRATE_PROBABILITY)) { instance_destroy(); } }
	with (obj_bones) { 
		if (!is_solid_at_position(x, y)) {
			has_bug = get_random_chance_out_of(BUG_PROBABILITY);
			trap = (get_random_chance_out_of(TRAP_BONES_PROBABILITY)); 
		} 
	}
	with (obj_stairs) { active = false; }
	with (obj_door) { 
		if (door_for_exit != -1 && door_for_exit.destroyed) { instance_destroy(); }
		else if (place_meeting(x, y, _player)) { open_door(); }
		else if (!is_existing_instance(closed) && !stuck_open) { close_door(); }
	}
	with (obj_gudetama) { play_sound(snd_give_up, false); }
	with (obj_giant_eye) { shoot_timer = irandom_range(24,48); }
	
	/*
	// Make a random fountain and a random statue fire immediately
	var random_statue = get_random_instance(obj_statue, true);
	with random_statue { shoot_timer = irandom_range(1,4); }
	var random_fountain = get_random_instance(obj_fountain, true);
	with random_fountain { shoot_timer = irandom_range(1,4); }
	*/
	with (obj_statue) { 
		trap = false;
		if (other.transition >= directions.stairs) { shoot_timer += 4; }
	}
}

/// @function										game_room_start_spawn_instances();
function game_room_start_spawn_instances() {
	//// If room has dropped item, consider spawning hands
	if (instance_number(obj_item) > 0) {
		// Set up list of items that could cause hands to spawn
		var _potential_items = [];
		with (obj_item) { if (!is_existing_instance(holder) && can_pick_up && object_index != obj_heart && object_index != obj_meat && !is_solid_at_position(x, y) && !place_meeting(x, y, obj_hands)) { 
			array_push(_potential_items, id); } 
		}
		
		// Spawn a hand on each potential item if probability is met
		// Hands only spawn if the player holds something besides a key or bomb to trade
		var _can_trade = false, _player = global.player;
		with (_player) {
			_can_trade = (is_existing_instance(right_hand_item) && !is_carrying_item_in_right_hand(obj_key) && !is_carrying_item_in_right_hand(obj_bomb))
				|| (is_existing_instance(left_hand_item) && !is_carrying_item_in_left_hand(obj_key) && !is_carrying_item_in_left_hand(obj_bomb));
		}

		if (entered_from_dir != directions.respawn && _can_trade) {
			for (var _i = 0; _i < array_length(_potential_items); _i++) {
				var _potential_item = _potential_items[_i];
				if (get_random_chance_out_of(HANDS_PROBABILITY)) { 
					var _new_hands = instance_create(_potential_item.x, _potential_item.y, obj_hands);
					_new_hands.target_item = _potential_item;
					_new_hands.xstart = _potential_item.x;
					_new_hands.ystart = _potential_item.y;
				}
			}
		}
	}
	
	with (obj_encased_heart) { if (are_all_collectables_collected()) { break_heart_case(false); } }
	
	/// If room has lava, consider spawning enemies in lava
	if (instance_number(obj_lava) > 0) {
		if (instance_number(obj_nose) < global.difficulty && get_random_chance_out_of(MIDGAME_NOSE_PROBABILITY)) { instance_create(-16, -16, obj_nose); }
		else if (instance_number(obj_fire_skeleton) == 0 && get_random_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY)) { 
			var _fire_skeleton = instance_create(-16, -16, obj_fire_skeleton);
			with (_fire_skeleton) {  
				if (teleport_to_lava() == noone) { instance_destroy(self, false); }
				else { xstart = x; ystart = y; }
			}
		}
	}
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
	with (obj_projectile) { instance_destroy(); }
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
				with (obj_enemy) { if (corporeal && place_meeting(x, y, other.id)) { 
					kill_enemy(noone, obj_meat);
					increment_run_stat("meat_kill_count");
				} 
			}
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
	with (obj_spider) {
		activated = true;
		if (instance_number(obj_spider_spot) > 0) {
			var _random_spider_spot = get_random_instance(obj_spider_spot);
			x = _random_spider_spot.x;
			y = _random_spider_spot.y;
			start_waiting();
		}
	}
	with (obj_mouth) { activated = false; x = -16; y = -16; }
	with (obj_nose) { activated = false; x = -16; y = -16; }
	//with (obj_fire_skeleton) { activated = false; x = -16; y = -16; }
	with (obj_phantom) { activated = false; x = -16; y = -16; }
	with (obj_floater) { activated = false; x = -16; y = -16; }
	with (obj_snake) { turn_away_from_player(); }
	with (obj_giant_worm_body) {
		var _new_worm_body = instance_create(xstart, ystart, object_index);
		_new_worm_body.xstart = xstart;
		_new_worm_body.ystart = ystart;
		_new_worm_body.image_blend = global.bg_color;
		instance_destroy(id, false);
	}
	with (obj_giant_worm_head) { connect_segments(); }
	with (obj_echo_generator) {
		var _player = global.player;
		play_sound(snd_echo, false); 
		spawn_timer = 16;
		moves = [];
		x = _player.x;
		y = _player.y;
	}
}

/// @function										set_initial_positions();
function set_initial_positions() {
	with obj_game_object { image_angle = 0; }
	with obj_placeholder { image_angle = 0; }
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
}

/// @function destroy_all_game_rooms()
/// @description Clears the map's rooms when the game restarts: removes the instances from each room's room asset, and
///	frees each room's path grids
function destroy_all_game_rooms() {
	for (var _i = 0; _i < array_length(game_rooms); _i++) {
		var _game_room = game_rooms[_i];
		room_instance_clear(_game_room.room_reference);
		_game_room.destroy();
	}
}

/// @function								spawn_dirt();
function spawn_dirt() {
	var _x_pos = irandom(room_width/8) * 8, _y_pos = irandom(room_height/8) * 8
	with (instance_create(_x_pos, _y_pos, obj_dirt)) {
		if (is_covered_at_each_quadrant_by(obj_lava) || 
			is_covered_at_each_quadrant_by(obj_solid) ||
			is_covered_at_each_quadrant_by(obj_statue) ||
			is_covered_at_each_quadrant_by(obj_fountain) ||
			is_covered_at_each_quadrant_by(obj_mirror) ||
			is_covered_at_each_quadrant_by(obj_stairs) ||
			is_covered_at_each_quadrant_by(obj_bush) ||
			is_covered_at_each_quadrant_by(obj_cross) ||
			is_covered_at_each_quadrant_by(obj_lantern)) { 
				instance_destroy(id, false); 
		}
	}
}

/// @function								get_used_item_score()
function get_used_item_score() {
	var _controller = global.controller;
	if (!is_existing_instance(_controller)) { return 0; }
	
	var _item_score = array_length(global.controller.used_item_types) - 3;
	if (global.player_right_hand_item != noone) { _item_score -= 1; }
	if (global.player_left_hand_item != noone) { _item_score -= 1; }
	if (_item_score < 0) { _item_score = 0; }
	return _item_score;
}

/// @function								get_collectables_score()
function get_collectables_score() {
	var _controller = global.controller;
	if (!is_existing_instance(_controller)) { return 0; }
	
	var _collectables_collected = global.controller.total_number_of_rooms_with_collectables - array_length(global.controller.rooms_with_collectables);
	return floor(100*(_collectables_collected/global.controller.total_number_of_rooms_with_collectables));
}

/// @function								get_mapped_rooms_score()
function get_mapped_rooms_score() {
	var _controller = global.controller;
	if (!is_existing_instance(_controller)) { return 0; }
	
	return floor(100*(array_length(global.controller.mapped_rooms)/array_length(global.controller.game_rooms)));
}

/// @function								get_victory_amount_score()
function get_victory_amount_score() {
	var _controller = global.controller;
	if (!is_existing_instance(_controller)) { return 0; }
	
	return floor(100*(global.controller.completion_amount/TOTAL_COMPLETION_AMOUNT));
}

/// @function								get_probability_for_difficulty(_probability_list);
///	@param		{array} _probability_list	A 5 position array containing the probabilities for each difficulty
function get_probability_for_difficulty(_probability_list) {
	if (global.difficulty == difficulties.ALL) { return 1; }
	return _probability_list[global.difficulty];
}

/// @function								get_direction_input(_key_pressed_only)
/// @param		{bool} _key_pressed_only		Whether to only count if the key has been pressed this frame
function get_direction_input(_key_pressed_only) {
	var _player = global.player, _game_manager = global.game_manager;
	// Return no input if player is dead or looking at map
	if (_player.dead || _game_manager.key_space) { return directions.none; }
	
	// Starting with the previous direction, check each direction for inputs
	var _possible_directions = [];
	for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
		var _current_dir = (_dir+_player.dir_prev) % 4;
		
		// For the player object, skip directions that block movement
		// This allows doors, chests, blocks, etc. to evaluate ignoring blocking objects
		// so that they can be pushed and opened even when against a wall
		if (object_index == obj_player && !can_move_in_direction(_current_dir, false, true)) { continue; }
		
		if _current_dir == directions.up &&
			_game_manager.key_up && 
			!_game_manager.key_down &&
			(_game_manager.key_up_pressed || !_game_manager.key_up_released) &&
			(!_key_pressed_only || _game_manager.key_up_pressed) { 
				array_push(_possible_directions, directions.up); 
		}
		else if _current_dir == directions.down &&
				_game_manager.key_down && 
				!_game_manager.key_up &&
				(_game_manager.key_down_pressed || !_game_manager.key_down_released) &&
				(!_key_pressed_only || _game_manager.key_down_pressed) { 
					array_push(_possible_directions, directions.down);  
		}
		else if _current_dir == directions.left &&
				_game_manager.key_left && 
				!_game_manager.key_right &&
				(_game_manager.key_left_pressed || !_game_manager.key_left_released) &&
				(!_key_pressed_only || _game_manager.key_left_pressed) { 
					array_push(_possible_directions, directions.left); 
		}
		else if _current_dir == directions.right &&
				_game_manager.key_right && 
				!_game_manager.key_left &&
				(_game_manager.key_right_pressed || !_game_manager.key_right_released) && 
				(!_key_pressed_only || _game_manager.key_right_pressed) { 
					array_push(_possible_directions, directions.right); 
		}
	}
	
	if (array_length(_possible_directions) == 0) { return directions.none; }
	return _possible_directions[0];
}

/// @function								screen_flash();
function screen_flash() {
	if (global.can_screen_flash) {
		with (global.controller) {
			flash_obj = other.id;
			flash_time = SCREEN_FLASH_DURATION;
			global.bg_color = c_white;
		}
	}
}

