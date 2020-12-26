draw_set_font(ft_hud);
var has_won = game_has_been_won();
var has_lost = game_has_been_lost();
var has_timed_out = game_has_timed_out();
var is_looking_at_map = key_space && !has_lost;
var collectables_collected = total_number_of_rooms_with_collectables - ds_list_size(rooms_with_collectables);

if (transition || has_won || has_timed_out || is_looking_at_map) {
	// Draw background over entire screen
	draw_set_color(bg_color);
	draw_rectangle(0, 0, room_width, room_height, false);

    // Draw map of rooms if applicable
    if (is_looking_at_map && !has_won && !has_lost && !transition) {
        // Draw each visited room
        with obj_room { drawn = false; }
        with current_room {
            draw_room(room_width/2, (room_height/2));
        }

        draw_set_color(bg_color);
        draw_rectangle(0, 0, room_width, 24, false);
        draw_rectangle(0, room_height-40, room_width, room_height, false);

        // Draw progress bar
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_text(4, 4, string_hash_to_newline("Collected: "));
        draw_rectangle(84, 6, (room_width-4), 19, true);

        if (collectables_collected > 0) { 
			draw_rectangle(84, 6, get_scaling_amount(84, (room_width-4), collectables_collected, total_number_of_rooms_with_collectables), 18, false); 
		}
    }
	
	var hud_x_pos = 4
	if (room == rm_finish) {
	    // Draw a winning or losing message
	    if (has_won || has_lost) {
	        draw_set_halign(fa_center);
	        var message;
	        if has_won { draw_set_color(c_white); message = "YOU WIN!" }
	        if has_lost { draw_set_color(c_white); message = "YOU LOSE!" }
	        draw_text(room_width/2, room_height-208, string_hash_to_newline(message));
	        hud_x_pos = room_width/2;
	    }

	    // Draw final score and game seed
		draw_text(hud_x_pos, room_height-40, string_hash_to_newline("Game Seed: "+string(random_get_seed())));
		var percentage_of_collectables_collected = floor(100*(collectables_collected/total_number_of_rooms_with_collectables));
		var percentage_of_time_remaining = 100*(time_remaining / time_provided);
		var bonus_for_winning_game = game_won ? 100 : 0;
		var total_score = floor(percentage_of_collectables_collected + bonus_for_winning_game + percentage_of_time_remaining)/3;
	    if (has_won || has_lost) { 
			draw_text(hud_x_pos, room_height-160, string_hash_to_newline("Collected: "+string(percentage_of_collectables_collected)+"%")); 
			draw_text(hud_x_pos, room_height-144, string_hash_to_newline("Time Left: "+string(percentage_of_time_remaining)+"%")); 
			draw_text(hud_x_pos, room_height-128, string_hash_to_newline("Victory: "+string(bonus_for_winning_game)+"%")); 
			draw_text(hud_x_pos, room_height-96, string_hash_to_newline("Total Score: "+string(total_score)+"%")); 
		}
	}
	
	// Draw elapsed time
	var time_elapsed = (time_provided - time_remaining);
	draw_text(hud_x_pos, room_height-20, string_hash_to_newline("Time Elapsed: "+string(floor(time_elapsed/(60)))+":"+zero_padded_string(floor(time_elapsed mod 60), 2)));
}

if (TEST_MODE) { 
	draw_set_halign(fa_left);
	draw_set_color(c_lime);
	//draw_text(4, room_height-20, string(fps)+"; "+string(random_get_seed())+"; "+string(current_room.item_type));
	draw_text(4, room_height-20, string(ds_list_size(rooms_with_key))+" "+string(ds_list_size(rooms_with_torch))+" "+string(ds_list_size(rooms_with_sword))+" "+string(ds_list_size(rooms_with_rosary))+" "+string(ds_list_size(rooms_with_map)));
}

