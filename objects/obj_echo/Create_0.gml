event_inherited();

// Echoes are incorporeal, so they flicker and swords, blocks and fire don't hurt them. They also float and can move
// along the room border
corporeal = false;
floating = true;
can_move_on_border = true;

// The generator whose recorded player moves it repeats, and the position in that list of the next move to repeat.
// walk_timer is set but never read
generator = noone;
walk_timer = 2;
move_pos = 0;

// Start on the second frame, and draw with the alpha that makes the shader swap white and red
image_index = 1;
image_alpha = INVERTED_COLORS_ALPHA;