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
		if (dir != -1) { audio_play_sound( sound_to_play, 10, false ); image_speed = original_image_speed; }
		else { image_speed = 0; }
	}
}
function set_segment_images() {
	set_segment_image();
	with tail { set_segment_images(); }
}

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

function move_segments(new_dir) {
	move_in_direction(dir, false);
	with tail { move_segments(other.dir); }
	dir = old_dir;
	old_dir = new_dir;
	//set_segment_image();
}
