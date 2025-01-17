/// @description Step
event_inherited();

// reset sprite
if is_blink_frame() && shoot_timer > 4 { sprite_index = get_sprite_to_use(spr_fire_skeleton); }

// Act like a fireball
update_fireball_torch_position();
fireball_light_bombs();
fireball_kill_enemies();

// flicker sprite
if (shoot_timer == 4) { sprite_index = get_sprite_to_use(spr_skeleton); }
else { sprite_index = get_random_chance_out_of(128/global.difficulty) ? get_sprite_to_use(spr_skeleton) : get_sprite_to_use(spr_fire_skeleton); }

// Shoot fireball
if shoot_timer > 0 { shoot_timer -= 1; }
else {
	var dir = irandom_range(1,360), x_pos = x + lengthdir_x(8, dir), y_pos = y + lengthdir_y(8, dir);
	shoot_projectile(x_pos, y_pos, false);
	shoot_timer = irandom_range(8, 64);
	sprite_index = get_sprite_to_use(spr_skeleton);
}

