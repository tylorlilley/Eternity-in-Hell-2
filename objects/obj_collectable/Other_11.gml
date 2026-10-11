/// @description Step
var _player = global.player;
visible = !is_blink_frame();

if (is_instance_at_coordinates(x, y, _player)) {
	if (instance_number(obj_collectable) == 1) {
	    // You are collecting the final collectable in the room
		play_sound(snd_mana2, true);
		with global.controller {
			current_room.has_collectables = false;
			array_remove_first(rooms_with_collectables, current_room);
			if (are_all_collectables_collected()) {
				if (instance_number(obj_encased_heart) == 0) { screen_flash(); }
				play_sound(snd_shatter, false); 
				completion_amount += 1;
			}
		}
	}
	else { play_sound(snd_mana, true); }
	increment_run_stat("total_collectables_collected");
	instance_destroy();
}

var _sucked_in = false;
with (_player) {
	if (is_carrying_special_item(obj_compass)) { _sucked_in = true; }
}


if (_sucked_in) {
	if (get_random_chance_out_of(3)) {
		target_x = _player.x;
		target_y = _player.y;
		set_automatic_target_path();
		move_towards_coordinates_on_path(false, true, 1, false);
		play_sound(snd_clock_tick, false);
	}
}
else if moving { run_away_from_player(false, false, true); }

event_inherited();

