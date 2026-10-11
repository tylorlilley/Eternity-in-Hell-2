// The outline blinks on and off with the game's blink cycle
visible = !is_blink_frame();
// Its color is halfway between the background color and white
image_blend = merge_color(global.bg_color, c_white, 0.5);