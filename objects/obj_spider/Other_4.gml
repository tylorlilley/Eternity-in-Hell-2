event_inherited();

lethal = (irandom(1) == 0);
if global.controller.entered_from_stairs { lethal = false; }

attacking = false;
screeched = 0;
dir = -1;

