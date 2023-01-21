event_inherited();

consume_block = true;
fire_resistant = true;

shoot_timer = irandom_range(8, 24);
covered = false;
dir = noone;

death_box = instance_create_depth(x, y, 0, obj_death);
death_box.creator = id;
	