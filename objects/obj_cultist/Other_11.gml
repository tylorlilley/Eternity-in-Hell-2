/// @description Step
event_inherited();

// Stand still in its casting frame for the last 12 steps before it teleports, shooting halfway through
if (shoot_timer <= 12) { image_index = 2; skeleton_speed = 0; }

// Shoot a magic beam at dropped meat, or else at the player
if (shoot_timer == 6) {
	var _target = get_dropped_meat();
	if (!is_existing_instance(_target)) { _target = global.player; }
	shoot_magic_beam(_target, 0, 3);
}

// Count down while it isn't inside a solid, then teleport to an empty space and start again
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

