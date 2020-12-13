/// @function  							light_lantern(room_start);
///	@param		{boolean}	room_start	Whether or not this is being lit by the game upon room initialization
function light_lantern(room_start) {
	image_speed = 1/6; 
	
	light_source = instance_create_depth(x, y, 0, obj_light_source);
	light_source.lighting_range = global.controller.LANTERN_LIGHT_RANGE;

	if (!room_start) {
	    audio_play_sound( snd_torchlight, 10, false );
    
	    var last_lantern = true;
	    with obj_lantern { if (!light_source) { last_lantern = false; } }
	    if (last_lantern) { global.controller.current_room.lit = true; }
	}
}
