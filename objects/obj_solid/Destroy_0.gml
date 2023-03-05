if (is_existing_instance(global.controller)) { 
	mp_grid_remove(global.controller.current_room.solid_grid); 
	mp_path_grid_remove(global.controller.current_room.solid_path_grid); 
}