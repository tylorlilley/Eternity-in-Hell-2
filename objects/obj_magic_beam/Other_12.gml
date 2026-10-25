/// @description End Step
event_inherited();

update_fireball_torch_position(0.5);
var _blocked = false;

// Kill Player
var _player = global.player;
if (!_player.dead && place_meeting(x, y, _player) && get_distance_to_instance(_player) <= 8) { 
	_blocked = true;
	with (_player) {
		if (!is_carrying_item(obj_staff)) {
			play_sound(snd_no, false);
			kill_player(other.creator_obj);
		}
		else {
			increment_run_stat("staff_blocked_beams");
		}
	}
}

// Destroy Self
if (is_outside_room(x, y)) { instance_destroy(); }
if (_blocked) { play_sound(snd_thud, false); instance_destroy(); }
