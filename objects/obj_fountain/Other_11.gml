/// @description Step
shoot_timer -= 1;
if (shoot_timer <= 0) {
	shoot_timer = irandom_range(8, 24);
	shoot_magic_beam(90);
}
	
event_inherited();
