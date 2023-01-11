// Drw extra tile when changing direction for tail
if (head && head.dir == head.prev_dir && head.x != x && head.y != y) {
	/*
	var x_offset = 0, y_offset = 0;
	switch (dir) {
		case directions.up: { y_offset = 8; break; }
		case directions.right: { x_offset = -8; break; }
		case directions.down: { y_offset = -8; break; }
		case directions.left: { x_offset = 8; break; }
	}
	*/
	
	if (head.dir == directions.right && dir == directions.up) {
		draw_sprite_ext(sprite_index, 2, x, y-8, 1, -1, 0, image_blend, image_alpha);
	}
	else if (head.dir == directions.left && dir == directions.up) {
		draw_sprite_ext(sprite_index, 2, x, y-8, -1, -1, 0, image_blend, image_alpha);
	}
	else if (head.dir == directions.right && dir == directions.down) {
		draw_sprite_ext(sprite_index, 2, x, y+8, 1, 1, 0, image_blend, image_alpha);
	}
	else if (head.dir == directions.left && dir == directions.down) {
		draw_sprite_ext(sprite_index, 2, x, y+8, -1, 1, 0, image_blend, image_alpha);
	}
	else if (head.dir == directions.down && dir == directions.right) {
		draw_sprite_ext(sprite_index, 2, x+8, y, -1, -1, 0, image_blend, image_alpha);
	}
	else if (head.dir == directions.up && dir == directions.right) {
		draw_sprite_ext(sprite_index, 2, x+8, y, -1, 1, 0, image_blend, image_alpha);
	}
	else if (head.dir == directions.down && dir == directions.left) {
		draw_sprite_ext(sprite_index, 2, x-8, y, 1, -1, 0, image_blend, image_alpha);
	}
	else if (head.dir == directions.up && dir == directions.left) {
		draw_sprite_ext(sprite_index, 2, x-8, y, 1, 1, 0, image_blend, image_alpha);
	}
	//draw_sprite_ext(sprite_index, image_index, x+x_offset, y+y_offset, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}

event_inherited();