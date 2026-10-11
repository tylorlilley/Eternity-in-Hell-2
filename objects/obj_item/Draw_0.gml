/// @description Draw
// Draw it where it lies when nobody holds it, or dormant hands do
if (!is_existing_instance(holder) || (holder.object_index == obj_hands && !holder.activated)) { 
	event_inherited();
	
	// Draw the clock's sand or the compass's hands over it
	if (time_sprite_index != noone) {			
		draw_sprite_ext(time_sprite_index, time_image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
	
	// Draw the fire of a lit torch
	if (torch_light_image_timer >= 0) {
		var _light_offset = (object_index == obj_torch && image_index == 0) ? 1 : 0; // Only the dropped torch frame needs its fire nudged
		draw_sprite_ext(torch_light_sprite_index, torch_light_image_index, x + (_light_offset * image_xscale), y - _light_offset, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
	}
}
else if (holder.visible) { 
	// Otherwise draw it in its holder's hand, along with any clock sand, compass hands or torch fire
	draw_while_carried( x-(8*image_xscale),  y-(8*image_yscale), 0, 0, abs(sprite_width), abs(sprite_height), image_xscale, image_blend, false); 
}
