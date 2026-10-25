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
fireball_light_bombs();
fireball_kill_enemies();
fireball_burn_bushes();

// Flicker to the white shooting frame, without the torch's fire, while it's about to shoot
// TODO: Check at runtime that it keeps its sprite, in and out of lava, flickers to its white shooting frame without its
// torch's fire before each shot, and shows its torch's fire the rest of the time
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
		// Shoot a fireball at the dropped meat, or at the player when there is none
		var _target = get_dropped_meat();
		if (!is_existing_instance(_target)) { _target = global.player; }
		shoot_projectile(_target.x, _target.y, false);
		shoot_timer = irandom_range(8, 64);
	}
}

