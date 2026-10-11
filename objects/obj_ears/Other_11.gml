/// @description Step

// An awake ear that hasn't moved yet this step follows its path, and falls asleep once it arrives or if it has no path
// to follow. An ear that already moved this step (a loud sound just woke it) stays awake
var _fall_asleep = false;
if (awake && !moved && target_path != noone) { _fall_asleep = move_ears(); }
else { _fall_asleep = !moved; }
	
// Falling asleep shows the first frame and restarts the twitch timer
if (awake && _fall_asleep) {
	image_index = 0;
	sprite_timer = 6;
	awake = false;
}

// Sleeping ears twitch between their first two frames every few steps, and awake ears show their third frame
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