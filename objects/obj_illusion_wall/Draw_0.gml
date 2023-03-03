event_inherited();

// Consider each quadrant of the sprite and draw a blank square over it its corresponding solid is visible
var bg_color = global.bg_color;
draw_set_color(bg_color);
for (var quadrant = 0; quadrant < 4; quadrant++;) {
	var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);

	if (is_existing_instance(parts[quadrant]) && !parts[quadrant].illusion_visible) {
	    draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, bg_color, 1);
	}
}