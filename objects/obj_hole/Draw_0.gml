event_inherited(); 
// Once a second hole links it to a room, draw its linked frame on top
if (connected_exit.get_connected_room(global.controller.current_room) != -1) { draw_sprite_ext(sprite_index, 1, x, y, 1, 1, 0, image_blend, image_alpha); }
