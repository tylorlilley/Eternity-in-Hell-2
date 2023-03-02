// If this frame should be processed
var game_manager = global.game_manager;
var key_space = game_manager.key_space;

draw_set_font(ft_hud);
var has_won = is_game_won();
var has_lost = is_game_lost();
var has_timed_out = is_time_up();
var is_looking_at_map = key_space && !has_lost;
var collectables_collected = total_number_of_rooms_with_collectables - array_length(rooms_with_collectables);

if (transition != directions.none || has_won || has_timed_out || is_looking_at_map) {
	// Draw background over entire screen
	draw_set_color(global.bg_color);
	draw_rectangle(0, 0, room_width-1, room_height-1, false);

    // Draw map of rooms if applicable
	var hud_x_pos = 4;
    if (is_looking_at_map && !has_won && !has_lost && transition == directions.none) {
        // Draw each visited room
		var x_origin = (room_width/2) - (current_room.virtual_x * 16), y_origin = (room_height/2) - (current_room.virtual_y * 16)
		for (var i = 0; i < array_length(game_rooms); i++) {
			var next_room = game_rooms[i];
			var x_pos = (next_room.virtual_x * 16), y_pos = (next_room.virtual_y * 16);
			next_room.draw_room(x_origin + x_pos, y_origin + y_pos);
		}

        // Draw progress bar
		var os_offset = (os_type == os_windows) ? 0: 1
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_text(4, 12, string_hash_to_newline("Progress: "));
		draw_sprite_ext(spr_progress_bar, 1, 84, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 96, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 112, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 128, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 144, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 160, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 176, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 192, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 208, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 224, 12, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 3, 228, 12, 1, 1, 0, c_white, 1);
       // draw_rectangle(84, 6, (room_width-8), 18+os_offset, true);

        if (collectables_collected > 0 || array_length(mapped_rooms) > 1) {
			var progress_percentage = ((5*collectables_collected)+array_length(mapped_rooms)-1) / ((5*total_number_of_rooms_with_collectables)+array_length(game_rooms)-1);
			draw_sprite_ext(spr_progress_bar, 0, 84, 12, 10*progress_percentage, 1, 0, c_white, 1);
			//draw_rectangle(84, 6, get_scaling_amount(84, (room_width-8), (5*collectables_collected)+array_length(mapped_rooms)-1, (5*total_number_of_rooms_with_collectables)+array_length(game_rooms)-1), 18, false); 
		}
		
		// Draw elapsed time
		var time_elapsed = (time_provided - time_remaining);
		draw_text(hud_x_pos, room_height-12, "Time Elapsed: ");
        draw_set_halign(fa_right);
		draw_text(room_width-32, room_height-12, string_hash_to_newline(string(floor(time_elapsed/(60)))+":"+get_zero_padded_string(floor(modulo(time_elapsed, 60)), 2)));
		draw_sprite(get_sprite_to_use(spr_clock), get_clock_image_index(), room_width-12, room_height-12);
    }
	
	if (room == rm_finish) {
	    // Draw a winning or losing message
	    if (has_won || has_lost) {
	        draw_set_halign(fa_center);
	        var message;
	        if has_won { draw_set_color(c_white); message = "YOU WIN!" }
	        if has_lost { 
				draw_set_color(c_white); message = "Killed By:    "
				draw_death_type_sprite(room_width/2+40, room_height-216, killed_by);
			}
	        draw_text(room_width/2, room_height-216, string_hash_to_newline(message));
	        hud_x_pos = room_width/2;
	    }

	    // Draw final score and game seed and game version
		var total_score = get_current_score();
		
		if (key_space) {
			// Draw game seed information
			draw_text(hud_x_pos, room_height-20,"ver." + GM_version); 
			draw_text(hud_x_pos, room_height-36, string_hash_to_newline("Game Seed: "+get_zero_padded_string(random_get_seed(), 9)));
		}
		
		var time_elapsed = (time_provided - time_remaining);
		var percentage_of_collectables_collected = floor(100*(collectables_collected/total_number_of_rooms_with_collectables));
		var percentage_of_time_remaining = 100*(time_remaining / time_provided);
		var bonus_for_winning_game = floor(100*(completion_amount/TOTAL_COMPLETION_AMOUNT))
		var percentage_of_rooms_mapped = floor(100*(array_length(mapped_rooms)/array_length(game_rooms)))
		if (has_won || has_lost) { 
			draw_text(hud_x_pos, room_height-56-16+8, string_hash_to_newline("Final Grade: "+get_percentage_string(total_score))); 
			draw_text(hud_x_pos, room_height-56-16-16+8, string_hash_to_newline(get_difficulty_string(global.difficulty))); 
			draw_text(hud_x_pos, room_height-128-16-16, string_hash_to_newline("Collected: "+get_percentage_string(percentage_of_collectables_collected))); 
			draw_text(hud_x_pos, room_height-112-16-16, string_hash_to_newline("Mapped: "+get_percentage_string(percentage_of_rooms_mapped)));
			draw_text(hud_x_pos, room_height-96-16-16, string_hash_to_newline("Time Left: "+get_percentage_string(percentage_of_time_remaining))); 
			if (completion_amount > 0) { draw_text(hud_x_pos, room_height-96-16, string_hash_to_newline("Victory: "+get_percentage_string(bonus_for_winning_game))); }
			draw_text(hud_x_pos, room_height-160-16-16, string_hash_to_newline("Time Elapsed: "+string(floor(time_elapsed/(60)))+":"+get_zero_padded_string(floor(modulo(time_elapsed, 60)), 2)));
		}
	}

}



if (global.is_test_mode) { 
	draw_set_halign(fa_left);
	draw_set_color(c_lime);
	//if (is_existing_instance(global.player)) { draw_text(4, room_height-20, string(global.player.dir) + "; " + string(global.player.dir_prev)); }
	//draw_text(4, room_height-20, string(fps)+"; "+string(random_get_seed())+"; "+string(current_room.id)+"; "+string(current_room.visited));
	//draw_text(4, room_height-40, string(one_exits)+"; "+string(two_exits_opp)+"; "+string(two_exits_perp)+"; "+string(three_exits)+"; "+string(four_exits)+"= "+string(avg_exits)+" / "+string(array_length(game_rooms)));
	draw_text(4, room_height-20, string(fps)+"; "+string(random_get_seed())+"; "); //+string(current_room.id));
}
