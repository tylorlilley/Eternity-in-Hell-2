event_inherited();

// Drawn behind items and enemies, at the depth of the cross
depth = CROSS_DEPTH;

// A lantern is a torch that stays where it is. Being special, it never burns down, and its full lit time tops up any
// torch lit from it
special = true;
can_pick_up = false;
lighting_range = LANTERN_LIGHT_RANGE;
time_to_remain_lit = MAX_TORCH_TIME_TO_REMAIN_LIT;
// Its flame is drawn with the lantern's own fire sprite
torch_light_sprite_index = spr_lantern_light;