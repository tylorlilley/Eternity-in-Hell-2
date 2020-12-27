
// Initialize global values
randomize()
//random_set_seed(2775969425
clear_inputs_for_next_frame();
initialize_game_variables();

// Generate Initial Room with Four Exits
var uninitialized_rooms = ds_list_create(); // Used by functions called add_random_exit and initialized_room
current_room = instance_create_depth(0,0,0,obj_room);
current_room.exits = array(true, true, true, true, false);
with current_room { initialize_room(uninitialized_rooms); }
//ds_list_pop_random_value(uninitialized_rooms);

// Generate More Rooms until minimum number is met.
var target_number_of_rooms = MINIMUM_NUMBER_OF_ROOMS + irandom(ADDITIONAL_ROOMS);
while (instance_number(obj_room) < target_number_of_rooms) {
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
until (!current_room.stairs_spot_obj);
with current_room { calculate_distance_to_current(0); }

// Set up lists used to walk the map
var locked_exits = ds_list_create(), keyless_rooms = ds_list_create(), farthest_rooms = ds_list_create();
with (obj_room) {
	// Determine if room could be the room the heart is in
	if (!exits[4]) {
		if (ds_list_size(farthest_rooms) == 0) { ds_list_add(farthest_rooms, id); }
		else {
			var distance = ds_list_find_value(farthest_rooms, 0).distance_to_current_room;
			if (distance_to_current_room == distance) {
				ds_list_add(farthest_rooms, id);
			}
			else if (distance_to_current_room > distance){
				ds_list_clear(farthest_rooms);
				ds_list_add(farthest_rooms, id);
			}
		}
	}
	// Determine if room has a key or not
    if (!has_key && id != global.controller.current_room) { ds_list_add(keyless_rooms, id); }
}
// Create heart in farthest room
with ds_list_pop_random_value(farthest_rooms) {
	stairs_spot_obj = obj_encased_heart;
	for (var i = 0; i <= 3; i += 1;) {
		if (exits[i]) { create_locked_exit(i); }
	}
}
// Create list of locked exits
with (obj_exit) {
    if (locked) { ds_list_add(locked_exits, id); }
}

// Walk the Map and tweak it until map is possible
show_debug_message("NUMBER OF KEYS: "+string(instance_number(obj_room) - (ds_list_size(keyless_rooms)+1)));
show_debug_message("NUMBER LOCKED DOORS: "+string(ds_list_size(locked_exits)));
var visited_all_rooms = is_current_map_possible();
while (!visited_all_rooms) {
	var number_of_keys = instance_number(obj_room) - (ds_list_size(keyless_rooms)+1);
	var number_of_locked_exits = ds_list_size(locked_exits);
	
	//// Remove one of the locked exits if there are way too many
	//if (ds_list_size(locked_exits) >= LOCKED_DOOR_PROBABILITY*2) {
    //    with ds_list_pop_random_value(locked_exits) { remove_exit(); }
			
	//	show_debug_message("NUMBER OF LOCKS -1");
	//}
    // Add an additional key somewhere
    if (ds_list_size(keyless_rooms) > 0 && (ds_list_size(locked_exits) == 0 || number_of_keys <= number_of_locked_exits*1.5)) {
        ds_list_pop_random_value(keyless_rooms).has_key = true;
		
		show_debug_message("NUMBER OF KEYS +1");
    }
    // Remove one of the locked doors and reset all rooms to have no keys
    else if (ds_list_size(locked_exits) > 0) {
        with ds_list_pop_random_value(locked_exits) { remove_exit(); }
		with (obj_room) {
		    if (has_key) { has_key = false; ds_list_add(keyless_rooms, id); }
		}
		
		show_debug_message("KEYS RESET; NUMBER OF LOCKS -1");
    }
	// Should never need to reach this clause
	else {
		show_debug_message("WARNING: lock generation screwed up.");
		break;
	}
	
	visited_all_rooms = is_current_map_possible();
}
show_debug_message("WALK RESULTS: "+string(visited_all_rooms));
show_debug_message("NUMBER OF KEYS: "+string(instance_number(obj_room) - (ds_list_size(keyless_rooms)+1)));
show_debug_message("NUMBER LOCKED DOORS: "+string(ds_list_size(locked_exits)));

// Destroy the lists used for lock generation
ds_list_destroy(keyless_rooms);
ds_list_destroy(farthest_rooms);
ds_list_destroy(locked_exits);

//Randomly spawn a special item for each item type
total_number_of_rooms_with_collectables = ds_list_size(rooms_with_collectables);
if (ds_list_size(rooms_with_key) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with ds_list_pop_random_value(rooms_with_key) { has_special_item = true; } }
if (ds_list_size(rooms_with_torch) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with ds_list_pop_random_value(rooms_with_torch) { has_special_item = true; } }
if (ds_list_size(rooms_with_sword) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with ds_list_pop_random_value(rooms_with_sword) { has_special_item = true; } }
if (ds_list_size(rooms_with_rosary) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with ds_list_pop_random_value(rooms_with_rosary) { has_special_item = true; } }
if (ds_list_size(rooms_with_map) > 0 && get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { with ds_list_pop_random_value(rooms_with_map) { has_special_item = true; } }
ds_list_destroy(rooms_with_key);
ds_list_destroy(rooms_with_torch);
ds_list_destroy(rooms_with_sword);
ds_list_destroy(rooms_with_rosary);
ds_list_destroy(rooms_with_map);


// Set up point and time related variables
time_provided = (instance_number(obj_room) * TIME_PROVIDED_PER_ROOM) + (instance_number(obj_exit) * TIME_PROVIEDED_PER_LOCK);
time_remaining = time_provided;

// Create player object and change room to current room's referenced room
current_room.stairs_spot_obj = obj_cross;
global.player = instance_create_depth(0, 0, -10, obj_player);
room_goto(current_room.room_reference);

