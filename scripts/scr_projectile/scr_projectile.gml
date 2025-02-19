/// @function									initialize_lava_lighting();
function initialize_lava_lighting() {
	lighting_distance = LAVA_LIGHT_RANGE;
	intensity = 0.125 + irandom(0.35-0.125);
	maximum_intensity = 1;
	minimum_intensity = 0;
}

/// @function									get_relative_light_intensity();
function update_lava_lighting() {
	intensity += (get_coin_flip()) ? random(0.025) : -1 * random(0.025);
	if (intensity < 0.125) { intensity = 0.125; }
	else if (intensity > 0.35) { intensity = 0.35; }
	lighting_distance = (LAVA_LIGHT_RANGE + floor((-24 + irandom(50))/25));
}

/// @function									fireball_light_bombs();
function fireball_light_bombs() {
	var bomb = instance_place(x, y, obj_bomb);
	if (is_existing_instance(bomb) && (!is_existing_instance(creator) || creator != bomb)) {
		with (bomb) {
			lit_by_player = other.shot_by_player;
			light_bomb(); 
		}
	}
}

/// @function									fireball_kill_enemies();
///	@param		{bool} ignore_fire_resistantce  If true will kill fire resistant enemies
///	@param		{bool} use_magic_resistance		If true will use magic resistance instead of fire
function fireball_kill_enemies(use_magic_resistance = false) {
	var kill_snd = use_magic_resistance ? snd_no : snd_extinguish
	var blocked = false;
	var enemies_at_position = instance_place_all(x, y, obj_enemy);
	while (array_length(enemies_at_position) > 0) {
		var enemy = array_random_pop(enemies_at_position);
		var resistance = use_magic_resistance ? enemy.magic_resistant : enemy.fire_resistant;
		if (enemy.activated && enemy.corporeal && get_distance_to_instance(enemy) <= 8) {
			if (enemy.object_index == obj_hands) {
				blocked = true;
				with (enemy) {
					if (!is_carrying_item(obj_staff)) { 
						kill_enemy(kill_snd);
						if (other.shot_by_player) { update_kill_log(object_index, global.difficulty, other.object_index); global.controller.kill_count += 1; }
					}
				}
			}
			else { 
				blocked = !resistance;
				with (enemy) { 
					if (!resistance) { 
						kill_enemy(kill_snd);
						if (other.shot_by_player) { update_kill_log(object_index, global.difficulty, other.object_index); global.controller.kill_count += 1; }
					} 
				}
			}
		}
	}
	return blocked;
}

/// @function								initialize_fireball_torch_variables(lighting_range);
///	@param		{int} lighting_range		The lighting range to set the torch to
function initialize_fireball_torch_variables(lighting_range) {
	var torch = instance_create(x, y, obj_torch);
	torch.special = true;
	torch.holder = id;
	torch.time_to_remain_lit = MAX_TORCH_TIME_TO_REMAIN_LIT;
	torch.special = true;
	torch.lighting_range = lighting_range;
	torch.light_source = instance_create(x, y, obj_light_source);
	torch.light_source.lighting_range = lighting_range;
	torch.visible = false;
	torch.sprite_index = spr_box;
	torch.image_blend = c_lime;
	
	return torch;
}

/// @function								update_fireball_torch_position(new_x_scale);
///	@param		{float} new_x_scale			The new x scale to set the torch object to
function update_fireball_torch_position(new_x_scale = 1) { 
	if (is_existing_instance(torch)) { 
		set_instance_to_same_position(torch);  
		torch.image_xscale =new_x_scale; 
	}
}

/// @function								shoot_magic_beam(max_angle);
///	@param		{inst} target				The instantce to shoot at
///	@param		{int} max_angle				The maximum angle away from the target to shoot
function shoot_magic_beam(target, max_angle) {
	if (!is_existing_instance(target)) { target = global.player; } // Should this not default to player?
	var dir = point_direction(x, y, target.x, target.y) - max_angle + irandom_range(0,max_angle*2);
	var target_x = x + lengthdir_x(16, dir), target_y = y + lengthdir_y(16, dir);
	return shoot_projectile(target_x, target_y, false, obj_magic_beam);
}