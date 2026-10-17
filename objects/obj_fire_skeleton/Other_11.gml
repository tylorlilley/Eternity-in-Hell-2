/// @description Step
event_inherited();

// Update Torch Sprite information
if (torch_light_image_timer > 0) { torch_light_image_timer -= 1; }
if (torch_light_image_timer == 0) {
	torch_light_image_index += 1;
	if (torch_light_image_index > 3) { torch_light_image_index = 0; }
}

// Update lighting information
update_lava_lighting();

// Act like a fireball
//update_fireball_torch_position();
fireball_light_bombs();
fireball_kill_enemies();
fireball_burn_bushes();

// Flicker to the white shooting frame, without the torch's fire, while it's about to shoot
if (shoot_timer <= 4) {
	image_index = 2;
	torch_light_sprite_index = noone;
}
else {
	if (image_index == 2) { image_index = 0; }
	torch_light_sprite_index = spr_torch_light;
}

if shoot_timer > 0 { shoot_timer -= 1; }
else {
	if (get_random_chance_out_of(NOSE_SELF_DESTRUCT_PROBABILITY)) { increment_run_stat("spontaneously_exploded_enemy"); explode(true); }
	else {
		// Shoot fireball in random direction
		/*
		var dir = irandom_range(1,360), x_pos = x + lengthdir_x(8, dir), y_pos = y + lengthdir_y(8, dir);
		shoot_projectile(x_pos, y_pos, false);
		*/
		var _target = get_dropped_meat();
		if (!is_existing_instance(_target)) { _target = global.player; }
		shoot_projectile(_target.x, _target.y, false);
		shoot_timer = irandom_range(8, 64);
	}
}

