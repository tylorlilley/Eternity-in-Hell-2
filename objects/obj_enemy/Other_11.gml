/// @description Step
event_inherited();
	
visible = activated;
	
if (activated) {
	if (corporeal) {
		var death_sound = noone;
		var death_by_fire_skeleton = object_index != obj_fire_skeleton && instance_place(x, y, obj_fire_skeleton);
			
		if (!floating) {
			if (!fire_resistant && (is_covered_at_each_quadrant_by(obj_lava_part) || death_by_fire_skeleton)) { death_sound = snd_extinguish; }
			else if (is_covered_at_each_quadrant_by(obj_solid) && (object_index != obj_hands || !is_carrying_special_item(obj_staff))) { death_sound = snd_crunch; }
		}
			
		if (death_sound != noone) { kill_enemy(death_sound); }
		depth = (floating) ? FLOATING_ENEMY_DEPTH : start_depth;
	}
	else {
		// Flicker sprite if not corporeal
		depth = INCORPOREAL_ENEMY_DEPTH;
		visible = is_blink_frame();;
	}
}

