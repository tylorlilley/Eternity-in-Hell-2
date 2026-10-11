/// @function kill_enemy(_death_sound, _killed_by)
/// @description Kills the calling enemy: plays its death sound, leaves bones (for a skeleton) or blood (for any other
///	enemy with a body), logs the kill, and destroys it. Hands holding a rosary come back at their start position after a
///	delay, and the rosary is used up unless it's special, in which case the new hands go for it. The evaluation counts a
///	gudetama's death as solving its room, and also counts any kill made after the player has died.
/// @param {Asset.GMSound} _death_sound The sound to play as it dies (loud, so it draws ears enemies), or noone for none
/// @param {Asset.GMObject} _killed_by The object type to credit with the kill, or noone to leave the kill unlogged
function kill_enemy(_death_sound, _killed_by) {
	if (_death_sound != noone) { play_sound(_death_sound, true); }
	if (corporeal) {
		var _corpse = (object_index == obj_skeleton || object_index == obj_fast_skeleton || object_index == obj_fire_skeleton) ? obj_bones : obj_blood;
		instance_create(x, y, _corpse);
	}
	// Hands holding a rosary come back to life at their start position
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

/// @function kill_with_sword(_sword)
/// @description Kills the calling enemy with a sword, crediting the sword's holder as the killer. A sword that isn't
///	special is used up: it's destroyed, and a sword stuck in the ground is left where the enemy stood. A kill by the
///	player counts as a sword kill for the evaluation.
/// @param {Id.Instance} _sword The sword that kills the enemy
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

/// @function run_away_from_player(_ignore_solid, _ignore_death, _make_sound)
/// @description Moves the calling instance one space (8 pixels) away from the player: in a random cardinal direction,
///	reversed if it heads towards the player. It stays put one time in three, and when that direction is blocked.
/// @param {bool} _ignore_solid Whether it can move through solid objects
/// @param {bool} _ignore_death Whether it can move onto objects that cause death, such as lava
/// @param {bool} _make_sound Whether the move makes a movement sound
/// @returns {real} The direction it moved in (see directions), or directions.none if it stayed put
function run_away_from_player(_ignore_solid, _ignore_death, _make_sound) {
	var _dir = get_random_cardinal_dir(), _player = global.player;
	if (is_direction_towards(_dir, _player)) { _dir = get_opposite_dir(_dir); }
	if (get_random_chance_out_of(3)) { _dir = directions.none; }
	if (can_move_in_direction(_dir, _ignore_solid, _ignore_death)) { move_in_direction(_dir, _make_sound);  return _dir; }
	
	return directions.none;
}

/// @function teleport_to_empty_space()
/// @description Moves the calling enemy, such as a mouth or cultist, to a random free spot on the room's 8-pixel grid:
///	inside the room, with no other enemy, solid, lava, hidden chest, illusion wall, stairs spot, button or player on it,
///	and at least TRAP_RANGE pixels from the player. It gives up after 128 tries, staying at the last spot it picked.
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

/// @function teleport_to_lava()
/// @description Moves the calling enemy, a nose, onto a random lava spot. It tries the lava tiles in turn from a random
///	one, at each tile's own position and at the four positions 8 pixels from it, and takes the first spot that is all
///	lava, inside the room, not all solid and clear of the player. If no tile has such a spot, which shouldn't happen, it
///	logs a warning and destroys the enemy without running its Destroy event.
/// @returns {Id.Instance} The lava tile it moved onto or next to, or noone if it found no spot and destroyed the enemy
function teleport_to_lava() {
	var _total_lava = instance_number(obj_lava), _count = 0, _current_pos = irandom(_total_lava -1), _player = global.player;
	while (_count < _total_lava) {
		var _lava = instance_find(obj_lava, _current_pos);

		// Try the tile's own position and the four positions 8 pixels from it, starting from a random one
		var _start_dir = irandom(4);
		for (var _dir = directions.up; _dir<= directions.stairs; _dir++) {
			// Start from the lava tile's position
			x = _lava.x;
			y = _lava.y;
			
			switch ((_dir+_start_dir) % 5) {
				case directions.up: { y -= 8; break; }
				case directions.right: { x += 8; break; }
				case directions.down: { y += 8; break; }
				case directions.left: { x -= 8; break; }
			}
			
			// Stop at the first spot that is all lava, inside the room, not all solid and clear of the player
			if (is_covered_at_each_quadrant_by(obj_lava_part) &&
				!is_outside_room(x, y) &&
				!is_covered_at_each_quadrant_by(obj_solid) &&
				!place_meeting(x, y, _player)) {
					return _lava;
			  }
		}
		
		// Go on to the next lava tile, wrapping around after the last
		_count += 1;
		_current_pos = (_current_pos + 1 >= _total_lava) ? 0 : _current_pos + 1;
	}
	
	// No lava tile has a spot for it, which should never happen
	write_debug_message("Teleport to lava failed.", debug_message_level.warning);
	instance_destroy(id, false);
	return noone;
}

/// @function shoot_projectile(_target_x, _target_y, _make_destructive, [_obj])
/// @description Fires a projectile from the calling instance towards a position, with a shot sound. The projectile
///	remembers who fired it, and flies at speed 2 if it's a fireball or 0.75 if it's another type, such as a magic beam.
/// @param {real} _target_x The x position to fire towards
/// @param {real} _target_y The y position to fire towards
/// @param {bool} _make_destructive Whether a fireball destroys closed doors, chests, statues and giant eyes it hits
/// @param {Asset.GMObject} [_obj] The type of projectile to fire (obj_fireball by default)
/// @returns {Id.Instance} The projectile
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

/// @function try_to_see_player()
/// @description Has the calling spider look along its row and column for something to attack: dropped meat first, then
///	the player. A spider standing on its target just waits. One that sees a target in a new direction, with a clear
///	straight line to it, screeches for 3 steps before it attacks, and adds its spot to its path, which it follows back
///	afterwards. It does nothing while the spider is already screeching.
function try_to_see_player() {
	// Look for a target in the same row or column, unless it is already screeching
	if (state != SCREECHING) {
		var _new_dir = directions.none, _on_target = false, _target = noone;
		
		// Dropped meat comes first, then the player if no meat is in line
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
		
		// Wait on the target, or screech at one in a new direction that it can reach in a straight line, then attack
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

/// @function start_waiting()
/// @description Puts the calling spider in its waiting state: it stops moving, drops its old path, and starts a new one
///	from its current spot, which becomes its target, so it can retrace its steps back to it after an attack
function start_waiting() {
	state = WAITING;
	dir = directions.none;
	end_target_path();
	target_path = path_add();
	target_x = x;
	target_y = y;
	path_add_point(target_path, x, y, 1);
}

/// @function move_snake(_iterations)
/// @description Moves the calling snake up to _iterations spaces in its current direction, stopping when something
///	blocks it. Once stopped, it picks a new direction at random from turning around or turning either way, taking only a
///	direction it can move in and, if meat is on the ground, only one towards the meat. A snake on the meat just stops.
/// @param {real} _iterations The most spaces to move in one go
/// @returns {real} The direction it is heading in afterwards (see directions), or directions.none if it is stopped
function move_snake(_iterations) {
	var _dropped_meat = get_dropped_meat();
	if (is_existing_instance(_dropped_meat) && is_instance_at_coordinates(x, y, _dropped_meat)) { dir = directions.none; return dir; }
		
	var _prev_dir = (dir == directions.none) ? get_random_cardinal_dir() : dir;
	
	// Move up to _iterations spaces in the current direction, stopping when blocked
	for (var _i = 0; _i < _iterations; _i += 1; ) {
		if (dir != directions.none && can_move_in_direction(dir, false, false)) { move_in_direction(dir, true); }
		else { dir = directions.none; break; }
	}
	
	// Once stopped, turn to a free direction, towards the dropped meat if there is any
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

/// @function set_segment_images()
/// @description Sets the sprite of the calling worm segment, then of every segment behind it, so the whole worm looks
///	like one connected body after it moves
function set_segment_images() {
	set_segment_image();
	with tail { set_segment_images(); }
}

/// @function set_segment_image()
/// @description Sets the calling worm segment's sprite frame, angle and flip from where the adjacent segments are. A
///	segment's head is the segment ahead of it, and its tail is the segment behind it. The front and last segments are
///	end caps, turned to line up with the segment next to them. A middle segment is a straight piece when the segments on
///	either side of it are in line, and otherwise a corner piece, turned towards the two segments it joins.
function set_segment_image() {
	// The last segment: an end cap, turned to line up with the segment ahead of it
	if (head && !tail) {
		flip_sprite_at_random(false);
		image_index = 0;
		image_yscale = 1;
		if (head.x == x) { image_angle = (head.y > y) ? 180 : 0; }
		if (head.y == y) { image_angle = (head.x < x) ? 90 : 270; }
	}
	// The front segment: an end cap, facing away from the segment behind it, or the way it is heading when that segment is
	// diagonal
	if (!head && tail) {
		flip_sprite_at_random(false);
		image_index = 0;
		image_yscale = -1;
		if (tail.x != x && tail.y != y && is_cardinal_direction(dir)) { image_angle = (dir*-90); }
		else if (tail.x == x) { image_angle = (tail.y < y) ? 180 : 0; }
		else if (tail.y == y) { image_angle = (tail.x > x) ? 90 : 270; }
	}
	// A middle segment: a straight piece when the segments on either side of it are in line, otherwise a corner piece
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
		else {
			// A corner piece, turned towards the two segments it joins
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

/// @function connect_segments()
/// @description Links the calling worm segment to the segment behind it, and that one to the next, down to the end of
///	the worm. The segment behind is the giant worm segment 16 pixels away on a cardinal side other than the segment
///	ahead. It's told that the calling segment is ahead of it, drawn just behind it, and set to move towards it. A worm's
///	front segment, which has nothing ahead, is set to move away from the segment behind it.
function connect_segments() {
	// Look 16 pixels away on each cardinal side for the segment behind this one
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
}

/// @function move_segments(_new_dir)
/// @description Moves the calling worm segment one space along its queued moves, then does the same for every segment
///	behind it. Segments are 16 pixels apart and move 8 at a time, so each one repeats the moves of the segment ahead of
///	it two moves later. Its queue holds the move it makes now (dir) and the one after (prev_dir), and the move the
///	segment ahead just made joins the end.
/// @param {real} _new_dir The direction (see directions) the segment ahead of it has just moved in
function move_segments(_new_dir) {
	move_in_direction(dir, false);
	with tail { move_segments(other.dir); }
	dir = prev_dir;
	prev_dir = _new_dir;
}

/// @function explode(_destroy_self)
/// @description Makes the calling enemy or bomb explode: it counts for the evaluation, plays the explosion sound,
///	flashes the screen, and fires 16 destructive fireballs outwards in a ring. The fireballs count as shot by the player
///	if the player lit the explosive (lit_by_player).
/// @param {bool} _destroy_self Whether to destroy the calling instance too
function explode(_destroy_self) {
	global.controller.evaluation_manager.increment_evaluation_variable("spontaneously_exploded_enemy");
	play_sound(snd_explosion, true);
	screen_flash();
	
	// Shots between the cardinal and diagonal directions
	var _projectiles = [];
	array_push(_projectiles, shoot_projectile(x-8, y-4, true));
	array_push(_projectiles, shoot_projectile(x-4, y-8, true));
	array_push(_projectiles, shoot_projectile(x+4, y-8, true));
	array_push(_projectiles, shoot_projectile(x+8, y-4, true));
	array_push(_projectiles, shoot_projectile(x-8, y+4, true));
	array_push(_projectiles, shoot_projectile(x-4, y+8, true));
	array_push(_projectiles, shoot_projectile(x+4, y+8, true));
	array_push(_projectiles, shoot_projectile(x+8, y+4, true));
		
	// Diagonal shots
	array_push(_projectiles, shoot_projectile(x-8, y-8, true));
	array_push(_projectiles, shoot_projectile(x+8, y-8, true));
	array_push(_projectiles, shoot_projectile(x-8, y+8, true));
	array_push(_projectiles, shoot_projectile(x+8, y+8, true));
	
	// Cardinal shots
	array_push(_projectiles, shoot_projectile(x+0, y-8, true));
	array_push(_projectiles, shoot_projectile(x+0, y+8, true));
	array_push(_projectiles, shoot_projectile(x-8, y+0, true));
	array_push(_projectiles, shoot_projectile(x+8, y+0, true));
	
	// The shots count as the player's if the player lit the explosive
	while (array_length(_projectiles) > 0) {
		var _proj = array_pop(_projectiles);
		_proj.shot_by_player = lit_by_player;
	}

	if (_destroy_self) { instance_destroy(); }
}

/// @function check_for_player_collision()
/// @description Resolves the calling enemy or deadly ground touching the player. It does nothing unless the instance is
///	activated, overlaps the player and the player is alive. A player carrying a sword kills an enemy that has a body.
///	Otherwise the player dies, credited to the enemy or deadly ground, unless a carried staff protects them from deadly
///	ground or a fire skeleton. Lava doesn't kill a player standing below it. It runs when the calling instance moves,
///	and when the player ends a step on top of it.
function check_for_player_collision() {
	var _player = global.player;
	if (activated && place_meeting(x, y, _player) && !_player.dead) {
		var _carried_sword = noone, _carried_staff = noone;
		with (_player) { _carried_sword = get_carried_item(obj_sword); _carried_staff =  get_carried_item(obj_staff); }
		// A player carrying a sword kills an enemy that has a body
		if (is_existing_instance(_carried_sword) && corporeal) { kill_with_sword(_carried_sword); }
		else if (object_index == obj_death || object_index == obj_lava_part) {
			// Lava doesn't kill a player standing below it
			if (object_index != obj_lava_part || _player.y <= y) {
				// A player carrying a staff is safe from deadly ground
				with (_player) { 
					if (!is_carrying_item(obj_staff)) { 
						play_sound(snd_extinguish, false);
						// Credit the ground's creator, or lava if it has none. A trap statue or fountain counts as a chest
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
			// An enemy kills the player, unless it's a fire skeleton and the player carries a staff
			if (object_index != obj_fire_skeleton || !is_existing_instance(_carried_staff)) {
				var _killer = object_index;
				// A skeleton still rising from bones counts as bones, and a fast-moving one as a fast skeleton
				if (_killer == obj_skeleton) {
					if (spawn_timer > 0) { _killer = obj_bones; }
					else if (skeleton_speed == FAST_SKELETON_MOVE_FREQUENCY) { _killer = obj_fast_skeleton; }
				}
				if (corporeal) { play_sound(snd_crunch, false); }
				// Hands holding a sword that isn't special leave it stuck in the ground where the player stood
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

/// @function set_automatic_target_path()
/// @description Plans a path from the calling instance to its target (target_x, target_y) over its path grid, and makes
///	it the instance's target path, starting at the first point. If the target can't be reached, it clears the target
///	path and the target instead (see end_target_path).
/// @returns {bool} Whether a path was set: false if the instance has no path grid or the target can't be reached
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

/// @function set_path_point_to_target_path_start()
/// @description Starts the calling instance at the first point of its target path, and counts the path's points so it
///	can tell when it has reached the end
function set_path_point_to_target_path_start() {
	// Reset variables used to track position along the target path
	total_path_points = path_get_number(target_path);
	current_path_point = 0;
}

/// @function initialize_target_path()
/// @description Prepares the calling instance's target path for walking: makes it straight instead of curved, and
///	rounds each of its points down to the 8-pixel grid
/// @returns {bool} False if the instance has no target path, otherwise true
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

/// @function end_target_path()
/// @description Stops the calling instance following its target path: it clears the path, the target position and its
///	progress along the path. The path itself isn't deleted.
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

/// @function								reset_nose();
function reset_nose() {
	image_index = 0;
	activated = false;
	spawn_timer = irandom_range(8, 64);
	teleport_to_lava();
}