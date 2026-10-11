x = room_width/2;
y = room_height/2;

image_speed = 0;
image_index = ((global.graphics_mode == graphics_modes.farmer) ? 1 : 0)
image_xscale = 0.25;
image_yscale = 0.25;

// Steps to show the logo before the game controller is created
timer = 2;

// Clear texture memory, then load the logo's texture page so it's ready to draw
draw_texture_flush();
sprite_prefetch(spr_logo);