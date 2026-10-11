/// @description Step
event_inherited();

// Advance its torch light's animation, which cycles through four frames
if (torch_light_image_timer > 0) { torch_light_image_timer -= 1; }
if (torch_light_image_timer == 0) {
	torch_light_image_index += 1;
	if (torch_light_image_index > 3) { torch_light_image_index = 0; }
}

// While lava covers it, it shows as a plain skeleton with no torch light
if (is_covered_at_each_quadrant_by(obj_lava_part)) {
	sprite_index = get_sprite_to_use(spr_skeleton);
	torch_light_sprite_index = noone;
}
else {
	sprite_index = get_sprite_to_use(spr_fire_skeleton);
	torch_light_sprite_index = spr_torch_light;
}
	

// Make its lava glow flicker
update_lava_lighting();

// Act like a fireball: light the bombs it touches, kill enemies that don't resist fire, and burn bushes
fireball_light_bombs();
fireball_kill_enemies();
fireball_burn_bushes();

// For the last few steps before the timer runs out, it flickers to a plain skeleton with no torch light
if (shoot_timer <= 4) { 
	sprite_index = get_sprite_to_use(spr_skeleton); 
	torch_light_sprite_index = noone;
}

// When the timer runs out, it blows itself up (with the same chance as a nose) or shoots a fireball, and then waits a
// random time before its next shot
if shoot_timer > 0 { shoot_timer -= 1; }
else {
	if (get_random_chance_out_of(NOSE_SELF_DESTRUCT_PROBABILITY)) { explode(true); } 
	else {
		// Shoot a fireball at the latest dropped meat, or at the player if there's none
		var _target = get_dropped_meat();
		if (!is_existing_instance(_target)) { _target = global.player; }
		shoot_projectile(_target.x, _target.y, false);
		shoot_timer = irandom_range(8, 64);
	}
}

