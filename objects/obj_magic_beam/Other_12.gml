/// @description End Step
event_inherited();

update_fireball_torch_position(0.5);
var _blocked = false;

// Kill Enemies
//var blocked_by_enemy = fireball_kill_enemies(true);
//if (blocked_by_enemy) { blocked = true; }

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
			global.controller.evaluation_manager.increment_evaluation_variable("staff_blocked_beams");
		}
	}
}

// Destroy Self
if (is_outside_room(x, y)) { instance_destroy(); }
if (_blocked) { play_sound(snd_thud, false); instance_destroy(); }
