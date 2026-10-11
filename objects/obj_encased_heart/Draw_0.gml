var _controller = global.controller;
var _collectables_collected = _controller.total_number_of_rooms_with_collectables - array_length(_controller.rooms_with_collectables);
var _img_index = floor(5 * (_collectables_collected / _controller.total_number_of_rooms_with_collectables));

event_inherited();

draw_sprite_ext(spr_heart_case, _img_index, x, y, image_xscale, image_yscale, image_angle, image_blend, 1);  
