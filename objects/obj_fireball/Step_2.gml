if (instance_exists(torch)) { set_instance_to_same_position(torch);  torch.image_xscale = 0.5; }
var blocked = false;

// Destroy doors
var door = instance_place(x, y, obj_door);
if (destructive) {
	with (door) { 
		if (closed != noone) { instance_destroy(); play_sound(snd_crunch, true); }
	}
}

// Kill Enemies
enemies_at_position = instance_place_all(x, y, obj_enemy);
while (array_length(enemies_at_position) > 0) {
	var enemy = array_random_pop(enemies_at_position);
	if (enemy.activated && enemy.corporeal && get_distance_to_instance(enemy) <= 8) {
		if (enemy.object_index == obj_hands) {
			blocked = true;
			with (enemy) {
				if (!is_carrying_item(obj_staff)) { kill_enemy(snd_extinguish); }
			}
		}
		else { 
			blocked = (!enemy.fire_resistant);
			with (enemy) { if (!fire_resistant) { kill_enemy(snd_extinguish); } }
		}
	}
}

// Kill Player
if (!global.player.dead && place_meeting(x, y, global.player) && get_distance_to_instance(global.player) <= 8) { 
	blocked = true;
	with (global.player) {
		if (!is_carrying_item(obj_staff)) {
			play_sound(snd_extinguish, false);
			kill_player(other.creator.object_index);
		}
	}
}

// Get Blocked by Solids
if (!blocked) {
	var solids_at_position = instance_place_all(x, y, obj_solid);
	while (array_length(solids_at_position) > 0) {
		var blocking_solid = array_random_pop(solids_at_position);
		if (blocking_solid != noone && blocking_solid != creator) { blocked = true; break; }
	}
}

// Destroy Self
if (blocked) {
	play_sound(snd_fuse, false);
	instance_destroy(); 
}
