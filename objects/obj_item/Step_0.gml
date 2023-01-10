event_inherited();

if (process_this_frame()) {
	var player_at_quadrant = get_presence_at_each_quadrant(global.player);
	if (!carried && lava_at_all_quadrants() && (get_carried_item_of_type(obj_amulet) == noone || (player_at_quadrant[0] == noone && player_at_quadrant[1] == noone && player_at_quadrant[2] == noone && player_at_quadrant[3] == noone))) {
		instance_destroy();
		play_sound(snd_extinguish, true);
	}
}