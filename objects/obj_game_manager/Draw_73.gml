/// @description Test Mode - Draw Grids
if (global.is_test_mode && instance_exists(global.controller)) {
	var show_solid_path_grid = keyboard_check(ord("Q")), show_lava_path_grid = keyboard_check(ord("w"));
	if (show_solid_path_grid || show_lava_path_grid) {
		draw_set_alpha(0.1);
		draw_set_colour(c_white);
		if (show_solid_path_grid) { 
			mp_grid_draw(global.controller.current_room.solid_path_grid);
		}
		if (show_lava_path_grid) { 
			mp_grid_draw(global.controller.current_room.lava_path_grid);
		}
		
		for (var i = 0; i < room_width; i += GRID_SIZE;) {
			draw_line_width(i, 0, i, room_height, 1);
		}
		for (var j = 0; j < room_width; j += GRID_SIZE;) {
			draw_line_width(0, j, room_width, j, 1);
		}
		draw_set_alpha(1);
		with (obj_enemy) {
			if (target_path_grid != -1 && path_exists(target_path)) { draw_path(target_path, x, y, true); }
		}
	}
	
	draw_set_alpha(1);
	with (obj_enemy) {
		if (target_path_grid != -1 && path_exists(target_path)) { draw_path(target_path, x, y, true); }
	}
	draw_set_colour(c_white);
}