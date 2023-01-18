if (instance_exists(torch)) { set_instance_to_same_position(torch);  torch.image_xscale = 0.5; }
with (death_box) { x = other.x; y = other.y; }
	
// Destroy self and/or other when colliding with solid, enemy, or player
var enemies_at_position = instance_place_all(x, y, obj_enemy), hit_enemy = false;
while (array_length(enemies_at_position) > 0) {
	var enemy = array_random_pop(enemies_at_position);
	if (enemy.activated && enemy.corporeal && !enemy.fire_resistant) { hit_enemy = true; break; }
}
	
// TODO: Update to include hands carrying staff as well
if (hit_enemy||
	is_solid_at_position(x, y) || 
	(place_meeting(x, y, global.player) && is_carrying_item(obj_staff))) {
		with (death_box) { check_for_player_collision(); }
		play_sound(snd_fuse, true); instance_destroy(); 
}
