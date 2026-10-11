event_inherited();

// Drawn further back than other enemies
start_depth = MOUTH_DEPTH;

// A squelch that ears enemies don't hear, as it's created
play_sound(snd_squelch, false);

// Hidden until the player comes within trap range. It eats blocks pushed onto it, and lava and fireballs can't kill it
activated = false;
consume_block = true;
fire_resistant = true;
