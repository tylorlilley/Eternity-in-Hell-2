/// @description Step
if (shoot_timer == -1 && !is_existing_instance(projectile)) {
	shoot_timer = irandom_range(8, 18);
}
else if (shoot_timer == 0 && !is_existing_instance(projectile)) {
	shoot_timer = -1;
	var _target = get_dropped_meat();
	if (!is_existing_instance(_target)) { _target = global.player; }
	projectile = shoot_magic_beam(_target, 45);
}
else if (shoot_timer > 0) { shoot_timer -= 1; }
// Turn a quarter every other processing frame, so it keeps spinning at a steady pace
if (global.game_manager.number_of_frames_since_game_began % (FRAMES_TO_WAIT_BEFORE_PROCESSING * 2) == 0) { image_angle = (image_angle + 90) % 360; }
	
event_inherited();
