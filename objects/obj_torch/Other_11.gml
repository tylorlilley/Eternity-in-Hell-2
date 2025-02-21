/// @description Step
if (torch_light_image_timer > 0) { torch_light_image_timer -= 1; }
if (torch_light_image_timer == 0) {
	torch_light_image_index += 1;
	if (torch_light_image_index > 3) { torch_light_image_index = 0; }
}

if (light_source != noone && !is_existing_instance(holder) && is_instance_at_coordinates(x, y, obj_block)) { 
	extinguish_torch();
	global.controller.current_room.lit = false;
}

interact_with_other_torches();
	
event_inherited();