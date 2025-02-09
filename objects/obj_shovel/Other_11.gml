/// @description Step
image_index = (special) ? 5 : 4;
if (!dropped_by_digger || is_existing_instance(holder) || !can_dig_hole()) { 
	image_index = 0;
	if (image_index < 2 && damaged > 0) { image_index = (special) ? 3 : 2; }
}

event_inherited();
