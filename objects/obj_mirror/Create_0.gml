event_inherited();
// Drawn before the other objects, so their reflections land on top of its glass
depth = MIRROR_DEPTH;
// The frame and glare over clear glass, which the Draw event draws over the reflections (Draw Begin draws the glass)
image_index = 1;

