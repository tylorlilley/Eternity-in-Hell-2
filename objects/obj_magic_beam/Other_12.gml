/// @description End Step
event_inherited();

update_fireball_torch_position(0.5);
var blocked = false;

// Kill Enemies
var blocked_by_enemy = fireball_kill_enemies(true);
if (blocked_by_enemy) { blocked = true; }

// Kill Player
var player = global.player;
if (!player.dead && place_meeting(x, y, player) && get_distance_to_instance(player) <= 8) { 
	blocked = true;
	with (player) {
		if (!is_carrying_item(obj_staff)) {
			play_sound(snd_no, false);
			kill_player(other.creator_obj);
		}
	}
}

// Destroy Self
if (is_outside_room(x, y)) { instance_destroy(); }
if (blocked) { play_sound(snd_thud, false); instance_destroy(); }
