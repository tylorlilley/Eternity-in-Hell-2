if (process_this_frame()) {
	event_inherited(); 
	
	var x_pos = x, y_pos = y;
	if (!instance_place(x, y-16, obj_solid)) { y_pos -= 16; image_angle = 0; } 
	else if (!instance_place(x+16, y, obj_solid)) { x_pos += 16; image_angle = 90; } 
	else if (!instance_place(x, y+16, obj_solid)) { y_pos += 16; image_angle = 180; } 
	else if (!instance_place(x-16, y, obj_solid)) { x_pos -= 16; image_angle = 270; }
	
	if (shoot_timer > 0) { shoot_timer -= 1; }
	else {
		shoot_timer = irandom_range(16, 32);
		if (x_pos != x || y_pos != y) { shoot_fireball(x_pos, y_pos); }
	}
}
