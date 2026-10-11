event_inherited();

// Enemies are hidden until they're activated, and are drawn at start_depth unless they float or aren't corporeal
visible = false;
start_depth = STANDARD_DEPTH;

// Whether it has a body: swords, blocks and fire can't kill an incorporeal enemy, which flickers instead. A floating
// enemy isn't killed by lava, and is drawn in front of the other enemies
corporeal = true;
floating = false;

// Whether fire (lava and fireballs) or magic can't kill it
fire_resistant = false;
magic_resistant = false;

// Whether it can move along the room's border
can_move_on_border = false;

// Enemies only find paths once they're given a path grid (-1 for none), and make a new path whenever they have none to
// follow. With can_interrupt_target_path, they make a new path after every move instead of following the old one to
// its end
target_path_grid = -1;
has_automatic_target_path_generation = true;
can_interrupt_target_path = false;

// Whether the fireballs from its explosion (see explode) count as shot by the player
lit_by_player = false;
