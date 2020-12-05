/// @description  obj_game_object_is_direction_toward_player(dir)
function obj_game_object_is_direction_toward_player(argument0) {
	var dir = argument0;

	return ((y < global.player.y && dir == 0) ||
	        (x > global.player.x && dir == 1) ||
	        (y > global.player.y && dir == 2) ||
	        (x < global.player.x && dir == 3));



}
