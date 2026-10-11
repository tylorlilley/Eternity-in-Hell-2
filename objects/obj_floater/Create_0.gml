event_inherited();

// A floater is incorporeal and floats, so swords, blocks, fire and lava can't kill it. It stays dormant until the
// player walks away from it
corporeal = false;
floating = true;
activated = false;

// These two timers are set but never read
spawn_timer = 0;
start_timer = false;