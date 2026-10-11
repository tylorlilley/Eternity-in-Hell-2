/// @description Invert Special Colors

// Special items are drawn with an alpha that makes the shader swap white and red, including in their reflections
image_alpha = get_special_draw_alpha();
// Inherit the parent event, which draws the reflection in mirrors
event_inherited();

