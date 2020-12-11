if (global.controller.number_of_frames_since_game_began % 6 == 0) {
	event_inherited();

	if (!active) { active = !instance_place(x, y, global.player); }
}