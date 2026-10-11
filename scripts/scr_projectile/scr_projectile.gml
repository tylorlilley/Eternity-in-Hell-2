/// @function									initialize_lava_lighting();
function initialize_lava_lighting() {
	lighting_range = 0;
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
	var _bomb = instance_place(x, y, obj_bomb);
	if (is_existing_instance(_bomb) && (!is_existing_instance(creator) || creator != _bomb)) {
		with (_bomb) {
			lit_by_player = other.shot_by_player;
			if (!global.player.dead) {
				global.controller.evaluation_manager.increment_evaluation_variable("bombs_lit_by_fireball");
			}
			light_bomb(); 
		}
	}
}

/// @function									fireball_kill_enemies(ignore_fire_resistance, _use_magic_resistance);
///	@param		{bool} ignore_fire_resistantce  If true will kill fire resistant enemies
///	@param		{bool} _use_magic_resistance		If true will use magic resistance instead of fire
function fireball_kill_enemies(_use_magic_resistance = false) {
	var _kill_snd = _use_magic_resistance ? snd_no : snd_extinguish
	var _blocked = false;
	var _enemies_at_position = instance_place_all(x, y, obj_enemy);
	while (array_length(_enemies_at_position) > 0) {
		var _enemy = array_random_pop(_enemies_at_position);
		var _resistance = _use_magic_resistance ? _enemy.magic_resistant : _enemy.fire_resistant;
		if (_enemy.activated && _enemy.corporeal && get_distance_to_instance(_enemy) <= 8) {
			if (_enemy.object_index == obj_hands) {
				_blocked = true;
				with (_enemy) {
					if (!is_carrying_item(obj_staff)) {
						var _kill_type = (other.shot_by_player)? other.object_index : noone;
						kill_enemy(_kill_snd, _kill_type);
						if (_kill_type != noone) {
							global.controller.evaluation_manager.increment_evaluation_variable("fireball_kill_count");
						}
					}
				}
			}
			else { 
				_blocked = !_resistance;
				with (_enemy) { 
					if (!_resistance) { 
						var _kill_type = (other.shot_by_player)? other.object_index : noone;
						kill_enemy(_kill_snd, _kill_type);
						if (_kill_type != noone) {
							global.controller.evaluation_manager.increment_evaluation_variable("fireball_kill_count");
						}
					} 
				}
			}
		}
	}
	return _blocked;
}

/// @function								initialize_fireball_torch_variables(_lighting_range);
///	@param		{int} _lighting_range		The lighting range to set the torch to
function initialize_fireball_torch_variables(_lighting_range) {
	var _torch = instance_create(x, y, obj_torch);
	_torch.special = true;
	_torch.holder = id;
	_torch.time_to_remain_lit = MAX_TORCH_TIME_TO_REMAIN_LIT;
	_torch.special = true;
	_torch.lighting_range = _lighting_range;
	_torch.light_source = instance_create(x, y, obj_light_source);
	_torch.light_source.lighting_range = _lighting_range;
	_torch.visible = false;
	_torch.sprite_index = spr_box;
	_torch.image_blend = c_lime;
	
	return _torch;
}

/// @function								update_fireball_torch_position(_new_x_scale);
///	@param		{float} _new_x_scale			The new x scale to set the torch object to
function update_fireball_torch_position(_new_x_scale = 1) { 
	if (is_existing_instance(torch)) { 
		set_instance_to_same_position(torch);  
		torch.image_xscale =_new_x_scale; 
	}
}

/// @function								shoot_magic_beam(_target, _max_angle [_number_to_shoot]);
///	@param		{inst} _target				The instantce to shoot at
///	@param		{int} _max_angle				The maximum angle away from the target to shoot
///	@param		{int} _number_to_shoot		OPTIONAL: Number of projectiles to shoot
function shoot_magic_beam(_target, _max_angle, _number_to_shoot = 1) {
	if (!is_existing_instance(_target)) { _target = global.player; }
	var _dir = point_direction(x, y, _target.x, _target.y) - _max_angle + irandom_range(0,_max_angle*2);
	var _first_shot = noone
	for (var _i = 0; _i < _number_to_shoot; _i++) {
		var _dir_offset = 25*ceil(_i/2);
		if (_i % 2 == 0) { _dir_offset *= -1; }
		var _target_x = x + lengthdir_x(16, _dir+_dir_offset), _target_y = y + lengthdir_y(16, _dir+_dir_offset);
		var _next_shot = shoot_projectile(_target_x, _target_y, false, obj_magic_beam);
		if (_i == 0) { _first_shot = _next_shot; }
	}
	return _first_shot;
}

/// @ function								fireball_burn_bushes()
function fireball_burn_bushes() {
	var _blocked = false;
	var _bush = instance_place(x, y, obj_bush);
	with (_bush) {
		_blocked = true;
		play_sound(snd_extinguish, true);
		instance_create(x, y, obj_dirt);
		instance_destroy();
	}
	return _blocked;
}