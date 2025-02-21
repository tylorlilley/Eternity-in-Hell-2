/// @description Step
shoot_timer -= 1;
if (shoot_timer <= 0) {
	shoot_timer = irandom_range(24, 40);
	var target = get_dropped_meat();
	if (!is_existing_instance(target)) { target = global.player; }
	shoot_magic_beam(target, 45);
}
if (is_blink_frame()) { image_angle += 90; }
if (image_angle >= 360) { image_angle = 0; }
	
event_inherited();
