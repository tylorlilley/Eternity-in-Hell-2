// If this frame should be processed
var game_manager = global.game_manager;
var key_space = game_manager.key_space;

draw_set_font(ft_hud);
var has_won = is_game_won();
var has_lost = is_game_lost();
var has_timed_out = is_time_up();
var is_looking_at_map = key_space && !has_lost;
var collectables_collected = total_number_of_rooms_with_collectables - array_length(rooms_with_collectables);
var bg_color = get_game_bg_color(), special_text_color = get_inverted_game_bg_color(), standard_text_color = c_white;

if (transition != directions.none || has_won || has_timed_out || is_looking_at_map) {
	// Draw background over entire screen
	draw_set_color(bg_color);
	draw_rectangle(0, 0, room_width-1, room_height-1, false);

    // Draw map of rooms if applicable
	var hud_x_pos = 4, hud_y_pos = 24;
    if (is_looking_at_map && !has_won && !has_lost && transition == directions.none) {
		if (current_room.has_hall_of_mirrors) {
			// Draw Mirror Directions Instead of Rooms
			if (is_blink_frame()) {
				var display_directions = false, x_pos = (room_width/2)-24;
				with (global.player) {
					display_directions = (global.is_test_mode || is_carrying_item(obj_map));
				}
				for (var i = 0; i < array_length(current_room.mirror_directions); i++) {
					var current_dir = current_room.mirror_directions[i];
					var arrow_image_index = (display_directions) ? 0 : 1, arrow_image_dir = (display_directions) ? current_dir*-90 : 0;
					draw_sprite_ext(spr_map_arrows, arrow_image_index, x_pos, room_height/2, 1, 1, arrow_image_dir, c_white, 1);
					x_pos += 16;
				}
			}
		}
		else {
			// Draw each visited room
			var x_origin = (room_width/2) - (current_room.virtual_x * 16), y_origin = (room_height/2) - (current_room.virtual_y * 16)
			for (var i = 0; i < array_length(game_rooms); i++) {
				var next_room = game_rooms[i];
				var x_pos = (next_room.virtual_x * 16), y_pos = (next_room.virtual_y * 16);
				next_room.draw_room(x_origin + x_pos, y_origin + y_pos);
			}
		}

        // Draw progress bar		
		draw_set_color(bg_color);
		draw_rectangle(0, 0, room_width-1, 24, false);
		
        draw_set_color(standard_text_color);
        draw_set_halign(fa_left);
        draw_text(4, 12, string_hash_to_newline("Progress: "));
		draw_sprite_ext(spr_progress_bar, 1, 84, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 96, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 112, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 128, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 144, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 160, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 176, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 192, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 208, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 2, 224, 14, 1, 1, 0, c_white, 1);
		draw_sprite_ext(spr_progress_bar, 3, 228, 14, 1, 1, 0, c_white, 1);

        if (collectables_collected > 0 || array_length(mapped_rooms) > 1) {
			var progress_percentage = ((5*collectables_collected)+array_length(mapped_rooms)-1) / ((5*total_number_of_rooms_with_collectables)+array_length(game_rooms)-1);
			draw_sprite_ext(spr_progress_bar, 0, 84, 14, 10*progress_percentage, 1, 0, c_white, 1);
			//draw_rectangle(84, 6, get_scaling_amount(84, (room_width-8), (5*collectables_collected)+array_length(mapped_rooms)-1, (5*total_number_of_rooms_with_collectables)+array_length(game_rooms)-1), 18, false); 
		}
		
		// Draw elapsed time
		draw_set_color(bg_color);
		draw_rectangle(0, room_height-24, room_width-1, room_height, false);
        draw_set_color(standard_text_color);
		
		var time_elapsed = (time_provided - time_remaining);
		draw_text(hud_x_pos, room_height-12, "Time Elapsed: ");
        draw_set_halign(fa_right);
		draw_text(room_width-32, room_height-12, string_hash_to_newline(string(floor(time_elapsed/(60)))+":"+get_zero_padded_string(floor(modulo(time_elapsed, 60)), 2)));
		draw_sprite(get_sprite_to_use(spr_clock), get_clock_image_index(), room_width-12, room_height-12);
    }
	
	if (room == rm_finish) {
	    // Draw main win or loss message
	    draw_set_halign(fa_center);
		draw_set_color(special_text_color);
		hud_x_pos = room_width/2;
	    var main_message = (has_won) ? "YOU WIN!" : "Killed By:    ";
	    if (has_lost) { draw_death_type_sprite(room_width/2+40, hud_y_pos, killed_by); }
	    draw_text(hud_x_pos, hud_y_pos, main_message);
		draw_set_color(standard_text_color);
		
	    // Draw final score information
		draw_text(hud_x_pos, hud_y_pos + (1.5*16), string_hash_to_newline(get_difficulty_string(global.difficulty))); 
		var time_elapsed = (time_provided - time_remaining);
		draw_text(hud_x_pos, hud_y_pos + (2.5*16), string_hash_to_newline("Time Elapsed: "+string(floor(time_elapsed/(60)))+":"+get_zero_padded_string(floor(modulo(time_elapsed, 60)), 2)));
		if ((has_won && death_count > 0) || (has_lost && death_count > 1)) { draw_text(hud_x_pos, hud_y_pos + (3.5*16), string_hash_to_newline("Deaths: "+string(death_count))); }
		if (used_special_items > 0) { draw_text(hud_x_pos, hud_y_pos + (4.5*16), string_hash_to_newline("Cursed Items Used: "+string(used_special_items))); }
		// Half-Line-Break
		draw_text(hud_x_pos, hud_y_pos + (6*16), string_hash_to_newline("Collected: "+get_percentage_string(get_collectables_score()))); 
		draw_text(hud_x_pos, hud_y_pos + (7*16), string_hash_to_newline("Mapped: "+get_percentage_string(get_mapped_rooms_score())));
		draw_text(hud_x_pos, hud_y_pos + (8*16), string_hash_to_newline("Time Left: "+get_percentage_string(get_time_remaining_score())));
		if (completion_amount > 0) { draw_text(hud_x_pos, hud_y_pos + (9*16), string_hash_to_newline("Escaped: "+get_percentage_string(get_victory_amount_score()))); }
		if (has_won > 0) { draw_text(hud_x_pos, hud_y_pos + (10*16), string_hash_to_newline("Preperation: "+string(get_item_hands_score()))); }
		draw_set_color(special_text_color);
		// Half-Line-Break
		draw_text(hud_x_pos, hud_y_pos + (11.5*16), string_hash_to_newline("Final Grade: "+get_percentage_string( get_current_score())));
		
		// Draw game seed information
		if (global.is_test_mode) {
			draw_text(hud_x_pos, hud_y_pos + (12.5*16), string_hash_to_newline("Game Seed: "+get_zero_padded_string(random_get_seed(), 9)));
			draw_text(hud_x_pos, hud_y_pos + (13.5*16),"ver." + GM_version); 
		}
		else {
			draw_set_color(special_text_color);
			// 12.5 blank line
			draw_text(room_width/2, hud_y_pos + (13.5*16), get_input_enter_key_string() + ": Return");
			draw_set_color(standard_text_color);
		}
		draw_set_color(standard_text_color);
	}

}



if (global.is_test_mode && !has_won && !has_lost) { 
	draw_set_halign(fa_left);
	draw_set_color(c_lime);
	//if (is_existing_instance(global.player)) { draw_text(4, room_height-20, string(global.player.dir) + "; " + string(global.player.dir_prev)); }
	//draw_text(4, room_height-20, string(fps)+"; "+string(random_get_seed())+"; "+string(current_room.id)+"; "+string(current_room.visited));
	//draw_text(4, room_height-40, string(one_exits)+"; "+string(two_exits_opp)+"; "+string(two_exits_perp)+"; "+string(three_exits)+"; "+string(four_exits)+"= "+string(avg_exits)+" / "+string(array_length(game_rooms)));
	draw_text(4, room_height-20, string(fps)+"; OLD: "+string(current_room.old_room_reference_difficulty)+"; NEW: "+string(current_room.room_reference_difficulty)+"; "); //+string(current_room.id));
}
