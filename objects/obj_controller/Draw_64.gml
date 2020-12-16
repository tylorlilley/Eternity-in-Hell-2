draw_set_font(ft_hud);
var has_won = game_has_been_won();
var has_lost = game_has_been_lost();
var is_looking_at_map = key_space;

if (transition) {
	// Draw background over entire screen
	draw_set_color(global.controller.bg_color);
	draw_rectangle(0, 0, room_width, room_height, false);
}
if (has_won || has_lost || is_looking_at_map) {
    // Draw background over entire screen
    draw_set_color(global.controller.bg_color);
    draw_rectangle(0, 0, room_width, room_height, false);

    // Draw map of rooms if applicable
    if (is_looking_at_map && !has_won && !has_lost) {
        // Draw each visited room
        with obj_room { drawn = false; }
        with current_room {
            draw_room(room_width/2, (room_height/2));
        }

        draw_set_color(global.controller.bg_color);
        draw_rectangle(0, 0, room_width, 24, false);
        draw_rectangle(0, room_height-40, room_width, room_height, false);

        // Draw progress bar
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_text(4, 4, string_hash_to_newline("Progress: "));
        draw_rectangle(80, 10, (room_width-4), 19, true);
        if (rooms_with_collectables_collected > 0) { draw_rectangle(80, 10, get_scaling_amount(80, (room_width-4), rooms_with_collectables_collected, rooms_with_collectables), 18, false); }
        draw_sprite(spr_key, 0, 12, 32);
        draw_text(24, 24, string_hash_to_newline("x "+string(collected_keys)));
    }

    // Draw a message if applicable
    var hud_x_pos = 4
    if (has_won || has_lost) {
        draw_set_halign(fa_center);
        var message;
        if has_won { draw_set_color(c_white); message = "YOU WIN!" }
        if has_lost { draw_set_color(c_black); message = "YOU LOSE!" }
        draw_text(room_width/2, (room_height/2)-8, string_hash_to_newline(message));
        hud_x_pos = room_width/2;
    }

    // Draw time and score
    var time_in_seconds = (number_of_frames_since_game_began/game_get_speed(gamespeed_fps));
    draw_text(hud_x_pos, room_height-20, string_hash_to_newline("Time Elapsed: "+string(floor(time_in_seconds/(60)))+":"+zero_padded_string(floor(time_in_seconds mod 60), 2)));
    if (has_won || has_lost) { draw_text(hud_x_pos, room_height-36, string_hash_to_newline("Score: "+zero_padded_string(floor(points*rooms_with_collectables), 4))); }
}

