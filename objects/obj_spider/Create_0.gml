event_inherited();

activated = get_coin_flip();
if global.controller.entered_from_stairs { activated = false; }

WAITING = 0;
SCREECHING = 1;
ATTACKING = 2;
state = WAITING;
dir = -1;
