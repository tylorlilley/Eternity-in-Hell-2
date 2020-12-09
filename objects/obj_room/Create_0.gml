//initialized = false;
distance_to_current_room = 9999;

// Initialize room state values
visited = false;
flip_horizontal = false;
flip_vertical = false;
rotate = noone;
has_key = false;
has_collectables = false;
collectables_collected = false;
lit = (irandom(4) == 0);

// Initialize room topography information
exits = array( false, false, false, false, false );
locked_exits = array( noone, noone, noone, noone, noone );
adj_rooms = array( noone, noone, noone, noone, noone );

