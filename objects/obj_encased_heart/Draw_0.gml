var controller = global.controller;
var collectables_collected = controller.total_number_of_rooms_with_collectables - array_length(controller.rooms_with_collectables);
var img_index = floor(5 * (collectables_collected / controller.total_number_of_rooms_with_collectables));

event_inherited();

draw_sprite_ext(spr_heart_case, img_index, x, y, image_xscale, image_yscale, image_angle, image_blend, 1);  
