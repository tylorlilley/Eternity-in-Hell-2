if (process_this_frame()) {
	if (!visible) {
		if (distance_to_instance(global.player) < TRAP_DISTANCE && !visible) { 
			visible = true;
			play_sound(snd_laugh, true);
			with carried_items[1] { pick_up_item(1, false, other); }
		}
	}
	else {
		run_away_from_player();
		run_away_from_player();
		set_instance_to_same_position(carried_items[1]);
	}

	event_inherited();
}
