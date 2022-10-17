//initialized = false;
distance_to_current_room = 9999;

// Initialize room state values
visited = false;
flip_horizontal = false;
flip_vertical = false;
rotate = noone;
lit = get_random_chance_out_of(5);

// Room content values
has_key = false;
has_special_item = false;
has_collectables = false;
stairs_spot_obj = noone;
item_type = noone;

// Initialize room topography information
exits = [false, false, false, false, false];
locked_exits = [noone, noone, noone, noone, noone];
adj_rooms = [noone, noone, noone, noone, noone];

