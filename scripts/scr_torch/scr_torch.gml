/// @function  							obj_torch_light();
function obj_torch_light() {
	image_index = 0;
	image_speed = 1;

	sound_play(snd_torchlight);

	light_source = instance_create_depth(x, y, 0, obj_light_source);
	light_source.lighting_range = global.controller.TORCH_LIGHT_RANGE;
	light_source.persistent = true;

	time_to_remain_lit = global.controller.MAX_TORCH_TIME_TO_REMAIN_LIT;
}
