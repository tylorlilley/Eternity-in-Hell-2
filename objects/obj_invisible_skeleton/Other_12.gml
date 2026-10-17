/// @description End Step
event_inherited();

// Unlike other enemies, it shows at the lowest brightness in the dark and fades out to the background as light reaches it.
// It shows under normal lighting while it flashes the screen, and on a rare flash of its own
if (can_process_this_frame()) {
	var _shows_normally = (global.controller.flash_obj == id || get_random_chance_out_of(INVISIBLE_SKELETON_FLASH_FREQUENCY));
	image_alpha = (has_red_sprite && !_shows_normally) ? INVERTED_COLORS_ALPHA : 1;
	if (!_shows_normally) {
		var _dark_color = merge_color(global.bg_color, global.gms_game_color, global.game_color_fade / 100);	// The game color at its lowest brightness, like a red pixel in the dark
		image_blend = merge_color(_dark_color, global.bg_color, min(1, get_greatest_lighting() / INVISIBLE_SKELETON_VANISHING_LIGHT));
	}
}
