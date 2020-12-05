lighting_range = global.controller.PLAYER_LIGHT_RANGE;
x_prev = x;
y_prev = y;
dead = false;
carried_item = instance_create(x, y, obj_torch);
carried_item.carried = true;
with carried_item { obj_torch_light(); }
image_speed = 0;

