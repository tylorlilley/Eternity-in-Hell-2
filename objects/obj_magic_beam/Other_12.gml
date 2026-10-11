/// @description End Step
event_inherited();

// Keep its torch at its position
update_fireball_torch_position(0.5);
var _blocked = false;

// Hitting the player kills them, unless they carry a staff, which blocks the beam
var _player = global.player;
if (!_player.dead && place_meeting(x, y, _player) && get_distance_to_instance(_player) <= 8) { 
	_blocked = true;
	with (_player) {
		if (!is_carrying_item(obj_staff)) {
			play_sound(snd_no, false);
			kill_player(other.creator_obj);
		}
		else {
			global.controller.evaluation_manager.increment_evaluation_variable("staff_blocked_beams");
		}
	}
}

// The beam ends when it leaves the room, or when it hits the player, with a thud
if (is_outside_room(x, y)) { instance_destroy(); }
if (_blocked) { play_sound(snd_thud, false); instance_destroy(); }
