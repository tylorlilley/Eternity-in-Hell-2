depth = -10;
lighting_range = global.controller.PLAYER_LIGHT_RANGE;
flicker_value = 0;
is_flickering_light_source = false;
x_prev = x;
y_prev = y;
dead = false;
carried_item = instance_create_depth(x, y, -1, obj_torch);
carried_item.carried = true;
with carried_item { obj_torch_light(); }
image_speed = 0;
pause_movement = 0;

