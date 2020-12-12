event_inherited();

lethal = get_random_chance_out_of(2);
if global.controller.entered_from_stairs { lethal = false; }

attacking = false;
screeched = 0;
dir = -1;

