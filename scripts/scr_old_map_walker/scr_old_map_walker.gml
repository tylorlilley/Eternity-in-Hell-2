
function RoomGroup(given_rooms, given_keys, given_distance) constructor {
	rooms = given_rooms;
	room_group_size = array_create(0);
	keys = given_keys;
}

function MapWalker() constructor {
	rooms_to_visit = array_create(0); 
	visited_rooms = array_create(0);
	locked_exits = array_create(0);
	keys = 0;
	internal_locks = 0;
	
	function visit_room(current_room) {
		// TODO: Update distance to start for current_room based on traveled distance
		
		// Only visit unvisited rooms
		if (array_contains(visited_rooms, current_room)) { return; }
		
		// Visit each of current room's exits
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = current_room.exits[dir];
			if (next_exit == -1) { continue; }
			
			var next_room = next_exit.get_connected_room(dir);
			if (next_room.has_key) { keys += 1; }
			if (next_exit.locked) {
				array_push(locked_exits, [next_exit, dir]);
				continue;
			}
			
			array_push(rooms_to_visit, next_room);
		}
	}
}

function walk_the_map() {
	var controller = global.controller, walker = new MapWalker(), visited_room_groups = array_create(0);
	
	with (walker) {
		array_push(rooms_to_visit, controller.start_room);
		
		while (array_length(rooms_to_visit) < array_length(controller.game_rooms)) {
			// Visit all rooms in this room group
			while (array_length(rooms_to_visit) > 0) {
				var current_visit = array_pop(rooms_to_visit), current_room = current_visit[0], traveled_distance = current_visit[1]+1;
			
				visit_room (current_room, traveled_distance);
			}
		
			// Make a Room Group out of this walker state
			//var new_room_group = new RoomGroup(visited_rooms, locked_exits, 
			while (keys < array_length(locked_exits)) {
				// Add key to this or previous room groups until map has enough keys for these locks
				// Remove lock and restart if enough keys can't be added
			}
		}
	}
}

