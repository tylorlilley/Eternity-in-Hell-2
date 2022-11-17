event_inherited();

audio_play_sound_for_object_only_once(snd_bumper);

death_sound = snd_bumper;
image_speed = 0;

lethal = false;
visible = false;

blink_amount = irandom_range(10, 16);