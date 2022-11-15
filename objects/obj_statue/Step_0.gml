if (process_this_frame()) {
	event_inherited();
	
	// Determine initial direction if not set
	if (dir == noone) {
		if (!instance_place(x, y-16, obj_solid)) { dir = directions.up; } 
		else if (!instance_place(x+16, y, obj_solid)) { dir = directions.right; } 
		else if (!instance_place(x, y+16, obj_solid)) { dir = directions.down; } 
		else if (!instance_place(x-16, y, obj_solid)) { dir = directions.left; }
		else { covered = true; }
	}
	
	// Setup direction spot
	var x_pos = x, y_pos = y;
	switch (dir) {
		case directions.up: { y_pos -= 16; break; }
		case directions.right: { x_pos += 16; break; }
		case directions.down: { y_pos += 16; break; }
		case directions.left: { x_pos -= 16; break; }
	}
	
	// Determine whether statue is covered
	var prev_covered = covered;
	covered = instance_place(x_pos, y_pos, obj_solid);
	
	if (!covered) {
		image_angle = dir * -90;
		shoot_timer = (prev_covered) ? irandom_range(8, 24) : shoot_timer-1;
		if (shoot_timer <= 0) {
			shoot_timer = irandom_range(8, 24);
			shoot_fireball(x_pos, y_pos);
		}
	}
}
