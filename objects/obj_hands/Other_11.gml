/// @description Step

event_inherited();

if (death_timer > 0) { 
	death_timer -= 1; 
	if (death_timer == 0) { play_sound(snd_win, true); activated = true; }
}
else {
	// Make any dropped meat that can be moved towards a target
	if (!is_existing_instance(right_hand_item) || !is_carrying_item(obj_meat)) {
		var dropped_meat = get_dropped_meat();
			
		if (is_existing_instance(dropped_meat) && target_item != dropped_meat) { 
			if (!activated) { 
				play_sound(snd_laugh, true);
				pick_up_item(target_item, false, directions.right);
				end_target_path();
				xstart = x;
				ystart = y;
			}
			target_item = dropped_meat;
			target_x = target_item.x;
			target_y = target_item.y;
			activated = true;
		}
	}
		
	if (get_distance_to_instance(global.player) < TRAP_RANGE && !activated) { 
		if (is_solid_at_position(x, y)) { instance_destroy(); }
		else { activated = true; }
	}
	if (activated) {
		fire_resistant = is_carrying_item(obj_staff);
		floating = is_carrying_special_item(obj_staff);
		if (floating) { depth = INCORPOREAL_ENEMY_DEPTH; }
		else if (fire_resistant) { depth = HANDS_WITH_STAFF_DEPTH; }
				
		// Move Around
		for (var i = 0; i < 2; i++) {
			if (!is_existing_instance(target_item)) {
				// Run Away From Player While Carrying Target
				run_away_from_player(floating, fire_resistant, true);
			}
			else if (is_existing_instance(target_item) && (!is_existing_instance(target_item.holder) || target_item.holder == id)) {
				if (x == target_item.x && y == target_item.y) {
					// Pick Up New Item and Drop Current
					play_sound(snd_laugh, true);
					put_down_item(right_hand_item, false, true);
					pick_up_item(target_item, false, directions.right);
					target_item = noone;
					end_target_path();
					xstart = x;
					ystart = y;
				}
				else if (!is_existing_instance(target_item.holder)) {
					// Move Towards New Target if still possible to pick it up
					target_x = target_item.x;
					target_y = target_item.y;
					var prev_path = target_path, move_dir = move_towards_coordinates_on_path(floating, fire_resistant, 1);
					if (move_dir == directions.none) {
						// Give up on unreachable target
						if (prev_path != noone) { play_sound(snd_give_up, false); }
						target_item = noone;
						end_target_path();
					}
						
					if (prev_target_item != target_item) { 
						if (target_item == noone) { play_sound(snd_give_up, true); }
						else { play_sound(snd_laugh, true); }
					}
				}
				else { 
					target_item = noone; 
					end_target_path(); 
				}
			}
			else if (target_item != noone) {
				// Give up on carried or non-existant target
				play_sound(snd_give_up, false);
				target_item = noone; 
				end_target_path(); 
			}
				
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
}