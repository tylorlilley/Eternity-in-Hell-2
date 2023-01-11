/// @function								kill_enemy();
function kill_enemy() {
	play_sound(death_sound, true);
	instance_destroy();
}

/// @function								run_away_from_player();
function run_away_from_player() {
	var dir = irandom(3);
	if (is_direction_toward_player(dir)) { dir = opposite_dir(dir); }
	if (get_random_chance_out_of(3)) { dir = 4; }
	if (can_move_in_direction(dir, false, false)) { move_in_direction(dir, true); }
}

/// @function								teleport_to_empty_space()
function teleport_to_empty_space() {
	do {
		x = irandom(room_width/8)*8;
		y = irandom(room_height/8)*8;
	}
	until (!instance_place(x, y, obj_solid) && 
			!instance_place(x, y, obj_death) && 
			!instance_place(x, y, obj_stairs_spot) && 
			!instance_place(x, y, obj_player) &&
			!position_is_outside_room(x, y) &&
			distance_to_instance(global.player) >= MOUTH_DISTANCE);
}

/// @function								teleport_to_lava()
function teleport_to_lava() {
	var count = 0;
	do {
		//count += 1;
		var lava = get_random_instance(obj_lava);
		x = lava.x;
		y = lava.y;
		if (instance_place(x-8, y, obj_lava) && get_random_chance_out_of(2)) { x -= 8; }
		else if (instance_place(x+8, y, obj_lava) && get_random_chance_out_of(2)) { x += 8; }
		if (instance_place(x, y-8, obj_lava) && get_random_chance_out_of(2)) { y -= 8; }
		else if (instance_place(x, y+8, obj_lava) && get_random_chance_out_of(2)) { y += 8; }
		var lava_at_quadrant = lava_at_position();
		var solid_at_quadrant = get_presence_at_each_quadrant(obj_solid);
		var player_at_quadrant = get_presence_at_each_quadrant(global.player);
	}
	until (count >= 128 || (
		!position_is_outside_room(x, y) && lava_at_all_quadrants() &&
		solid_at_quadrant[0] == noone && solid_at_quadrant[1] == noone && solid_at_quadrant[2] == noone && solid_at_quadrant[3] == noone &&
		player_at_quadrant[0] == noone && player_at_quadrant[1] == noone && player_at_quadrant[2] == noone && player_at_quadrant[3] == noone
	));
	if (count >= 255) { instance_destroy(self, false); }
}

/// @function								shoot_fireball()
///	@param		{int}	target_x			The x position of the target to move towards;
///	@param		{int}	target_y			The y position of the target to move towards;
function shoot_fireball(target_x, target_y) {
	play_sound(snd_shoot, false);
	with (instance_create_depth(x, y, 10, obj_fireball)) { move_towards_point(target_x, target_y, 2); }	
}

/// @function								try_to_see_player();
function try_to_see_player() {
	
	var target = noone, dropped_meat = noone;
	if (!global.player.dead) { target = global.player; }
	with (obj_meat) { if (carried == noone) { dropped_meat = self; } }
	
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
	//if (!can_move_in_direction(dir, false, true)) { dir = -1; }
	if (dir == -1) {
		var new_directions = array_create(0);
		array_push(new_directions, opposite_dir(prev_dir), dir_turn_right(prev_dir), dir_turn_left(prev_dir));
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
			if ((instance_place(x, y-16, tail) && instance_place(x+16, y, head)) ||
				(instance_place(x, y-16, head) && instance_place(x+16, y, tail))) {
					image_angle = 0;
			}
			else if ((instance_place(x, y+16, tail) && instance_place(x+16, y, head)) ||
					 (instance_place(x, y+16, head) && instance_place(x+16, y, tail))) {
					image_angle = 270;
			}
			else if ((instance_place(x, y+16, tail) && instance_place(x-16, y, head)) ||
					 (instance_place(x, y+16, head) && instance_place(x-16, y, tail))) {
					image_angle = 180;
			}
			else if ((instance_place(x, y-16, tail) && instance_place(x-16, y, head)) ||
					 (instance_place(x, y-16, head) && instance_place(x-16, y, tail))) {
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
			tail.dir = opposite_dir(i);
			tail.prev_dir = opposite_dir(i);
			tail.depth = depth + 1;
			if (!head) { dir = opposite_dir(i); prev_dir = opposite_dir(i); }
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

/// @function								play_sound();
///	@param		{Sound}	  snd				The sound to play
///	@param		{Boolean} loud_soun			Whether the sound is heard by ears or not
function play_sound(snd, loud_sound) {
	audio_play_sound(snd, 10, false);
	if (loud_sound) {
		with (obj_ears) {
			if id != other.id {
				target_x = other.x;
				target_y = other.y;
				awake = true;
				hiss_timer = 2;
			}
		}
	}
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
