event_inherited();

lethal = get_random_chance_out_of(2);
if global.controller.entered_from_stairs { lethal = false; }

WAITING = 0;
SCREECHING = 1;
ATTACKING = 2;
state = WAITING;
dir = -1;
