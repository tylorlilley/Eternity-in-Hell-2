/// @description Step
event_inherited();

// flicker sprite
if (shoot_timer <= 8) { image_index = 1; skeleton_speed = 0; }
else { image_index = 0; }

// Shoot beam
if shoot_timer > 0 { shoot_timer -= 1; }
else {
	var target = get_dropped_meat();
	if (!is_existing_instance(target)) { target = global.player; }
	shoot_magic_beam(target, 22);
	shoot_timer = irandom_range(16, 64);
	skeleton_speed = SKELETON_MOVE_FREQUENCY*4;
}

