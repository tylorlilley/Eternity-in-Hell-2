/// @function light_torch(_lighting_torch, _make_noise)
/// @description Lights the calling torch or lantern from another torch, or tops up its time. Lighting one that was out
///	gives it a light source, marks the room as lit once every lantern in it is lit, and counts toward the end-of-game
///	evaluation.
/// @param {Id.Instance} _lighting_torch The torch doing the lighting, or noone to light it for the full time
/// @param {bool} _make_noise Whether lighting it should play a sound (currently ignored: the sound always plays)
function light_torch(_lighting_torch, _make_noise) {
	// Top up the remaining time to the lighting torch's remaining time, or to the full time if there's no lighting torch
	// or it has no time left
	var _controller = global.controller, _new_lit_amount = MAX_TORCH_TIME_TO_REMAIN_LIT;
	if (is_existing_instance(_lighting_torch) && _lighting_torch.time_to_remain_lit > 0) { _new_lit_amount = _lighting_torch.time_to_remain_lit; }
	if (time_to_remain_lit < _new_lit_amount && time_to_remain_lit >= 0) {
		time_to_remain_lit = _new_lit_amount;
		play_sound(snd_torchlight, true);
	}
	
	// Light the torch if it was completely extinguished
	if (!is_existing_instance(light_source)) {
		play_sound(snd_torchlight, true);
		
		torch_light_image_index = 1;
		torch_light_image_timer = 1;

		light_source = instance_create(x, y, obj_light_source);
		light_source.lighting_range = lighting_range;
		light_source.persistent = (is_existing_instance(holder));
		
		// Mark the room as lit once every lantern in it is lit, which counts for the evaluation when the player lit the
		// last one
		if (object_index == obj_lantern) {
			var _last_lantern = true;
		    with obj_lantern { if (!light_source) { _last_lantern = false; } }
		    _controller.current_room.lit = _last_lantern;
			if (_last_lantern && is_existing_instance(_lighting_torch) && _lighting_torch.holder == global.player) { 
				_controller.evaluation_manager.increment_evaluation_variable("rooms_lit");
			}
		}
		else if (object_index == obj_torch) {
			_controller.evaluation_manager.increment_evaluation_variable("torches_lit");
			if (special) { _controller.evaluation_manager.increment_evaluation_variable("special_torches_lit"); }
		}
	}
	// Relight the lighting torch for the full time if this torch has more time left than it
	with (_lighting_torch) { if (other.time_to_remain_lit > time_to_remain_lit) { light_torch(noone, false); } }
}

/// @function extinguish_torch()
/// @description Puts out the calling torch: stops its flame, clears its remaining time and destroys its light source. If
///	the player was holding it, they no longer earn the evaluation for keeping the fire burning.
function extinguish_torch() {
	torch_light_image_index = 0;
	torch_light_image_timer = -1;
	time_to_remain_lit = 0;
	
	if (is_existing_instance(holder) && holder == global.player) {
		global.controller.evaluation_manager.kept_fire = false;
	}
	
	play_sound( snd_extinguish, true );
	
	with light_source { instance_destroy(); }
	light_source = noone;
}

/// @function interact_with_other_torches()
/// @description A torch's step: it catches fire from each lit torch it touches when exactly one of the two is carried
///	(a torch on the ground and a carried one at the same spot, or a fireball's torch passing over one on the ground).
///	While no torch is lighting it, a torch that isn't special burns down until it goes out.
function interact_with_other_torches() {
	var _actively_lit = false, _torches = instance_place_all(x, y, obj_torch);
	
	// Catch fire from each lit torch here (at the same spot, or carried by a fireball) when exactly one of the two is
	// carried
	while (array_length(_torches) > 0) {
		var _other_torch = array_random_pop(_torches);
		
		if (((is_existing_instance(_other_torch) && is_existing_instance(_other_torch.holder) && _other_torch.holder.object_index == obj_fireball) || is_instance_at_coordinates(x, y, _other_torch)) && id != _other_torch.id) {
			var _not_carried = (!is_existing_instance(holder)), _other_not_carried = (!is_existing_instance(_other_torch) || !is_existing_instance(_other_torch.holder));
			if (is_existing_instance(_other_torch.light_source) && _not_carried != _other_not_carried) {
				if (!global.player.dead && is_existing_instance(_other_torch) && is_existing_instance(_other_torch.holder) && _other_torch.holder.object_index == obj_fireball && !is_existing_instance(light_source)) { 
					global.controller.evaluation_manager.increment_evaluation_variable("torches_lit_by_fireball");
				}
				light_torch(_other_torch, true);		
				_actively_lit = true;
			}
		}
	}
	
	// Burn down while no torch is lighting this one, unless it's special: the light's range shrinks toward just over the
	// player's own as time runs out, and the torch goes out when none is left
	if (!_actively_lit && !special && time_to_remain_lit > 0) {
		time_to_remain_lit -= get_one_unit_of_game_time();
		if (is_existing_instance(light_source)) { light_source.lighting_range = ceil(get_scaling_amount(PLAYER_LIGHT_RANGE+1, lighting_range, time_to_remain_lit, MAX_TORCH_TIME_TO_REMAIN_LIT)); }
		if (!time_to_remain_lit && torch_light_image_timer >= 0) { extinguish_torch(); }
	}
}
