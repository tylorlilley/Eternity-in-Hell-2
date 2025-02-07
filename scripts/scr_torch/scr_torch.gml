/// @function  								light_torch(lighting_torch, make_noise);
///	@param		{index}	lighting_torch		The instance that is doing the lighting
///	@param		{boolean}	make_noise		Whether or not lighting this torch should play a sound
function light_torch(lighting_torch, make_noise) {
	// Set remaining torch time for the calling instance to new lit amount
	var controller = global.controller, new_lit_amount = MAX_TORCH_TIME_TO_REMAIN_LIT;
	if (is_existing_instance(lighting_torch) && lighting_torch.time_to_remain_lit > 0) { new_lit_amount = lighting_torch.time_to_remain_lit; }
	if (time_to_remain_lit < new_lit_amount && time_to_remain_lit >= 0) {
		time_to_remain_lit = new_lit_amount;
		play_sound(snd_torchlight, true);
	}
	
	// Light torch from completely extinguished
	if (!is_existing_instance(light_source)) {
		play_sound(snd_torchlight, true);
		
		torch_sprite_image_index = 1;
		torch_light_image_timer = 1;

		light_source = instance_create(x, y, obj_light_source);
		light_source.lighting_range = lighting_range;
		light_source.persistent = (is_existing_instance(holder));
		
		// Mark room as lit if this was the last lantern in the room
		if (object_index == obj_lantern) {
			var last_lantern = true;
		    with obj_lantern { if (!light_source) { last_lantern = false; } }
		    controller.current_room.lit = last_lantern;
		}
	}
	// Light the lighting torch in response if necessary
	with (lighting_torch) { if (other.time_to_remain_lit > time_to_remain_lit) { light_torch(noone, false); } }
}

/// @function							extinguish_torch();
function extinguish_torch() {
	torch_sprite_image_index = 0;
	torch_light_image_timer = -1;
	time_to_remain_lit = 0;
	
	play_sound( snd_extinguish, true );
	
	with light_source { instance_destroy(); }
	light_source = noone;
}

/// @function							interact_with_other_torches();
function interact_with_other_torches() {
	var actively_lit = false, torches = instance_place_all(x, y, obj_torch);
	
	// Light torches from lava
	/*
	if (is_covered_at_each_quadrant_by(obj_lava_part)) {
		light_torch(noone, true);	
		actively_lit = true;
	}
	*/
	
	// Cycle through and interact with each carried torch on this object
	while (array_length(torches) > 0) {
		var other_torch = array_random_pop(torches);
		
		if (((is_existing_instance(other_torch) && is_existing_instance(other_torch.holder) && other_torch.holder.object_index == obj_fireball) || is_instance_at_coordinates(x, y, other_torch)) && id != other_torch.id) {
			var not_carried = (!is_existing_instance(holder)), other_not_carried = (!is_existing_instance(other_torch) || !is_existing_instance(other_torch.holder));
			if (is_existing_instance(other_torch.light_source) && not_carried != other_not_carried) { 
				light_torch(other_torch, true);		
				actively_lit = true;
			}
		}
	}
	
	// Decrement time remaining if not actively_lit
	if (!actively_lit && !special && time_to_remain_lit > 0) {
		time_to_remain_lit -= get_one_unit_of_game_time();
		if (is_existing_instance(light_source)) { light_source.lighting_range = ceil(get_scaling_amount(PLAYER_LIGHT_RANGE+1, lighting_range, time_to_remain_lit, MAX_TORCH_TIME_TO_REMAIN_LIT)); }
		if (!time_to_remain_lit && torch_light_image_timer >= 0) { extinguish_torch(); }
	}
}
