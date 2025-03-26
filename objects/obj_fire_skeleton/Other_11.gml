/// @description Step
event_inherited();

// Update Torch Sprite information
if (torch_light_image_timer > 0) { torch_light_image_timer -= 1; }
if (torch_light_image_timer == 0) {
	torch_light_image_index += 1;
	if (torch_light_image_index > 3) { torch_light_image_index = 0; }
}

if (is_covered_at_each_quadrant_by(obj_lava_part)) {
	sprite_index = get_sprite_to_use(spr_skeleton);
	torch_light_sprite_index = noone;
}
else {
	sprite_index = get_sprite_to_use(spr_fire_skeleton);
	torch_light_sprite_index = spr_special_torch_light;
}
	

// Update lighting information
update_lava_lighting();

// Act like a fireball
//update_fireball_torch_position();
fireball_light_bombs();
fireball_kill_enemies();
fireball_burn_bushes();

// flicker sprite
if (shoot_timer <= 4) { 
	sprite_index = get_sprite_to_use(spr_skeleton); 
	torch_light_sprite_index = noone;
}

if shoot_timer > 0 { shoot_timer -= 1; }
else {
	if (get_random_chance_out_of(NOSE_SELF_DESTRUCT_PROBABILITY)) { explode(true); } 
	else {
		// Shoot fireball in random direction
		/*
		var dir = irandom_range(1,360), x_pos = x + lengthdir_x(8, dir), y_pos = y + lengthdir_y(8, dir);
		shoot_projectile(x_pos, y_pos, false);
		*/
		var target = get_dropped_meat();
		if (!is_existing_instance(target)) { target = global.player; }
		shoot_projectile(target.x, target.y, false);
		shoot_timer = irandom_range(8, 64);
	}
}

