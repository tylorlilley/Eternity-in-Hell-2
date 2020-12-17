/// @function  							light_torch();
function light_torch() {
	image_index = 0;
	image_speed = 1/6;

	audio_play_sound( snd_torchlight, 10, false );

	light_source = instance_create_depth(x, y, 0, obj_light_source);
	light_source.lighting_range = global.controller.TORCH_LIGHT_RANGE;
	light_source.persistent = true;

	time_to_remain_lit = global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT;
}


/// @function							interact_with_torches();
function interact_with_torches() {
	var lit_by_torch = false, torches = ds_list_create();
	instance_place_list(x, y, obj_torch, torches, false);
	
	// Cycle through each torches on this place
	while (ds_list_size(torches) > 0) {
		var torch = ds_list_pop_random_value(torches);
		
		if (!instance_at_coordinates(x, y, torch)) { torch = noone; }
	
		// Light the calling instance if this is a lit torch
		if (!light_source && torch && torch.light_source && !lit_by_torch) {
		    lit_by_torch = true;
		}
		// Light the torch if it is an unlit torch and the calling instance is lit
		if (light_source && torch) {
		    with torch {
		        if (time_to_remain_lit == 0) { light_torch(); }
		        else { time_to_remain_lit = other.time_to_remain_lit; }
		    }
		}
	}
	
	ds_list_destroy(torches);
	return lit_by_torch;
}