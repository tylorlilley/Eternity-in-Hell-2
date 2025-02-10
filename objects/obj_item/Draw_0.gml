/// @description Step
if (!is_existing_instance(holder) || (holder.object_index == obj_hands && !holder.activated)) { 
	event_inherited();
	
	// Draw Fire if Torch is Lit
	if (torch_light_image_timer >= 0) { draw_sprite_ext(torch_light_sprite_index, torch_light_image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha); }
	
	// Draw Clock Time
	if (sprite_index == get_sprite_to_use(spr_clock) || sprite_index == get_sprite_to_use(spr_clock_farmer)) {
		var time_sprite = get_sprite_to_use(spr_clock_sand), time_image = get_clock_image_index();
		if (special) { time_sprite = (sprite_index == spr_clock) ? spr_special_clock_sand : spr_special_clock_sand_farmer; }
			
		draw_sprite_ext(time_sprite, time_image, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
}
else if (holder.visible) { 
	draw_while_carried( x-(8*image_xscale),  y-(8*image_yscale), 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend); 
}
