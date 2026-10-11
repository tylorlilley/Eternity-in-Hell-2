// If this frame should be processed
var _game_manager = global.game_manager;
var _key_space = _game_manager.key_space;

draw_set_font(ft_hud);
var _has_won = is_game_won();
var _has_lost = is_game_lost();
var _has_timed_out = is_time_up();
var _is_looking_at_map = _key_space && !_has_lost;
var _collectables_collected = total_number_of_rooms_with_collectables - array_length(rooms_with_collectables);
var _bg_color = get_game_bg_color(), _special_text_color = get_inverted_game_color(), _standard_text_color = c_white;

if (transition != directions.none || _has_won || _has_timed_out || _is_looking_at_map) {
	// Draw background over entire screen
	draw_set_color(_bg_color);
	draw_rectangle(0, 0, room_width-1, room_height-1, false);

    // Draw map of rooms if applicable
	var _hud_x_pos = 4, _hud_y_pos = 24;
    if (_is_looking_at_map && !_has_won && !_has_lost && transition == directions.none) {
		if (current_room.has_hall_of_mirrors) {
			// Draw Mirror Directions Instead of Rooms
			if (is_blink_frame()) {
				var _display_directions = false, _x_pos = (room_width/2)-24;
				with (global.player) {
					_display_directions = (global.is_test_mode || is_carrying_item(obj_map));
				}
				for (var _i = 0; _i < array_length(current_room.mirror_directions); _i++) {
					var _current_dir = current_room.mirror_directions[_i];
					var _arrow_image_index = (_display_directions) ? 0 : 1, _arrow_image_dir = (_display_directions) ? _current_dir*-90 : 0;
					draw_sprite_ext(spr_map_arrows, _arrow_image_index, _x_pos, room_height/2, 1, 1, _arrow_image_dir, c_white, 1);
					_x_pos += 16;
				}
			}
		}
		else {
			// Draw each visited room
			var _x_origin = (room_width/2) - (current_room.virtual_x * 16), _y_origin = (room_height/2) - (current_room.virtual_y * 16)
			for (var _i = 0; _i < array_length(game_rooms); _i++) {
				var _next_room = game_rooms[_i];
				var _x_pos = (_next_room.virtual_x * 16), _y_pos = (_next_room.virtual_y * 16);
				_next_room.draw_room(_x_origin + _x_pos, _y_origin + _y_pos);
			}
		}

        // Draw progress bar		
		draw_set_color(_bg_color);
		draw_rectangle(0, 0, room_width-1, 24, false);
		
        draw_set_color(_standard_text_color);
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

        if (_collectables_collected > 0 || array_length(mapped_rooms) > 1) {
			var _progress_percentage = ((5*_collectables_collected)+array_length(mapped_rooms)-1) / ((5*total_number_of_rooms_with_collectables)+array_length(game_rooms)-1);
			draw_sprite_ext(spr_progress_bar, 0, 84, 14, 10*_progress_percentage, 1, 0, c_white, 1);
			//draw_rectangle(84, 6, get_scaling_amount(84, (room_width-8), (5*collectables_collected)+array_length(mapped_rooms)-1, (5*total_number_of_rooms_with_collectables)+array_length(game_rooms)-1), 18, false); 
		}
		
		// Draw elapsed time
		draw_set_color(_bg_color);
		draw_rectangle(0, room_height-24, room_width-1, room_height, false);
        draw_set_color(_standard_text_color);
		
		var _time_elapsed = (time_provided - time_remaining);
		draw_text(_hud_x_pos, room_height-12, "Time Elapsed: ");
        draw_set_halign(fa_right);
		draw_text(room_width-32, room_height-12, string_hash_to_newline(string(floor(_time_elapsed/(60)))+":"+get_zero_padded_string(floor(modulo(_time_elapsed, 60)), 2)));
		var _clock_sprite = get_sprite_to_use(spr_clock)
		draw_sprite(_clock_sprite, 0, room_width-12, room_height-12);
		draw_sprite(get_sprite_to_use(spr_clock_sand), (_clock_sprite == spr_clock) ? 0 : 2, room_width-12, room_height-12);
    }
	
	if (room == rm_finish) {
		// Draw Background
		_bg_color = (_has_won) ? c_white : c_black;
		_standard_text_color = (_has_won) ? c_black : c_white;
		_special_text_color = global.gms_game_color;
		draw_set_color(_bg_color);
		draw_rectangle(0, 0, room_width-1, room_height-1, false);
	
		// Draw Border
		draw_set_color(c_black);
		var _wall_spr = (_has_won) ? spr_wall_inverted : spr_wall, _wall_sprite_color = merge_color(c_white, c_black, (_has_won ? 0.125 : 0.5));
		for (var _border_x_pos = -8; _border_x_pos < room_width+8; _border_x_pos += 16;) {
			draw_sprite_ext(_wall_spr, 0, _border_x_pos, 8, 1, 1, 0, _wall_sprite_color, 1);
			draw_sprite_ext(_wall_spr, 0, _border_x_pos, 8+(16*2), 1, 1, 0, _wall_sprite_color, 1);
			draw_sprite_ext(_wall_spr, 0, _border_x_pos, 8+(16*4), 1, 1, 0, _wall_sprite_color, 1);
			draw_sprite_ext(_wall_spr, 0, _border_x_pos, room_height-8-(16*4), 1, 1, 0, _wall_sprite_color, 1);
			draw_sprite_ext(_wall_spr, 0, _border_x_pos, room_height-8-(16*2), 1, 1, 0, _wall_sprite_color, 1);
			draw_sprite_ext(_wall_spr, 0, _border_x_pos, room_height-8, 1, 1, 0, _wall_sprite_color, 1);
		}
		for (var _border_y_pos = -8; _border_y_pos < room_width+8; _border_y_pos += 16;) {
			draw_sprite_ext(_wall_spr, 0, 8, _border_y_pos, 1, 1, 0, _wall_sprite_color, 1);
			draw_sprite_ext(_wall_spr, 0, room_width-8, _border_y_pos, 1, 1, 0, _wall_sprite_color, 1);
		}
		
	    // Draw main win or loss message
	    draw_set_halign(fa_center);
		draw_set_color(_special_text_color);
		_hud_x_pos = room_width/2;
	    var _main_message = (_has_won) ? "YOU WIN!" : "Killed By:    ";
	    if (_has_lost) { draw_death_type_sprite(room_width/2+40, _hud_y_pos, killed_by); }
	    draw_text(_hud_x_pos, _hud_y_pos, _main_message);
		draw_set_color(_standard_text_color);
		draw_text(_hud_x_pos, _hud_y_pos + (2*16), string_hash_to_newline(get_difficulty_string(global.difficulty)));
		
	    // Draw final score information
		_hud_y_pos = 8+(16*5)-2;
		draw_set_font(ft_hud_small);

		// Draw Evaluation Messages
		if (evaluation_pos > 0 && !_game_manager.key_up_pressed) { draw_sprite_ext(spr_menu_arrow, 0, room_width/2, _hud_y_pos, 1, 1, 90, (_has_won ? c_black : c_white), 1); }
		for (var _i = evaluation_pos; _i < evaluation_pos+6; _i++) {
			_hud_y_pos += 12;
			if (_i >= array_length(evaluation_manager.evaluation_messages)) { break; }
			var _next_message = evaluation_manager.evaluation_messages[_i], _message_text = _next_message[0], _use_special_text_color = _next_message[1];
			draw_set_color(_use_special_text_color ? _special_text_color : _standard_text_color);
			draw_text(_hud_x_pos, _hud_y_pos, _message_text);
		}
		_hud_y_pos += 12;
		if (evaluation_pos < array_length(evaluation_manager.evaluation_messages)-6 && !_game_manager.key_down_pressed) { draw_sprite_ext(spr_menu_arrow, 0, room_width/2, _hud_y_pos, 1, 1, -90, (_has_won ? c_black : c_white), 1); }
		draw_set_font(ft_hud)
		draw_set_color(_special_text_color);
		draw_text(_hud_x_pos, room_height-24-24-8, string_hash_to_newline("Final Grade: "+get_percentage_string( global.controller.evaluation_manager.current_score )));
		
		// Draw game seed information
		if (global.is_test_mode) {
			draw_text(_hud_x_pos, room_height-24, string_hash_to_newline("Game Seed: "+get_zero_padded_string(random_get_seed(), 9)));
		}
		else {
			draw_set_color(_special_text_color);
			// 12.5 blank line
			draw_text(room_width/2, room_height-24, get_input_enter_key_string() + ": Return");
			draw_set_color(_standard_text_color);
		}
		draw_set_color(_standard_text_color);
	}

}



if (global.is_test_mode && !_has_won && !_has_lost) { 
	draw_set_halign(fa_left);
	draw_set_color(c_lime);
	//if (is_existing_instance(global.player)) { draw_text(4, room_height-20, string(global.player.dir) + "; " + string(global.player.dir_prev)); }
	//draw_text(4, room_height-20, string(fps)+"; "+string(random_get_seed())+"; "+string(current_room.id)+"; "+string(current_room.visited));
	//draw_text(4, room_height-40, string(one_exits)+"; "+string(two_exits_opp)+"; "+string(two_exits_perp)+"; "+string(three_exits)+"; "+string(four_exits)+"= "+string(avg_exits)+" / "+string(array_length(game_rooms)));
	//draw_text(4, room_height-20, string(fps)+"; OLD: "+string(current_room.old_room_reference_difficulty_score)+"; NEW: "+string(current_room.room_reference_difficulty_score)+"; "); //+string(current_room.id));
	draw_text(4, room_height-20, string(fps)+"; "+room_get_name(current_room.room_reference));
}
