event_inherited();

image_speed = 0;

if (get_distance_to_instance(global.player) <= 4 ||
	place_meeting(x, y, obj_death) ||
	place_meeting(x, y, obj_solid)) {
		instance_destroy();
}
