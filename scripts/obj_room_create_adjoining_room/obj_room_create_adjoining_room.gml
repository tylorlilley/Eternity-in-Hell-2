/// @description  obj_room_create_adjoining_room(dir, list_of_rooms)
function obj_room_create_adjoining_room(argument0, argument1) {
	var dir = argument0, list_of_rooms = argument1;

	var x_offset = 0
	var y_offset = 0;

	switch(dir)
	{
	    case 0: { y_offset = -16; break; }
	    case 1: { x_offset = 16; break; }
	    case 2: { y_offset = 16; break; }
	    case 3: { x_offset = -16; break; }
	}

	var new_room = instance_create(x+x_offset, y+y_offset, obj_room);
	obj_room_link_adjoining_room(new_room, dir);
	ds_list_add(list_of_rooms, new_room);



}
