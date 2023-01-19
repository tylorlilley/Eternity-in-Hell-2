event_inherited();
global.player = id;

depth = -10;

right_hand_item = noone;
left_hand_item = noone;

lighting_range = global.controller.PLAYER_LIGHT_RANGE;
is_flickering_light_source = false;
flicker_value = 0;

dir = noone;
dir_prev = noone;
x_prev = x;
y_prev = y;
dead = false;
pause_movement = 0;

// Create initial carried torch
with create_item_in_hand(directions.left, obj_torch) { light_torch(noone, true); };
//with create_item_in_hand(directions.right, obj_rosary) {}//{ special = true; image_index = 1; }