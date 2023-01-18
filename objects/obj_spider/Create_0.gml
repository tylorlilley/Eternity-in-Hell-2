event_inherited();
set_farm_mode_sprite(spr_spider_farmer);

activated = get_coin_flip();
if global.controller.entered_from_stairs { activated = false; }

WAITING = 0;
SCREECHING = 1;
ATTACKING = 2;
state = WAITING;
dir = -1;
