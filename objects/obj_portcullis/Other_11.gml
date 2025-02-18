/// @description Step
event_inherited();

if (is_existing_instance(closed) && !door_for_exit.has_closed_portcullis_for_room(global.controller.current_room)) {
	door_for_exit.close_portcullis()
}