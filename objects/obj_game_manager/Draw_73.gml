shader_reset();

if (global.is_test_mode && instance_exists(global.controller)) {
	var show_solid_grid = keyboard_check(vk_f1), show_lava_grid = keyboard_check(vk_f2);
	if (show_solid_grid || show_lava_grid) {
		draw_set_alpha(0.1);
		draw_set_colour(c_white);
		if (show_solid_grid) { mp_grid_draw(global.controller.current_room.solid_grid); }
		if (show_lava_grid) { mp_grid_draw(global.controller.current_room.lava_grid); }
		
		for (var i = 0; i < room_width; i += GRID_SIZE;) {
			draw_line_width(i, 0, i, room_height, 1);
		}
		for (var j = 0; j < room_width; j += GRID_SIZE;) {
			draw_line_width(0, j, room_width, j, 1);
		}
		draw_set_alpha(1);
		//draw_path(global.ai_path, x, y, true);
	}
}