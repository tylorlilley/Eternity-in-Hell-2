// Draw over bush
var bush_at_quadrant = get_instance_at_each_quadrant(obj_bush);
for (var i = 0; i <= 3; i +=1;) {
	var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

	if (bush_at_quadrant[i] != noone) {
		draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1);
	}
}

event_inherited();

