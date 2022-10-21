event_inherited();

depth = 5;
image_speed = 0;
flip_sprite_at_random(true);
image_index = irandom(3);
rotate_sprite_to_random_angle();

if (get_random_chance_out_of(1024)) { 
	instance_create_depth(x, y, 0, obj_player_corpse);
	instance_destroy();
}