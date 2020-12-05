/// @description  obj_room_draw(x_pos, y_pos)
function obj_room_draw(argument0, argument1) {
	var x_pos = argument0, y_pos = argument1;

	// Only draw the room if the room has been visited at least once, or game is in test mode
	if (global.controller.TEST_MODE || visited) {
	    // Draw Room, fading it based on its distance to the current room. Make it blink if it is the current room
	    var room_image_alpha = 1-(distance_to_current_room/global.controller.MAX_MAP_DRAW_DISTANCE);
	    if (global.controller.current_room.id == id && global.controller.number_of_frames_since_game_began mod 2 == 0) { room_image_alpha /= 2; }
	    //if (lit) { draw_sprite_ext(spr_box, 0, x_pos, y_pos, 1, 1, 0, c_red, room_image_alpha/2); }
		draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.875, 0.875, 0, c_white, room_image_alpha);

	    // Draw Room's Exits
	    for (var i = 0; i < 4; i++) {
	        // Change the color of just the locked exits if the game is in test mode
	        if (global.controller.TEST_MODE && locked_exits[i]) { draw_set_color(c_red); }
	        else { draw_set_color(__background_get_colour( )); }
        
	        var x_offset = 0;
	        var y_offset = 0;
	        var x_size = 0.25;
	        var y_size = 0.25;
        
	        if (i == 0) { y_offset = -8; y_size += 0.125; } 
	        if (i == 1) { x_offset = 8; x_size += 0.125; } 
	        if (i == 2) { y_offset = 8; y_size += 0.125; } 
	        if (i == 3) { x_offset = -8; x_size += 0.125; } 

	        if exits[i] draw_sprite_ext(spr_box, 0, x_pos+x_offset, y_pos+y_offset, x_size, y_size, 0, draw_get_color(), 1);
	    }
	    // Draw Room's Stairs
	    draw_set_color(__background_get_colour( ));
	    if exits[4] draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.125, 0.125, 0, draw_get_color(), 1);
	    // Draw Room's Keys if game is in test mode
	    if (global.controller.TEST_MODE && has_key) { draw_set_color(c_red); draw_sprite_ext(spr_box, 0, x_pos-4, y_pos-4, 0.125, 0.125, 0, draw_get_color(), 1); }
    
	    // Draw distance information if testing
	    if (global.controller.TEST_MODE) {
	        draw_set_color(c_lime);
	        draw_set_halign(fa_center);
	        draw_set_valign(fa_middle);
	        if (distance_to_current_room < 9999) { draw_text(x_pos, y_pos, string_hash_to_newline(string(distance_to_current_room))); }
	    }
	}

	// Mark the room as having been drawn, then draw each of its applicable neighbors
	drawn = true;
	if (distance_to_current_room < global.controller.MAX_MAP_DRAW_DISTANCE || game_has_been_lost() || game_has_been_won()) {
	  if (adj_rooms[0] && !adj_rooms[0].drawn && y_pos-16 >= 0) with adj_rooms[0] { obj_room_draw(x_pos, y_pos-16); }
	  if (adj_rooms[1] && !adj_rooms[1].drawn && x_pos+16 <= room_width) with adj_rooms[1] { obj_room_draw(x_pos+16, y_pos); }
	  if (adj_rooms[2] && !adj_rooms[2].drawn && y_pos+16 <= room_height) with adj_rooms[2] { obj_room_draw(x_pos, y_pos+16); }
	  if (adj_rooms[3] && !adj_rooms[3].drawn && x_pos-16 >= 0) with adj_rooms[3] { obj_room_draw(x_pos-16, y_pos); }
	}



}
