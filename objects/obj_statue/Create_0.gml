event_inherited();
image_speed = 0;
image_index = 0;
sprite_index = (global.controller.FARM_MODE) ? spr_statue_farmer : spr_statue;
shoot_timer = irandom_range(8, 24);
covered = false;
dir = noone;
	