event_inherited();

activated = get_random_chance_out_of(global.controller.SPIDER_PROBABILITY);
if global.controller.entered_from_stairs { activated = false; }

WAITING = 0;
SCREECHING = 1;
ATTACKING = 2;
state = WAITING;
dir = -1;
