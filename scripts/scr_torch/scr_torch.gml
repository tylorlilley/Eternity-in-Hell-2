/// @function  								light_torch();
///	@param		{index}	lighting_torch		The instance that is doing the lighting
///	@param		{boolean}	play_sound		Whether or not lighting this torch should play a sound
function light_torch(lighting_torch, play_sound) {
	// Set remaining torch time for the calling instance to new lit amount
	var new_lit_amount = global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT;
	if (lighting_torch && object_index != obj_lantern) { new_lit_amount = lighting_torch.time_to_remain_lit; }
	if (time_to_remain_lit < new_lit_amount) {
		time_to_remain_lit = new_lit_amount;
		if (play_sound) { audio_play_sound( snd_torchlight, 10, false ); }
	}
	// Light torch from completely extinguished
	if (!light_source) {
		image_index = 0;
		image_speed = 1/6;

		light_source = instance_create_depth(x, y, 0, obj_light_source);
		light_source.lighting_range = lighting_range;
		light_source.persistent = (carried != noone);
		
		// Mark room as lit if this was the last lantern in the room
		if (object_index == obj_lantern) {
			var last_lantern = true;
		    with obj_lantern { if (!light_source) { last_lantern = false; } }
		    global.controller.current_room.lit = last_lantern;
		}
	}
	// Light the lighting torch in response if necessary
	if (lighting_torch && time_to_remain_lit > lighting_torch.time_to_remain_lit) {
		with lighting_torch { light_torch(noone, false); }
	}
}

/// @function							extinguish_torch();
function extinguish_torch() {
	image_speed = 0;
	image_index = 0;
	
	audio_play_sound( snd_extinguish, 10, false );
	
	with light_source { instance_destroy(); }
	light_source = noone;
}

/// @function							interact_with_carried_torches();
function interact_with_other_torches() {
	var actively_lit = false, torches = instance_place_all(x, y, obj_torch);
	
	// Cycle through and interact with each carried torch on this object
	while (array_length(torches) > 0) {
		var other_torch = array_random_pop(torches);
		
		if (instance_at_coordinates(x, y, other_torch) && id != other_torch.id) {
			var not_carried = (carried == noone), other_not_carried = (other_torch.carried == noone);
			if (other_torch.light_source && not_carried != other_not_carried) { 
				light_torch(other_torch, true);		
				actively_lit = true;
			}
		}
	}	
	
	// Decrement time remaining if not actively_lit
	if (!actively_lit && !special && object_index == obj_torch && time_to_remain_lit > 0) { 
		time_to_remain_lit -= one_unit_of_game_time();
		if (light_source) { light_source.lighting_range = ceil(get_scaling_amount(global.controller.PLAYER_LIGHT_RANGE+1, lighting_range, time_to_remain_lit, global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT)); }
		if (!time_to_remain_lit && image_speed > 0) { extinguish_torch(); }
	}
}
