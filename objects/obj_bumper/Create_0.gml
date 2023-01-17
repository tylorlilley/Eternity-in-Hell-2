event_inherited();

sprite_index = (global.controller.FARM_MODE) ? spr_eyes_farmer : spr_eyes;
play_sound(snd_bumper, false);

death_sound = snd_bumper;
image_speed = 0;

lethal = false;
visible = false;
killable_by_sword = true;

blink_amount = irandom_range(10, 16);
