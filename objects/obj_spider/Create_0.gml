event_inherited();

var controller = global.controller;
activated = get_random_chance_out_of(SPIDER_PROBABILITY);
if controller.entered_from_stairs { activated = false; }

WAITING = 0;
SCREECHING = 1;
ATTACKING = 2;
state = WAITING;
dir = -1;
