/// @description  obj_room_flip_vertically
function obj_room_flip_vertically() {

	with obj_game_object {
	    if (object_index != obj_player) { y = room_height - y; }
	}



}
