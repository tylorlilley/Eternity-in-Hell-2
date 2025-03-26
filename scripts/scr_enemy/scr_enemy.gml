/// @function								kill_enemy(death_sound, killed_by);
///	@param		{index}	death_sound			The sound to play upon killing this enemy
///	@param		{obj}	killed_by			The type of object to credit for killing this enemy
function kill_enemy(death_sound, killed_by) {
	if (death_sound != noone) { play_sound(death_sound, true); }
	if (corporeal) {
		var corpse = (object_index == obj_skeleton || object_index == obj_fast_skeleton || object_index == obj_fire_skeleton) ? obj_bones : obj_blood;
		instance_create(x, y, corpse);
	}
	if (object_index == obj_hands) {
		with (right_hand_item) {
			if (object_index == obj_rosary) {
				var new_hands = instance_create(other.xstart, other.ystart, obj_hands);
				new_hands.death_timer = RESPAWN_FREQUENCY;
				if (!special) { instance_destroy(); }
				else {
					new_hands.target_item = id; 
					new_hands.target_x = x;
					new_hands.target_y = y;
				}
			}
		}
	}
	if (object_index == obj_gudetama) {
		global.controller.evaluation_manager.increment_evaluation_variable("gudetama_room_solved");
	}
	if (killed_by != noone) {
		update_kill_log(object_index, global.difficulty, killed_by);
	}
	if (global.player.dead) {
		global.controller.evaluation_manager.increment_evaluation_variable("kill_after_death_count");
	}
	instance_destroy();
}

/// @function								kill_with_sword();
///	@param		{instance}	sword			The sword being used to kill this enemy
function kill_with_sword(sword) {
	var killer = (is_existing_instance(sword) && is_existing_instance(sword.holder)) ? sword.holder.object_index : noone;
	if (is_existing_instance(sword) && is_existing_instance(sword.holder) && sword.holder == global.player) {
		global.controller.evaluation_manager.increment_evaluation_variable("sword_kill_count");
	}
	if (!sword.special) { 
		var sword_in_ground = instance_create(x, y, obj_sword_in_ground);
		sword_in_ground.image_xscale = sword.image_xscale;
		sword_in_ground.sprite_index = sword.sprite_index;
		instance_destroy(sword); 
	}
	kill_enemy(snd_crunch, killer);
}

/// @function								run_away_from_player(ignore_solid, ignore_death, make_sound);
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function run_away_from_player(ignore_solid, ignore_death, make_sound) {
	var dir = get_random_carindal_dir(), player = global.player;
	if (is_direction_toward(dir, player)) { dir = get_opposite_dir(dir); }
	if (get_random_chance_out_of(3)) { dir = directions.none; }
	if (can_move_in_direction(dir, ignore_solid, ignore_death)) { move_in_direction(dir, make_sound);  return dir; }
	
	return directions.none;
}

/// @function								teleport_to_empty_space()
function teleport_to_empty_space() {
	var player = global.player, blocked_by_enemy = false;
	do {
		x = irandom(room_width/8)*8;
		y = irandom(room_height/8)*8;
		blocked_by_enemy = false;
		var enemies = instance_place_all(x, y, obj_enemy);
		while (array_length(enemies) > 0) {
			var enemy = array_pop(enemies);
			if (enemy.id != id && instance_place(x, y, enemy)) { blocked_by_enemy = true; break; }
		}
	}
	until (!blocked_by_enemy &&
			!is_solid_at_position(x, y) && 
			!is_lava_at_position(x, y) && 
			!place_meeting(x, y, obj_hidden_chest) && 
			!place_meeting(x, y, obj_illusion_wall) && 
			!place_meeting(x, y, obj_stairs_spot) && 
			!place_meeting(x, y, obj_player) &&
			!place_meeting(x, y, obj_button) &&
			!is_outside_room(x, y) &&
			get_distance_to_instance(player) >= TRAP_RANGE);
}

/// @function								teleport_to_lava()
function teleport_to_lava() {
	var total_lava = instance_number(obj_lava)-1, count = 0, current_pos = irandom(total_lava), player = global.player;
	while (count < total_lava) {
		var lava = instance_find(obj_lava, current_pos);

		// Test this lava and all offsets by 8
		var start_dir = irandom(4);
		for (var dir = directions.up; dir<= directions.stairs; dir++) {
			// Set up lava for this run
			x = lava.x;
			y = lava.y;
			
			switch ((dir+start_dir) % 5) {
				case directions.up: { y -= 8; break; }
				case directions.right: { x += 8; break; }
				case directions.down: { y += 8; break; }
				case directions.left: { x -= 8; break; }
			}
			
			// return early if this is a good teleported position
			if (is_covered_at_each_quadrant_by(obj_lava_part) &&
				!is_outside_room(x, y) &&
				!is_covered_at_each_quadrant_by(obj_solid) &&
				!place_meeting(x, y, player)) {
					return lava;
			  }
		}
		
		// Setup next iteration
		count += 1;
		current_pos = (current_pos + 1 > total_lava) ? 0 : current_pos + 1;
	}
	
	// No suitable teleport spot; Should never need to reach this clause
	write_debug_message("Teleport to lava failed.", "WARNING");
	instance_destroy(id, false);
	return noone;
}

/// @function								shoot_projectile(target_x, target_y, make_destructive)
///	@param		{int}	target_x			The x position of the target to move towards;
///	@param		{int}	target_y			The y position of the target to move towards;
///	@param		{boolean} make_destructive	The y position of the target to move towards;
///	@param		{obj} obj					The type of projectile to spawn;
function shoot_projectile(target_x, target_y, make_destructive, obj = obj_fireball) {
	play_sound((obj == obj_magic_beam ? snd_magic : snd_shoot), false);
	var proj = instance_create(x, y, obj);
	with (proj) {
		creator = other.id;
		creator_obj = other.object_index;
		destructive = make_destructive;
		move_towards_point(target_x, target_y, (obj == obj_fireball ? 2 : 1)); 
	}
	return proj;
}

/// @function								try_to_see_player();
function try_to_see_player() {
	// Check for a target being exactly aligned with your x or y
	if (state != SCREECHING) {
		var new_dir = directions.none, on_target = false, target = noone;// offset = (state == ATTACKING) ? 8 : 0;
		
		// Check all dropped meat and player
		with (obj_meat) {
			if (!is_existing_instance(holder) && new_dir == directions.none) {
				if (x == other.x && y != other.y) {
					if (y > other.y) { new_dir = directions.down; }
					else if (y < other.y) { new_dir = directions.up; }
				}
				else if (y == other.y && x != other.x) {
					if (x > other.x) { new_dir = directions.right; }
					else if (x < other.x) { new_dir = directions.left; }
				}
				else if (y == other.y && x == other.x) {
					target = id;
					on_target = true;
				}
				
				if (new_dir != directions.none) { target = id; }
			}
		}
		if (new_dir == directions.none) {
			with (global.player) {
				if (x == other.x && y != other.y) {
					if (y > other.y) { new_dir = directions.down; }
					else if (y < other.y) { new_dir = directions.up; }
				}
				else if (y == other.y && x != other.x) {
					if (x > other.x) { new_dir = directions.right; }
					else if (x < other.x) { new_dir = directions.left; }
				}
				else if (y == other.y && x == other.x) {
					target = id;
					on_target = true;
				}
				
				if (new_dir != directions.none) { target = id; }
			}
		}
		
		// Attack the new target
		if (on_target) { state = WAITING; dir = directions.none; return; }
		else if (new_dir != directions.none && new_dir != dir && is_existing_instance(target) && can_move_in_direction_and_reach(new_dir, target, false, true)) {
			dir = new_dir;
			state = SCREECHING;
			screech_timer = 3;
			path_add_point(target_path, x, y, 1);
			play_sound(snd_spider, true);
		}
	}
}

/// @function								start_waiting();
function start_waiting() {
	state = WAITING;
	dir = directions.none;
	end_target_path();
	target_path = path_add();
	target_x = x;
	target_y = y;
	path_add_point(target_path, x, y, 1);
}

/// @function								move_snake(iterations);
///	@param		{int}	iterations			The number of times to move in one frame
function move_snake(iterations) {
	var dropped_meat = get_dropped_meat();
	if (is_existing_instance(dropped_meat) && is_instance_at_coordinates(x, y, dropped_meat)) { dir = directions.none; return dir; }
		
	var prev_dir = (dir == directions.none) ? get_random_carindal_dir() : dir;
	
	// Move as far as possible in current direction
	for (var i = 0; i < iterations; i += 1; ) {
		if (dir != directions.none && can_move_in_direction(dir, false, false)) { move_in_direction(dir, true); }
		else { dir = directions.none; break; }
	}
	
	// Choose new direction to turn in
	if (dir == directions.none) {
		var new_directions = array_create(0);
		array_push(new_directions, get_opposite_dir(prev_dir), get_turn_right_dir(prev_dir), get_turn_left_dir(prev_dir));
		while (array_length(new_directions) > 0) {
			var new_dir = array_random_pop(new_directions);
			if ((!is_existing_instance(dropped_meat) || is_direction_toward(new_dir, dropped_meat)) && can_move_in_direction(new_dir, false, false)) { dir = new_dir; break; }
		}
	}
	
	return dir;
}

/// @function								set_segment_images();
function set_segment_images() {
	set_segment_image();
	with tail { set_segment_images(); }
}

/// @function								set_segment_image();
function set_segment_image() {
	if (head && !tail) {
		flip_sprite_at_random(false);
		image_index = 0;
		image_yscale = 1;
		if (head.x == x) { image_angle = (head.y > y) ? 180 : 0; }
		if (head.y == y) { image_angle = (head.x < x) ? 90 : 270; }
	}
	if (!head && tail) {
		flip_sprite_at_random(false);
		image_index = 0;
		image_yscale = -1;
		if (tail.x != x && tail.y != y && is_cardinal_direction(dir)) { image_angle = (dir*-90); }
		else if (tail.x == x) { image_angle = (tail.y < y) ? 180 : 0; }
		else if (tail.y == y) { image_angle = (tail.x > x) ? 90 : 270; }
	}
	if (tail && head) {
		if (tail.x == head.x) {	
			flip_sprite_at_random(true);
			image_index = 1;
			image_angle = 0;
		}
		else if (tail.y == head.y) {	
			flip_sprite_at_random(true);
			image_index = 1;
			image_angle = 90;
		}
		//else if (abs(tail.x - x) == 8 && abs(tail.y - y) == 8) {
			//flip_sprite_at_random(true);
			//image_angle = get_random_carindal_dir()*90;
		//	image_index = 3;
		//}
		else {
			image_index = 2;
			image_xscale = 1;
			image_yscale = 1;
			if ((place_meeting(x, y-16, tail) && place_meeting(x+16, y, head)) ||
				(place_meeting(x, y-16, head) && place_meeting(x+16, y, tail))) {
					image_angle = 0;
			}
			else if ((place_meeting(x, y+16, tail) && place_meeting(x+16, y, head)) ||
					 (place_meeting(x, y+16, head) && place_meeting(x+16, y, tail))) {
					image_angle = 270;
			}
			else if ((place_meeting(x, y+16, tail) && place_meeting(x-16, y, head)) ||
					 (place_meeting(x, y+16, head) && place_meeting(x-16, y, tail))) {
					image_angle = 180;
			}
			else if ((place_meeting(x, y-16, tail) && place_meeting(x-16, y, head)) ||
					 (place_meeting(x, y-16, head) && place_meeting(x-16, y, tail))) {
					image_angle = 90;
			}
		}
	}
}

/// @function								connect_segments();
function connect_segments() {
	for (var next_dir = directions.up; next_dir < directions.stairs; next_dir++) {
		var x_offset = 0, y_offset = 0;
		
		switch(next_dir)
		{
			case directions.up: { y_offset = -16; break; }
			case directions.right: { x_offset = 16; break; }
			case directions.down: { y_offset = 16; break; }
			case directions.left: { x_offset = -16; break; }
		}
	
		var potential_tail = instance_place(x+x_offset, y+y_offset, obj_giant_worm_body);
		if (is_existing_instance(potential_tail) && potential_tail != head) { 
			tail = potential_tail;
			tail.head = id; 
			tail.dir = get_opposite_dir(next_dir);
			tail.prev_dir = get_opposite_dir(next_dir);
			tail.depth = depth + 1;
			if (!is_existing_instance(head)) {
				dir = get_opposite_dir(next_dir); 
				prev_dir = get_opposite_dir(next_dir);
			}
			break;
		}
	}
	with tail { connect_segments(); }
	//set_segment_image();
}

/// @function								move_segments();
///	@param		{dir}	new_dir				The direction to move the segments in
function move_segments(new_dir) {
	move_in_direction(dir, false);
	with tail { move_segments(other.dir); }
	dir = prev_dir;
	prev_dir = new_dir;
	//set_segment_image();
}

/// @function								explode(destroy_self);
///	@param		{bool}	  destroy_self		Whether to destroy the calling instance or not
function explode(destroy_self) {
	global.controller.evaluation_manager.increment_evaluation_variable("spontaneously_exploded_enemy");
	play_sound(snd_explosion, true);
	screen_flash();
	
	// The Rest
	var projectiles = array_create(0);
	array_push(projectiles, shoot_projectile(x-8, y-4, true));
	array_push(projectiles, shoot_projectile(x-4, y-8, true));
	array_push(projectiles, shoot_projectile(x+4, y-8, true));
	array_push(projectiles, shoot_projectile(x+8, y-4, true));
	array_push(projectiles, shoot_projectile(x-8, y+4, true));
	array_push(projectiles, shoot_projectile(x-4, y+8, true));
	array_push(projectiles, shoot_projectile(x+4, y+8, true));
	array_push(projectiles, shoot_projectile(x+8, y+4, true));
		
	// Diagonals
	array_push(projectiles, shoot_projectile(x-8, y-8, true));
	array_push(projectiles, shoot_projectile(x+8, y-8, true));
	array_push(projectiles, shoot_projectile(x-8, y+8, true));
	array_push(projectiles, shoot_projectile(x+8, y+8, true));
	
	// Cardinal Directions
	array_push(projectiles, shoot_projectile(x+0, y-8, true));
	array_push(projectiles, shoot_projectile(x+0, y+8, true));
	array_push(projectiles, shoot_projectile(x-8, y+0, true));
	array_push(projectiles, shoot_projectile(x+8, y+0, true));
	
	while (array_length(projectiles) > 0) {
		var proj = array_pop(projectiles);
		proj.shot_by_player = lit_by_player;
	}

	if (destroy_self) { instance_destroy(); }
}

/// @function								check_for_player_collision();
function check_for_player_collision() {
	var player = global.player;
	if (activated && place_meeting(x, y, player) && !player.dead) {
		var carried_sword = noone, carried_staff = noone;
		with (player) { carried_sword = get_carried_item(obj_sword); carried_staff =  get_carried_item(obj_staff); }
		if (is_existing_instance(carried_sword) && corporeal) { kill_with_sword(carried_sword); }
		else if (object_index == obj_death || object_index == obj_lava_part) {
			if (object_index != obj_lava_part || player.y <= y) {
				// Kill player from projectile
				with (player) { 
					if (!is_carrying_item(obj_staff)) { 
						play_sound(snd_extinguish, false);
						var killer = obj_lava;
						if (is_existing_instance(other.creator)) { 
							killer = other.creator.object_index;
							if ((killer == obj_statue || killer = obj_fountain) && killer.trap) { killer = obj_chest; }
						}
						kill_player(killer);
					} 
				}
			}
		}
		else {
			// Kill player from enemy
			if (object_index != obj_fire_skeleton || !is_existing_instance(carried_staff)) {
				var killer = object_index;
				if (killer == obj_skeleton) {
					if (spawn_timer > 0) { killer = obj_bones; }
					else if (killer.skeleton_speed == FAST_SKELETON_MOVE_FREQUENCY) { killer = obj_fast_skeleton; }
				}
				if (corporeal) { play_sound(snd_crunch, false); }
				if (object_index == obj_hands && is_existing_instance(right_hand_item) && right_hand_item.object_index == obj_sword && !right_hand_item.special) {
					var sword_in_ground = instance_create(player.x, player.y, obj_sword_in_ground);
					sword_in_ground.image_xscale = right_hand_item.image_xscale;
					sword_in_ground.sprite_index = right_hand_item.sprite_index;
					instance_destroy(right_hand_item); 
				}
				if (object_index == obj_fire_skeleton) { play_sound(snd_extinguish, false); }
				kill_player(killer);
			}
		}
	}
}

/// @function								update_target_path();
function update_target_path() {
	if (target_path_grid == -1) { return false; }
	
	if (has_automatic_target_path_generation && (can_interrupt_target_path || target_path == noone)) {
		return set_automatic_target_path();
	}
	
	return false;
}

/// @function								set_automatic_target_path();
function set_automatic_target_path() {
	if (target_path_grid == -1) { return false; }
	
	// Create a new path asset if none exists
	if (target_path == noone) { target_path = path_add(); }
	// Generate new path using mp_grid path function if possible
	if (!mp_grid_path(target_path_grid, target_path, x, y, target_x, target_y, true)) {
		// Path generation is impossible
		end_target_path();
		return false;
	}
	
	// Path generation successful
	initialize_target_path();
	set_path_point_to_target_path_start();
	return true;
}

/// @function								set_path_point_to_target_path_start();
function set_path_point_to_target_path_start() {
	// Reset variables used to track position along the target path
	total_path_points = path_get_number(target_path);
	current_path_point = 0;
}

/// @function								initialize_target_path();
function initialize_target_path() {
	if (!path_exists(target_path)) { return false; }
	
	// Set to Straight path and not curved
	path_set_kind(target_path, 0); 
	
	// If possible path exists update it to be on an 8x8 grid
	for (var i = 0; i < path_get_number(target_path); i += 1) {
		var px = (path_get_point_x(target_path, i) div 8) * 8;
		var py = (path_get_point_y(target_path, i) div 8) * 8;

		path_change_point(target_path, i, px, py, 8);
	}
	
	return true;
}

/// @function								end_target_path();
function end_target_path() {
	target_path = noone;
	total_path_points = 0;
	current_path_point = -1;
	target_x = -1;
	target_y = -1;
}

/// @function								move_towards_coordinates_on_path(ignore_solid, ignore_death, number_of_moves);
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
/// @param		{real} number_of_moves		The number of steps to take
function move_towards_coordinates_on_path(ignore_solid, ignore_death, number_of_moves, make_noise = true) {
	//if (ignore_solid && ignore_death) { return move_towards_coordinates(target_x, target_y, ignore_solid, ignore_death); }
	if (target_path == noone && !has_automatic_target_path_generation) { return false; }
	else if (target_path_grid == -1) { return false; }
	
	// Update grid to be used for target path
	var current_room = global.controller.current_room
	target_path_grid = (ignore_death) ? current_room.solid_path_grid : current_room.lava_path_grid;
	if (ignore_solid) { target_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE); }
	
	// Generate new target path if one is needed
	if (target_path == noone) {
		var has_found_new_path = set_automatic_target_path();
		if (!has_found_new_path) { return directions.none; } 
	}
	if (target_x == -1 || target_y == -1) { return directions.none; }
	
	// Path generation worked or current path exists, so move along it
	var move_count = 0, move_dir = directions.none;
	while (target_path != noone && move_count < number_of_moves) {
		// Update current point along path
		var x_diff = 0, y_diff = 0, path_point_x = 0, path_point_y = 0;
		do {
			path_point_x = path_get_point_x(target_path, current_path_point);
			path_point_y = path_get_point_y(target_path, current_path_point);
			x_diff = abs(path_point_x - x);
			y_diff = abs(path_point_y - y);
			if ((x_diff+y_diff) < 8) { current_path_point += 1; }
			if (current_path_point > total_path_points) { end_target_path(); }
		}
		until (target_path == noone || (x_diff+y_diff) >= 8);
		if (target_path == noone) { return directions.none; }
	
		// Determine the direction to move
		var move_horizontally = get_coin_flip();
		if (x_diff > y_diff) { move_horizontally = true; }
		else if (y_diff > x_diff) { move_horizontally = false; }
		
		if (move_horizontally) {
			if (path_point_x > x) { move_dir = directions.right; }
			else if (path_point_x < x) { move_dir = directions.left; }
		}
		else {
			if (path_point_y > y) { move_dir = directions.down; }
			else if (path_point_y < y) { move_dir = directions.up; }
		}
	
		// Move once along the path
		var blocked = !can_move_in_direction(move_dir, ignore_solid, ignore_death);
		if (move_dir == directions.none || blocked || target_x < 0 || target_y < 0) { 
			move_dir = directions.none; 
			end_target_path(); 
		}
		else {
			move_in_direction(move_dir, make_noise);
			move_count += 1;
			if (is_instance_at_coordinates(target_x, target_y, id)) { end_target_path(); break; }
			else if (can_interrupt_target_path && has_automatic_target_path_generation) { set_automatic_target_path(); }
		}
	}
	
	return move_dir;
}


/// @function								teleport_to_player();
function teleport_to_player() {
	var player = global.player, controller = global.controller;
	
	if (controller.entered_from_dir >= directions.stairs) {
		x = player.x;
		y = player.y;
	}
	else {
		x = get_exit_x_pos(controller.entered_from_dir);
		y = get_exit_y_pos(controller.entered_from_dir);
	}
}

/// @function								turn_away_from_player();
function turn_away_from_player() {
	// Set initial direction to be away from player if possible
	var start_dir = get_random_carindal_dir();
	for (var possible_dir = directions.up; possible_dir < directions.stairs; possible_dir++) {
		var next_dir = ((possible_dir+start_dir) % 4)
		if (is_direction_toward(next_dir, global.player)) { dir = get_opposite_dir(next_dir); break; }
	}
}

/// @function								move_ears();
function move_ears() {
	image_xscale = (x > target_x) ? 1 : -1;
	image_index = 2;
	image_speed = 0;
	move_towards_coordinates_on_path(false, true, 4);
	moved = true;
	return (target_path == noone);
}

/// @function								move_toward_player(ignore_solid, ignore_death, accuracy);
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
///	@param		{real}	accuracy			How often to move correctly
function move_toward_player(ignore_solid, ignore_death, accuracy = 3) {
	var dir = irandom(accuracy), target = get_dropped_meat();
	if (dir >= directions.stairs) { return directions.none; }
	
	if (!is_existing_instance(target)) { target = global.player; }
	if (!is_direction_toward(dir, target)) { dir = get_opposite_dir(dir); }
	if (can_move_in_direction(dir, ignore_solid, ignore_death)) { 
		move_in_direction(dir, false); 
		return dir; 
	}
	
	return directions.none;
}

/// @function								reset_nose();
function reset_nose() {
	image_index = 0;
	activated = false;
	spawn_timer = irandom_range(8, 64);
	teleport_to_lava();
}