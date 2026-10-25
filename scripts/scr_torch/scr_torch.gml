/// @function  								light_torch(_lighting_torch);
///	@param		{index}	_lighting_torch		The instance that is doing the lighting
function light_torch(_lighting_torch) {
	// Set remaining torch time for the calling instance to new lit amount
	var _controller = global.controller, _new_lit_amount = MAX_TORCH_TIME_TO_REMAIN_LIT;
	if (is_existing_instance(_lighting_torch) && _lighting_torch.time_to_remain_lit > 0) { _new_lit_amount = _lighting_torch.time_to_remain_lit; }
	if (time_to_remain_lit < _new_lit_amount && time_to_remain_lit >= 0) {
		time_to_remain_lit = _new_lit_amount;
		play_sound(snd_torchlight, true);
	}
	
	// Light torch from completely extinguished
	if (!is_existing_instance(light_source)) {
		play_sound(snd_torchlight, true);
		
		torch_light_image_index = 1;
		torch_light_image_timer = 1;

		light_source = instance_create(x, y, obj_light_source);
		light_source.lighting_range = lighting_range;
		light_source.persistent = (is_existing_instance(holder));
		
		// Mark room as lit if this was the last lantern in the room, and whether the player lit it
		if (object_index == obj_lantern) {
			var _last_lantern = true;
		    with obj_lantern { if (!light_source) { _last_lantern = false; } }
		    _controller.current_room.lit = _last_lantern;
			_controller.current_room.lit_by_player = (_last_lantern && is_existing_instance(_lighting_torch) && _lighting_torch.holder == global.player);
			if (_controller.current_room.lit_by_player) { increment_run_stat("rooms_lit"); }
		}
		else if (object_index == obj_torch) {
			increment_run_stat("torches_lit");
			if (special) { increment_run_stat("special_torches_lit"); }
		}
	}
	// Light the lighting torch in response if necessary
	with (_lighting_torch) { if (other.time_to_remain_lit > time_to_remain_lit) { light_torch(noone); } }
}

/// @function							extinguish_torch();
function extinguish_torch() {
	torch_light_image_index = 0;
	torch_light_image_timer = -1;
	time_to_remain_lit = 0;
	
	if (is_existing_instance(holder) && holder == global.player) {
		increment_run_stat("carried_torch_lost_count");
	}
	
	play_sound( snd_extinguish, true );
	
	with light_source { instance_destroy(); }
	light_source = noone;
}

/// @function							interact_with_other_torches();
function interact_with_other_torches() {
	var _actively_lit = false, _torches = instance_place_all(x, y, obj_torch);
	
	// Cycle through and interact with each carried torch on this object
	while (array_length(_torches) > 0) {
		var _other_torch = array_random_pop(_torches);
		
		if (((is_existing_instance(_other_torch) && is_existing_instance(_other_torch.holder) && _other_torch.holder.object_index == obj_fireball) || is_instance_at_coordinates(x, y, _other_torch)) && id != _other_torch.id) {
			var _not_carried = (!is_existing_instance(holder)), _other_not_carried = (!is_existing_instance(_other_torch) || !is_existing_instance(_other_torch.holder));
			if (is_existing_instance(_other_torch.light_source) && _not_carried != _other_not_carried) {
				if (!global.player.dead && is_existing_instance(_other_torch) && is_existing_instance(_other_torch.holder) && _other_torch.holder.object_index == obj_fireball && !is_existing_instance(light_source)) { 
					increment_run_stat("torches_lit_by_fireball");
				}
				light_torch(_other_torch);		
				_actively_lit = true;
			}
		}
	}
	
	// Decrement time remaining if not actively_lit
	if (!_actively_lit && !special && time_to_remain_lit > 0) {
		time_to_remain_lit -= get_one_unit_of_game_time();
		if (is_existing_instance(light_source)) { light_source.lighting_range = ceil(get_scaling_amount(PLAYER_LIGHT_RANGE+1, lighting_range, time_to_remain_lit, MAX_TORCH_TIME_TO_REMAIN_LIT)); }
		if (!time_to_remain_lit && torch_light_image_timer >= 0) { extinguish_torch(); }
	}
}
