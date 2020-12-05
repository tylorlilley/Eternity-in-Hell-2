x_prev = x;
y_prev = y;

if (!dead && !game_has_been_won() && !game_has_been_lost()) {   
    // Get input from player
    var dir = -1;
    
    var key_up = keyboard_check(vk_up);
    var key_down = keyboard_check(vk_down);
    var key_left = keyboard_check(vk_left);
    var key_right = keyboard_check(vk_right);
    
    if keyboard_check(vk_space) {
        // do nothing
    }
    else if key_up && !key_down { dir = 0; }
    else if key_down && !key_up { dir = 2; }
    else if key_left && !key_right { dir = 3; }
    else if key_right && !key_left { dir = 1; }
    
    // Move player in chosen direction if possible
    if (obj_game_object_can_move_in_direction(dir, false)) { 
        obj_game_object_move_in_direction(dir); 
        image_index += 1;
        if (image_index > 1) { image_index = 0; }
    }
    
    // Transition to new room depending on player position
    var stairs = instance_place(x, y, obj_stairs);
    if x < 0 { x = room_width-8; transition_to_room(3); }
    else if x > room_width { x = 8; transition_to_room(1); }
    else if y < 0 { y = room_height-8; transition_to_room(0); }
    else if y > room_height { y = 8; transition_to_room(2); }
    else if ( stairs && stairs.active && instance_at_coordinates(x, y, stairs)) { transition_to_room(4); }
    
    // Move carried item to current position
    obj_game_object_set_instance_to_same_position(carried_item);
}
else if dead image_index = 2;

event_inherited();

