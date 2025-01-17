/// @description Step
event_inherited();

// flicker sprite
if (shoot_timer <= 8) { image_index = 1; skeleton_speed = 0; }
else { image_index = 0; }

// Shoot fireball
if shoot_timer > 0 { shoot_timer -= 1; }
else {
	var player = global.player;
	var dir = point_direction(x, y, player.x, player.y) - 45 + irandom_range(0,90);
	var target_x = x + lengthdir_x(16, dir), target_y = y + lengthdir_y(16, dir);
	shoot_projectile(target_x, target_y, false, obj_magic_beam);
	shoot_timer = irandom_range(16, 64);
	skeleton_speed = SKELETON_MOVE_FREQUENCY*4;
}

