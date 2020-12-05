/// @description  obj_room_initialize(list_of_rooms)
function obj_room_initialize(argument0) {
	var list_of_rooms = argument0;

	// Randomly decide if room will have collectables, stairs, or keys
	if (irandom(100) < global.controller.HAS_KEY_PROBABILITY) { has_key = true; }
	if (irandom(100) < global.controller.HAS_STAIRS_PROBABILITY) { exits[4] = true; }
	if (irandom(100) < global.controller.HAS_COLLECTABLE_PROBABILITY) { 
	    has_collectables = true; 
	    global.controller.rooms_with_collectables += 1; 
	}

	// Randomly determine the number of exits this room should have based on probability weighting
	var target_number_of_exits = 0;
	var rand = irandom(100)-instance_number(obj_room); // subtract number of rooms in order to drive generation toward an end eventually
	do {
	    rand -= global.controller.NUMBER_OF_EXITS_PROBABILITIES[target_number_of_exits];
	    target_number_of_exits += 1;
	}
	until (rand <= 0);

	// Take care of exits that must exist based on adjacent rooms and decrement number of exits accordingly
	for (var i = 0; i < 4; i++) {
	    if (adj_rooms[i]) { 
	        // If this room has an adjoining room in this direction, make sure it also has an exit in that
	        // direction. Then, link the rooms so they each have the other listed as an adj_room.
	        exits[i] = true; 
	        obj_room_link_adjoining_room(adj_rooms[i], i) 
	    }
	    else if (exits[i]) {
	        // Create adjoining room if this room has an exit in that direction but not an adjoining room.
	        // This really only happens for the first room, where exits are set to true by the controller.
	        obj_room_create_adjoining_room(i, list_of_rooms);
	    }
	}

	// Generate some number of random additional exits
	while (obj_room_count_exits() < target_number_of_exits) {
	    obj_room_add_random_exit(false, list_of_rooms);
	}



}
