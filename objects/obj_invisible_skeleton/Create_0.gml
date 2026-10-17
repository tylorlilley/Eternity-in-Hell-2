event_inherited();

// Its own sprite is all red, and the shader never draws a red pixel dimmer than the lowest brightness, so it gets swapped
// to white to fade out completely. A shuffled sprite in the unknown graphics mode isn't swapped: its white pixels fade
// out, and its red ones stay at the lowest brightness
has_red_sprite = (sprite_index == spr_invisible_skeleton || sprite_index == spr_invisible_skeleton_farmer);