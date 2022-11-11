play_sound(snd_move, false);
if (seed_option == seed_options.specified) { global.seed = current_seed; }
else if (seed_option == seed_options.rand) { global.seed = irandom_range(0,99999999); }
room_goto(rm_start);