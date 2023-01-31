x = room_width/2;
y = room_height/2;

image_speed = 0;
image_index = ((global.FARM_MODE) ? 1 : 0)
image_xscale = 0.25;
image_yscale = 0.25;

timer = 2;

draw_texture_flush();
sprite_prefetch(spr_logo);