/// @description  obj_game_object_can_move_in_direction(dir, ignore_solid)
function obj_game_object_can_move_in_direction(argument0, argument1) {
	var dir = argument0, ignore_solid = argument1;

	return (!keyboard_check(vk_space) && 
	    (dir == 0 && (ignore_solid || !instance_place(x, y-8, obj_solid)) && (object_index == obj_player || y-8 > 0)) ||
	    (dir == 2 && (ignore_solid || !instance_place(x, y+8, obj_solid)) && (object_index == obj_player || y+8 < room_height)) ||
	    (dir == 3 && (ignore_solid || !instance_place(x-8, y, obj_solid)) && (object_index == obj_player || x-8 > 0)) ||
	    (dir == 1 && (ignore_solid || !instance_place(x+8, y, obj_solid)) && (object_index == obj_player || x+8 < room_width)));



}
