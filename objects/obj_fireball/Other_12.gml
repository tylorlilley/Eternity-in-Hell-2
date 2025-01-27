/// @description End Step
event_inherited();

update_fireball_torch_position(0.5);
var blocked = false, prev_reflected_by = reflected_by;

if (destructive) {
	// Destroy doors
	var door = instance_place(x, y, obj_door);
	with (door) { 
		if (is_existing_instance(closed)) { 
			instance_destroy(); 
			play_sound(snd_crunch, true);
			blocked = true;
		}
	}
	
	// Destroy chests
	var chest = instance_place(x, y, obj_chest);
	with (chest) {
		instance_destroy(); 
		play_sound(snd_crunch, true);
	}
	
	// Destroy statues
	var statue = instance_place(x, y, obj_statue);
	if (is_existing_instance(statue) && (!is_existing_instance(creator) || creator != statue )) { 
		blocked = true; 
	}
	with (statue) {
		if (other.shot_by_player) { update_kill_log(object_index, global.difficulty, other.object_index); }
		instance_destroy(); 
		play_sound(snd_crunch, true);
	}
}

// Light Bombs
fireball_light_bombs();

// Kill Enemies
var blocked_by_enemy = fireball_kill_enemies();
if (blocked_by_enemy) { blocked = true; }

// Kill Player
var player = global.player;
if (!player.dead && place_meeting(x, y, player) && get_distance_to_instance(player) <= 8) { 
	blocked = true;
	with (player) {
		if (!is_carrying_item(obj_staff)) {
			play_sound(snd_extinguish, false);
			kill_player(other.creator_obj);
		}
	}
}

// Get Blocked by Solids
if (!blocked) {
	var solids_at_position = instance_place_all(x, y, obj_solid);
	while (array_length(solids_at_position) > 0) {
		var blocking_solid = array_random_pop(solids_at_position);
		if (is_existing_instance(blocking_solid) && (!is_existing_instance(creator) || creator != blocking_solid) && blocking_solid.object_index != obj_mirror) { blocked = true; break; }
		else if (is_existing_instance(blocking_solid) && blocking_solid.object_index == obj_mirror && (!is_existing_instance(reflected_by) || reflected_by != blocking_solid)) {
			reflected_by = blocking_solid;
		}
	}
}

// Destroy Self
if (blocked) {
	play_sound(snd_fuse, false);
	instance_destroy(); 
}

// Reflect Self
else if (prev_reflected_by != reflected_by) {
	direction = (abs(lengthdir_y(16, direction)) > abs(lengthdir_x(16, direction))) ? -direction : 180-direction;
	play_sound(snd_yes);
}