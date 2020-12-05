/// @description  obj_game_object_set_instance_to_same_position(instance)
function obj_game_object_set_instance_to_same_position(argument0) {
	var instance = argument0;

	with instance { 
	    x = other.x; 
	    y = other.y; 
	    image_xscale = other.image_xscale; 
	}



}
