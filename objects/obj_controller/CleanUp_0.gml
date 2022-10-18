// Destroy remaing ds lists
//ds_list_destroy(rooms_with_collectables);
//ds_list_destroy(rooms_with_torch);
//ds_list_destroy(rooms_with_key);
//ds_list_destroy(rooms_with_sword);
//ds_list_destroy(rooms_with_map);
//ds_list_destroy(rooms_with_rosary);

// Destroy Persistent Rooms and Exits
room_persistent = false;
// with (obj_exit) { instance_destroy(); }
with (obj_room) {
	room_goto(room_reference);
	room_persistent = false;
	instance_destroy();
}
room_goto(rm_title);
draw_set_color(c_black);