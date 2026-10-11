/// @description Step
// A fountain has one magic beam out at a time. Once its beam is gone (shoot_timer is -1 while it's out), it waits a
// random time, and then shoots a new beam at the latest dropped meat or the player, off by up to 45 degrees
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
// On blink frames it turns a quarter turn each step
if (is_blink_frame()) { image_angle += 90; }
if (image_angle >= 360) { image_angle = 0; }
	
event_inherited();
