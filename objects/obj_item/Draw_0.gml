/// @description Step
if (!is_existing_instance(holder) || (holder.object_index == obj_hands && !holder.activated)) { event_inherited(); }
else if (holder.visible) { 
	draw_while_carried( x-(8*image_xscale),  y-(8*image_yscale), 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend); 
	draw_reflection_in_mirrors();
}

if (sprite_index == get_sprite_to_use(spr_clock) || sprite_index == get_sprite_to_use(spr_special_clock)) {
	image_index = get_clock_image_index();
}
