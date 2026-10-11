/// @description Step

event_inherited();

// Hands revived by a rosary wait out their death timer, then come back awake
if (death_timer > 0) { 
	death_timer -= 1; 
	if (death_timer == 0) { play_sound(snd_win, true); activated = true; }
}
else {
	// Go for the newest dropped meat unless it already carries meat. A dormant hand first grabs the item it lies on
	if (!is_existing_instance(right_hand_item) || !is_carrying_item(obj_meat)) {
		var _dropped_meat = get_dropped_meat();
			
		if (is_existing_instance(_dropped_meat) && target_item != _dropped_meat) { 
			if (!activated) { 
				play_sound(snd_laugh, true);
				pick_up_item(target_item, false, directions.right);
				end_target_path();
				xstart = x;
				ystart = y;
			}
			target_item = _dropped_meat;
			target_x = target_item.x;
			target_y = target_item.y;
			activated = true;
		}
	}
		
	// Wake up once the player comes within trap range, unless a solid now stands on it, which destroys it
	if (get_distance_to_instance(global.player) < TRAP_RANGE && !activated) { 
		if (is_solid_at_position(x, y)) { instance_destroy(); }
		else { activated = true; }
	}
	if (activated) {
		// A staff makes it fire resistant, and a special staff makes it float through walls, each at its own depth
		fire_resistant = is_carrying_item(obj_staff);
		floating = is_carrying_special_item(obj_staff);
		if (floating) { depth = INCORPOREAL_ENEMY_DEPTH; }
		else if (fire_resistant) { depth = HANDS_WITH_STAFF_DEPTH; }
				
		// Move around, twice per step
		for (var _i = 0; _i < 2; _i++) {
			if (!is_existing_instance(target_item)) {
				// With no target, run away from the player with whatever it carries
				can_move_on_border = false;
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
					// Move towards New Target if still possible to pick it up
					target_x = target_item.x;
					target_y = target_item.y;
					can_move_on_border = true;
					var _prev_path = target_path, _move_dir = move_towards_coordinates_on_path(floating, fire_resistant, 1);
					if (_move_dir == directions.none) {
						// Give up on unreachable target
						if (_prev_path != noone) { play_sound(snd_give_up, false); }
						target_item = noone;
						end_target_path();
					}
						
					// Sound off when its target changed this step: a laugh for a new target, the give-up sound for none
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
				// Give up on a target that someone else now carries
				play_sound(snd_give_up, false);
				target_item = noone; 
				end_target_path(); 
			}
				
			// Kill other enemies with carried sword
			if (is_carrying_item(obj_sword)) {
				var _enemies_at_position = instance_place_all(x, y, obj_enemy);
				while (array_length(_enemies_at_position) > 0) {
					var _enemy = array_random_pop(_enemies_at_position);
					if (_enemy == id || !_enemy.corporeal) { continue; }
				
					with (_enemy) { kill_with_sword(other.right_hand_item); }
					if (is_existing_instance(right_hand_item)) { continue; }
					else { break; }
				}
			}
		}
			
		// Keep its item with it, facing the same way
		set_instance_to_same_position(right_hand_item);
		with (right_hand_item) { image_xscale = other.image_xscale; }
	}
}