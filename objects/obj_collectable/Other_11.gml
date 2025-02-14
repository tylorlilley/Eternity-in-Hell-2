/// @description Step
var player = global.player;
visible = !is_blink_frame();

if (is_instance_at_coordinates(x, y, player)) {
	if (instance_number(obj_collectable) == 1) {
	    // You are collecting the final collectable in the room
		play_sound(snd_mana2, true);
		with global.controller {
			current_room.has_collectables = false;
			array_remove(rooms_with_collectables, current_room);
			if (are_all_collectables_collected()) {
				if (instance_number(obj_encased_heart) == 0) { screen_flash(); }
				play_sound(snd_shatter, false); 
				completion_amount += 1;
			}
		}
	}
	else { play_sound(snd_mana, true); }
	instance_destroy();
}

var sucked_in = false;
with (player) {
	if (is_carrying_special_item(obj_compass)) { sucked_in = true; }
}


if (sucked_in) {
	if (get_random_chance_out_of(3)) {
		target_x = player.x;
		target_y = player.y;
		set_automatic_target_path();
		move_towards_coordinates_on_path(false, true, 1, false);
		play_sound(snd_clock_tick, false);
	}
}
else if moving { run_away_from_player(false, false, true); }

event_inherited();

