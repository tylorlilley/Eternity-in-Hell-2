/// @description Step
event_inherited();

if (can_press_button() && image_index == 0) {
		with (obj_portcullis) { 
			stuck_open = true; 
			open_door();
			door_for_exit.set_portcullis_for_room(global.controller.current_room, false);
		}
		flip_sprite_at_random(true);
		play_sound(snd_shovel, true);
		image_index = 1;
		visible = true;
}