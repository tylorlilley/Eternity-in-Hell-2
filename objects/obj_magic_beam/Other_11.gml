/// @description Step
event_inherited();
	
// Keep its torch's collision box small
if (is_existing_instance(torch)) { torch.image_xscale = 0.5; }
// One step in four, wobble a pixel sideways from its direction of travel
if (get_random_chance_out_of(4)) {
	var _nudge_dir = get_coin_flip() ? direction-90 : direction+90;
	x += round(lengthdir_x(1, _nudge_dir));
	y += round(lengthdir_y(1, _nudge_dir));
}