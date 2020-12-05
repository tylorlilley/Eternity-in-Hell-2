/// @description  obj_game_object_turn_to_face_player
function obj_game_object_turn_to_face_player() {

	if (obj_game_object_is_direction_toward_player(1)) { image_xscale = -1; }
	else { image_xscale = 1; }



}
