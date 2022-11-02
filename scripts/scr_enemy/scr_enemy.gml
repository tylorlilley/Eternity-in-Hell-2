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
			distance_to_instance(global.player) >= MOUTH_DISTANCE);
}

/// @function								teleport_to_lava()
function teleport_to_lava() {
	var lava_at_quadrant = [];
	do {
		x = irandom(room_width/8)*8;
		y = irandom(room_height/8)*8;
		var lava_at_quadrant = get_presence_at_each_quadrant(obj_lava);
	}
	until (lava_at_quadrant[0] && lava_at_quadrant[1] && lava_at_quadrant[2] && lava_at_quadrant[3]);
}

/// @function								shoot_fireball()
///	@param		{int}	target_x		The x position of the target to move towards;
///	@param		{int}	target_y		The y position of the target to move towards;
function shoot_fireball(target_x, target_y) {
	play_sound(snd_shoot, false);
	with (instance_create_depth(x, y, 10, obj_fireball)) { move_towards_point(target_x, target_y, 2); }	
}

/// @function								try_to_see_player();
function try_to_see_player() {
	if (state != SCREECHING && !global.player.dead && !global.player.hidden) {   
		var new_dir = noone;
		if (global.player.x == x) {
		    if (global.player.y > y) { new_dir = directions.down; }
		    else { new_dir = directions.up; }
		}
		else if (global.player.y == y) {
		    if (global.player.x > x) { new_dir = directions.right; }
		    else { new_dir = directions.left; }
		}
			
		if (new_dir != noone && new_dir != dir && can_move_in_direction_and_reach(new_dir, global.player, false, true)) {
			dir = new_dir;
			state = SCREECHING;
			screech_timer = 3;
			play_sound(snd_lose, true);
		}
	}
}

/// @function								move_snake();
function move_snake(sound_to_play, iterations){
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
		if (dir != -1) { play_sound(sound_to_play, true); image_speed = original_image_speed; }
		else { image_speed = 0; }
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
			tail.old_dir = opposite_dir(i);
			tail.depth = depth + 1;
			if (!head) { dir = opposite_dir(i); old_dir = opposite_dir(i); }
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
	dir = old_dir;
	old_dir = new_dir;
	//set_segment_image();
}

/// @function								play_sound();
///	@param		{Sound}	  snd					The sound to play
///	@param		{Boolean} loud_soun				Whether the sound is heard by ears or not
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

