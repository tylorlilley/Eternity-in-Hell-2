// Drw extra tile when changing direction
if ((tail) && (tail.dir != prev_dir)) {
	if (prev_dir == directions.down && tail.dir == directions.left) {
		draw_sprite_ext(spr_giant_wurm, 2, x, y-8, 1, -1, 0, image_blend, image_alpha);
	}
	else if (prev_dir == directions.down && tail.dir == directions.right) {
		draw_sprite_ext(spr_giant_wurm, 2, x, y-8, -1, -1, 0, image_blend, image_alpha);
	}
	else if (prev_dir == directions.up && tail.dir == directions.left) {
		draw_sprite_ext(spr_giant_wurm, 2, x, y+8, 1, 1, 0, image_blend, image_alpha);
	}
	else if (prev_dir == directions.up && tail.dir == directions.right) {
		draw_sprite_ext(spr_giant_wurm, 2, x, y+8, -1, 1, 0, image_blend, image_alpha);
	}
	else if (prev_dir == directions.left && tail.dir == directions.up) {
		draw_sprite_ext(spr_giant_wurm, 2, x+8, y, -1, -1, 0, image_blend, image_alpha);
	}
	else if (prev_dir == directions.left && tail.dir == directions.down) {
		draw_sprite_ext(spr_giant_wurm, 2, x+8, y, -1, 1, 0, image_blend, image_alpha);
	}
	else if (prev_dir == directions.right && tail.dir == directions.up) {
		draw_sprite_ext(spr_giant_wurm, 2, x-8, y, 1, -1, 0, image_blend, image_alpha);
	}
	else if (prev_dir == directions.right && tail.dir == directions.down) {
		draw_sprite_ext(spr_giant_wurm, 2, x-8, y, 1, 1, 0, image_blend, image_alpha);
	}
}

/*
if (tail) {
	if (instance_place(x, y-16, tail) && instance_place(x+16, y, tail)) {
			bend_angle = 0;
	}
	else if (instance_place(x, y+16, tail) || instance_place(x+16, y, tail)) {
			bend_angle = 270;
	}
	else if (instance_place(x, y+16, tail) || instance_place(x-16, y, tail)) {
			bend_angle = 180;
	}
	else if (instance_place(x, y-16, tail) || instance_place(x-16, y, tail)) {
			draw_sprite_ext(spr_giant_wurm, 2, x-8, y, 1, 1, bend_angle, c_white, 0)
	}
}
*/

event_inherited();
//if (dir != noone && dir != -1) { draw_sprite_ext(spr_arrow,0,x,y,1,1,(dir*-90),c_white,1); }
//draw_set_color(c_red); draw_text(x, y, string(dir));