//initialized = false;
distance_to_current_room = 9999;

// Initialize room state values
visited = false;
flip_horizontal = false;
flip_vertical = false;
rotate = noone;
has_heart = false;
has_cross = false;
has_key = false;
has_special_key = false;
has_collectables = false;
has_item = false;
collectables_collected = false;
lit = get_random_chance_out_of(5);

// Initialize room topography information
exits = array( false, false, false, false, false );
locked_exits = array( noone, noone, noone, noone, noone );
adj_rooms = array( noone, noone, noone, noone, noone );

