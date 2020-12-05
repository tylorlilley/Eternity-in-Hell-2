/// @description  obj_room_flip_horizontally
function obj_room_flip_horizontally() {

	with obj_game_object {
	    if (object_index != obj_player) { x = room_width - x; }
	}



}
