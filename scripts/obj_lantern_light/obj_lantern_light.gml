/// @description  obj_lantrern_light(room_start)
function obj_lantern_light(argument0) {
	var room_start = argument0;

	image_speed = 1; 
	
	light_source = instance_create_depth(x, y, 0, obj_light_source);
	light_source.lighting_range = global.controller.LANTERN_LIGHT_RANGE;

	if (!room_start) {
	    sound_play(snd_torchlight); 
    
	    var last_lantern = true;
	    with obj_lantern { if (!light_source) { last_lantern = false; } }
	    if (last_lantern) { global.controller.current_room.lit = true; }
	}
}
