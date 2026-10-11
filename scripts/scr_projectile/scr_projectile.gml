/// @function initialize_lava_lighting()
/// @description Sets the calling instance (lava, a statue or a fire skeleton) up as a dim light source that glows like
///	lava. Its lighting range of 0 leaves it out of lighting checks that need a minimum range.
function initialize_lava_lighting() {
	lighting_range = 0;
	lighting_distance = LAVA_LIGHT_RANGE;
	intensity = 0.125 + irandom(0.35-0.125);
	maximum_intensity = 1;
	minimum_intensity = 0;
}

/// @function update_lava_lighting()
/// @description Makes the calling instance's lava light flicker each step: its intensity drifts at random between 0.125
///	and 0.35, and its lighting distance jumps a step around LAVA_LIGHT_RANGE
function update_lava_lighting() {
	intensity += (get_coin_flip()) ? random(0.025) : -1 * random(0.025);
	if (intensity < 0.125) { intensity = 0.125; }
	else if (intensity > 0.35) { intensity = 0.35; }
	lighting_distance = (LAVA_LIGHT_RANGE + floor((-24 + irandom(50))/25));
}

/// @function fireball_light_bombs()
/// @description Lights a bomb the calling fireball or fire skeleton touches, unless that bomb created it. The bomb counts
///	as lit by the player when the player shot the fireball, and the evaluation counts it while the player is alive.
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

/// @function fireball_kill_enemies([_use_magic_resistance])
/// @description Kills every activated, corporeal enemy within 8 pixels of the calling fireball or fire skeleton that
///	doesn't resist it. Hands always block it, and die unless they carry a staff. A kill is credited to the player, and
///	counted for the evaluation, when the player shot the fireball.
/// @param {bool} [_use_magic_resistance] Whether to check magic resistance instead of fire resistance (false by default)
/// @returns {bool} Whether an enemy blocked it: hands, or an enemy that doesn't resist it (when several enemies are hit,
///	the last one checked decides)
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

/// @function initialize_fireball_torch_variables(_lighting_range)
/// @description Gives the calling projectile (a fireball or magic beam) an invisible, lit special torch to carry, so it
///	gives off light and lights the torches it passes over
/// @param {real} _lighting_range The lighting range of the torch and its light source
/// @returns {Id.Instance} The new torch
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

/// @function update_fireball_torch_position([_new_x_scale])
/// @description Keeps the calling projectile's torch (see initialize_fireball_torch_variables) at its position
/// @param {real} [_new_x_scale] The torch's horizontal scale, which sizes its collision box (1 by default)
function update_fireball_torch_position(_new_x_scale = 1) { 
	if (is_existing_instance(torch)) { 
		set_instance_to_same_position(torch);  
		torch.image_xscale =_new_x_scale; 
	}
}

/// @function shoot_magic_beam(_target, _max_angle, [_number_to_shoot])
/// @description Shoots magic beams from the calling instance toward a target, aimed at random up to _max_angle degrees
///	to either side of it. Extra beams fan out from the first in 25 degree steps, alternating sides.
/// @param {Id.Instance} _target The instance to shoot at (the player if it doesn't exist)
/// @param {real} _max_angle The most degrees away from the target to aim
/// @param {real} [_number_to_shoot] How many beams to shoot (1 by default)
/// @returns {Id.Instance} The first beam shot, or noone if none were shot
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

/// @function fireball_burn_bushes()
/// @description Burns a bush the calling fireball or fire skeleton touches, leaving dirt in its place
/// @returns {bool} Whether a bush was in the way and burned
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