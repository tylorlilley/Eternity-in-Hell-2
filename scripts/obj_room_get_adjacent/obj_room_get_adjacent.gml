/// @description  obj_room_get_adjacent(dir)
function obj_room_get_adjacent(argument0) {
	var dir = argument0;

	var x_pos = 0;
	var y_pos = 0;

	switch (dir)
	{
	    case 0: { y_pos = -16; break; }
	    case 1: { x_pos = 16; break; }
	    case 2: { y_pos = 16; break; }
	    case 3: { x_pos = -16; break; }
	}

	return instance_position(x+x_pos, y+y_pos, obj_room);




}
