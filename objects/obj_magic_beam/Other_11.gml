/// @description Step
event_inherited();
	
if (is_existing_instance(torch)) { torch.image_xscale = 0.5; }
if (get_random_chance_out_of(4)) {
	var nudge_dir = get_coin_flip() ? direction-90 : direction+90;
	x += round(lengthdir_x(1, nudge_dir));
	y += round(lengthdir_y(1, nudge_dir));
}