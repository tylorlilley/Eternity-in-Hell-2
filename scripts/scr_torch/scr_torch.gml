/// @function  								light_torch();
///	@param		{index}	lighting_torch		The instance that is doing the lighting
///	@param		{boolean}	make_noise		Whether or not lighting this torch should play a sound
function light_torch(lighting_torch, make_noise) {
	// Set remaining torch time for the calling instance to new lit amount
	var new_lit_amount = global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT, newly_lit = false;
	if (lighting_torch && lighting_torch.time_to_remain_lit) { new_lit_amount = lighting_torch.time_to_remain_lit; }
	if (time_to_remain_lit < new_lit_amount && time_to_remain_lit >= 0) {
		time_to_remain_lit = new_lit_amount;
		newly_lit = true;
	}
	// Light torch from completely extinguished
	if (!light_source) {
		newly_lit = true;
		
		image_index = 0;
		image_speed = 1/6;

		light_source = instance_create_depth(x, y, 0, obj_light_source);
		light_source.lighting_range = lighting_range;
		light_source.persistent = (holder != noone);
		
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
	// Play sound if a torch is newly lit from this interaction
	if (make_noise && newly_lit) { 
		play_sound(snd_torchlight, true); 
	}
}

/// @function							extinguish_torch();
function extinguish_torch() {
	image_speed = 0;
	image_index = 0;
	time_to_remain_lit = 0;
	
	play_sound( snd_extinguish, true );
	
	with light_source { instance_destroy(); }
	light_source = noone;
}

/// @function							interact_with_other_torches();
function interact_with_other_torches() {
	var actively_lit = false, torches = instance_place_all(x, y, obj_torch);
	
	// Light torches from lava
	if (is_covered_at_each_quadrant_by(obj_lava)) {
		light_torch(noone, true);	
		actively_lit = true;
	}

	
	// Cycle through and interact with each carried torch on this object
	while (array_length(torches) > 0) {
		var other_torch = array_random_pop(torches);
		
		if ((other_torch.holder == global.controller || is_instance_at_coordinates(x, y, other_torch)) && id != other_torch.id) {
			var not_carried = (holder == noone), other_not_carried = (other_torch.holder == noone);
			if (other_torch.light_source && not_carried != other_not_carried) { 
				light_torch(other_torch, true);		
				actively_lit = true;
			}
		}
	}	
	
	// Decrement time remaining if not actively_lit
	if (!actively_lit && !special && time_to_remain_lit > 0) { 
		time_to_remain_lit -= one_unit_of_game_time();
		if (light_source) { light_source.lighting_range = ceil(get_scaling_amount(global.controller.PLAYER_LIGHT_RANGE+1, lighting_range, time_to_remain_lit, global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT)); }
		if (!time_to_remain_lit && image_speed > 0) { extinguish_torch(); }
	}
}
