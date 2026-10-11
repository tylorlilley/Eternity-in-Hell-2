/// @description Step
event_inherited();

// The first time the player, a ground enemy or a block presses it, open the room's portcullises and end its trap
if (can_press_button() && image_index == 0) {
		with (global.controller.current_room) { has_portcullis_trap = false; }
		with (obj_portcullis) { open_portcullis(); }
		global.controller.evaluation_manager.increment_evaluation_variable("portcullises_opened");
		flip_sprite_at_random(true);
		play_sound(snd_shovel, true);
		image_index = 1;
		visible = true;
}