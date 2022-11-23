event_inherited();

sprite_index = (global.controller.FARM_MODE) ? spr_nose_farmer : spr_nose;
killable_by_sword = true;
consumed_by_block = true;
lethal = true;
visible = false;
image_speed = 0;
image_blend = global.controller.bg_color;
death_sound = snd_crunch;
spawn_timer = irandom_range(8, 32);
shoot_timer = 0;