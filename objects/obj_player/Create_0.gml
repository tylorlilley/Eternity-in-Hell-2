global.player = id;
depth = -10;
lighting_range = global.controller.PLAYER_LIGHT_RANGE;
flicker_value = 0;
is_flickering_light_source = false;
x_prev = x;
y_prev = y;
dead = false;
image_speed = 0;
pause_movement = 0;

// Create initial carried torch
carried_items = array(noone, noone, noone, noone, noone);
with instance_create_depth(x, y, -1, obj_torch) {
	pick_up_item(directions.left);
	light_torch();
}
