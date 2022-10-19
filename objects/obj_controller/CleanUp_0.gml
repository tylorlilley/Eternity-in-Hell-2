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
for (var i = 0; i < array_length(game_rooms); i++) {
	room_goto(game_rooms[i].room_reference);
	room_persistent = false;
}
room_goto(rm_title);
draw_set_color(c_black);