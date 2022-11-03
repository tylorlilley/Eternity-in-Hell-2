draw_set_font(ft_hud);
var has_won = game_has_been_won();
var has_lost = game_has_been_lost();
var has_timed_out = game_has_timed_out();
var is_looking_at_map = key_space && !has_lost;
var collectables_collected = total_number_of_rooms_with_collectables - array_length(rooms_with_collectables);

if (transition || has_won || has_timed_out || is_looking_at_map) {
	// Draw background over entire screen
	draw_set_color(bg_color);
	draw_rectangle(0, 0, room_width, room_height, false);

    // Draw map of rooms if applicable
	var hud_x_pos = 4;
    if (is_looking_at_map && !has_won && !has_lost && !transition) {
        // Draw each visited room
       for (var i = 0; i < array_length(game_rooms); i++) { game_rooms[i].drawn = false; }
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
        draw_rectangle(84, 6, (room_width-4), 18, true);

        if (collectables_collected > 0) { 
			draw_rectangle(84, 6, get_scaling_amount(84, (room_width-4), collectables_collected, total_number_of_rooms_with_collectables), 18, false); 
		}
		
		// Draw elapsed time
		var time_elapsed = (time_provided - time_remaining);
		draw_text(hud_x_pos, room_height-20, string_hash_to_newline("Time Elapsed: "+string(floor(time_elapsed/(60)))+":"+zero_padded_string(floor(time_elapsed mod 60), 2)));
		
		// Draw game version
		draw_set_halign(fa_right);
		draw_text(room_width-4, room_height-20,"ver." + GM_version); 
		draw_set_halign(fa_left);
    }
	
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

	    // Draw final score and game seed and game version
		draw_text(hud_x_pos, room_height-20,"ver." + GM_version); 
		draw_text(hud_x_pos, room_height-36, string_hash_to_newline("Game Seed: "+string(random_get_seed())));	// Draw elapsed time
		var time_elapsed = (time_provided - time_remaining);
		draw_text(hud_x_pos, room_height-52, string_hash_to_newline("Time Elapsed: "+string(floor(time_elapsed/(60)))+":"+zero_padded_string(floor(time_elapsed mod 60), 2)));
		var percentage_of_collectables_collected = floor(100*(collectables_collected/total_number_of_rooms_with_collectables));
		var percentage_of_time_remaining = 100*(time_remaining / time_provided);
		var bonus_for_winning_game = floor(100*(completion_amount/TOTAL_COMPLETION_AMOUNT))
		var total_score = floor(percentage_of_collectables_collected + bonus_for_winning_game + percentage_of_time_remaining)/3;
		var difficulty_string = "";
		switch (difficulty) {
			case difficulties.easy: { difficulty_string = "Minute"; break; }
			case difficulties.medium: { difficulty_string = "Lifetime"; break; }
			case difficulties.hard: { difficulty_string = "Eons"; break; }
			case difficulties.hell: { difficulty_string = "Eternity"; break; }
		}
		difficulty_string += " in Hell";
	    if (has_won || has_lost) { 
			draw_text(hud_x_pos, room_height-160, string_hash_to_newline("Collected: "+string(percentage_of_collectables_collected)+"%")); 
			draw_text(hud_x_pos, room_height-144, string_hash_to_newline("Time Left: "+string(percentage_of_time_remaining)+"%")); 
			draw_text(hud_x_pos, room_height-128, string_hash_to_newline("Victory: "+string(bonus_for_winning_game)+"%")); 
			draw_text(hud_x_pos, room_height-96, string_hash_to_newline("Final Grade: "+string(total_score)+"%")); 
			draw_text(hud_x_pos, room_height-80, string_hash_to_newline("Difficulty: "+difficulty_string)); 
		}
	}

}

if (TEST_MODE) { 
	draw_set_halign(fa_left);
	draw_set_color(c_lime);
	//draw_text(4, room_height-20, string(fps)+"; "+string(random_get_seed())+"; "+string(current_room.id)+"; "+string(current_room.visited));
	draw_text(4, room_height-40, string(one_exits)+"; "+string(two_exits)+"; "+string(three_exits)+"; "+string(four_exits)+"= "+string(avg_exits));
	draw_text(4, room_height-20, string(fps)+"; "+string(random_get_seed())+"; "+string(current_room.id));
	//draw_text(4, room_height-20, string(array_length(rooms_with_key))+" "+string(array_length(rooms_with_torch))+" "+string(array_length(rooms_with_sword))+" "+string(array_length(rooms_with_rosary))+" "+string(array_length(rooms_with_map)));
}

