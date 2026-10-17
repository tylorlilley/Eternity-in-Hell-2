/// @description End Step
event_inherited();

// Unlike other enemies, it shows at the lowest brightness in the dark, red and white pixels alike, and fades out to the
// background as light reaches it. It flashes into view under normal lighting at random, and right after it kills the player
if (can_process_this_frame()) {
	var _player = global.player, _just_killed_player = (_player.dead && !player_was_dead && place_meeting(x, y, _player));
	player_was_dead = _player.dead;

	if (_just_killed_player || get_random_chance_out_of(INVISIBLE_SKELETON_FLASH_FREQUENCY)) { image_alpha = 1; }
	else {
		var _visibility = 1 - min(1, get_greatest_lighting() / INVISIBLE_SKELETON_VANISHING_LIGHT);
		image_alpha = FADING_COLORS_ALPHA;
		image_blend = merge_color(global.bg_color, c_white, _visibility * global.game_color_fade / 100);
	}
}
