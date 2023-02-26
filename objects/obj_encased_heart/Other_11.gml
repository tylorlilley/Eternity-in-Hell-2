/// @description End Step
event_inherited();
	
thump();
	
var push_direction = get_direction_pushed_against();
if (push_direction != directions.none) { play_sound(snd_locked, false); }
	
	
if (are_all_collectables_collected()) {
	instance_create(x, y, obj_dirt);
	instance_create(x, y, obj_heart_plate);
	var new_heart = instance_create(x, y, obj_heart);
	new_heart.image_index = image_index;
	global.controller.current_room.add_to_instances_at_map_positions(new_heart);
	instance_destroy();
}