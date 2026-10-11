/// @description End Step
event_inherited();

update_fireball_torch_position(0.5);
var _blocked = false, _prev_reflected_by = reflected_by;

if (destructive) {
	// Destroy doors
	var _door = instance_place(x, y, obj_door);
	with (_door) { 
		if (is_existing_instance(closed)) {
			if (other.shot_by_player) { record_run_kill(obj_door, other.creator_obj); }
			instance_destroy(); 
			play_sound(snd_crunch, true);
			_blocked = true;
		}
	}
	
	// Destroy chests
	var _chest = instance_place(x, y, obj_chest);
	with (_chest) {
		if (other.shot_by_player) { record_run_kill((locked) ? obj_locked_chest : obj_chest, other.creator_obj); }
		if (contents_obj == obj_statue || contents_obj == obj_fountain) {
			if (other.shot_by_player) {
				increment_run_stat("trapped_chests_destroyed");
				record_run_kill(contents_obj, other.creator_obj);
			}
		}
		instance_destroy(); 
		play_sound(snd_crunch, true);
	}
	
	// Destroy statues
	var _statue = instance_place(x, y, obj_statue);
	if (is_existing_instance(_statue) && (!is_existing_instance(creator) || creator != _statue )) { 
		_blocked = true; 
	}
	with (_statue) {
		if (other.shot_by_player) { 
			record_run_kill(object_index, other.creator_obj);
		}
		instance_destroy(); 
		play_sound(snd_crunch, true);
	}
	
	// Destroy giant eyes
	var _giant_eye = instance_place(x, y, obj_giant_eye);
	with (_giant_eye) {
		if (dying == 0) { dying = 32; }
		play_sound(snd_crunch, true);
	}
}

// Light Bombs
fireball_light_bombs();

// Kill Enemies
var _blocked_by_enemy = fireball_kill_enemies();
if (_blocked_by_enemy) { _blocked = true; }

// Burn Bushes
// if (!blocked) { blocked = fireball_burn_bushes(); }

// Kill Player
var _player = global.player;
if (!_blocked && !_player.dead && place_meeting(x, y, _player) && get_distance_to_instance(_player) <= 8) { 
	_blocked = true;
	with (_player) {
		if (!is_carrying_item(obj_staff)) {
			play_sound(snd_extinguish, false);
			kill_player(other.creator_obj);
		}
		else {
			increment_run_stat("staff_blocked_fireballs");
		}
	}
}


// Get Blocked by Solids
if (!_blocked) {
	var _solids_at_position = instance_place_all(x, y, obj_solid);
	while (array_length(_solids_at_position) > 0) {
		var _blocking_solid = array_random_pop(_solids_at_position);
		if (is_existing_instance(_blocking_solid) && (!is_existing_instance(creator) || creator != _blocking_solid) && _blocking_solid.object_index != obj_mirror) { _blocked = true; break; }
		else if (is_existing_instance(_blocking_solid) && _blocking_solid.object_index == obj_mirror && (!is_existing_instance(reflected_by) || reflected_by != _blocking_solid)) {
			reflected_by = _blocking_solid;
			increment_run_stat("mirror_bounced_projectile");
		}
	}
}


// Destroy Self
if (_blocked) {
	play_sound(snd_fuse, false);
	instance_destroy(); 
}

// Reflect Self
else if (_prev_reflected_by != reflected_by) {
	direction = (abs(lengthdir_y(16, direction)) > abs(lengthdir_x(16, direction))) ? -direction : 180-direction;
	play_sound(snd_yes, false);
}