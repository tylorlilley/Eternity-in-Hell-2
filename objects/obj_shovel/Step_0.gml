if (carried == noone && !has_been_carried) { sprite_index = spr_shovel; }
else if (carried != noone && !damaged) { sprite_index = spr_shovel; }
else if (carried != noone && damaged) { sprite_index = spr_worn_shovel; }
else if (carried == noone && !damaged) { 
	if (sprite_index != spr_shovel_in_ground) {
		sprite_index = spr_shovel_in_ground;
		play_sound(snd_shovel, true);
	}
}
else if (carried == noone && damaged) { 
	if (sprite_index != spr_worn_shovel_in_ground) {
		sprite_index = spr_worn_shovel_in_ground;
		play_sound(snd_shovel, true);
	}
}

event_inherited();
