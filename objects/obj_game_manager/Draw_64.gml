// On Windows, draw the GameFrame custom window frame (its title bar and buttons) over the game
if (os_type == os_windows) {
	draw_set_color(c_white);
	gameframe_draw();
}