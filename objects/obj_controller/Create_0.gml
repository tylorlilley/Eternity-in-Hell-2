// Initialize global values\
randomize();
clear_inputs_for_next_frame();
initialize_game_variables();

// Generate Initial Room with Four Exits
var uninitialized_rooms = ds_list_create(); // Used by functions called add_random_exit and initialized_room
current_room = instance_create_depth(0,0,0,obj_room);
current_room.exits = array(true, true, true, true, false);
with current_room { initialize_room(uninitialized_rooms); }
//ds_list_pop_random_value(uninitialized_rooms);

// Generate More Rooms until minimum number is met.
while (instance_number(obj_room) < MINIMUM_NUMBER_OF_ROOMS) {
    var random_room = get_random_instance(obj_room);
    with random_room { add_random_exit(true, uninitialized_rooms); }
}

// Generate and initialize rooms until all rooms have been initialized
while (ds_list_size(uninitialized_rooms) > 0) {
    var random_uninitialized_room = ds_list_pop_random_value(uninitialized_rooms);
    with random_uninitialized_room { initialize_room(uninitialized_rooms); }
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
create_room_lists();
with obj_room {
    room_reference = get_room_from_room_lists();
}
destroy_room_lists();

// Lock Random Exits
with obj_room {
    for(var i = 0; i <= 3; i+= 1;) {
        if (exits[i] && get_random_chance_out_of(global.controller.LOCKED_DOOR_PROBABILITY)) { 
            create_locked_exit(i);
        }
    }
}

// Begin Game in Random Room that has no stairs in it
do { current_room = get_random_instance(obj_room); }
until (!current_room.has_key && !current_room.exits[4]);

// Set up lists used to walk the map
var keyless_rooms = ds_list_create(), locked_exits = ds_list_create();
with (obj_room) {
    if (!has_key && id != global.controller.current_room) { ds_list_add(keyless_rooms, id); }
}
with (obj_exit) {
    if (locked) { ds_list_add(locked_exits, id); }
}

// Walk the Map and tweak it until map is possible
var visited_all_rooms = walk_the_map_using_keys();
while (!visited_all_rooms) {
    // Add an additional key somewhere
    if (ds_list_size(keyless_rooms) > 0) {
        ds_list_pop_random_value(keyless_rooms).has_key = true;
    }
    // Start removing locks on doors
    else if (ds_list_size(locked_exits) > 0) {
        with ds_list_pop_random_value(locked_exits) { unlock_exit(); instance_destroy(); }
    }
	// Should never need to reach this clause
	else {
		show_debug_message("WARNING: lock generation screwed up.");
		break;
	}
	
	visited_all_rooms = walk_the_map_using_keys();
}
show_debug_message("WALK RESULTS: "+string(visited_all_rooms));

// Destroy the lists used for lock generation
ds_list_destroy(keyless_rooms);
ds_list_destroy(locked_exits);

//// Set up lists used to walk the map
//var empty_list = ds_list_create(), list_of_all_keyless_rooms = ds_list_create(), list_of_all_locked_exits = ds_list_create();
//with (obj_room) {
//    if (!has_key && id != global.controller.current_room) { ds_list_add(list_of_all_keyless_rooms, id); }
//}
//with (obj_exit) {
//    if (locked) { ds_list_add(list_of_all_locked_exits, id); }
//}

//// Walk the Map and tweak it until map is possible
//while (!can_reach_all_rooms(empty_list)) {
//    ds_list_clear(empty_list);
//    // Add an additional key somewhere
//    if (ds_list_size(list_of_all_keyless_rooms) > 0) {
//        ds_list_pop_random_value(list_of_all_keyless_rooms).has_key = true;
//    }
//    // Start removing locks on doors
//    else if (ds_list_size(list_of_all_locked_exits) > 0) {
//        with ds_list_pop_random_value(list_of_all_locked_exits) { unlock_exit(); instance_destroy(); }
//    }
//	// Should never need to reach this clause
//	else {
//		show_debug_message("WARNING: lock generation screwed up.");
//		break;
//	}
//}
//// Destroy the lists used for lock generation
//ds_list_destroy(empty_list);
//ds_list_destroy(list_of_all_keyless_rooms);
//ds_list_destroy(list_of_all_locked_exits);

// Create player object and change room to current room's referenced room
entered_from_stairs = true;
global.player = instance_create_depth(0, 0, -10, obj_player);
room_goto(current_room.room_reference);

