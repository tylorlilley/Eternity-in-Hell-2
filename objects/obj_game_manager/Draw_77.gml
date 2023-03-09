if (!gameframe_get_fullscreen() || window_has_focus()) {
	var window_scaling = (global.fullscreen) ? global.fullscreen_window_scaling : global.window_scaling;
	var surface_width = (room_width * window_scaling);
	var surface_height = (room_width * window_scaling);
	var window_width = window_get_width();
	var window_height = window_get_height();

	var surface_x = ((window_width/2)-(surface_width/2));
	var surface_y = ((window_height/2)-(surface_height/2))
	var gameframe_height = (global.fullscreen) ? 0: gameframe_caption_height_normal;

	draw_surface_ext(application_surface, surface_x, surface_y+gameframe_height/2, window_scaling, window_scaling, 0, c_white, 1);
}
