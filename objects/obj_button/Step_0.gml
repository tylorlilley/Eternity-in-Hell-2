event_inherited();
var enemy = instance_position(x, y, obj_enemy), block = instance_position(x, y, obj_solid);

if (image_index == 0 &&
	((enemy && enemy.killable_by_sword && instance_at_coordinates(x, y, enemy)) || 
	instance_at_coordinates(x, y, global.player) || 
	(block && instance_at_coordinates(x, y, block)))) {
		with (obj_portcullis) { stuck_open = true; open_door(); }
		flip_sprite_at_random(true);
		play_sound(snd_shovel, true);
		image_index = 1;
}