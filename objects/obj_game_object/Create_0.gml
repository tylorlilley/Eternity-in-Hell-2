image_speed = 0;
image_blend = global.bg_color;
sprite_index = get_sprite_to_use(sprite_index);

shader_color = shader_get_uniform(sh_eih, "new_color");