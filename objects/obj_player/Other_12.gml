/// @description End Step
event_inherited();

// Check for collisions with things that can kill you
var death_boxes = instance_place_all(x, y, obj_death);
while (array_length(death_boxes) > 0) {
	var death_box = array_pop(death_boxes);
	with (death_box) { check_for_player_collision(); }
}
	
// Update movement history for echo genertor if not moved this frame
if (!is_existing_instance(moved_by)) {
	with (obj_echo_generator) { 
		if (array_length(moves) > 0) { array_push(moves, directions.none); } 
	}
}