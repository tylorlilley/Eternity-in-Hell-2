if (can_process_this_frame()) {
	if (death_timer > 0) { 
		death_timer -= 1; 
		if (death_timer == 0) { play_sound(snd_win, false); activated = true; }
	}
	else {
		if (get_distance_to_instance(global.player) < TRAP_RANGE && !activated) { 
			if (is_solid_at_position(x, y)) { instance_destroy(); }
			else { activated = true; }
		}
		if (activated) {
			fire_resistant = is_carrying_item(obj_staff);
			depth = (fire_resistant) ? -4 : 0;
				
			// Move Around
			for (var i = 0; i < 2; i++) {
				if (!is_existing_instance(target_item)) {
					// Run Away From Player While Carrying Target
					run_away_from_player(!corporeal, fire_resistant, true);
				}
				else if (is_existing_instance(target_item) && (!is_existing_instance(target_item.holder) || target_item.holder == id)) {
					if (x == target_item.x && y == target_item.y) {
						// Pick Up New Item and Drop Current
						play_sound(snd_laugh, true);
						if (is_existing_instance(right_hand_item)) { put_down_item(right_hand_item, false, true); }
						pick_up_item(target_item, false, directions.right);
						target_item = noone;
						xstart = x;
						ystart = y;
					}
					else if (!is_existing_instance(target_item.holder)) {
						// Move Towards New Target if still possible to pick it up
						var move_dir = move_towards_coordinates(target_item.x, target_item.y, !corporeal, fire_resistant);
						if (move_dir == directions.none) { 
							if (target_item.object_index != obj_meat) { play_sound(snd_give_up, false); }
							target_item = noone;  
						}
					}
					else { target_item = noone; }
				}
				else { target_item = noone; }
				
				// Kill other enemies with carried sword
				if (is_carrying_item(obj_sword)) {
					var enemies_at_position = instance_place_all(x, y, obj_enemy);
					while (array_length(enemies_at_position) > 0) {
						var enemy = array_random_pop(enemies_at_position);
						if (enemy == id || !enemy.corporeal) { continue; }
				
						with (enemy) { kill_with_sword(other.right_hand_item); }
						if (is_existing_instance(right_hand_item)) { continue; }
						else { break; }
					}
				}
			}
			
			set_instance_to_same_position(right_hand_item);
			with (right_hand_item) { image_xscale = other.image_xscale; }
		}
	
		// Make any dropped meat that can be moved towards a target
		if (!is_existing_instance(right_hand_item) || !is_carrying_item(obj_meat)) {
			var dropped_meat = get_dropped_meat();
			
			if (is_existing_instance(dropped_meat) && target_item != dropped_meat) { 
				if (!activated) { play_sound(snd_laugh, true); }
				target_item = dropped_meat; 
				activated = true;
			}
		}
	}
	
	event_inherited();
}
