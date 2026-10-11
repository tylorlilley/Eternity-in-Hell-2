/// @description Step

if (object_index == obj_statue) {
	// Determine initial direction if not set
	if (dir == directions.none) {
		if (!place_meeting(x, y-8, obj_solid)) { dir = directions.up; } 
		else if (!place_meeting(x+8, y, obj_solid)) { dir = directions.right; } 
		else if (!place_meeting(x, y+8, obj_solid)) { dir = directions.down; } 
		else if (!place_meeting(x-8, y, obj_solid)) { dir = directions.left; }
		else { covered = true; }
	}
	
	// Setup direction spot
	var _x_pos = x, _y_pos = y;
	switch (dir) {
		case directions.up: { _y_pos -= 8; break; }
		case directions.right: { _x_pos += 8; break; }
		case directions.down: { _y_pos += 8; break; }
		case directions.left: { _x_pos -= 8; break; }
	}
	
	// Determine whether statue is covered
	var _prev_covered = covered;
	covered = place_meeting(_x_pos, _y_pos, obj_solid);
	
	if (!covered) {
		image_index = 0
		image_angle = dir * -90;
		shoot_timer = (_prev_covered) ? irandom_range(8, 24) : shoot_timer-1;
		if (shoot_timer <= 0) {
			shoot_timer = irandom_range(8, 24);
			shoot_projectile(_x_pos, _y_pos, false);
		}
	}
	else if (!_prev_covered) {
		image_index = 1;
		play_sound(snd_give_up, false);
	}
}
	
event_inherited();
