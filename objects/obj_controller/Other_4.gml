with obj_room { distance_to_current_room = 9999; }
with current_room { obj_room_calculate_distance_to_current(0); }

if (!current_room.visited) {
    room_speed = 10;
    
    // Flip game object positions as necesarry
    if (current_room.flip_horizontal) { obj_room_flip_horizontally(); }
    if (current_room.flip_vertical) { obj_room_flip_vertically(); }
    
    // Change player position if necessarry
    var stairs_spot = instance_find(obj_stairs_spot, 0);
    
    if entered_from_stairs {
        global.player.x = stairs_spot.x;
        global.player.y = stairs_spot.y;
        entered_from_stairs = false;
    }
    
    // Create stairs for room if they should exist
    if (current_room.exits[4]) {
        instance_create(stairs_spot.x, stairs_spot.y, obj_stairs)
    }
    
    // Create key for room if it should exist
    if (current_room.has_key) {
        instance_create(stairs_spot.x, stairs_spot.y, obj_key)
    }
    
    // Create locked exits if they should exist
    for (var i = 0; i < 4; i++) {
        var x_pos = 0;
        var y_pos = 0;
        
        if (i == 0) { x_pos = room_width/2; y_pos = 8; }
        if (i == 1) { x_pos = room_width-8; y_pos = room_height/2; }
        if (i == 2) { x_pos = room_width/2; y_pos = room_height-8; }
        if (i == 3) { x_pos = 8; y_pos = room_height/2; }
        var door = instance_position(x_pos, y_pos, obj_door);
        
        var exit_to_create_door_for = current_room.locked_exits[i];
        if (exit_to_create_door_for) {   
            if !door { door = instance_create(x_pos, y_pos, obj_door); }
            door.door_for_exit = exit_to_create_door_for;
            door.locked = exit_to_create_door_for.locked;
        }
    }
    
    // Remove collectables from room if they shouldn't exist
    if (!current_room.has_collectables || current_room.collectables_collected) {
        with obj_collectable instance_destroy();
    }
	
	// Remove lit status from room if it should't exist
	if (current_room.lit && instance_number(obj_lantern) == 0) {
		current_room.lit = false;
	}
    
    // Mark room as one that has been visited at some point during this game
    current_room.visited = true;
}

