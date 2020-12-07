// Initialize global values
randomize();
obj_controller_initialize();

// Generate Initial Room with Four Exits
var uninitialized_rooms = ds_list_create(); // Used by functions called add_random_exit and initialized_room
current_room = instance_create_depth(0,0,0,obj_room);
current_room.exits = array(true, true, true, true, false);
with current_room { obj_room_initialize(uninitialized_rooms); }
ds_list_pop_random_value(uninitialized_rooms);

// Generate More Rooms until minimum number is met.
while (instance_number(obj_room) < MINIMUM_NUMBER_OF_ROOMS) {
    var random_room = get_random_instance(obj_room);
    with random_room { obj_room_add_random_exit(true, uninitialized_rooms); }
}

// Generate and initialize rooms until all rooms have been initialized
while (ds_list_size(uninitialized_rooms) > 0) {
    var random_uninitialized_room = ds_list_pop_random_value(uninitialized_rooms);
    with random_uninitialized_room { obj_room_initialize(uninitialized_rooms); }
}
ds_list_destroy(uninitialized_rooms);

// Generate stairs Connections
var rooms_with_stairs_spot = ds_list_create();
with (obj_room) {
    if (exits[4]) { ds_list_add(rooms_with_stairs_spot, self); }
}
ds_list_shuffle(rooms_with_stairs_spot);
if (ds_list_size(rooms_with_stairs_spot) mod 2 != 0) {
    var odd_room_out = ds_list_find_value(rooms_with_stairs_spot, 0);
    odd_room_out.exits[4] = false;
    ds_list_delete(rooms_with_stairs_spot, 0);
}
for (var i = 0; i < ds_list_size(rooms_with_stairs_spot); i += 2) {
    var first_room = ds_list_find_value(rooms_with_stairs_spot, i);
    var second_room = ds_list_find_value(rooms_with_stairs_spot, i+1);
    first_room.adj_rooms[4] = second_room;
    second_room.adj_rooms[4] = first_room;
}
ds_list_destroy(rooms_with_stairs_spot);

// Assign a room reference from possible rooms for each room
with obj_room {
    obj_room_create_room_lists();
    room_reference = obj_room_assign_room();
    obj_room_destroy_room_lists();
}

current_room = get_random_instance(obj_room);

//// Lock Random Exits
//with obj_room {
//    for(var i = 0; i < 4; i++) {
//        if exits[i] && (irandom(global.controller.LOCKED_DOOR_PROBABILITY) == 0) { 
//            obj_room_create_locked_exit(i);
//        }
//    }
//}

//// Begin Game in Random Room that has no key in it
//do {
//    current_room = get_random_instance(obj_room);
//}
//until (!current_room.has_key);

//// Walk the Map and tweak it until map is possible
//var empty_list = ds_list_create();

//var list_of_all_keyless_rooms = ds_list_create();
//with (obj_room) {
//    if (!exits[4] && !has_key && id != global.controller.current_room) { ds_list_add(list_of_all_keyless_rooms, id); }
//}

//var list_of_all_locked_exits = ds_list_create();
//with (obj_exit) {
//    ds_list_add(list_of_all_locked_exits, id);
//}

//while (!obj_controller_can_reach_all_rooms(empty_list)) {
//    ds_list_clear(empty_list);
//    // Add an additional key somewhere
//    if (ds_list_size(list_of_all_keyless_rooms) > 0) {
//        ds_list_shuffle(list_of_all_keyless_rooms);
//        var room_to_add_key_to = ds_list_find_value(list_of_all_keyless_rooms, 0);
//        room_to_add_key_to.has_key = true;
//    }
//    else {
//        // Start removing locks on doors
//        ds_list_shuffle(list_of_all_locked_exits);
//        var locked_exit_to_destroy = ds_list_find_value(list_of_all_locked_exits, 0);
//        with locked_exit_to_destroy { obj_exit_unlock(); instance_destroy(); }
//    }
//}
//ds_list_destroy(empty_list);
//ds_list_destroy(list_of_all_keyless_rooms);
//ds_list_destroy(list_of_all_locked_exits);

// Create player object and change room to current room's referenced room
global.player = instance_create_depth(0, 0, -10, obj_player);
room_goto(current_room.room_reference);

