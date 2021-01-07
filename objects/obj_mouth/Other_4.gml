//var offset = irandom(7);
//if (offset == 0) { y -= 16; }
//if (offset == 1) { x += 16; }
//if (offset == 2) { y += 16; }
//if (offset == 3) { x -= 16; }

//if (offset == 4 || offset == 5) { lethal = false; }
//else { lethal = true; }

event_inherited();
audio_play_sound_for_object_only_once(snd_squelch);
teleport_to_empty_space();
//lethal = !get_random_chance_out_of(4);