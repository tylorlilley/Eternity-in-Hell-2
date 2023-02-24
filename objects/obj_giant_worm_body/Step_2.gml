event_inherited();

// Setup corner drawing
if (is_existing_instance(head) && head.x != x && head.y != y) {
	corner_x = x;
	corner_y = y;
	corner_x_scale = 1; 
	corner_y_scale = 1;
	if (x > head.x && y > head.y) {
		if (dir == directions.up) { corner_y -= 8; corner_x_scale = -1; corner_y_scale = -1; }
		else if (dir == directions.left) { corner_x -= 8; corner_x_scale = 1; corner_y_scale = 1; }
	}
	else if (x < head.x && y > head.y) {
		if (dir == directions.up) { corner_y -= 8; corner_x_scale = 1; corner_y_scale = -1; }
		else if (dir == directions.right) { corner_x += 8; corner_x_scale = -1; corner_y_scale = 1; }
	}
	else if (x > head.x && y < head.y) {
		if (dir == directions.down) { corner_y += 8; corner_x_scale = -1; corner_y_scale = 1; }
		else if (dir == directions.left) { corner_x -= 8; corner_x_scale = 1; corner_y_scale = -1; }
	}
	else if (x < head.x && y < head.y) {
		if (dir == directions.down) { corner_y += 8;  corner_x_scale = 1; corner_y_scale = 1; }
		else if (dir == directions.right) { corner_x += 8;  corner_x_scale = -1; corner_y_scale = -1; }
	}
	
	var x_prev = x, y_prev = y;
	x = corner_x;
	y = corner_y;
	corner_blend = get_image_blend();
	x = x_prev;
	y = y_prev;
}

image_blend = get_image_blend();
