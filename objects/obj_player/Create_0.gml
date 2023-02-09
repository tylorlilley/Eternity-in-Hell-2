event_inherited();
global.player = id;

depth = PLAYER_DEPTH;

right_hand_item = noone;
left_hand_item = noone;

lighting_range = PLAYER_LIGHT_RANGE;
is_flickering_light_source = false;
flicker_value = 0;

dir = directions.none;
dir_prev = directions.none;
moved_by = noone;
dead = false;
pause_movement = 0;

// Create initial carried torch
with create_item_in_hand(directions.left, obj_torch) { light_torch(noone, true); };
//with create_item_in_hand(directions.right, obj_clock) { make_item_special(); }