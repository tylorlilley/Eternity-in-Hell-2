// ===== ROOM CONTENT =====
#macro MOVING_COLLECTABLE_PROBABILITY get_probability_for_difficulty([0, 0, 24, 18, 16]) 
#macro MOUTHS_PER_MOUTH (1+global.difficulty)
#macro HIDDEN_CHEST_PROBABILITY get_probability_for_difficulty([0, 3, 3, 2, 2])  // This happens only after the chest probability succeeds, so its combined with that probability. Also, only appears in non-lit lantern rooms, so combined with that too

// ===== ROOM BUILDING =====
#macro DIRT_PROBABILITY get_probability_for_difficulty([0, 16, 20, 24, 28]) 
#macro SKIP_COLLECTABLE_SPAWN_PROBABILITY 0// UNUSED get_probability_for_difficulty([0, 0, 12, 8, 6])
#macro BLOCK_ITEM_PROBABILITY get_probability_for_difficulty([0, 256, 256, 128, 64]) // Even if this passes, 50% of the time we spawn bones instead
#macro BLOCK_SPECIAL_ITEM_PROBABILITY get_probability_for_difficulty([0, 0, 8, 6, 4]) // Checked when a block hides an item instead of bones

// ===== DIFFICULTY SCORES =====
#macro ROOM_DIFFICULTY_SCORE_MAX 8 // Generation won't randomly add a hazard to a room when it would take the difficulty score of the room's hazards past this
#macro COLLECTABLES_EXPOSURE 1.4			// Collecting everything crosses the whole room, so its difficulty score counts 1.4 times
#macro PORTCULLIS_TRAP_DANGER 0.03			// Shut in until the button is pressed, once per trap room
#macro SPECIAL_ITEM_DIFFICULTY_SCORE -2		// A special item makes the rest of the run easier, so the map can take more

// ===== TIME =====
// Seconds a careful novice needs for a room's first visit, before the map's TIME_ALLOWANCE
#macro ROOM_VISIT_TIME get_probability_for_difficulty([0, 12, 14, 14, 15])	// Exploring a dark room for its exits and what's in it. A lit room shows everything, so it takes half as long
#macro COLLECTABLE_TIME 1.5					// Picking up each collectable, lit or dark
#macro MISLEADING_OPENING_TIME 7			// Checking each opening more or fewer than its exits that a dark room with misleading exits shows
#macro PORTCULLIS_TRAP_TIME 10				// Finding the button that lifts a trap room's portcullis

/// @function GameRoom(_given_x, _given_y)
/// @description One room of the map: its cell on the map's grid and its exits, the layout it's built from and the
///	random content generated for it, the map roles and spot objects each pass gives it, and its instances and path
///	grids during play
/// @param {real} _given_x Its grid column
/// @param {real} _given_y Its grid row
function GameRoom(_given_x, _given_y) constructor {
	// ============================
	// Public Getter Functions - Called outside of the map generation scripts
	// ============================

	/// @function has_exit(_dir)
	/// @description Whether the room has an exit in a direction
	/// @param {real} _dir A direction, stairs included
	/// @returns {bool}
	static has_exit = function(_dir) {
		return (exits[_dir] != -1);
	};
	
		/// @function get_connected_room(_dir)
	/// @description The room an exit of this room leads to
	/// @param {real} _dir The exit's direction, stairs included
	/// @returns {GameRoom|real} The room, or -1 if there is no exit in that direction
	static get_connected_room = function(_dir) {
		if (_dir > directions.stairs) { return -1; }
		
		return ((exits[_dir] == -1) ? -1 : exits[_dir].get_connected_room(self));
	};

	/// @function is_pre_lit()
	/// @description Whether the room starts with its lanterns lit, as generation decided when the room got its layout
	/// @returns {bool}
	static is_pre_lit = function() {
		return lit;
	};

	// ============================
	// Map Generation Exit Type Functions
	// ============================
	
	/// @function can_gain_exits()
	/// @description Whether the room may still gain exits: any room but one only reached by stairs. Every room gets a new
	///	layout each pass, so a room's exits can change while the map grows.
	/// @returns {bool}
	static can_gain_exits = function() {
		return !has_no_cardinal_exits;
	};

	/// @function can_become_special_room(_layout)
	/// @description Whether the room can take a special room layout: never the start or heart room, or a room with a cardinal
	///	exit to either, and a hall of mirrors never has stairs, which would let the player leave it unsolved
	/// @param {RoomLayout} _layout The special room layout
	/// @returns {bool}
	static can_become_special_room = function(_layout) {
		// Start and Heart room can't be special
		if (is_start_room || is_heart_room) { return false; }
		// The Hall of Mirrors can't have stairs
		if (_layout.has_hall_of_mirrors && has_exit(directions.stairs)) { return false; }
		
		// Special rooms can't be connected to start or heart rooms
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			var _connected_room = get_connected_room(_dir);
			if (_connected_room != -1 && (_connected_room.is_heart_room || _connected_room.is_start_room)) { return false; }
		}
		
		// Otherwise, this room can become a special room
		return true;
	};

	/// @function get_exit_type()
	/// @description The layout exit kind matching the room's real cardinal exits
	/// @returns {real} A layout_exit_types kind
	static get_exit_type = function() {
		return get_exit_type_for_count(get_cardinal_exits_count());
	};

	/// @function get_cardinal_exits_count()
	/// @description How many cardinal exits the room has
	/// @returns {real}
	static get_cardinal_exits_count = function() {
		var _exit_count = 0;
		for (var _dir = directions.up; _dir < directions.stairs; _dir++;) { if (has_exit(_dir)) { _exit_count += 1; } }
		return _exit_count;
	};

	/// @function get_exit_type_for_count(_exit_count)
	/// @description The layout exit kind for a number of cardinal exits. For two exits, it uses whether the room's own
	///	cardinal exits are on opposite sides.
	/// @param {real} _exit_count How many cardinal exits, 0 to 4
	/// @returns {real} A layout_exit_types kind
	static get_exit_type_for_count = function(_exit_count) {
		switch (_exit_count) {
			case 0: return layout_exit_types.none;
			case 1: return layout_exit_types.one;
			case 2: return has_opposite_exits() ? layout_exit_types.two_opposite : layout_exit_types.two_perpendicular;
			case 3: return layout_exit_types.three;
			default: return layout_exit_types.four;
		}
	};

	/// @function has_opposite_exits()
	/// @description Whether the room has cardinal exits on two opposite sides
	/// @returns {bool}
	static has_opposite_exits = function() {
		return (has_exit(directions.up) && has_exit(directions.down)) || (has_exit(directions.left) && has_exit(directions.right));
	};

	/// @function get_exit_type_with_new_exit(_dir)
	/// @description The layout exit kind the room's real cardinal exits would match with one more exit in a direction
	/// @param {real} _dir A cardinal direction the room has no exit in yet
	/// @returns {real} A layout_exit_types kind
	static get_exit_type_with_new_exit = function(_dir) {
		var _exit_count = get_cardinal_exits_count() + 1;
		if (_exit_count == 2) { return has_exit(get_opposite_dir(_dir)) ? layout_exit_types.two_opposite : layout_exit_types.two_perpendicular; }
		return get_exit_type_for_count(_exit_count);
	};

	/// @function would_fit_layout_with_new_exit(_dir, _layout, _linked_room)
	/// @description Whether one more exit in a direction would let the room take a special room layout: the exit gives it the
	///	layout's exit kind, the room can become that special room, and the new exit doesn't lead to the start or heart room
	/// @param {real} _dir A cardinal direction the room has no exit in yet
	/// @param {RoomLayout} _layout The special room layout
	/// @param {GameRoom|undefined} _linked_room The room the new exit leads to, or undefined for a new room
	/// @returns {bool}
	static would_fit_layout_with_new_exit = function(_dir, _layout, _linked_room) {
		if (get_exit_type_with_new_exit(_dir) != _layout.exit_type || !can_become_special_room(_layout)) { return false; }
		return is_undefined(_linked_room) || !(_linked_room.is_start_room || _linked_room.is_heart_room);
	};
	
	// ============================
	// Map Generation Getters
	// ============================

	/// @function can_be_start()
	/// @description Whether the room can be the start: never a room with stairs. The start is chosen before any room gets
	///	a layout, and special layouts only go to other rooms.
	/// @returns {bool}
	static can_be_start = function() {
		return !has_exit(directions.stairs);
	};
	
	/// @function can_be_heart(_start)
	/// @description Whether the room can be the heart for a given start: never the start itself, never a room with stairs,
	///	which would be a way in past its locked doors, and never linked by a cardinal exit to the start. The heart is chosen
	///	before any room gets a layout, so special layouts, the hall of mirrors among them, keep away from it instead.
	/// @param {GameRoom} _start The start candidate
	/// @returns {bool}
	static can_be_heart = function(_start) {
		if (self == _start || has_exit(directions.stairs)) { return false; }
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			if (get_connected_room(_dir) == _start) { return false; }
		}
		return true;
	};
	
	/// @function has_floor_key()
	/// @description Whether a key lies on one of the room's collectable spots: its own key, unless that's in a chest, or the
	///	extra key the first bomb standing in for a key brings
	/// @returns {bool}
	static has_floor_key = function() {
		return (has_key && !has_chest_key) || has_extra_key;
	};

	/// @function get_floor_item_count()
	/// @description How many items lie on the room's floor for hands to come for: a key on one of its key spots
	/// @returns {real}
	static get_floor_item_count = function() {
		return has_floor_key() ? 1 : 0;
	};
	
	/// @function has_gudetama_item()
	/// @description Whether the room's chest holds an item that can defeat a gudetama or get the player past it: a sword, a
	///	bomb or a special staff. A locked or hidden chest counts too, but the keys and bombs placed for the locks don't,
	///	since the locks need them.
	/// @returns {bool}
	static has_gudetama_item = function() {
		if (!has_chest() || has_chest_key) { return false; }

		return chest_content_object_type == obj_sword || chest_content_object_type == obj_bomb || (chest_content_object_type == obj_staff && has_special_item);
	};
	
	/// @function has_basic_chest()
	/// @description Whether the room holds a chest that is not locked, hidden, trapped, or containing a special item
	/// @returns {bool}
	static has_basic_chest = function() {
		return has_chest() && !has_hidden_chest() && !has_trap_chest() && !has_locked_chest && !has_special_item;
	};

	/// @function has_chest()
	/// @description Whether the room holds a chest, hidden or not
	/// @returns {bool}
	static has_chest = function() {
		return chest_spot_object_type == obj_chest || chest_spot_object_type == obj_hidden_chest || stairs_spot_object_type == obj_chest || stairs_spot_object_type == obj_hidden_chest;
	};
	
	/// @function has_hidden_chest()
	/// @description Whether the room's chest is a hidden chest
	/// @returns {bool}
	static has_hidden_chest = function() {
		return chest_spot_object_type == obj_hidden_chest || stairs_spot_object_type == obj_hidden_chest;
	};
	
	/// @function has_trap_chest()
	/// @description Whether the room's chest holds a statue or fountain trap instead of an item
	/// @returns {bool}
	static has_trap_chest = function() {
		return chest_content_object_type == obj_statue || chest_content_object_type == obj_fountain;
	};
	
	/// @function can_have_chest()
	/// @description Whether the room is allowed to have a chest added to it: not the start or heart room, with nothing on
	///	its stairs spot yet
	/// @returns {bool}
	static can_have_chest = function() {
		return (!has_chest() && !is_start_room && !is_heart_room);
	};
	
	/// @function can_have_hazard_with_eyes(_hazard_name)
	/// @description Whether generation may randomly add a hazard to the room when it already has eyes
	/// @param {string} _hazard_name The hazard's name in the hazards table
	/// @returns {bool}
	static can_have_hazard_with_eyes = function(_hazard_name) {
		return !has_eyes || !hazard_has_tag(_hazard_name, TARGETS_PLAYER_TAGS);
	};

	/// @function can_have_phantom()
	/// @description Whether generation may randomly add a phantom to the room: an unlit lantern room with no hidden chest,
	///	which isn't the start room, a special room or a portcullis trap room
	/// @returns {bool}
	static can_have_phantom = function() {
		return has_lanterns && !is_pre_lit() && !has_hidden_chest() && !is_start_room && !is_special_room && !has_portcullis_trap;
	};

	/// @function can_have_special_exit_types()
	/// @description Whether the room can have illusion walls, portcullis traps and plain doors: it isn't only reached by
	///	stairs, isn't the start or heart room, and isn't a hall of mirrors or linked to one
	/// @returns {bool}
	static can_have_special_exit_types = function() {
		return (!has_no_cardinal_exits && !is_start_room && !is_heart_room && !is_connected_to_hall_of_mirrors());
	};

	/// @function is_connected_to_hall_of_mirrors()
	/// @description Whether the room is a hall of mirrors, or is linked to one by a cardinal exit
	/// @returns {bool}
	static is_connected_to_hall_of_mirrors = function() {
		if (has_hall_of_mirrors) { return true; }
		
		for (var _dir = directions.up; _dir < directions.stairs; _dir++;) {
			var _next_exit = exits[_dir];
			if (_next_exit == -1) { continue; }
			
			var _next_room = _next_exit.get_connected_room(self);
			if (_next_room.has_hall_of_mirrors) { return true; }
		}
		
		return false;
	};

	/// @function can_have_portcullis_trap()
	/// @description Whether the room can become a portcullis trap room: it can have special exit types, none of its
	///	cardinal exits has a door or illusion walls or leads to another trap room, and it has a free spot for the button
	/// @returns {bool}
	static can_have_portcullis_trap = function() {
		if (!can_have_special_exit_types()) { return false; }
		
		// Check each of the room's cardinal exits
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			// Skip if there is no exit in this direction
			var _exit = exits[_dir];
			if (_exit == -1) { continue; }
			
			// Return false if this exit is already in use some other way
			if (_exit.exit_type != exit_types.none) { return false; }
		}
		
		// Return whether there is a spot for the button: the stairs or chest spot when one is open, or else a clear collectable
		// spot with another left for the floor key, since building places the button first
		return has_open_stairs_or_chest_spot() || (array_length(layout.button_spots) > 0 && array_length(layout.key_spots) > (has_floor_key() ? 1 : 0));
	};

	/// @function has_open_stairs_or_chest_spot()
	/// @description Whether the room's stairs spot or chest spot is free with nothing else on it, so the portcullis button
	///	can take it without anything holding it down
	/// @returns {bool}
	static has_open_stairs_or_chest_spot = function() {
		return (stairs_spot_object_type == -1 && layout.stairs_spot_is_alone) || (chest_spot_object_type == -1 && layout.chest_spot_is_alone);
	};

	/// @function can_have_collectables()
	/// @description Whether the room has a collectable spot left for collectables
	/// @returns {bool}
	static can_have_collectables = function() {
		return get_free_collectable_spot_count() > 0;
	};

	/// @function get_free_collectable_spot_count()
	/// @description How many of the room's collectable spots are left for collectables, once its floor key has one, and its
	///	portcullis button has one when the stairs and chest spots are both taken. Building picks every spot, the button first.
	/// @returns {real}
	static get_free_collectable_spot_count = function() {
		var _taken_spot_count = (has_floor_key() ? 1 : 0) + ((has_portcullis_trap && !has_open_stairs_or_chest_spot()) ? 1 : 0);
		return array_length(layout.key_spots) - _taken_spot_count;
	};

	/// @function can_light_torch()
	/// @description Whether a torch can be lit in the room: its lanterns start lit, or something in it shoots fireballs that
	///	light a torch dropped in their way
	/// @returns {bool}
	static can_light_torch = function() {
		return is_pre_lit() || (count_hazards_with_tags(get_actual_mapgen_spawns(), hazard_tags.lights_torches) > 0);
	};

	/// @function can_have_floater()
	/// @description Whether generation may randomly add a floater to the room: one with no phantom, which isn't the start
	///	room, a special room or a portcullis trap room
	/// @returns {bool}
	static can_have_floater = function() {
		return !has_phantom && !is_start_room && !is_special_room && !has_portcullis_trap;
	};

	/// @function can_have_special_item()
	/// @description Whether the room is allowed to have a special item added to it: it has no chest yet, has none yet, isn't a special room, and it is at least
	///	two rooms from the start
	/// @returns {bool}
	static can_have_special_item = function() {
		return (can_have_chest() && !is_special_room && !has_special_item && distance_to_start >= 2);
	};

	/// @function has_regular_item_chest()
	/// @description Whether the room has a chest with a regular item: not a special item, not a trap, and not a key or
	///	bomb placed for the locks
	/// @returns {bool}
	static has_regular_item_chest = function() {
		return (has_chest() && !has_special_item && !has_chest_key && !has_trap_chest());
	};

	/// @function is_wrath_room()
	/// @description Whether the room is wrath's special room, whose chest takes a trip to the start cross and back
	/// @returns {bool}
	static is_wrath_room = function() {
		return is_special_room && special_room_type.name == "wrath";
	};

	// ============================
	// Map Generation Functions
	// ============================
	
	/// @function calculate_reachable_rooms_bitmask()
	/// @description Every room the player can reach from this one without opening a lock, through cardinal exits and
	///	stairs
	/// @returns {real} Bitmask of those rooms, this one included, by map_rooms_index
	static calculate_reachable_rooms_bitmask = function() {
		// For each room in the queue, add to the queue all new rooms reachable from that room
		var _queue = [self], _reached_rooms_bitmask = 0;
		while (array_length(_queue) > 0) {
			// Get the next room in the queue and mark it as reached in the bitmask
			var _room = array_shift(_queue);
			_reached_rooms_bitmask |= (1 << _room.map_rooms_index);
			
			// For each exit out of this room, including stairs, add new connecting rooms to the queue
			for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
				// Skip rooms with no exit or a locked exit
				var _exit = _room.exits[_dir];
				if (_exit == -1 || _exit.exit_type == exit_types.locked_doors) { continue; }
				
				// Skip if the room connected by this exit is already in the bitmask
				var _other_room = _exit.get_connected_room(_room);
				if ((_reached_rooms_bitmask & (1 << _other_room.map_rooms_index)) != 0) { continue; }
				
				// Otherwise, add the connecting room to the queue
				array_push(_queue, _other_room);
			}
		}

		return _reached_rooms_bitmask;
	};

	/// @function determine_layout_exit_type()
	/// @description Picks the exit kind of the layouts the room can use: usually the kind of its real cardinal exits,
	///	but sometimes one with more or fewer openings, which makes its exits misleading
	/// @returns {real} A layout_exit_types kind
	static determine_layout_exit_type = function() {
		// Start with the real exit count for this room
		var _exit_count = get_cardinal_exits_count();
		
		if (get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY)) {
			// Pick whether the layout shows more or fewer exits than the room has. A room with one exit or none always shows
			// more and a room with four always shows fewer, so the count always changes
			var _step = get_coin_flip() ? 1 : -1;
			if (_exit_count <= 1) { _step = 1; }
			if (_exit_count == 4) { _step = -1; }
			
			// Keep adding or removing exits, for a chance to be even more misleading
			while (_exit_count + _step >= 1 && _exit_count + _step <= 4) {
				_exit_count += _step;
				if (!get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY)) { break; }
			}
			
			// The room's own exits can't decide which kind of two exit layout it shows, so pick one at random
			if (_exit_count == 2) { return get_coin_flip() ? layout_exit_types.two_opposite : layout_exit_types.two_perpendicular; }
		}
		
		// Return the exit kind for that many exits
		return get_exit_type_for_count(_exit_count);
	};

	/// @function assign_layout(_layout, _special_room_type, _is_guaranteed_lit_room)
	/// @description Gives the room a layout: sets its room asset, its lanterns and its hall of mirrors from the layout, whether
	///	it's a special room and the guaranteed lit room, and a hall of mirrors' sequence of exits. Its random content went with
	///	its old layout, so it has none until content is determined for this one.
	/// @param {RoomLayout} _layout The layout
	/// @param {SpecialRoomType|undefined} _special_room_type The special room type the layout belongs to, or undefined for a regular layout
	/// @param {bool} _is_guaranteed_lit_room Whether the room is the map's guaranteed lit room, which always starts lit
	static assign_layout = function(_layout, _special_room_type, _is_guaranteed_lit_room) {
		// Assign content based on the room layout
		layout = _layout;
		room_reference = layout.room_reference;
		has_lanterns = layout.has_lanterns;
		has_hall_of_mirrors = layout.has_hall_of_mirrors;
		is_special_room = !is_undefined(_special_room_type);
		special_room_type = _special_room_type;
		is_guaranteed_lit_room = _is_guaranteed_lit_room;

		// A hall of mirrors' sequence of exits to take
		mirror_directions = [];
		if (has_hall_of_mirrors) {
			for (var _mirror = 0; _mirror < 4; _mirror++) { array_push(mirror_directions, get_random_cardinal_dir()); }
		}
	};

	/// @function determine_layout_orientation()
	/// @description Flips the room's layout at random, then picks a random rotation among those that put the most of its
	///	openings on the room's real cardinal exits
	static determine_layout_orientation = function() {
		flip_horizontal = get_coin_flip();
		flip_vertical = get_coin_flip();

		// Where the layout's openings end up once flipped
		var _open_dirs = layout.get_open_cardinal_exits();
		for (var _dir = 0; _dir < array_length(_open_dirs); _dir++) {
			var _open_dir = _open_dirs[_dir];
			if (flip_horizontal && (_open_dir == directions.left || _open_dir == directions.right)) { _open_dir = get_opposite_dir(_open_dir); }
			if (flip_vertical && (_open_dir == directions.up || _open_dir == directions.down)) { _open_dir = get_opposite_dir(_open_dir); }
			_open_dirs[_dir] = _open_dir;
		}
	
		// Keep the rotations that put the most openings on real cardinal exits, and pick one at random
		var _best_rotations = [], _most_matches = -1;
		for (var _rotation = directions.up; _rotation < directions.stairs; _rotation++) {
			var _matches = 0;
			for (var _dir = 0; _dir < array_length(_open_dirs); _dir++) {
				if (has_exit(get_rotated_dir(_open_dirs[_dir], _rotation))) { _matches += 1; }
			}
			if (_matches > _most_matches) { _most_matches = _matches; _best_rotations = []; }
			if (_matches == _most_matches) { array_push(_best_rotations, _rotation); }
		}
		rotate = array_random_get(_best_rotations);
	};

	/// @function determine_lighting()
	/// @description Randomly determines whether the room starts with its lanterns lit. The guaranteed lit room always does, so
	///	the map has a lit room, and a special room never does.
	static determine_lighting = function() {
		lit = has_lanterns && !is_special_room && (is_guaranteed_lit_room || get_random_chance_out_of(PRE_LIT_PROBABILITY));
	};
	
	/// @function set_chest_or_stairs_spot_object(_object)
	/// @description Places the room's stairs spot object (the cross, the encased heart, or a chest), and picks whether
	///	it goes on the stairs spot or the chest spot, based on which is already full and a random chance check if neither are.
	/// @param {Asset.GMObject} _object What to place
	static set_chest_or_stairs_spot_object = function(_object) {
		// Return if neither spot is free
		var _stairs_spot_free = (stairs_spot_object_type == -1), _chest_spot_free = (chest_spot_object_type == -1);
		if (!_stairs_spot_free && !_chest_spot_free) {
			// This should NEVER happen, since generation only places these in rooms with a free spot, and counts on them being placed
			write_debug_message("Tried to add object " + object_get_name(_object) + " to room, but its stairs spot (" + object_get_name(stairs_spot_object_type) + ") and chest spot (" + object_get_name(chest_spot_object_type) + ") were already taken.", debug_message_level.error);
			return false;
		}
		
		// Otherwise, pick the free spot if only one is occupied
		if (!_stairs_spot_free) { chest_spot_object_type = _object; }
		else if (!_chest_spot_free) { stairs_spot_object_type = _object }
		// Otherwise, pick based on th eobject type
		else if (_object == obj_cross) { stairs_spot_object_type = _object; }
		// Otherwise, pick the spot with a weighted random chance
		else if (get_random_chance_out_of(CHEST_ON_STAIRS_SPOT_PROBABILITY)) { stairs_spot_object_type = _object; }
		else { chest_spot_object_type = _object }
	};

	/// @function add_special_room_chest()
	/// @description Puts the chest of the room's special room type in it, always locked, with no item yet. Pride, envy and
	///	wrath hide one that holds a special item, which building moves onto a giant eye in envy and onto an inverted cross in
	///	wrath. Greed shows one whose item starts as a regular item, which the room's red chest can make special, and sloth
	///	one that holds a special item, always on the chest spot behind the gudetama.
	static add_special_room_chest = function() {
		has_locked_chest = true;
		switch (special_room_type.name) {
			case "greed": { set_chest_or_stairs_spot_object(obj_chest); break; }
			case "sloth": {
				chest_spot_object_type = obj_chest;
				has_special_item = true;
				break;
			}
			default: {
				add_hidden_or_regular_chest(true);
				has_special_item = true;
				break;
			}
		}
	};

	/// @function add_hidden_or_regular_chest([_must_be_hidden])
	/// @description Puts a chest with no item yet in the room. Unless it must be hidden, a hidden chest can only appear in
	///	an unlit lantern room, which then never gets a phantom.
	/// @param {bool} [_must_be_hidden] Whether the chest must be hidden (false by default)
	static add_hidden_or_regular_chest = function(_must_be_hidden = false) {
		var _has_hidden_chest = _must_be_hidden || (has_lanterns && !is_pre_lit() && get_random_chance_out_of(HIDDEN_CHEST_PROBABILITY));
		set_chest_or_stairs_spot_object(_has_hidden_chest ? obj_hidden_chest : obj_chest);
	};
	
	/// @function add_key_chest([_can_use_bomb])
	/// @description Puts a chest with a key type item into the room
	/// @param {bool} [_can_use_bomb] Whether the chest must be hidden (false by default)
	/// @returns {bool} Whether the a bomb was used to stand in for the key
	static add_key_chest = function(_can_use_bomb) {
		// The key chest is never locked or hidden, and never holds a special item
		has_key = true;
		has_chest_key = true;
		set_chest_or_stairs_spot_object(obj_chest);
		
		// Sometimes a bomb stands in for a key
		var _key_is_bomb = _can_use_bomb && get_random_chance_out_of(BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY);
		chest_content_object_type = _key_is_bomb ? obj_bomb : obj_key;
		return _key_is_bomb;
	};

	/// @function add_portcullis_trap()
	/// @description Traps the room: the portcullis on its side of each cardinal exit closes until the player presses its
	///	button. Content decided later gives a trap room no phantom or floater. Building picks the button's spot.
	static add_portcullis_trap = function() {
		// Set the portcullis flag, which also keeps content decided later from giving the room a phantom or floater
		has_portcullis_trap = true;

		// Close the portcullis on the room's side of each cardinal exit
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			var _exit = exits[_dir];
			if (_exit != -1) { _exit.add_portcullis_for_room(self); }
		}
	};

	/// @function determine_room_content(_same_skeleton_type)
	/// @description Randomly determines the room's content, once its layout, map roles, spot objects and special exit types decide
	///	which of its layout's instances survive, so content is only determined for those. Eyes come first. Then each random hazard
	///	is skipped when it would chase or shoot at a player held still by eyes, or take the room past ROOM_DIFFICULTY_SCORE_MAX,
	///	checked against everything the room spawns so far. The start room gets no random hazards but its skeleton types, and
	///	only the ones that aren't dangerous.
	/// @param {Asset.GMObject} _same_skeleton_type The map's same skeleton type, or noone if that event is off
	/// @returns {bool} False if the room still ends up with eyes alongside something that targets the player, so a new map has to be tried
	static determine_room_content = function(_same_skeleton_type) {
		// Determine eyes first, so nothing that chases or shoots at the player joins a room where eyes hold them still
		determine_eyes();

		// Determine how many columns and statues to replace with fountains, up to a total of MAX_REPLACED_FOUNTAINS between them
		if (!is_start_room && can_have_hazard_with_eyes("obj_fountain")) {
			for (var _column = 0; _column < get_object_count("obj_column") && replaced_column_fountain_count < MAX_REPLACED_FOUNTAINS; _column++) {
				if (get_random_chance_out_of(COLUMN_FOUNTAIN_PROBABILITY) && !would_exceed_max_difficulty("obj_fountain")) { replaced_column_fountain_count += 1; }
			}
			for (var _statue = 0; _statue < get_object_count("obj_statue") && replaced_column_fountain_count + replaced_statue_fountain_count < MAX_REPLACED_FOUNTAINS; _statue++) {
				if (get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY) && !would_exceed_max_difficulty("obj_fountain", "obj_statue")) { replaced_statue_fountain_count += 1; }
			}
		}

		// Determine how many of the blocks on block spots come alive
		if (!is_start_room) {
			for (var _block_spot = 0; _block_spot < get_object_count("obj_block_spot"); _block_spot++) {
				if (get_random_chance_out_of(LIVING_BLOCK_PROBABILITY) && !would_exceed_max_difficulty("obj_living_block")) { living_block_count += 1; }
			}
		}

		// Determine lava enemy spawns
		if (!is_start_room && get_object_count("obj_lava") > 0) {
			if (get_random_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY) && !would_exceed_max_difficulty("obj_fire_skeleton")) { initial_fire_skeleton_count = 1; }
			
			for (var _nose_chance = 0; _nose_chance < global.difficulty - 1; _nose_chance++) {
				if (get_random_chance_out_of(NOSE_PROBABILITY) && !would_exceed_max_difficulty("obj_nose")) { initial_nose_count += 1; }
			}
		}
		
		// Determine skeleton spot enemies for the spots the eyes didn't take. A spot keeps its basic skeleton when its random type would not work for this room
		var _skeleton_spot_count = get_object_count("obj_skeleton_spot");
		while (array_length(skeleton_types) < _skeleton_spot_count) {
			// Get the skeleton type, setting it to a regular skeleton in the start room or lit room for invisible skeletons
			var _skeleton_type = (_same_skeleton_type == noone) ? get_skeleton_type() : _same_skeleton_type;
			if ((is_start_room && _skeleton_type != obj_skeleton) || (is_pre_lit() && _skeleton_type == obj_invisible_skeleton)) { _skeleton_type = obj_skeleton; }
			// Set the skeleton type to regular skeleton if it can't coexist with eyes present in the room
			var _skeleton_name = object_get_name(_skeleton_type);
			if (_skeleton_type != obj_skeleton && (!can_have_hazard_with_eyes(_skeleton_name) || would_exceed_max_difficulty(_skeleton_name, "obj_skeleton"))) { _skeleton_type = obj_skeleton; }
			array_push(skeleton_types, _skeleton_type);
		}
		
		// Determine additional enemy spawns, the moving collectable, and the extra mouths higher difficulties add to each one the layout places
		has_phantom = can_have_phantom() && can_have_hazard_with_eyes("obj_phantom") && get_random_chance_out_of(PHANTOM_PROBABILITY) && !would_exceed_max_difficulty("obj_phantom");
		has_floater = can_have_floater() && can_have_hazard_with_eyes("obj_floater") && get_random_chance_out_of(FLOATER_PROBABILITY) && !would_exceed_max_difficulty("obj_floater");
		has_moving_collectable = has_collectables && get_random_chance_out_of(MOVING_COLLECTABLE_PROBABILITY);
		initial_mouth_count = get_object_count("obj_mouth") * (MOUTHS_PER_MOUTH - 1);

		// A final check to make sure the eyes never coexist with anything that targets the player
		var _spawn_counts = get_actual_mapgen_spawns();
		if (count_hazards_with_tags(_spawn_counts, hazard_tags.stops_player_movement) > 0 && count_hazards_with_tags(_spawn_counts, TARGETS_PLAYER_TAGS) > 0) {
			// This should NEVER happen
			write_debug_message("Generation randomly added a hazard that stops the player to a room with one that chases or shoots at them: " + layout.room_name, debug_message_level.warning);
			return false;
		}
		return true;
	};
	
	/// @function determine_eyes()
	/// @description Determines whether the room has eyes, before any of its other random content: the ones its layout places,
	///	or ones randomly put on one of its skeleton spots, outside the start room, when nothing in it chases or shoots at the
	///	player. A fountain trap chest counts, since it shoots at the player once opened, though it's scored as a hazard that doesn't.
	static determine_eyes = function() {
		// Return without spawning if this room already has eyes, is the start room, or can't have random eyes placed
		has_eyes = (get_object_count("obj_eyes") > 0);
		if (has_eyes || is_start_room || get_object_count("obj_skeleton_spot") == 0) { return; }

		// Return without spawning if there is already anything in the room that would shoot directly at the player
		if (chest_content_object_type == obj_fountain || count_hazards_with_tags(get_actual_mapgen_spawns(), TARGETS_PLAYER_TAGS) > 0) { return; }
		
		// Return if midgame spawns could cause there to be something in the room that would shoot directly at the player
		if (get_object_count("obj_lava") > 0) { return; }
		
		// Otherwise, there is a random chance to spawn eyes on a skeleton spot
		if (get_random_chance_out_of(EYES_PROBABILITY) && !would_exceed_max_difficulty("obj_eyes", "obj_skeleton")) {
			// Building shuffles the skeleton types onto the skeleton spots, so the eyes land on a random one
			has_eyes = true;
			array_push(skeleton_types, obj_eyes);
		}
	};

	// ============================
	// Difficulty Score Functions
	// ============================

	/// @function would_exceed_max_difficulty(_hazard_name, [_replaced_hazard_name])
	/// @description Whether one more of a hazard would take the difficulty score of the room's hazards past
	///	ROOM_DIFFICULTY_SCORE_MAX, so generation can skip adding it. What spawns into the room during play counts too, on
	///	average. The room is scored as a player holding nothing meets it, with light only if it starts lit.
	/// @param {string} _hazard_name The hazard's name in the hazards table
	/// @param {string} [_replaced_hazard_name] A hazard the new one takes the place of, like a skeleton spot's basic skeleton
	/// @returns {bool}
	static would_exceed_max_difficulty = function(_hazard_name, _replaced_hazard_name = undefined) {
		// Get the spawn counts with everything determined so far, and one more of the given hazard in place of the one it replaces
		var _potential_spawn_counts = layout.get_spawned_object_counts(get_actual_mapgen_spawns());
		add_to_count_struct(_potential_spawn_counts, _hazard_name, 1);
		if (!is_undefined(_replaced_hazard_name)) { add_to_count_struct(_potential_spawn_counts, _replaced_hazard_name, -1); }
		
		var _empty_handed_mitigation = new HazardMitigation(0, 0, 0, lit ? 1 : 0);
		return _empty_handed_mitigation.get_total_difficulty_score_for_spawn_counts(_potential_spawn_counts) > ROOM_DIFFICULTY_SCORE_MAX;
	};

	/// @function get_current_difficulty_score()
	/// @description The room's difficulty score as it is now: its hazards, with its map roles, spot objects and special exit types
	/// @returns {real}
	static get_current_difficulty_score = function() {
		return get_potential_difficulty_score(get_actual_mapgen_spawns());
	};

	/// @function get_potential_difficulty_score(_mapgen_spawns)
	/// @description The room's difficulty score for some map generation spawn counts, without time. The counts hold what the
	///	layout spawns for sure and the room's actual random content, scored together since hazards make each other worse,
	///	and what spawns into it during play is added on average. Then the rest of the room counts: its collectables, its
	///	trap and its chest's item.
	/// @param {struct} _mapgen_spawns Object names and how many of each spawn in the room during map generation
	/// @returns {real}
	static get_potential_difficulty_score = function(_mapgen_spawns) {
		var _difficulty_score = hazard_mitigation.get_total_difficulty_score_for_spawn_counts(layout.get_spawned_object_counts(_mapgen_spawns));
 
		// Collecting everything crosses the whole room, not just the way to one objective
		if (has_collectables) { _difficulty_score *= COLLECTABLES_EXPOSURE; }
 
		// Shut in until the button is pressed. One button opens every exit, so it counts once
		if (has_portcullis_trap) { _difficulty_score += get_difficulty_score_from_danger(PORTCULLIS_TRAP_DANGER); }
 
		// Items make the rest of the run easier
		if (has_special_item) { _difficulty_score += SPECIAL_ITEM_DIFFICULTY_SCORE; }
		else {
			switch (chest_content_object_type) {
				case obj_rosary: { _difficulty_score += -1.5; break; }			// One extra life
				case obj_sword: { _difficulty_score += -1; break; }				// Kills most enemy types
				case obj_staff: { _difficulty_score += -1; break; }				// Lava, fireballs and beams can't kill you while you hold it
				case obj_meat: { _difficulty_score += -0.75; break; }			// Mitigates the most danger, but you have to use it proactively
				case obj_bomb: { _difficulty_score += -0.5; break; }			// Can kill multiple enemies, but can also kill self
			}
		}
 
		return _difficulty_score;
	};

	// ============================
	// Time Functions
	// ============================

	/// @function get_time_needed()
	/// @description Seconds a careful novice needs for the room's first visit: exploring it, which takes half as long when it's
	///	lit, picking up its collectables, lighting its lanterns to banish its phantom, checking its misleading openings while it's
	///	dark, finding its portcullis trap's button, and the hold-ups its hazards cause
	/// @returns {real}
	static get_time_needed = function() {
		var _time_needed = is_pre_lit() ? (ROOM_VISIT_TIME / 2) : ROOM_VISIT_TIME;
		if (has_collectables) { _time_needed += get_free_collectable_spot_count() * COLLECTABLE_TIME; }
		if (has_phantom) { _time_needed += get_object_count("obj_lantern") * PHANTOM_TIME_PER_LANTERN; }
		if (!is_pre_lit()) { _time_needed += abs(array_length(layout.get_open_cardinal_exits()) - get_cardinal_exits_count()) * MISLEADING_OPENING_TIME; }
		if (has_portcullis_trap) { _time_needed += PORTCULLIS_TRAP_TIME; }
		return _time_needed + get_hazards_time();
	};

	/// @function get_hazards_time()
	/// @description Seconds the room's hazards hold the player up for on each visit, with what spawns into it during play on average
	/// @returns {real}
	static get_hazards_time = function() {
		return HAZARD_TIME_SCALE * get_time_score_for_spawn_counts(layout.get_spawned_object_counts(get_actual_mapgen_spawns()));
	};

	/// @function get_trip_time()
	/// @description Seconds to cross the room again on a trip through the map: as quickly as a lit room, since the player knows
	///	it by then, and held up by its hazards again
	/// @returns {real}
	static get_trip_time = function() {
		return (ROOM_VISIT_TIME / 2) + get_hazards_time();
	};

	// ============================
	// Layout Object Count Functions
	// ============================

	/// @function get_object_count(_object_name)
	/// @description How many instances of an object type the room's layout places, minus those its exit and chest spots destroy when the room is built
	/// @param {string} _object_name The string name of the Game Maker object type
	/// @returns {real}
	static get_object_count = function(_object_name) {
		// Loop through all the covered instances in the layout
		var _count = layout.get_object_count(_object_name);
		for (var _i = 0; _i < array_length(layout.covered_instances); _i++) {
			// Skip instances that don't match the given object name
			var _covered_instance = layout.covered_instances[_i];
			if (_covered_instance.object_name != _object_name) { continue; }
			
			// Reduce the total count for each one building the room destroys
			if (is_covered_instance_destroyed(_covered_instance)) { _count -= 1; }
		}
		return _count;
	};

	/// @function is_covered_instance_destroyed(_covered_instance)
	/// @description Whether building the room destroys one of the layout's instances that an exit or chest spot covers: one of
	///	the spots it's under destroys what's under it. Generation counts the room's instances with this, and building creates
	///	only the ones it keeps, so the counts always match what's built
	/// @param {struct} _covered_instance One of the layout's covered_instances
	/// @returns {bool}
	static is_covered_instance_destroyed = function(_covered_instance) {
		for (var _i = 0; _i < array_length(_covered_instance.destroying_spots); _i++) {
			if (get_spot_destroyed(layout.destroying_spots[_covered_instance.destroying_spots[_i]])) { return true; }
		}
		return false;
	};

	/// @function get_spot_destroyed(_destroying_spot)
	/// @description Whether building the room destroys instances under this exit or chest spot. An open exit destroys its blocked spots,
	/// a closed one its free spots, and illusion walls all of them. The chest spot destroys when the room's chest spot object spawns there.
	/// @param {struct} _destroying_spot One of the layout's destroying_spots
	/// @returns {bool}
	static get_spot_destroyed = function(_destroying_spot) {
		// Return whether the chest spot destroys instances
		if (_destroying_spot.exit_direction == -1) { return destroys_chest_spot(); }
		
		// Return whether the exit spot destroys instances
		var _exit = exits[get_room_dir_for_layout_exit_direction(_destroying_spot.exit_direction)], _is_open = (_exit != -1);
		return (_is_open == _destroying_spot.blocked) || (_is_open && _exit.exit_type == exit_types.illusion_walls);
	};

	/// @function get_room_dir_for_layout_exit_direction(_exit_direction)
	/// @description The room direction a side of the layout faces once the layout is flipped and rotated
	/// @param {real} _exit_direction A cardinal direction of the layout, before it's flipped or rotated
	/// @returns {real}
	static get_room_dir_for_layout_exit_direction = function(_exit_direction) {
		if (flip_horizontal && (_exit_direction == directions.left || _exit_direction == directions.right)) { _exit_direction = get_opposite_dir(_exit_direction); }
		if (flip_vertical && (_exit_direction == directions.up || _exit_direction == directions.down)) { _exit_direction = get_opposite_dir(_exit_direction); }
		return get_rotated_dir(_exit_direction, rotate);
	};

	/// @function get_actual_mapgen_spawns()
	/// @description How many instances of each object type spawn in the room during map generation: what its layout places,
	///	minus what its exit and chest spots destroy, plus its exits, its random content, and what its spot objects add, like
	///	a key on its floor or a trap chest. Content is only determined for the layout's instances that survive, so every count is exact.
	/// @returns {struct}
	static get_actual_mapgen_spawns = function() {
		var _actual_spawns = {}
		
		// Start with what the room's layout places, minus what its exit and chest spots destroy
		var _layout_object_names = variable_struct_get_names(layout.instance_object_counts);
		for (var _i = 0; _i < array_length(_layout_object_names); _i++) {
			var _layout_object_name = _layout_object_names[_i];
			add_to_count_struct(_actual_spawns, _layout_object_name, get_object_count(_layout_object_name));
		}
		
		// Add the actual exit counts
		var _exit_count = 0;
		for (var _dir = directions.up; _dir <= directions.stairs; _dir++) { if (exits[_dir] != -1) { _exit_count += 1; } }
		add_to_count_struct(_actual_spawns, "obj_exit_spot", _exit_count);
		
		// Fill in what spawns on the skeleton spots: the type content gave each one, or a basic skeleton until it gives one
		var _skeleton_spot_count = get_object_count("obj_skeleton_spot");
		for (var _i = 0; _i < _skeleton_spot_count; _i++) {
			add_to_count_struct(_actual_spawns, object_get_name((_i < array_length(skeleton_types)) ? skeleton_types[_i] : obj_skeleton), 1);
		}
		
		// Adjust counts based on what has been spawned. A fountain takes its column or statue's place, but a block that comes alive
		// still counts on its spot, since it can still be pushed. The extra mouths higher difficulties add to each placed one aren't counted
		add_to_count_struct(_actual_spawns, "obj_fountain", replaced_column_fountain_count + replaced_statue_fountain_count);
		add_to_count_struct(_actual_spawns, "obj_statue", -replaced_statue_fountain_count);
		add_to_count_struct(_actual_spawns, "obj_living_block", living_block_count);
		add_to_count_struct(_actual_spawns, "obj_nose", initial_nose_count);
		add_to_count_struct(_actual_spawns, "obj_fire_skeleton", initial_fire_skeleton_count); // These are additional ones spawned in lava
		add_to_count_struct(_actual_spawns, "obj_phantom", has_phantom ? 1 : 0);
		add_to_count_struct(_actual_spawns, "obj_floater", has_floater ? 1 : 0);
		add_to_count_struct(_actual_spawns, "obj_item", get_floor_item_count());
		add_to_count_struct(_actual_spawns, "obj_chest", has_trap_chest() ? 1 : 0);
		add_to_count_struct(_actual_spawns, "obj_collectable", has_moving_collectable ? 1 : 0);
		
		// Return the modified counts
		return _actual_spawns;
	};

	/// @function destroys_chest_spot()
	/// @description Whether building the room destroys what's under its chest spot: its stairs spot object spawns there in a room
	///	with stairs, or when it wasn't placed on the stairs spot, and anything but a hidden chest destroys it
	/// @returns {bool}
	static destroys_chest_spot = function() {
		return chest_spot_object_type != -1 && chest_spot_object_type != obj_hidden_chest;
	};

	// ============================
	// Room Building Functions
	// ============================

	/// @function build(_map)
	/// @description Builds the room once, right after map generation, while the controller points at it: creates its layout's
	///	instances that survive its exit and chest spots, orients them, walls up its exit spots, spawns what generation
	///	determined and placed for it, from fountains and enemies to its key, stairs, chest, button, doors and collectables,
	///	and hides bones or an item under some of its blocks
	/// @param {GameMap} _map The map the room belongs to
	static build = function(_map) {
		// Create the layout's instances, leaving out what the exit and chest spots destroy, then flip game object positions as necessary
		initialize_from_room_reference();
		if (flip_horizontal) { flip_room_contents_horizontally(); }
		if (flip_vertical) { flip_room_contents_vertically(); }
		if (rotate != noone) { rotate_room_contents_around_room_center(rotate); }
		with (obj_game_object) { image_angle = 0; }
		with (obj_placeholder) { image_angle = 0; }
		
		// Wall up each spot of a closed exit that nothing blocks, and put an illusion wall on each spot of an illusion exit. What
		// the spots destroy was never created, so the only blockers left on exit spots are on closed exits
		with (obj_exit_spot) {
			var _existing_exit = other.exits[exit_dir];
			var _blocker_at_pos = (instance_place(x, y, obj_wall) || instance_place(x, y, obj_solid) || instance_place(x, y, obj_lava));
			if (_existing_exit != -1 && _existing_exit.exit_type == exit_types.illusion_walls) { instance_create(x, y, obj_illusion_wall); }
			else if (_existing_exit == -1 && !_blocker_at_pos) {
				instance_create(x, y, obj_wall);
				instance_destroy();
			}
		}
		
		// Break tiles into parts
		with (obj_tile) { initialize_tile(); }
		
		// Spawn Fountains
		for (var _i = 0; _i < replaced_column_fountain_count; _i++) {
			with (get_random_instance(obj_column)) {
				var _new_inst = instance_create(x, y, obj_fountain);
				other.remove_from_instances_at_map_positions(id);
				other.add_to_instances_at_map_positions(_new_inst);
				mark_current_room_for_grid_update();
				instance_destroy();
			}
		}
		for (var _i = 0; _i < replaced_statue_fountain_count; _i++) {
			with (get_random_instance(obj_statue, true)) { // Exact statues only, since fountains are children of obj_statue
				var _new_inst = instance_create(x, y, obj_fountain);
				other.remove_from_instances_at_map_positions(id);
				other.add_to_instances_at_map_positions(_new_inst);
				mark_current_room_for_grid_update();
				instance_destroy(id, false);
			}
		}
		
		// Spawn living blocks instead of regular blocks on some block spots
		for (var _i = 0; _i < living_block_count; _i++) {
			with (get_random_instance(obj_block, true)) { // Exact blocks only, since living blocks are children of obj_block
				var _new_inst = instance_create(x, y, obj_living_block);
				_new_inst.creator = creator;
				creator.spawned_block = _new_inst;
				mark_current_room_for_grid_update();
				instance_destroy(id, false);
			}
		}
		
		// Spawn bones and items under blocks
		var _hand_items = [global.player_left_hand_item, global.player_right_hand_item];
		with (obj_block_spot) {
			if (get_random_chance_out_of(BLOCK_ITEM_PROBABILITY)) {
				if (get_coin_flip()) { instance_create(x, y, obj_bones); }
				else if (_map.special_item_under_block == -1 && array_length(_map.spawned_special_items) < SPECIAL_ITEM_LIMIT && get_random_chance_out_of(BLOCK_SPECIAL_ITEM_PROBABILITY)) {
					_map.special_item_under_block = _map.pick_item_type(true);
					with (instance_create(x, y, _map.special_item_under_block)) { make_item_special(); }
				}
				else {
					// Regular meat rots into bones before the player can reach it, so a bomb takes its place
					var _item_type = _map.pick_item_type(false, true, _hand_items);
					if (_item_type == obj_meat) { _item_type = obj_bomb; }
					array_push(_map.regular_items_under_blocks, _item_type);
					instance_create(x, y, _item_type);
				}
			}
		}
				
		// Spawn skeletons. Generation gave a skeleton type to each skeleton spot left, so the counts should always match
		array_shuffle_ext(skeleton_types);
		var _total_skeletons = instance_number(obj_skeleton_spot);
		if (_total_skeletons != array_length(skeleton_types)) {
			// This should NEVER happen
			write_debug_message("Room has " + string(_total_skeletons) + " skeleton spots for " + string(array_length(skeleton_types)) + " skeleton types: " + room_get_name(room_reference), debug_message_level.warning);
			_total_skeletons = min(_total_skeletons, array_length(skeleton_types));
		}
		for (var _i = 0; _i < _total_skeletons; _i++;) {
			var _skeleton_type = skeleton_types[_i];
			
			var _skeleton_spot = instance_find(obj_skeleton_spot, _i);
			with (_skeleton_spot) { instance_create(x, y, _skeleton_type); }
		}
		with (obj_skeleton_spot) { instance_destroy(); }
			
		// Set up Lava Edge Drawing
		with (obj_lava) { set_up_lava_edge_visibility(true); }
		
		// Spawn Spider
		if (instance_number(obj_spider_spot) > 0) {
			var _spider_spot = get_random_instance(obj_spider_spot);
			with (_spider_spot) { instance_create(x, y, obj_spider); }
			with (obj_spider) { start_waiting(); }
		}
		
		// Spawn noses
		for (var _i = 0; _i < initial_nose_count; _i++;) { instance_create(-16, -16, obj_nose); }
		
		// Spawn fire skeletons
		for (var _i = 0; _i < initial_fire_skeleton_count; _i++;) {
			var _fire_skeleton = instance_create(-16, -16, obj_fire_skeleton);
			with (_fire_skeleton) {  
				if (teleport_to_lava() == noone) { instance_destroy(self, false); }
			}
		}
			
		// If room has mouth, spawn more mouths
		var _extra_mouths = 0;
		while (_extra_mouths < initial_mouth_count) { instance_create(-16, -16, obj_mouth); _extra_mouths += 1; }
			
		// Update objects in room to reflect new x, y position as initial positions
		set_initial_positions();

		// Pre-light room if the room is marked as lit
		if (lit) {
			// This should NEVER happen. Leaving the room unlit isn't a fix, since the lock and key search counted on its light
			if (instance_number(obj_lantern) == 0) { write_debug_message("Room marked as lit has no lanterns: "  + room_get_name(room_reference), debug_message_level.error); }
			with obj_lantern { light_torch(noone, false); }
		}
		
		// Spawn phantoms and floaters
		if (has_phantom) {
			instance_create(-16, -16, obj_phantom);
		}
		if (has_floater) {
			instance_create(-16, -16, obj_floater);
		}
		
		// Find room's stairs and chest spots. Every layout should have one of each, as validated by the RoomLayout initializer
		var _stairs_spot = instance_find(obj_stairs_spot, 0);
		if (_stairs_spot == noone) {
			// This should never happen if every room has a stairs spot
			write_debug_message("Room with no stairs spot: " + room_get_name(room_reference), debug_message_level.error);
		}
		var _chest_spot = instance_find(obj_chest_spot, 0);
		if (_chest_spot == noone) {
			// This should never happen if every room has a chest spot
			write_debug_message("Room with no chest spot: " + room_get_name(room_reference), debug_message_level.error);
		}

		// Spawn stairs spot object
		spawn_spot_object_at(stairs_spot_object_type, _stairs_spot);
		spawn_spot_object_at(chest_spot_object_type, _chest_spot);
		
		// Check if room has portcullis
		var _room_has_portcullis = false;
		for (var _dir = directions.up; _dir < directions.stairs; _dir++;) {
			var _current_exit = exits[_dir];
			if (_current_exit != -1 && _current_exit.has_closed_portcullis_for_room(self)) { _room_has_portcullis = true; break; }
		}
		
		// Setup Collectable Spots
		var _has_floor_key = has_floor_key(), _collectable_spots = [], _possible_button_spots = [], _button_spot = noone, _key_spot = noone;
		with (obj_collectable_spot) { array_push(_collectable_spots, id); }
		
		// Pick the button's spot before the floor key takes one, since generation only checks that the room has a spot left for the
		// button: the stairs or chest spot when it's open with nothing else on it, or a clear collectable spot the key and collectables can spare
		if (_room_has_portcullis) {
			if (stairs_spot_object_type == -1 && layout.stairs_spot_is_alone) { array_push(_possible_button_spots, _stairs_spot); }
			if (chest_spot_object_type == -1 && layout.chest_spot_is_alone) { array_push(_possible_button_spots, _chest_spot); }
			var _needed_collectable_spot_count = (_has_floor_key ? 1 : 0) + (has_collectables ? 1 : 0);
			if (array_length(_collectable_spots) > _needed_collectable_spot_count) {
				var _clear_spots = layout.button_spots;
				for (var _i = 0; _i < array_length(_clear_spots); _i++) { array_push(_possible_button_spots, collectable_spot_instances[_clear_spots[_i]]); }
			}
			_button_spot = array_random_get(_possible_button_spots);
			array_remove_first(_collectable_spots, _button_spot);
		}
		
		// Create floor key on a collectable spot the button didn't take
		if (_has_floor_key) {
			var _key = noone;
			_key_spot = array_random_get(_collectable_spots);
			with (_key_spot) {
				_key = instance_create(x, y, obj_key);
				instance_destroy();
			}
			add_to_instances_at_map_positions(_key);
		}
		
		// Create Button on its spot, and decoy dirt on the other spots it could have taken
		if (_room_has_portcullis) {
			for (var _i = 0; _i < array_length(_possible_button_spots); _i++) {
				// Skip the spots where the key or a collectable will spawn
				var _possible_button_spot = _possible_button_spots[_i];
				if (_possible_button_spot == _key_spot || (has_collectables && array_contains(_collectable_spots, _possible_button_spot))) { continue; }
				var _dirt = instance_create(_possible_button_spot.x, _possible_button_spot.y, obj_dirt);
				
				// Create button and button dirt
				if (_possible_button_spot == _button_spot) {
					var _button = instance_create(_button_spot.x, _button_spot.y, obj_button);
					_button.dirt = _dirt;
					_dirt.has_bug = true;
					_dirt.no_special_bug = true;
					var _dirt_to_spawn = irandom(DIRT_PROBABILITY/2);
					for (var _j = 0; _j < _dirt_to_spawn; _j++) { spawn_dirt(); }
					
					// Remove the spot the button spawned at
					if (_button_spot == _stairs_spot) { stairs_spot_object_type = obj_button; }
					else if (_button_spot == _chest_spot) { chest_spot_object_type = obj_button; }
					else { with (_button_spot) { instance_destroy(); } }
				}
			}
			
			if (_button_spot == noone) {
				// This should NEVER happen, since generation only traps a room with a spot for its button
				write_debug_message("Portcullis button room with no spot for its button: " + room_get_name(room_reference), debug_message_level.warning);
				has_portcullis_trap = false;
				for (_dir = directions.up; _dir < directions.stairs; _dir++) {
					var _current_exit = exits[_dir];
					if (_current_exit == -1) { continue; }
					
					if (_current_exit.exit_type == exit_types.closed_portcullis) { _current_exit.reset_exit_type(); }
				}
			}
		}
		
		// Create collectables in room on remaining collectables spots
		if (has_collectables) {
			var _spawned_collectables = 0, _moving_collectable_spot = (has_moving_collectable) ? get_random_instance(obj_collectable_spot) : noone;
			with (obj_collectable_spot) {
				if (_spawned_collectables == 0 || !get_random_chance_out_of(SKIP_COLLECTABLE_SPAWN_PROBABILITY)) {
					var _new_collectable = instance_create(x, y, obj_collectable);
					if (id == _moving_collectable_spot) { _new_collectable.moving = true; }
					
					_spawned_collectables += 1;
				}
				instance_destroy(); 
			}
			
			if (instance_number(obj_collectable) == 0) { 
				// This should NEVER happen if every room has 2+ collectable spots
				write_debug_message("Room with NO room to spawn collectables: " + room_get_name(room_reference), debug_message_level.warning);
				has_collectables = false;
				array_remove_first(_map.rooms_with_collectables, self);
			}
		}

		// Check each exit for a door or portcullis to create
		var _portcullis_exit_count = 0, _exit_count = 0;
		for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
			// Skip directions that have no exit in the current room
			var _current_exit = exits[_dir];
			if (_current_exit == -1) { continue; }
			
			// Setup exit object and exit counts
			var _current_exit_door_type = _current_exit.get_door_type_for_room(self);
			if (_current_exit_door_type != noone) {			
				// Create door for exit
				var _x_pos = get_exit_x_pos(_dir), _y_pos = get_exit_y_pos(_dir);
				var _door = instance_create(_x_pos, _y_pos, _current_exit_door_type);
				_door.door_for_exit = _current_exit;
				
				// Count the portcullis exit
				if (_current_exit_door_type == obj_portcullis) { _portcullis_exit_count += 1; }
			}
			
			// Always count the exit, and count the stairs exits in portcullis rooms, since they can't be locked by the portcullis
			_exit_count += 1;
			if (_dir == directions.stairs) { _portcullis_exit_count += 1; }
		}
		if (has_portcullis_trap && _portcullis_exit_count != _exit_count) {
			// This should NEVER happen
			write_debug_message("Portcullis button room has exits without a portcullis: " + room_get_name(room_reference), debug_message_level.error);
		}
		with (obj_door) { 
			initialize_door(); 
			close_door();
		}
			
		// Spawn some dirt
		var _dirt_to_spawn = irandom(DIRT_PROBABILITY*2) - DIRT_PROBABILITY;
		for (var _i = 0; _i < _dirt_to_spawn; _i++) { spawn_dirt(); }
		
		// Set up room grids
		mark_current_room_for_grid_update();
	};

	/// @function spawn_spot_object_at(_map)
	/// @description Used to spawn the chest and stairs spot objects at their appropriate spot
	/// @param {Id.Object} _object_type The object type to spawn an instance of
	/// @param {Id.Instance} _spawn_spot The instance of the spot object to spawn the new instance at the position of
	static spawn_spot_object_at = function(_object_type, _spawn_spot) {
		// Skip spawning if spot is missing or no object was generated for this spot
		if (_object_type == -1 || _spawn_spot == noone) { return false; }
		
		var _new_inst = instance_create(_spawn_spot.x, _spawn_spot.y, _object_type);
		if (is_existing_instance(_new_inst)) {
			if (is_special_room && _new_inst.object_index == obj_hidden_chest) {
				// Move a special room's hidden chest onto a random giant eye or inverted cross, or tie it to the hall of mirrors.
				// Greed and sloth get a visible chest from generation instead
				if (instance_number(obj_giant_eye) > 0) {
					var _chosen_eye = get_random_instance(obj_giant_eye);
					_new_inst.x = _chosen_eye.x;
					_new_inst.y = _chosen_eye.y;
					_new_inst.eye_chest = true;
				}
				else if (instance_number(obj_inverted_cross) > 0) {
					var _chosen_cross = get_random_instance(obj_inverted_cross);
					_new_inst.x = _chosen_cross.x;
					_new_inst.y = _chosen_cross.y;
					_new_inst.cross_chest = true;
				}
				else if (has_hall_of_mirrors) { _new_inst.mirror_chest = true; }
			}
			
			switch (_new_inst.object_index) {
				case obj_chest:
				case obj_hidden_chest:
				case obj_cross:
				case obj_stairs:
				case obj_encased_heart:{ 
					add_to_instances_at_map_positions(_new_inst);
					break;
				}
			}
		}
	}

	/// @function initialize_from_room_reference()
	/// @description Creates the room's layout instances when it's built, except those its exit and chest spots destroy, which
	///	generation never counted, and lists its collectable spots in layout order, with noone for a destroyed one, so the
	///	layout's collectable spot numbers still match. A hidden chest destroys what's under it once it shows instead
	static initialize_from_room_reference = function() {
		// Find the layout's instances that building the room destroys
		var _destroyed_instances = [];
		for (var _i = 0; _i < array_length(layout.covered_instances); _i++) {
			var _covered_instance = layout.covered_instances[_i];
			if (is_covered_instance_destroyed(_covered_instance)) { array_push(_destroyed_instances, _covered_instance.instance); }
		}
		
		// Create every other instance, and list the collectable spots
		var _reference_instances = layout.instances_to_create;
		collectable_spot_instances = [];
		for (var _j = 0; _j < array_length(_reference_instances); _j++) {
			var _ref = _reference_instances[_j], _new_instance = noone;
			if (!array_contains(_destroyed_instances, _ref)) { _new_instance = instance_create(_ref.x, _ref.y, asset_get_index(_ref.object_name)); }
			if (_ref.object_name == "obj_collectable_spot") { array_push(collectable_spot_instances, _new_instance); }
		}
	};

	// ============================
	// Midgame Functions
	// ============================

	/// @function destroy()
	/// @description Frees the room's path grids, once the room will never be built again
	static destroy = function() {
		// The mp_grids MUST be cleaned up manually or this will cause a memory leak
		mp_grid_destroy(solid_path_grid);
		mp_grid_destroy(lava_path_grid);
		mp_grid_destroy(empty_path_grid);
	};

	/// @function rebuild_room_grids()
	/// @description Rebuilds the room's solid and lava path grids from the instances in it now: solids block both grids,
	///	and lava blocks the lava grid
	static rebuild_room_grids = function() {
		mp_grid_clear_all(solid_path_grid);
		mp_grid_clear_all(lava_path_grid);
		with (obj_lava_part) { mp_path_grid_add(other.lava_path_grid); }
		with (obj_solid) { mp_path_grid_add(other.solid_path_grid); mp_path_grid_add(other.lava_path_grid); }
	};

	/// @function add_to_instances_at_map_positions(_inst)
	/// @description Records an instance's object in the part of the room it's in, one of a three by three grid, so the
	///	map can draw it there
	/// @param {Id.Instance} _inst The instance
	static add_to_instances_at_map_positions = function(_inst) {
		var _room_map_pos = get_room_map_position(_inst);
		array_push(instances_at_map_positions[_room_map_pos[0]][_room_map_pos[1]], _inst.object_index);
	};

	/// @function remove_from_instances_at_map_positions(_inst)
	/// @description Removes an instance's object type from the part of the room the map draws it in
	/// @param {Id.Instance} _inst The instance
	static remove_from_instances_at_map_positions = function(_inst) {
		var _room_map_pos = get_room_map_position(_inst);
		array_remove_first(instances_at_map_positions[_room_map_pos[0]][_room_map_pos[1]], _inst.object_index);
	};

	/// @function activate_room_instances()
	/// @description Activates the instances the room put away when it was last left
	static activate_room_instances = function() {
		for (var _i = 0; _i < array_length(instances); _i++) {
			instance_activate_object(instances[_i]);
		}
	};

	/// @function deactivate_room_instances()
	/// @description Deactivates the room's non-persistent instances during gameplay
	static deactivate_room_instances = function() {
		instances = [];
		collectable_spot_instances = [];
		
		with (obj_light_source) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_game_object) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_placeholder) { if (!persistent) { array_push(other.instances, id); } }
		for (var _i = 0; _i < array_length(instances); _i++) { instance_deactivate_object(instances[_i]); }
	};

	/// @function flip_room_contents_horizontally()
	/// @description Used during gameplay by the hall of mirrors to flip the room horizontally, updating the exit spots to match
	static flip_room_contents_horizontally = function() {
		with obj_game_object {
		    if (object_index != obj_player) { x = room_width - x; }
		}
		with obj_placeholder {
			x = room_width - x;
		}
		with obj_exit_spot {
			if (exit_dir == directions.right || exit_dir == directions.left) { exit_dir = get_opposite_dir(exit_dir); }
		}
	};

	/// @function flip_room_contents_vertically()
	/// @description Used during gameplay by the hall of mirrors to flip the room vertically, updating the exit spots to match
	static flip_room_contents_vertically = function() {
		with obj_game_object {
		    if (object_index != obj_player) { y = room_height - y; }
		}
		with obj_placeholder {
			y = room_height - y;
		}
		with obj_exit_spot {
			if (exit_dir == directions.up || exit_dir == directions.down) { exit_dir = get_opposite_dir(exit_dir); }
		}
	};

	/// @function rotate_room_contents_around_room_center(_direction_to_face)
	/// @description Rotates the room's instances, other than the player, around the room's center, and turns the exit
	///	spots to match
	/// @param {real} _direction_to_face The direction the room's top side faces once rotated
	static rotate_room_contents_around_room_center = function(_direction_to_face) {
		var _angle = _direction_to_face * 90;
	
		with obj_game_object {
		    if (object_index != obj_player) { 
				image_angle = 0;
				var _x_prev = x - room_width/2;
				var _y_prev = y - room_height/2;
			
				x = ((_x_prev * dcos(_angle)) - (_y_prev * dsin(_angle))) + room_width/2;
				y = ((_y_prev * dcos(_angle)) + (_x_prev * dsin(_angle))) + room_height/2;
				if (!place_snapped(4, 4)) { move_snap(4, 4); }
			}
		}
		with obj_placeholder {
			image_angle = 0;
			var _x_prev = x - room_width/2;
			var _y_prev = y - room_height/2;
			
			x = ((_x_prev * dcos(_angle)) - (_y_prev * dsin(_angle))) + room_width/2;
			y = ((_y_prev * dcos(_angle)) + (_x_prev * dsin(_angle))) + room_height/2;
			if (!place_snapped(4, 4)) { move_snap(4, 4); }
		}
		with obj_exit_spot {
			if (_direction_to_face == directions.right) { exit_dir = get_turn_right_dir(exit_dir); }
			else if (_direction_to_face == directions.left) { exit_dir = get_turn_left_dir(exit_dir); }
			else if (_direction_to_face == directions.down) { exit_dir = get_opposite_dir(exit_dir); }
		}
	};

	/// @function draw_room(_x_pos, _y_pos)
	/// @description Draws the room on the map, once the player has visited it or holds the map: its box, its exits, and
	///	what's in it, as much as the player has seen or their map shows
	/// @param {real} _x_pos The x position to draw this room at
	/// @param {real} _y_pos The y position to draw this room at
	/// @returns {bool} False if the position is off screen, so nothing was drawn
	static draw_room = function(_x_pos, _y_pos) {
		// Only draw the room if the given position is on screen
		if (_x_pos < 0 || _x_pos > room_width || _y_pos < 0 || _y_pos > room_height) { return false; }
		
		// Draw the room once the player has visited it, or while they hold the map (always in test mode)
		var _show_detailed_map = false, _show_collectables = false, _controller = global.controller, _is_test_mode_on = global.is_test_mode;
		with (global.player) {
			_show_detailed_map = (_is_test_mode_on || is_carrying_item(obj_map));
			_show_collectables = (_is_test_mode_on || is_carrying_special_item(obj_map));
		}
		
		if (_show_detailed_map || visited) {
			// Set up colors to draw this room with
			var _blink_frame = is_blink_frame();
			var _bg_color = global.bg_color;
			var _white_color = c_white;
			var _red_color = global.gms_game_color;
		
			// Darken the colors of unvisited rooms on the map
			if (!visited) {
				_white_color = merge_color(_white_color, _bg_color, 0.66);
				_red_color = merge_color(_red_color, _bg_color, 0.66);
			}
			
		    // Draw Room on Map
			var _room_color = lit ? _red_color : _bg_color;
			var _inverse_color = lit ? _bg_color : _red_color;
		    if (_controller.current_room != self || !_blink_frame) {
				draw_sprite_ext(spr_box, 0, _x_pos, _y_pos, 0.875, 0.875, 0, _white_color, 1);
				draw_sprite_ext(spr_box, 0, _x_pos, _y_pos, 0.75, 0.75, 0, _room_color, 1);
			}

		    // Draw Room's Exits on Map
			for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
				if (!has_exit(_dir)) { continue; }
				
				var _exit_color = _bg_color;
				if (!_blink_frame) {
					if (exits[_dir].exit_type == exit_types.locked_doors) { _exit_color = _red_color; }
					else if (exits[_dir].has_closed_portcullis_for_room(_controller.current_room)) { _exit_color = (_is_test_mode_on) ? c_fuchsia : _red_color; }
					else if (exits[_dir].exit_type == exit_types.illusion_walls) { _exit_color = (_is_test_mode_on) ? c_teal : _bg_color; }
				}

				var _x_offset = 0, _y_offset = 0, _x_size = 0.25, _y_size = 0.25;
				switch (_dir) {
					case directions.up: { _y_offset = -8; _y_size += 0.125; break; } 
					case directions.right: { _x_offset = 8; _x_size += 0.125; break; } 
					case directions.down: { _y_offset = 8; _y_size += 0.125; break; } 
					case directions.left: { _x_offset = -8; _x_size += 0.125; break; } 
				}

			    if (has_visited_exit(_dir) || _show_detailed_map) { draw_sprite_ext(spr_box, 0, _x_pos+_x_offset, _y_pos+_y_offset, _x_size, _y_size, 0, _exit_color, 1); }
			}
			
			// Draw room's map position objects
			for (var _yy = 0; _yy < 3; _yy++) {
				for (var _xx = 0; _xx < 3; _xx++) {
					// Check if any map positions exist at this part of the map and draw them if so
					var _room_map_pos_array = instances_at_map_positions[_xx][_yy];
					if (array_length(_room_map_pos_array) > 0) {
						// Get color of instance to draw
						var _pos_color = -1, _pos_sprite = spr_box, _pos_image = 0, _pos_scale = 0.125;
						for (var _i = 0; _i < array_length(_room_map_pos_array); _i++) { 
							var _room_map_obj = _room_map_pos_array[_i];
				

							if (_room_map_obj == obj_cross) {
								if (_show_collectables) { _pos_color = _white_color; _pos_sprite = spr_map_cross; _pos_scale = 1; continue; }
							}
							else if (_room_map_obj == obj_encased_heart || _room_map_obj == obj_heart) {
								if (_show_collectables) { 
									_pos_image = (is_thump_frame()) ? 1 : 0;
									_pos_color = _inverse_color; 
									_pos_sprite = spr_map_heart; 
									_pos_scale = 1; 
									continue;
								}
							}
							else if (_pos_sprite == spr_box) {
								if (_room_map_obj == obj_stairs) {
									if (_show_detailed_map || has_visited_exit(directions.stairs)) { _pos_color = _white_color; continue; }
								}
								else if (_room_map_obj == obj_hole) { _pos_color = _white_color; continue; }
								else if (_is_test_mode_on && has_locked_chest && (_room_map_obj == obj_chest || _room_map_obj == obj_hidden_chest)) { _pos_color = c_aqua; continue; }
								else if (_is_test_mode_on && (has_key || has_extra_key) && ((chest_content_object_type == obj_key && (_room_map_obj == obj_chest || _room_map_obj == obj_hidden_chest)) || _room_map_obj == obj_key)) { _pos_color = c_lime; continue; }
								else if (_is_test_mode_on && has_hidden_chest() && (_room_map_obj == obj_chest || _room_map_obj == obj_hidden_chest)) { _pos_color = c_yellow; continue; }
								else if (_pos_color == -1 && _show_detailed_map && (_show_collectables || _room_map_obj != obj_hidden_chest)) { _pos_color = _inverse_color; }
							}
						}
						
						// Draw obj at pos
						if (_pos_color != -1) {
							var _x_offset = 0, _y_offset = 0;
							if (_xx == 0) { _x_offset -= 3; }
							else if (_xx == 2) { _x_offset += 3; }
							if (_yy == 0) { _y_offset -= 3; }
							else if (_yy == 2) { _y_offset += 3; }
							draw_sprite_ext(_pos_sprite, _pos_image, _x_pos+_x_offset, _y_pos+_y_offset, _pos_scale, _pos_scale, 0, _pos_color, 1); 
						}
					}
				}
			}
		
			// Draw the room's collectables while the player holds the special map
		    if (_show_collectables && has_collectables && !_blink_frame) {
				draw_sprite_ext(spr_collectable, 0, _x_pos, _y_pos, 1, 1, 0, _white_color, 1); 
			}
    
		    // Draw distance information if testing
		    if (_is_test_mode_on && keyboard_check(vk_f1)) {
		       draw_set_color(c_lime);
		        draw_set_halign(fa_center);
		        draw_set_valign(fa_middle);
		        draw_text(_x_pos, _y_pos, string_hash_to_newline(string(distance_to_start)));
		    }
			
			// Draw difficulty information if testing
		    if (_is_test_mode_on && keyboard_check(vk_f2)) {
		       draw_set_color(c_lime);
		        draw_set_halign(fa_center);
		        draw_set_valign(fa_middle);
		        draw_text(_x_pos, _y_pos, string_hash_to_newline(string(room_difficulty_score)));
		    }
			
		}
		
		return true;
	};

	/// @function has_visited_exit(_dir)
	/// @description Whether the room has an exit in a direction that the player has gone through
	/// @param {real} _dir A direction, stairs included
	/// @returns {bool}
	static has_visited_exit = function(_dir) {
		return (exits[_dir] != -1 && exits[_dir].visited);
	};

	// ============================
	// Variables Reset Functions
	// ============================

	/// @function reset_map_generation_pass()
	/// @description Resets all variables that are set during a map generation pass
	static reset_map_generation_pass = function() {
		reset_map_role_variables();
		reset_layout_variables();
		reset_chest_and_collectable_spot_variables();
		reset_random_mapgen_variables();
		reset_difficulty_scoring_variables();
	};

	/// @function reset_map_role_variables()
	/// @description Resets room variables that are set when a room role is assigned
	static reset_map_role_variables = function() {
		is_start_room = false;
		is_heart_room = false;
		distance_to_start = 9999;
		chest_spot_object_type = -1;
		// Only reset the stairs spot object if it is not part of a stairs exit
		stairs_spot_object_type = has_exit(directions.stairs) ? obj_stairs : -1
	};

	/// @function reset_layout_variables()
	/// @description Resets room variables that are set when a RoomLayout is assigned
	static reset_layout_variables = function() {
		layout = undefined;
		room_reference = -1;
		
		has_lanterns = false;
		is_guaranteed_lit_room = false;
		lit = false;
		
		is_special_room = false;
		special_room_type = undefined;
		required_layout = undefined;
		has_hall_of_mirrors = false;
		mirror_directions = [];
		
		flip_horizontal = false;
		flip_vertical = false;
		rotate = noone;
	};

	/// @function reset_chest_and_collectable_spot_variables()
	/// @description Resets room variables that are set when chest and collectable spot are assigned during a map scoring pass
	static reset_chest_and_collectable_spot_variables = function() {
		// Chest Variables
		chest_content_object_type = -1;
		has_locked_chest = false;
		has_special_item = false;
		has_guaranteed_item = false;
		has_chest_key = false;
		
		// Collectable Spot Variables
		has_key = false;
		has_extra_key = false;
		has_collectables = false;
		has_portcullis_trap = false;
	};

	/// @function reset_random_mapgen_variables()
	/// @description Resets room variables that are set when random mapgen content is determined just before the scoring pass
	static reset_random_mapgen_variables = function() {
		has_eyes = false;
		has_phantom = false;
		has_floater = false;
		has_moving_collectable = false;
		replaced_column_fountain_count = 0;
		replaced_statue_fountain_count = 0;
		living_block_count = 0;
		initial_nose_count = 0;
		initial_fire_skeleton_count = 0;
		initial_mouth_count = 0;
		skeleton_types = [];
	};

	/// @function reset_difficulty_scoring_variables()
	/// @description Resets room variables that are set when performing room scoring at the end of a pass
	static reset_difficulty_scoring_variables = function() {
		hazard_mitigation = new HazardMitigation();
		room_difficulty_score = 0;
	};

	// ============================
	// Instance Variables
	// ============================

	// Map Position Values
	virtual_x = _given_x;
	virtual_y = _given_y;
	map_rooms_index = -1; // Unique identifier; this room's index in the map's rooms array
	exits = [-1, -1, -1, -1, -1];
	has_no_cardinal_exits = false; // Only ever reached by stairs, so it never gains a cardinal exit
	
	// Map Generation Pass Values, These get reset multiple times as the map is being built
	reset_map_role_variables();
	reset_layout_variables();
	reset_chest_and_collectable_spot_variables();
	reset_random_mapgen_variables();
	reset_difficulty_scoring_variables();

	// Room Build Variables - Assigned when building the room after a valid map is generated
	instances = [];
	instances_at_map_positions = [[[], [], []], [[], [], []], [[], [], []]];
	collectable_spot_instances = [];		// Its collectable spot instances while it's being built, by spot number
	
	// Gameplay Values - Changed after map generation during gameplay
	visited = false;
	lit_by_player = false;
	mirror_count = 0;
	solid_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	lava_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	empty_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
}

// ============================
// Global Room Functions
// ============================

/// @function mark_current_room_for_grid_update()
/// @description Has the controller rebuild the current room's path grids on its next update
function mark_current_room_for_grid_update() {
	global.controller.grid_update_timer = 1;
}