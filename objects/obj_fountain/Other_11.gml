/// @description Step
shoot_timer -= 1;
if (shoot_timer <= 0) {
	shoot_timer = irandom_range(24, 40);
	shoot_magic_beam(global.player, 45);
}
if (is_blink_frame()) { image_angle += 90; }
if (image_angle >= 360) { image_angle = 0; }
	
event_inherited();
