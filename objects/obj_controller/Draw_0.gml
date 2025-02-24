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
		draw_sprite(get_sprite_to_use(spr_clock), 0, room_width-12, room_height-12);
		draw_sprite(get_sprite_to_use(spr_clock_sand), get_clock_image_index(), room_width-12, room_height-12);
    }
	
	if (room == rm_finish) {
		// Draw Background
		bg_color = (has_won) ? c_white : c_black;
		standard_text_color = (has_won) ? c_black : c_white;
		special_text_color = get_game_color();
		draw_set_color(bg_color);
		draw_rectangle(0, 0, room_width-1, room_height-1, false);
	
		// Draw Border
		draw_set_color(c_black);
		var wall_spr = (has_won) ? spr_wall_inverted : spr_wall, wall_sprite_color = merge_color(c_white, c_black, 0.5);
		for (var border_x_pos = -8; border_x_pos < room_width+8; border_x_pos += 16;) {
			draw_sprite_ext(wall_spr, 0, border_x_pos, 8, 1, 1, 0, wall_sprite_color, 1);
			draw_sprite_ext(wall_spr, 0, border_x_pos, 8+(16*2), 1, 1, 0, wall_sprite_color, 1);
			draw_sprite_ext(wall_spr, 0, border_x_pos, 8+(16*4), 1, 1, 0, wall_sprite_color, 1);
			draw_sprite_ext(wall_spr, 0, border_x_pos, room_height-8-(16*4), 1, 1, 0, wall_sprite_color, 1);
			draw_sprite_ext(wall_spr, 0, border_x_pos, room_height-8-(16*2), 1, 1, 0, wall_sprite_color, 1);
			draw_sprite_ext(wall_spr, 0, border_x_pos, room_height-8, 1, 1, 0, wall_sprite_color, 1);
		}
		for (var border_y_pos = -8; border_y_pos < room_width+8; border_y_pos += 16;) {
			draw_sprite_ext(wall_spr, 0, 8, border_y_pos, 1, 1, 0, wall_sprite_color, 1);
			draw_sprite_ext(wall_spr, 0, room_width-8, border_y_pos, 1, 1, 0, wall_sprite_color, 1);
		}
		
	    // Draw main win or loss message
	    draw_set_halign(fa_center);
		draw_set_color(special_text_color);
		hud_x_pos = room_width/2;
	    var main_message = (has_won) ? "YOU WIN!" : "Killed By:    ";
	    if (has_lost) { draw_death_type_sprite(room_width/2+40, hud_y_pos, killed_by); }
	    draw_text(hud_x_pos, hud_y_pos, main_message);
		draw_set_color(standard_text_color);
		draw_text(hud_x_pos, hud_y_pos + (2*16), string_hash_to_newline(get_difficulty_string(global.difficulty)));
		
	    // Draw final score information
		hud_y_pos = 8+(16*5)-4;
		draw_set_font(ft_hud_small);
		calculate_evaluation_messages_and_score();
		
		// Draw Evaluation Messages
		if (evaluation_pos > 0 && is_blink_frame()) { draw_sprite_ext(spr_menu_arrow, 0, room_width/2, hud_y_pos, 1, 1, 90, c_white, 1); }
		for (var i = evaluation_pos; i < evaluation_pos+6; i++) {
			hud_y_pos += 12;
			if (i >= array_length(evaluation_messages)) { break; }
			var next_message = evaluation_messages[i], message_text = next_message[0], use_special_text_color = next_message[1];
			draw_set_color(use_special_text_color ? special_text_color : standard_text_color);
			draw_text(hud_x_pos, hud_y_pos, message_text);
		}
		hud_y_pos += 12;
		if (evaluation_pos < array_length(evaluation_messages)-6 && is_blink_frame()) { draw_sprite_ext(spr_menu_arrow, 0, room_width/2, hud_y_pos, 1, 1, -90, c_white, 1); }
		draw_set_font(ft_hud)
		draw_set_color(special_text_color);
		draw_text(hud_x_pos, room_height-24-24-8, string_hash_to_newline("Final Grade: "+get_percentage_string( global.controller.current_score )));
		
		// Draw game seed information
		if (global.is_test_mode) {
			draw_text(hud_x_pos, room_height-24, string_hash_to_newline("Game Seed: "+get_zero_padded_string(random_get_seed(), 9)));
		}
		else {
			draw_set_color(special_text_color);
			// 12.5 blank line
			draw_text(room_width/2, room_height-24, get_input_enter_key_string() + ": Return");
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
	//draw_text(4, room_height-20, string(fps)+"; OLD: "+string(current_room.old_room_reference_difficulty)+"; NEW: "+string(current_room.room_reference_difficulty)+"; "); //+string(current_room.id));
	draw_text(4, room_height-20, room_get_name(current_room.room_reference));
}
