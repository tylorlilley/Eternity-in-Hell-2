/// @description Insert description here
// You can write your code in this editor

// Inherit the parent event
event_inherited();

if (rage_counter > 0) { 
	rage_counter -= 1;
	
	if (rage_counter == 0) { play_sound(snd_give_up, true); }
	else { image_index = 2; }
}
else if (image_index == 2) { image_index = 0; }