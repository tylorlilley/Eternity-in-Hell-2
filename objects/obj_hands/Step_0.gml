if (process_this_frame()) {
	if (distance_to_instance(global.player) < TRAP_DISTANCE && !visible) { visible = true; lethal = true; }
	if (visible) {
		for (var i = 0; i < 2; i++) {
			var carried_amulet = (carried_items[1] != noone && carried_items[1].object_index == obj_amulet) ? carried_items[1] : noone;
			var carried_sword = (carried_items[1] != noone && carried_items[1].object_index == obj_sword) ? carried_items[1] : noone;
	
			consumed_by_fireball = (carried_amulet == noone);
			consumed_by_lava = (carried_amulet == noone);
			consumed_by_block = (carried_amulet == noone || !carried_amulet.special);
	
			if (target_item == noone) {
				// Run Away From Player While Carrying Target
				run_away_from_player(!consumed_by_block, !consumed_by_lava);
			}
			else if (instance_exists(target_item) && (target_item.holder == noone || target_item.holder == global.controller || target_item.holder == self)) {
				if (x == target_item.x && y == target_item.y) {
					// Pick Up New Item and Drop Current
					play_sound(snd_laugh, true);
					if (carried_items[1] != noone) { put_item_down(1); }
					var new_holder = self;
					with target_item { pick_up_item(1, false, new_holder); }
					target_item = noone;
					xstart = x;
					ystart = y;
				}
				else if (!target_item.carried) {
					// Move Towards New Target if still possible to pick it up
					var move_dir = move_towards_coordinates(target_item.x, target_item.y, !consumed_by_block, !consumed_by_lava);
					if (move_dir == noone) { target_item = noone; play_sound(snd_give_up, false); }
				}
				else { target_item = noone; }
			}
			else { target_item = noone; }
		}
		
		// Kill other enemies with carried sword
		if (carried_items[1] != noone && carried_items[1].object_index == obj_sword) {
			var enemies_at_position = instance_place_all(x, y, obj_enemy);
			while (array_length(enemies_at_position) > 0) {
				var enemy_to_kill = array_random_pop(enemies_at_position);
				if (enemy_to_kill == self) { continue; }
				
				with (enemy_to_kill) { kill_with_sword(carried_sword); }
				if (instance_exists(carried_sword)) { continue; }
				else { break; }
			}
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
