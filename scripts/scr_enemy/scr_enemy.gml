/// @function								kill_enemy(_death_sound, _killed_by);
///	@param		{index}	_death_sound			The sound to play upon killing this enemy
///	@param		{obj}	_killed_by			The type of object to credit for killing this enemy
function kill_enemy(_death_sound, _killed_by) {
	if (_death_sound != noone) { play_sound(_death_sound, true); }
	if (corporeal) {
		var _corpse = (object_index == obj_skeleton || object_index == obj_fast_skeleton || object_index == obj_fire_skeleton) ? obj_bones : obj_blood;
		instance_create(x, y, _corpse);
	}
	if (object_index == obj_hands) {
		with (right_hand_item) {
			if (object_index == obj_rosary) {
				var _new_hands = instance_create(other.xstart, other.ystart, obj_hands);
				_new_hands.death_timer = RESPAWN_FREQUENCY;
				if (!special) { instance_destroy(); }
				else {
					_new_hands.target_item = id; 
					_new_hands.target_x = x;
					_new_hands.target_y = y;
				}
			}
		}
	}
	if (object_index == obj_gudetama) {
		global.controller.evaluation_manager.increment_evaluation_variable("gudetama_room_solved");
	}
	if (_killed_by != noone) {
		update_kill_log(object_index, global.difficulty, _killed_by);
	}
	if (global.player.dead) {
		global.controller.evaluation_manager.increment_evaluation_variable("kill_after_death_count");
	}
	instance_destroy();
}

/// @function								kill_with_sword();
///	@param		{instance}	_sword			The sword being used to kill this enemy
function kill_with_sword(_sword) {
	var _holder_exists = is_existing_instance(_sword.holder);
    var _killer = _holder_exists ? _sword.holder.object_index : noone;

    if (_holder_exists && _sword.holder == global.player) {
        global.controller.evaluation_manager.increment_evaluation_variable("sword_kill_count");
    }
	if (!_sword.special) { 
		var _sword_in_ground = instance_create(x, y, obj_sword_in_ground);
		_sword_in_ground.image_xscale = _sword.image_xscale;
		_sword_in_ground.sprite_index = _sword.sprite_index;
		instance_destroy(_sword); 
	}
	kill_enemy(snd_crunch, _killer);
}

/// @function								run_away_from_player(_ignore_solid, _ignore_death, _make_sound);
/// @param		{boolean} _ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} _ignore_death		Whether to ignore objects that cause death or not when performing this check
function run_away_from_player(_ignore_solid, _ignore_death, _make_sound) {
	var _dir = get_random_cardinal_dir(), _player = global.player;
	if (is_direction_towards(_dir, _player)) { _dir = get_opposite_dir(_dir); }
	if (get_random_chance_out_of(3)) { _dir = directions.none; }
	if (can_move_in_direction(_dir, _ignore_solid, _ignore_death)) { move_in_direction(_dir, _make_sound);  return _dir; }
	
	return directions.none;
}

/// @function								teleport_to_empty_space()
function teleport_to_empty_space() {
	var _player = global.player, _blocked_by_enemy = false, _attempts = 0;
	do {
		_attempts += 1;
		x = irandom(room_width/8)*8;
		y = irandom(room_height/8)*8;
		_blocked_by_enemy = false;
		var _enemies = instance_place_all(x, y, obj_enemy);
		while (array_length(_enemies) > 0) {
			var _enemy = array_pop(_enemies);
			if (_enemy.id != id && instance_place(x, y, _enemy)) { _blocked_by_enemy = true; break; }
		}
	}
	until (_attempts > 128 || (!_blocked_by_enemy &&
			!is_solid_at_position(x, y) && 
			!is_lava_at_position(x, y) && 
			!place_meeting(x, y, obj_hidden_chest) && 
			!place_meeting(x, y, obj_illusion_wall) && 
			!place_meeting(x, y, obj_stairs_spot) && 
			!place_meeting(x, y, obj_player) &&
			!place_meeting(x, y, obj_button) &&
			!is_outside_room(x, y) &&
			get_distance_to_instance(_player) >= TRAP_RANGE));
}

/// @function								teleport_to_lava()
function teleport_to_lava() {
	var _total_lava = instance_number(obj_lava), _count = 0, _current_pos = irandom(_total_lava -1), _player = global.player;
	while (_count < _total_lava) {
		var _lava = instance_find(obj_lava, _current_pos);

		// Test this lava and all offsets by 8
		var _start_dir = irandom(4);
		for (var _dir = directions.up; _dir<= directions.stairs; _dir++) {
			// Set up lava for this run
			x = _lava.x;
			y = _lava.y;
			
			switch ((_dir+_start_dir) % 5) {
				case directions.up: { y -= 8; break; }
				case directions.right: { x += 8; break; }
				case directions.down: { y += 8; break; }
				case directions.left: { x -= 8; break; }
			}
			
			// return early if this is a good teleported position
			if (is_covered_at_each_quadrant_by(obj_lava_part) &&
				!is_outside_room(x, y) &&
				!is_covered_at_each_quadrant_by(obj_solid) &&
				!place_meeting(x, y, _player)) {
					return _lava;
			  }
		}
		
		// Setup next iteration
		_count += 1;
		_current_pos = (_current_pos + 1 >= _total_lava) ? 0 : _current_pos + 1;
	}
	
	// No suitable teleport spot; Should never need to reach this clause
	write_debug_message("Teleport to lava failed.", debug_message_level.warning);
	instance_destroy(id, false);
	return noone;
}

/// @function								shoot_projectile(_target_x, _target_y, _make_destructive)
///	@param		{int}	_target_x			The x position of the target to move towards;
///	@param		{int}	_target_y			The y position of the target to move towards;
///	@param		{boolean} _make_destructive	The y position of the target to move towards;
///	@param		{obj} _obj					The type of projectile to spawn;
function shoot_projectile(_target_x, _target_y, _make_destructive, _obj = obj_fireball) {
	play_sound((_obj == obj_magic_beam ? snd_magic : snd_shoot), false);
	var _proj = instance_create(x, y, _obj);
	with (_proj) {
		creator = other.id;
		creator_obj = other.object_index;
		destructive = _make_destructive;
		move_towards_point(_target_x, _target_y, (_obj == obj_fireball ? 2 : 0.75)); 
	}
	return _proj;
}

/// @function								try_to_see_player();
function try_to_see_player() {
	// Check for a target being exactly aligned with your x or y
	if (state != SCREECHING) {
		var _new_dir = directions.none, _on_target = false, _target = noone;// offset = (state == ATTACKING) ? 8 : 0;
		
		// Check all dropped meat and player
		with (obj_meat) {
			if (!is_existing_instance(holder) && _new_dir == directions.none) {
				if (x == other.x && y != other.y) {
					if (y > other.y) { _new_dir = directions.down; }
					else if (y < other.y) { _new_dir = directions.up; }
				}
				else if (y == other.y && x != other.x) {
					if (x > other.x) { _new_dir = directions.right; }
					else if (x < other.x) { _new_dir = directions.left; }
				}
				else if (y == other.y && x == other.x) {
					_target = id;
					_on_target = true;
				}
				
				if (_new_dir != directions.none) { _target = id; }
			}
		}
		if (_new_dir == directions.none) {
			with (global.player) {
				if (x == other.x && y != other.y) {
					if (y > other.y) { _new_dir = directions.down; }
					else if (y < other.y) { _new_dir = directions.up; }
				}
				else if (y == other.y && x != other.x) {
					if (x > other.x) { _new_dir = directions.right; }
					else if (x < other.x) { _new_dir = directions.left; }
				}
				else if (y == other.y && x == other.x) {
					_target = id;
					_on_target = true;
				}
				
				if (_new_dir != directions.none) { _target = id; }
			}
		}
		
		// Attack the new target
		if (_on_target) { state = WAITING; dir = directions.none; return; }
		else if (_new_dir != directions.none && _new_dir != dir && is_existing_instance(_target) && can_move_in_direction_and_reach(_new_dir, _target, false, true)) {
			dir = _new_dir;
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

/// @function								move_snake(_iterations);
///	@param		{int}	_iterations			The number of times to move in one frame
function move_snake(_iterations) {
	var _dropped_meat = get_dropped_meat();
	if (is_existing_instance(_dropped_meat) && is_instance_at_coordinates(x, y, _dropped_meat)) { dir = directions.none; return dir; }
		
	var _prev_dir = (dir == directions.none) ? get_random_cardinal_dir() : dir;
	
	// Move as far as possible in current direction
	for (var _i = 0; _i < _iterations; _i += 1; ) {
		if (dir != directions.none && can_move_in_direction(dir, false, false)) { move_in_direction(dir, true); }
		else { dir = directions.none; break; }
	}
	
	// Choose new direction to turn in
	if (dir == directions.none) {
		var _new_directions = [];
		array_push(_new_directions, get_opposite_dir(_prev_dir), get_turn_right_dir(_prev_dir), get_turn_left_dir(_prev_dir));
		while (array_length(_new_directions) > 0) {
			var _new_dir = array_random_pop(_new_directions);
			if ((!is_existing_instance(_dropped_meat) || is_direction_towards(_new_dir, _dropped_meat)) && can_move_in_direction(_new_dir, false, false)) { dir = _new_dir; break; }
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
			//image_angle = get_random_cardinal_dir()*90;
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
	for (var _next_dir = directions.up; _next_dir < directions.stairs; _next_dir++) {
		var _x_offset = 0, _y_offset = 0;
		
		switch(_next_dir)
		{
			case directions.up: { _y_offset = -16; break; }
			case directions.right: { _x_offset = 16; break; }
			case directions.down: { _y_offset = 16; break; }
			case directions.left: { _x_offset = -16; break; }
		}
	
		var _potential_tail = instance_place(x+_x_offset, y+_y_offset, obj_giant_worm_body);
		if (is_existing_instance(_potential_tail) && _potential_tail != head) { 
			tail = _potential_tail;
			tail.head = id; 
			tail.dir = get_opposite_dir(_next_dir);
			tail.prev_dir = get_opposite_dir(_next_dir);
			tail.depth = depth + 1;
			if (!is_existing_instance(head)) {
				dir = get_opposite_dir(_next_dir); 
				prev_dir = get_opposite_dir(_next_dir);
			}
			break;
		}
	}
	with tail { connect_segments(); }
	//set_segment_image();
}

/// @function								move_segments();
///	@param		{dir}	_new_dir				The direction to move the segments in
function move_segments(_new_dir) {
	move_in_direction(dir, false);
	with tail { move_segments(other.dir); }
	dir = prev_dir;
	prev_dir = _new_dir;
	//set_segment_image();
}

/// @function								explode(_destroy_self);
///	@param		{bool}	  _destroy_self		Whether to destroy the calling instance or not
function explode(_destroy_self) {
	global.controller.evaluation_manager.increment_evaluation_variable("spontaneously_exploded_enemy");
	play_sound(snd_explosion, true);
	screen_flash();
	
	// The Rest
	var _projectiles = [];
	array_push(_projectiles, shoot_projectile(x-8, y-4, true));
	array_push(_projectiles, shoot_projectile(x-4, y-8, true));
	array_push(_projectiles, shoot_projectile(x+4, y-8, true));
	array_push(_projectiles, shoot_projectile(x+8, y-4, true));
	array_push(_projectiles, shoot_projectile(x-8, y+4, true));
	array_push(_projectiles, shoot_projectile(x-4, y+8, true));
	array_push(_projectiles, shoot_projectile(x+4, y+8, true));
	array_push(_projectiles, shoot_projectile(x+8, y+4, true));
		
	// Diagonals
	array_push(_projectiles, shoot_projectile(x-8, y-8, true));
	array_push(_projectiles, shoot_projectile(x+8, y-8, true));
	array_push(_projectiles, shoot_projectile(x-8, y+8, true));
	array_push(_projectiles, shoot_projectile(x+8, y+8, true));
	
	// Cardinal Directions
	array_push(_projectiles, shoot_projectile(x+0, y-8, true));
	array_push(_projectiles, shoot_projectile(x+0, y+8, true));
	array_push(_projectiles, shoot_projectile(x-8, y+0, true));
	array_push(_projectiles, shoot_projectile(x+8, y+0, true));
	
	while (array_length(_projectiles) > 0) {
		var _proj = array_pop(_projectiles);
		_proj.shot_by_player = lit_by_player;
	}

	if (_destroy_self) { instance_destroy(); }
}

/// @function								check_for_player_collision();
function check_for_player_collision() {
	var _player = global.player;
	if (activated && place_meeting(x, y, _player) && !_player.dead) {
		var _carried_sword = noone, _carried_staff = noone;
		with (_player) { _carried_sword = get_carried_item(obj_sword); _carried_staff =  get_carried_item(obj_staff); }
		if (is_existing_instance(_carried_sword) && corporeal) { kill_with_sword(_carried_sword); }
		else if (object_index == obj_death || object_index == obj_lava_part) {
			if (object_index != obj_lava_part || _player.y <= y) {
				// Kill player from projectile
				with (_player) { 
					if (!is_carrying_item(obj_staff)) { 
						play_sound(snd_extinguish, false);
						var _killer = obj_lava;
						if (is_existing_instance(other.creator)) { 
							_killer = other.creator.object_index;
							if ((_killer == obj_statue || _killer == obj_fountain) && other.creator.trap) { _killer = obj_chest; }
						}
						kill_player(_killer);
					} 
				}
			}
		}
		else {
			// Kill player from enemy
			if (object_index != obj_fire_skeleton || !is_existing_instance(_carried_staff)) {
				var _killer = object_index;
				if (_killer == obj_skeleton) {
					if (spawn_timer > 0) { _killer = obj_bones; }
					else if (skeleton_speed == FAST_SKELETON_MOVE_FREQUENCY) { _killer = obj_fast_skeleton; }
				}
				if (corporeal) { play_sound(snd_crunch, false); }
				if (object_index == obj_hands && is_existing_instance(right_hand_item) && right_hand_item.object_index == obj_sword && !right_hand_item.special) {
					var _sword_in_ground = instance_create(_player.x, _player.y, obj_sword_in_ground);
					_sword_in_ground.image_xscale = right_hand_item.image_xscale;
					_sword_in_ground.sprite_index = right_hand_item.sprite_index;
					instance_destroy(right_hand_item); 
				}
				if (object_index == obj_fire_skeleton) { play_sound(snd_extinguish, false); }
				kill_player(_killer);
			}
		}
	}
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
	for (var _i = 0; _i < path_get_number(target_path); _i += 1) {
		var _px = (path_get_point_x(target_path, _i) div 8) * 8;
		var _py = (path_get_point_y(target_path, _i) div 8) * 8;

		path_change_point(target_path, _i, _px, _py, 8);
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

/// @function								move_towards_coordinates_on_path(_ignore_solid, _ignore_death, _number_of_moves);
/// @param		{boolean} _ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} _ignore_death		Whether to ignore objects that cause death or not when performing this check
/// @param		{real} _number_of_moves		The number of steps to take
function move_towards_coordinates_on_path(_ignore_solid, _ignore_death, _number_of_moves, _make_noise = true) {
	if (_ignore_solid && _ignore_death) { return move_towards_coordinates(target_x, target_y, _ignore_solid, _ignore_death); }
	if (target_path == noone && !has_automatic_target_path_generation) { return false; }
	else if (target_path_grid == -1) { return false; }
	
	// Update grid to be used for target path
	var _current_room = global.controller.current_room
	target_path_grid = (_ignore_death) ? _current_room.solid_path_grid : _current_room.lava_path_grid;
	if (_ignore_solid) { target_path_grid = _current_room.empty_path_grid; }
	
	// Generate new target path if one is needed
	if (target_path == noone) {
		var _has_found_new_path = set_automatic_target_path();
		if (!_has_found_new_path) { return directions.none; } 
	}
	if (target_x == -1 || target_y == -1) { return directions.none; }
	
	// Path generation worked or current path exists, so move along it
	var _move_count = 0, _move_dir = directions.none;
	while (target_path != noone && _move_count < _number_of_moves) {
		// Update current point along path
		var _x_diff = 0, _y_diff = 0, _path_point_x = 0, _path_point_y = 0;
		do {
			_path_point_x = path_get_point_x(target_path, current_path_point);
			_path_point_y = path_get_point_y(target_path, current_path_point);
			_x_diff = abs(_path_point_x - x);
			_y_diff = abs(_path_point_y - y);
			if ((_x_diff+_y_diff) < 8) { current_path_point += 1; }
			if (current_path_point > total_path_points) { end_target_path(); }
		}
		until (target_path == noone || (_x_diff+_y_diff) >= 8);
		if (target_path == noone) { return directions.none; }
	
		// Determine the direction to move
		var _move_horizontally = get_coin_flip();
		if (_x_diff > _y_diff) { _move_horizontally = true; }
		else if (_y_diff > _x_diff) { _move_horizontally = false; }
		
		if (_move_horizontally) {
			if (_path_point_x > x) { _move_dir = directions.right; }
			else if (_path_point_x < x) { _move_dir = directions.left; }
		}
		else {
			if (_path_point_y > y) { _move_dir = directions.down; }
			else if (_path_point_y < y) { _move_dir = directions.up; }
		}
	
		// Move once along the path
		var _blocked = !can_move_in_direction(_move_dir, _ignore_solid, _ignore_death);
		if (_move_dir == directions.none || _blocked || target_x < 0 || target_y < 0) { 
			_move_dir = directions.none; 
			end_target_path(); 
		}
		else {
			move_in_direction(_move_dir, _make_noise);
			_move_count += 1;
			if (is_instance_at_coordinates(target_x, target_y, id)) { 
				end_target_path(); break; 
			}
			else if (can_interrupt_target_path && has_automatic_target_path_generation) { set_automatic_target_path(); }
		}
	}
	
	return _move_dir;
}


/// @function								teleport_to_player();
function teleport_to_player() {
	var _player = global.player, _controller = global.controller;
	
	if (_controller.entered_from_dir >= directions.stairs) {
		x = _player.x;
		y = _player.y;
	}
	else {
		x = get_exit_x_pos(_controller.entered_from_dir);
		y = get_exit_y_pos(_controller.entered_from_dir);
	}
}

/// @function								turn_away_from_player();
function turn_away_from_player() {
	// Set initial direction to be away from player if possible
	var _start_dir = get_random_cardinal_dir();
	for (var _possible_dir = directions.up; _possible_dir < directions.stairs; _possible_dir++) {
		var _next_dir = ((_possible_dir+_start_dir) % 4)
		if (is_direction_towards(_next_dir, global.player)) { dir = get_opposite_dir(_next_dir); break; }
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

/// @function								move_towards_meat_or_player(_ignore_solid, _ignore_death, accuracy);
/// @param		{boolean} _ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} _ignore_death		Whether to ignore objects that cause death or not when performing this check
function move_towards_meat_or_player(_ignore_solid, _ignore_death) {
	// Target meat if possible, and player if not
	var _target = get_dropped_meat();
	if (!is_existing_instance(_target)) { _target = global.player; }
	
	// Set up a path towards the target
	target_x = _target.x;
	target_y = _target.y;
	return move_towards_coordinates_on_path(_ignore_solid, _ignore_death, 1);
}

/*
function move_towards_meat_or_player(ignore_solid, ignore_death, accuracy = 3) {
	var dir = irandom(accuracy), target = get_dropped_meat();
	if (dir >= directions.stairs) { return directions.none; }
	
	if (!is_existing_instance(target)) { target = global.player; }
	if (!is_direction_towards(dir, target)) { dir = get_opposite_dir(dir); }
	if (can_move_in_direction(dir, ignore_solid, ignore_death)) { 
		move_in_direction(dir, false); 
		return dir; 
	}
	
	return directions.none;
}
*/

/// @function								reset_nose();
function reset_nose() {
	image_index = 0;
	activated = false;
	spawn_timer = irandom_range(8, 64);
	teleport_to_lava();
}