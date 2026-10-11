/// @description End Step
event_inherited();

// Check for collisions with anything on the player's spot that can kill them
var _death_boxes = instance_place_all(x, y, obj_death);
while (array_length(_death_boxes) > 0) {
	var _death_box = array_pop(_death_boxes);
	with (_death_box) { check_for_player_collision(); }
}
	
// Echoes repeat the player's moves, so when the player hasn't moved this input frame, each echo generator that has
// started recording them records a pause
if (!is_existing_instance(moved_by)) {
	with (obj_echo_generator) { 
		if (array_length(moves) > 0) { array_push(moves, directions.none); } 
	}
}