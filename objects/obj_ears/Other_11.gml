/// @description Step

var fall_asleep = false;
if (awake && !moved && target_path != noone) { fall_asleep = move_ears(); }
else { fall_asleep = !moved; }
	
if (awake && fall_asleep) {
	image_index = 0;
	sprite_timer = 6;
	awake = false;
}

// Control Sprite
if (!awake) {
	if (sprite_timer > 0) { sprite_timer -= 1; }
	else if (sprite_timer == 0) { 
		image_index += 1;
		if (image_index > 1) { image_index = 0; }
		sprite_timer = 6;
	}
}
else { image_index = 2; }

event_inherited();