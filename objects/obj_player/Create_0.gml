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

// Create initial carried torch
carried_items = array(noone, noone, noone, noone, noone);
with create_item_in_hand(directions.left, obj_torch) { light_torch(); }
var new_item = create_item_in_hand(directions.right, obj_map);
new_item.special = true;
new_item.image_index = -1;