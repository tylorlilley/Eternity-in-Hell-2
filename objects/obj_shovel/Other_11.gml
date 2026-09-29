/// @description Step
var _holder_exists = is_existing_instance(holder);
if (!dropped_by_digger || _holder_exists || !can_dig_hole()) { 
	image_index = (_holder_exists) ? 1 : 0;
	if (image_index < 5 && damaged > 0) { image_index += 2; }
}

event_inherited();
