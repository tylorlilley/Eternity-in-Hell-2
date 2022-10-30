if (process_this_frame()) {
	event_inherited(); 
	
	var x_pos = x, y_pos = y, prev_covered = covered;
	if (!instance_place(x, y-16, obj_solid)) { y_pos -= 16; image_angle = 0; covered = false; } 
	else if (!instance_place(x+16, y, obj_solid)) { x_pos += 16; image_angle = 270; covered = false; } 
	else if (!instance_place(x, y+16, obj_solid)) { y_pos += 16; image_angle = 180; covered = false; } 
	else if (!instance_place(x-16, y, obj_solid)) { x_pos -= 16; image_angle = 90; covered = false; }
	else { covered = true; }
	
	// Set shoot timer when uncovered
	if (!covered) {
		shoot_timer = (prev_covered) ? irandom_range(8, 32) : shoot_timer-1;
		if (shoot_timer <= 0) {
			shoot_timer = irandom_range(8, 32);
			shoot_fireball(x_pos, y_pos);
		}
	}
}
