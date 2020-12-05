/// @description  obj_room_create_locked_exit(dir)
function obj_room_create_locked_exit(argument0) {
	var dir = argument0;

	var new_locked_exit = instance_create(0,0,obj_exit); 
	new_locked_exit.room_1 = id;
	new_locked_exit.room_1_dir = dir;
	new_locked_exit.room_2 = adj_rooms[dir];
	new_locked_exit.room_2_dir = opposite_dir(dir);
	new_locked_exit.room_1.locked_exits[new_locked_exit.room_1_dir] = new_locked_exit;
	new_locked_exit.room_2.locked_exits[new_locked_exit.room_2_dir] = new_locked_exit;
	return new_locked_exit;



}
