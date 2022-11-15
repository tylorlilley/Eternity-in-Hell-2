if (process_this_frame()) {
	if (distance_to_instance(global.player) < TRAP_DISTANCE && !visible) { visible = true; lethal = true; }
	if (visible) {
		for (var i = 0; i < 2; i++) {
			if (target_item == noone) {
				// Run Away From Player While Carrying Target
				run_away_from_player();
			}
			else if (instance_exists(target_item)) {
				if (x == target_item.x && y == target_item.y) {
					// Pick Up New Item and Drop Current
					play_sound(snd_laugh, true);
					with carried_items[1] { drop_item(1, false); }
					with target_item { pick_up_item(1, false, other); }
					target_item = noone;
					xstart = x;
					ystart = y;
				}
				else if (!target_item.carried) {
					// Move Towards New Target if still possible to pick it up
					var move_dir = move_towards_coordinates(target_item.x, target_item.y, false, false);
					if (move_dir == noone) { target_item = noone; play_sound(snd_give_up, false); }
				}
				else { target_item = noone; }
			}
			else { target_item = noone; }
		}
		
		set_instance_to_same_position(carried_items[1]);
	}

	event_inherited();
}
