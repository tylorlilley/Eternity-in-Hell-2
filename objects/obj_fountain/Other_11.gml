/// @description Step
if (shoot_timer == -1 && !is_existing_instance(projectile)) {
	shoot_timer = irandom_range(12, 20);
}
else if (shoot_timer == 0 && !is_existing_instance(projectile)) {
	shoot_timer = -1;
	var target = get_dropped_meat();
	if (!is_existing_instance(target)) { target = global.player; }
	projectile = shoot_magic_beam(target, 45);
}
else if (shoot_timer > 0) { shoot_timer -= 1; }
if (is_blink_frame()) { image_angle += 90; }
if (image_angle >= 360) { image_angle = 0; }
	
event_inherited();
