event_inherited();
var controller = global.controller;

closed = true;
contents_obj = (controller.current_room.chest_obj == -1) ? array_random_pop(controller.spawned_items) : controller.current_room.chest_obj;
