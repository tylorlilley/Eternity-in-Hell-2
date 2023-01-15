event_inherited();

killable_by_sword = true;
consume_block = true;
consumed_by_block = true;
consumed_by_lava = true;
consumed_by_fireball = false;
death_sound = snd_crunch;

image_speed = 0;
image_index = 0;
sprite_index = (global.controller.FARM_MODE) ? spr_statue_farmer : spr_statue;
shoot_timer = irandom_range(8, 24);
covered = false;
dir = noone;
	