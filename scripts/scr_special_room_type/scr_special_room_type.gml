/// @function SpecialRoomType(_name, _room_references)
/// @description One type of special room a map can include, with its name and dedicated layouts
/// @param {string} _name						A name for the room type
/// @param {array} _room_references				Room assets for the special room layouts
function SpecialRoomType(_name, _room_references) constructor {
	// ========================
	// Instance Variables
	// ========================
	name = _name;
	room_references = _room_references;
	layouts = array_create(array_length(room_references), -1); // Assigned from the cache at runtime in the GameMap constructor
}