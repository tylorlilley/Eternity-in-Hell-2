/// @description  obj_controller_can_reach_all_rooms(list_of_unlocked_exits)
function obj_controller_can_reach_all_rooms(argument0) {
	var list_of_unlocked_exits = argument0;

	// walk the map once with original list of unlocked exits to get list values of current state of map
	var array_of_returned_lists;
	with current_room {
	   array_of_returned_lists = obj_controller_walk_the_map(0, list_of_unlocked_exits, ds_list_create(), ds_list_create(), ds_list_create());
	}
	var list_of_visited_rooms = array_of_returned_lists[0];
	var list_of_unlockable_exits = array_of_returned_lists[1];
	var list_of_available_rooms_with_keys = array_of_returned_lists[2];
	ds_list_shuffle(list_of_unlockable_exits);

	var original_list_of_unlocked_exits = ds_list_create();
	ds_list_copy(original_list_of_unlocked_exits, list_of_unlocked_exits);

	// Set up values we care about based on the returned lists
	var remaining_keys = ds_list_size(list_of_available_rooms_with_keys) - ds_list_size(list_of_unlocked_exits);
	var number_of_existing_rooms = instance_number(obj_room);
	var visited_all_rooms = (ds_list_size(list_of_visited_rooms) == number_of_existing_rooms);

	if (!visited_all_rooms && remaining_keys > 0 && ds_list_size(list_of_unlockable_exits) > 0) {
	    // for each unlockable exit, try unlocking just it and then checking if the whole map is accesible.
	    // If the whole map is not accessible after unlocking any one of the possible exits first, the map is a failure.
	    // Otherwise, it is a success
	    if (remaining_keys >= ds_list_size(list_of_unlockable_exits)) {
	        ds_list_combine(list_of_unlocked_exits, list_of_unlockable_exits);
	        visited_all_rooms = obj_controller_can_reach_all_rooms(list_of_unlocked_exits);
	    }
	    else {
	        for (var i = 0; i < ds_list_size(list_of_unlockable_exits); i++) {
	            ds_list_copy(list_of_unlocked_exits, original_list_of_unlocked_exits);
	            var newly_unlocked_exit = ds_list_find_value(list_of_unlockable_exits, i);
	            ds_list_add(list_of_unlocked_exits, newly_unlocked_exit);
	            if !obj_controller_can_reach_all_rooms(list_of_unlocked_exits) { visited_all_rooms = false; break; }
	        }
	    }
	}

	ds_list_destroy(original_list_of_unlocked_exits);
	ds_list_destroy(list_of_available_rooms_with_keys);
	ds_list_destroy(list_of_unlockable_exits);
	ds_list_destroy(list_of_visited_rooms);

    
	return visited_all_rooms;



}
