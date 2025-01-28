/// @description Step
shoot_timer -= 1;
if (shoot_timer <= 0) {
	shoot_timer = irandom_range(16, 32);
	shoot_magic_beam(global.player, 45);
}
	
event_inherited();
