// Only one echo generator can exist at a time: a second one destroys itself
singleton_instance();

// Whether it has started spawning echoes, the steps until the next echo spawns, and the player's moves it has recorded,
// one per step, with directions.none for a step the player stood still. Every echo it spawns repeats these moves
spawning = false;
spawn_timer = ECHO_SPAWN_FREQUENCY/2;
moves = [];