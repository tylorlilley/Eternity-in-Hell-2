global.player = id;
depth = -10;
flicker_value = 0;
lighting_range = global.controller.PLAYER_LIGHT_RANGE;
is_flickering_light_source = false;
x_prev = x;
y_prev = y;
dead = false;
image_speed = 0;
pause_movement = 0;
hidden = false;
opened_door_this_frame = false;

// Create initial carried torch
carried_items = [noone, noone, noone, noone, noone];
with create_item_in_hand(directions.left, obj_torch) { light_torch(noone, true); }
//with create_item_in_hand(directions.right, obj_amulet) { special = true; image_index = 1; }