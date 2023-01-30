// If room becomes fully lit, destroy self
if (global.controller.current_room.lit) {
	instance_create(x, y, obj_chest);
	play_sound(snd_appear, false);
	screen_flash();
	instance_destroy();
}