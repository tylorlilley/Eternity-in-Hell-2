var stairs_spot = instance_find(obj_stairs_spot, 0);
 
// First Time Setup	
if (!current_room.visited) {    
    // Flip game object positions as necesarry
    if (current_room.flip_horizontal) { flip_room_contents_horizontally(); }
    if (current_room.flip_vertical) { flip_room_contents_vertically(); }
    if (current_room.rotate != -1) { rotate_room_contents_around_room_center(current_room.rotate); }
	with obj_game_object { 
		image_angle = 0;
	}
	with obj_placeholder { 
		image_angle = 0;
	}
    
    // Create stairs for room if they should exist
    if (current_room.exits[4]) {
        instance_create_depth(stairs_spot.x, stairs_spot.y, 5, obj_stairs)
    }
    
    // Create key for room if it should exist
    if (current_room.has_key) {
        instance_create_depth(stairs_spot.x, stairs_spot.y, 0, obj_key)
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
            if !door { door = instance_create_depth(x_pos, y_pos, 0, obj_door); }
            door.door_for_exit = exit_to_create_door_for;
            door.locked = exit_to_create_door_for.locked;
        }
    }
    
    // Remove collectables from room if they shouldn't exist
    if (!current_room.has_collectables || current_room.collectables_collected) {
        with obj_collectable instance_destroy();
    }
	
	// Remove lit status from room if it shouldn't exist
	if (current_room.lit) { 
		if (instance_number(obj_lantern) == 0) { current_room.lit = false; }
		else { with obj_lantern { light_lantern(true); } }
	}
	
    // Mark room as one that has been visited at some point during this game
    current_room.visited = true;
}

// Every Time Setup
background_id = layer_background_get_id(layer_get_id("Background"));
layer_background_blend( background_id, make_color_rgb(floor(get_scaling_amount(20, 255, power(1-(points/INITIAL_SCORE), 8), 1)), 20, 20) );
with obj_room { distance_to_current_room = 9999; }
with current_room { calculate_distance_to_current(0); }

// Change position if necessary
if entered_from_stairs {
    global.player.x = stairs_spot.x
	global.player.y = stairs_spot.y
}

// Move carried item to current position
with obj_player { set_instance_to_same_position(carried_item); }

// Add a small pause when entering a room
global.player.pause_movement = FRAMES_TO_WAIT_UPON_ENTERING_ROOM;

// Set initial lighting to darkness
with obj_game_object { image_blend = global.controller.bg_color; }
