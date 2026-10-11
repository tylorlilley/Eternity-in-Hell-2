/// @description Step

// Inherit the parent event
event_inherited();

// While it rages, it shows its angry frame, and it makes a loud sound when it gives up. Afterwards it goes back to its
// first frame
if (rage_counter > 0) { 
	rage_counter -= 1;
	
	if (rage_counter == 0) { play_sound(snd_give_up, true); }
	else { image_index = 2; }
}
else if (image_index == 2) { image_index = 0; }