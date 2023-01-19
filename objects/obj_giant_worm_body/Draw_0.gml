event_inherited();

// Draw extra tile when changing direction for tail
if (head && head.x != x && head.y != y) {
	var x_pos = x, y_pos = y, x_scale = 1, y_scale = 1;
	if (x > head.x && y > head.y) {
		if (dir == directions.up) { y_pos -= 8; x_scale = -1; y_scale = -1; }
		else if (dir == directions.left) { x_pos -= 8; x_scale = 1; y_scale = 1; }
	}
	else if (x < head.x && y > head.y) {
		if (dir == directions.up) { y_pos -= 8; x_scale = 1; y_scale = -1; }
		else if (dir == directions.right) { x_pos += 8; x_scale = -1; y_scale = 1; }
	}
	else if (x > head.x && y < head.y) {
		if (dir == directions.down) { y_pos += 8; x_scale = -1; y_scale = 1; }
		else if (dir == directions.left) { x_pos -= 8; x_scale = 1; y_scale = -1; }
	}
	else if (x < head.x && y < head.y) {
		if (dir == directions.down) { y_pos += 8;  x_scale = 1; y_scale = 1; }
		else if (dir == directions.right) { x_pos += 8;  x_scale = -1; y_scale = -1; }
	}
	
	draw_sprite_ext(sprite_index, 2, x_pos, y_pos, x_scale, y_scale, 0, head.image_blend, image_alpha);
}