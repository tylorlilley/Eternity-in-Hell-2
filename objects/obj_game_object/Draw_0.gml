if (sprite_index) {
    draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
    
    // Consider each quadrant of the sprite and draw a blank square over it if it is behind another object that should cover it
    draw_set_color(global.controller.bg_color);
    for (var i = 0; i <= 3; i++) {
        var x_pos = 4, y_pos = 4;
        if (i mod 2 == 0) { y_pos *= -1; }
        if (i < 2) { x_pos *= -1; }
        
        var bush = instance_position(x+x_pos,y+y_pos, obj_bush);
        var solid_obj = instance_position(x+x_pos,y+y_pos, obj_solid);
        if  (bush && bush.visible && bush.id != self.id) ||
            (solid_obj && solid_obj.visible && solid_obj.id != self.id) {
            draw_sprite_ext(spr_box, 0, x+x_pos, y+y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1);
        }
    }
}

