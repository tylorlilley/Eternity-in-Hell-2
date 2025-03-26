/// @description Step
event_inherited();

// flicker sprite
if (shoot_timer <= 12) { image_index = 2; skeleton_speed = 0; }

// Shoot beam
if (shoot_timer == 6) {
	var target = get_dropped_meat();
	if (!is_existing_instance(target)) { target = global.player; }
	shoot_magic_beam(target, 0, 3);
}

if shoot_timer > 0 {
	if (!place_meeting(x, y, obj_solid)) { shoot_timer -= 1; }
}
else {
	shoot_timer = irandom_range(32, 64);
	skeleton_speed = SKELETON_MOVE_FREQUENCY*4;
	image_index = 0;
	play_sound(snd_magicteleport, true);
	teleport_to_empty_space();
}

