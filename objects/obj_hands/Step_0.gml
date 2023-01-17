if (process_this_frame()) {
	if (distance_to_instance(global.player) < TRAP_DISTANCE && !visible) { visible = true; lethal = true; }
	if (visible) {
		for (var i = 0; i < 2; i++) {
			if (target_item == noone) {
				// Run Away From Player While Carrying Target
				run_away_from_player();
			}
			else if (instance_exists(target_item) && (target_item.holder == noone || target_item.holder == self)) {
				if (x == target_item.x && y == target_item.y) {
					// Pick Up New Item and Drop Current
					play_sound(snd_laugh, true);
					if (carried_items[1] != noone) { put_item_down(1); }
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
	
	// Make any dropped meat that can be moved towards a target
	if (carried_items[1] == noone || carried_items[1].object_index != obj_meat) {
		var dropped_meat = noone;
		with (obj_meat) { if (carried == noone) { dropped_meat = self; } }
		if (dropped_meat != noone && target_item != dropped_meat) { 
			if (!visible) { play_sound(snd_laugh, true); }
			target_item = dropped_meat; 
			visible = true; 
			lethal = true;  
		}
	}
	
	event_inherited();
}
