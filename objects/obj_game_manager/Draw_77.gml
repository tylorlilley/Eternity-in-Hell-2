// Skip drawing while the game is in exclusive fullscreen without focus
if (!window_get_fullscreen() || window_get_borderless_fullscreen() || window_has_focus()) {
	var _window_scaling = (global.fullscreen) ? global.fullscreen_window_scaling : global.window_scaling;
	var _surface_width = (room_width * _window_scaling);
	var _surface_height = (room_width * _window_scaling);
	var _window_width = window_get_width();
	var _window_height = window_get_height();

	var _surface_x = ((_window_width/2)-(_surface_width/2));
	var _surface_y = ((_window_height/2)-(_surface_height/2))

	draw_surface_ext(application_surface, _surface_x, _surface_y, _window_scaling, _window_scaling, 0, c_white, 1);
}
