/// @function								kill_enemy(death_sound);
///	@param		{index}	death_sound			The sound to play upon killing this enemy
function kill_enemy(death_sound) {
	if (death_sound != noone) { play_sound(death_sound, true); }
	if (corporeal) {
		var corpse = (object_index == obj_skeleton) ? obj_bones : obj_blood;
		instance_create_depth(x, y, 4, corpse);
	}
	if (object_index == obj_hands) {
		with (right_hand_item) {
			if (object_index == obj_rosary) {
				var new_hands = instance_create_depth(other.xstart, other.ystart, 0, obj_hands);
				new_hands.death_timer = global.controller.RESPAWN_FREQUENCY;
				if (!special) { instance_destroy(); }
				else { new_hands.target_item = id; }
			}
		}
	}
	instance_destroy();
}

/// @function								kill_with_sword();
///	@param		{instance}	sword			The sword being used to kill this enemy
function kill_with_sword(sword) {
	if (!sword.special) { 
		var sword_in_ground = instance_create_depth(x, y, 0, obj_sword_in_ground);
		sword_in_ground.image_xscale = sword.image_xscale;
		instance_destroy(sword); 
	}
	kill_enemy(snd_crunch);
}

/// @function								run_away_from_player(ignore_solid, ignore_death);
/// @param		{boolean} ignore_solid		Whether to ignore solid objects or not when performing this check
/// @param		{boolean} ignore_death		Whether to ignore objects that cause death or not when performing this check
function run_away_from_player(ignore_solid, ignore_death) {
	var dir = irandom(3);
	if (is_direction_toward(dir, global.player)) { dir = get_opposite_dir(dir); }
	if (get_random_chance_out_of(3)) { dir = 4; }
	if (can_move_in_direction(dir, ignore_solid, ignore_death)) { move_in_direction(dir, true); }
}

/// @function								teleport_to_empty_space()
function teleport_to_empty_space() {
	do {
		x = irandom(room_width/8)*8;
		y = irandom(room_height/8)*8;
	}
	until (!is_solid_at_position(x, y) && 
			!is_lava_at_position(x, y) && 
			!place_meeting(x, y, obj_stairs_spot) && 
			!place_meeting(x, y, obj_player) &&
			!is_outside_room(x, y) &&
			get_distance_to_instance(global.player) >= global.controller.TRAP_RANGE);
}

/// @function								teleport_to_lava()
function teleport_to_lava() {
	var total_lava = instance_number(obj_lava)-1, count = 0, current_pos = irandom(total_lava);
	while (count < total_lava) {
		var lava = instance_find(obj_lava, current_pos);

		// Test this lava and all offsets by 8
		var start_dir = irandom(4);
		for (var i = 0; i <= 4; i++) {
			// Set up lava for this run
			x = lava.x;
			y = lava.y;
			
			switch ((i+start_dir) % 5) {
				case directions.up: { y -= 8; break; }
				case directions.right: { x += 8; break; }
				case directions.down: { y += 8; break; }
				case directions.left: { x -= 8; break; }
			}
			
			// return early if this is a good teleported position
			if (is_covered_at_each_quadrant_by(obj_lava) &&
				!is_outside_room(x, y) &&
				!is_covered_at_each_quadrant_by(obj_solid) &&
				!place_meeting(x, y, global.player)) {
				  return lava;
			  }
		}
		
		// Setup next iteration
		count += 1;
		current_pos = (current_pos + 1 > total_lava) ? 0 : current_pos + 1;
	}
	
	// No suitable teleport spot; Should never need to reach this clause
	show_debug_message("WARNING: teleport to lava failed.");
	instance_destroy(id, false);
	return noone;
}

/// @function								shoot_fireball()
///	@param		{int}	target_x			The x position of the target to move towards;
///	@param		{int}	target_y			The y position of the target to move towards;
function shoot_fireball(target_x, target_y) {
	play_sound(snd_shoot, false);
	with (instance_create_depth(x, y, 10, obj_fireball)) {
		creator = other.id;
		move_towards_point(target_x, target_y, 2); 
	}	
}

/// @function								try_to_see_player();
function try_to_see_player() {
	
	var target = noone, dropped_meat = get_dropped_meat();
	if (!global.player.dead) { target = global.player; }
	
	if (state != SCREECHING) {
		var new_dir = noone, offset = (state == ATTACKING) ? 8 : 0
		
		if (dropped_meat != noone) {
			new_dir = get_random_possible_direction(dropped_meat.x, dropped_meat.y, false, true);
			if (new_dir != noone) { target = dropped_meat; }
		}
			
		if (target == global.player) {   
			if (target.x - offset <= x && target.x + offset >= x) {
			    if (target.y > y) { new_dir = directions.down; }
			    else if (target.y < y) { new_dir = directions.up; }
			}
			else if (target.y - offset <= y && target.y + offset >= y) {
			    if (target.x > x) { new_dir = directions.right; }
			    else if (target.x < x) { new_dir = directions.left; }
			}
		}
			
		if (new_dir != noone && new_dir != dir && (target != global.player || can_move_in_direction_and_reach(new_dir, target, false, true))) {
			dir = new_dir;
			state = SCREECHING;
			screech_timer = 3;
			if (target == global.player) { play_sound(snd_lose, true); }
		}
	}
}

/// @function								move_snake(iterations);
///	@param		{int}	iterations			The number of times to move in one frame
function move_snake(iterations){
	var prev_dir = (dir == -1) ? irandom(3) : dir;
	for (var i = 0; i < iterations; i +=1) {
		if (dir != -1 && can_move_in_direction(dir, false, true)) { move_in_direction(dir, true); }
		else { dir = -1; break; }
	}

	if (dir == -1) {
		var new_directions = array_create(0);
		array_push(new_directions, get_opposite_dir(prev_dir), get_turn_right_dir(prev_dir), get_turn_left_dir(prev_dir));
		while (array_length(new_directions) > 0) {
			var new_dir = array_random_pop(new_directions);
			if (can_move_in_direction(new_dir, false, true)) { dir = new_dir; break; }
		}
		if (dir == -1) { image_speed = 0; }
	}
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
		if (tail.x != x && tail.y != y && (dir >= 0 && dir <= 3)) { image_angle = (dir*-90); }
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
			//image_angle = irandom(3)*90;
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
	for (var i = 0; i < 4; i++) {
		var x_offset = 0, y_offset = 0;
		
		switch(i)
		{
			case directions.up: { y_offset = -16; break; }
			case directions.right: { x_offset = 16; break; }
			case directions.down: { y_offset = 16; break; }
			case directions.left: { x_offset = -16; break; }
		}
	
		var potential_tail = instance_place(x+x_offset, y+y_offset, obj_giant_worm_body)
		if (potential_tail && potential_tail != head) { 
			tail = potential_tail;
			tail.head = id; 
			tail.dir = get_opposite_dir(i);
			tail.prev_dir = get_opposite_dir(i);
			tail.depth = depth + 1;
			if (!head) { dir = get_opposite_dir(i); prev_dir = get_opposite_dir(i); }
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
///	@param		{Sound}	  destroy_self		Whether to destroy the calling instance or not
function explode(destroy_self) {
	play_sound(snd_explosion, true);
	shoot_fireball(x-8, y-8);
	shoot_fireball(x+0, y-8);
	shoot_fireball(x+8, y-8);
	shoot_fireball(x-8, y-4);
	shoot_fireball(x+0, y-4);
	shoot_fireball(x+8, y-4);
	shoot_fireball(x-8, y);
	shoot_fireball(x+0, y);
	shoot_fireball(x+8, y);
	shoot_fireball(x-8, y+4);
	shoot_fireball(x+0, y+4);
	shoot_fireball(x+8, y+4);
	shoot_fireball(x-8, y+8);
	shoot_fireball(x+0, y+8);
	shoot_fireball(x+8, y+8);
	if (destroy_self) { instance_destroy(); }
}

/// @function								check_for_player_collision();
function check_for_player_collision() {
	if (activated && place_meeting(x, y, global.player) && !global.player.dead) {
		var carried_sword = noone;
		with (global.player) { carried_sword = get_carried_item(obj_sword); }
		if (carried_sword != noone && corporeal) { kill_with_sword(carried_sword); }
		else if (object_index == obj_death) { 
			with (global.player) { 
				if (!is_carrying_item(obj_staff)) { 
					kill_player(obj_lava);;
				} 
			} 
		}
		else { kill_player(object_index); }
	}
}