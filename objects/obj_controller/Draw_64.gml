draw_set_font(ft_hud);
var has_won = game_has_been_won();
var has_lost = game_has_been_lost();
var has_timed_out = game_has_timed_out();
var is_looking_at_map = key_space && !has_lost;
var collectables_collected = total_number_of_rooms_with_collectables - array_length(rooms_with_collectables);

if (transition != noone || has_won || has_timed_out || is_looking_at_map) {
	// Draw background over entire screen
	draw_set_color(bg_color);
	draw_rectangle(0, 0, room_width-1, room_height-1, false);

    // Draw map of rooms if applicable
	var hud_x_pos = 4;
    if (is_looking_at_map && !has_won && !has_lost && transition == noone) {
        // Draw each visited room
       for (var i = 0; i < array_length(game_rooms); i++) { game_rooms[i].drawn = false; }
        with current_room {
            draw_room(room_width/2, (room_height/2));
        }

        draw_set_color(bg_color);
        draw_rectangle(0, 0, room_width, 24, false);
        draw_rectangle(0, room_height-40, room_width, room_height, false);

        // Draw progress bar
		var os_offset = (os_type == os_windows) ? 0: 1
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_text(4, 12, string_hash_to_newline("Progress: "));
        draw_rectangle(84, 6, (room_width-4), 18+os_offset, true);

        if (collectables_collected > 0 || array_length(mapped_rooms) > 1) { 
			draw_rectangle(84, 6, get_scaling_amount(84, (room_width-4), collectables_collected+array_length(mapped_rooms)-1, total_number_of_rooms_with_collectables+array_length(game_rooms)-1), 18, false); 
		}
		
		// Draw elapsed time
		var time_elapsed = (time_provided - time_remaining);
		draw_text(hud_x_pos, room_height-12, string_hash_to_newline("Time Elapsed: "+string(floor(time_elapsed/(60)))+":"+zero_padded_string(floor(time_elapsed mod 60), 2)));
		
		// Draw game version
		draw_set_halign(fa_right);
		//draw_text(room_width-4, room_height-12,"ver." + GM_version); 
		draw_set_halign(fa_left);
    }
	
	if (room == rm_finish) {
	    // Draw a winning or losing message
	    if (has_won || has_lost) {
	        draw_set_halign(fa_center);
	        var message;
	        if has_won { draw_set_color(c_white); message = "YOU WIN!" }
	        if has_lost { draw_set_color(c_white); message = "YOU LOSE!" }
	        draw_text(room_width/2, room_height-216, string_hash_to_newline(message));
	        hud_x_pos = room_width/2;
	    }

	    // Draw final score and game seed and game version
		draw_text(hud_x_pos, room_height-20,"ver." + GM_version); 
		draw_text(hud_x_pos, room_height-36, string_hash_to_newline("Game Seed: "+zero_padded_string(random_get_seed(), 9)));	// Draw elapsed time
		var time_elapsed = (time_provided - time_remaining);
		var percentage_of_collectables_collected = floor(100*(collectables_collected/total_number_of_rooms_with_collectables));
		var percentage_of_time_remaining = 100*(time_remaining / time_provided);
		var bonus_for_winning_game = floor(100*(completion_amount/TOTAL_COMPLETION_AMOUNT))
		var percentage_of_rooms_mapped = floor(100*(array_length(mapped_rooms)/array_length(game_rooms)))
		var total_score = floor(percentage_of_collectables_collected + bonus_for_winning_game + percentage_of_time_remaining + percentage_of_rooms_mapped)/4;
	    if (has_won || has_lost) { 
			draw_text(hud_x_pos, room_height-56-16+8, string_hash_to_newline("Final Grade: "+string(total_score)+"%")); 
			draw_text(hud_x_pos, room_height-56-16-16+8, string_hash_to_newline("Difficulty: "+difficulty_string())); 
			draw_text(hud_x_pos, room_height-128-16-16, string_hash_to_newline("Collected: "+string(percentage_of_collectables_collected)+"%")); 
			draw_text(hud_x_pos, room_height-112-16-16, string_hash_to_newline("Mapped: "+string(percentage_of_rooms_mapped)+"%"));
			draw_text(hud_x_pos, room_height-96-16-16, string_hash_to_newline("Time Left: "+string(percentage_of_time_remaining)+"%")); 
			if (completion_amount > 0) { draw_text(hud_x_pos, room_height-96-16, string_hash_to_newline("Victory: "+string(bonus_for_winning_game)+"%")); }
			draw_text(hud_x_pos, room_height-160-16-16, string_hash_to_newline("Time Elapsed: "+string(floor(time_elapsed/(60)))+":"+zero_padded_string(floor(time_elapsed mod 60), 2)));
		}
	}

}

if (TEST_MODE) { 
	draw_set_halign(fa_left);
	draw_set_color(c_lime);
	if (global.player != noone) { draw_text(4, room_height-20, string(global.player.dir) + "; " + string(global.player.dir_prev)); }
	//draw_text(4, room_height-20, string(fps)+"; "+string(random_get_seed())+"; "+string(current_room.id)+"; "+string(current_room.visited));
	//draw_text(4, room_height-40, string(one_exits)+"; "+string(two_exits_opp)+"; "+string(two_exits_perp)+"; "+string(three_exits)+"; "+string(four_exits)+"= "+string(avg_exits)+" / "+string(array_length(game_rooms)));
	//draw_text(4, room_height-20, string(fps)+"; "+string(random_get_seed())+"; "+string(current_room.id));
	//draw_text(4, room_height-20, string(array_length(rooms_with_key))+" "+string(array_length(rooms_with_torch))+" "+string(array_length(rooms_with_sword))+" "+string(array_length(rooms_with_rosary))+" "+string(array_length(rooms_with_map)));
}

