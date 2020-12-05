function __global_object_depths() {
	// Initialise the global array that allows the lookup of the depth of a given object
	// GM2.0 does not have a depth on objects so on import from 1.x a global array is created
	// NOTE: MacroExpansion is used to insert the array initialisation at import time
	gml_pragma( "global", "__global_object_depths()");

	// insert the generated arrays here
	global.__objectDepths[0] = 0; // obj_title
	global.__objectDepths[1] = 0; // obj_controller
	global.__objectDepths[2] = 0; // obj_room
	global.__objectDepths[3] = 0; // obj_exit
	global.__objectDepths[4] = 0; // obj_game_object
	global.__objectDepths[5] = 0; // obj_collectable
	global.__objectDepths[6] = 0; // obj_key_spot
	global.__objectDepths[7] = 0; // obj_key
	global.__objectDepths[8] = 0; // obj_stairs_spot
	global.__objectDepths[9] = 5; // obj_stairs
	global.__objectDepths[10] = -20; // obj_bush
	global.__objectDepths[11] = 4; // obj_bones
	global.__objectDepths[12] = 0; // obj_light_source
	global.__objectDepths[13] = -10; // obj_player
	global.__objectDepths[14] = 0; // obj_item
	global.__objectDepths[15] = -1; // obj_torch
	global.__objectDepths[16] = 1; // obj_lantern
	global.__objectDepths[17] = 0; // obj_solid
	global.__objectDepths[18] = 0; // obj_wall
	global.__objectDepths[19] = 0; // obj_column
	global.__objectDepths[20] = 0; // obj_death
	global.__objectDepths[21] = 0; // obj_door
	global.__objectDepths[22] = 5; // obj_lava
	global.__objectDepths[23] = 0; // obj_enemy
	global.__objectDepths[24] = 0; // obj_phantom
	global.__objectDepths[25] = 0; // obj_skeleton
	global.__objectDepths[26] = 0; // obj_spider
	global.__objectDepths[27] = 0; // obj_mouth
	global.__objectDepths[28] = 0; // obj_eyes


	global.__objectNames[0] = "obj_title";
	global.__objectNames[1] = "obj_controller";
	global.__objectNames[2] = "obj_room";
	global.__objectNames[3] = "obj_exit";
	global.__objectNames[4] = "obj_game_object";
	global.__objectNames[5] = "obj_collectable";
	global.__objectNames[6] = "obj_key_spot";
	global.__objectNames[7] = "obj_key";
	global.__objectNames[8] = "obj_stairs_spot";
	global.__objectNames[9] = "obj_stairs";
	global.__objectNames[10] = "obj_bush";
	global.__objectNames[11] = "obj_bones";
	global.__objectNames[12] = "obj_light_source";
	global.__objectNames[13] = "obj_player";
	global.__objectNames[14] = "obj_item";
	global.__objectNames[15] = "obj_torch";
	global.__objectNames[16] = "obj_lantern";
	global.__objectNames[17] = "obj_solid";
	global.__objectNames[18] = "obj_wall";
	global.__objectNames[19] = "obj_column";
	global.__objectNames[20] = "obj_death";
	global.__objectNames[21] = "obj_door";
	global.__objectNames[22] = "obj_lava";
	global.__objectNames[23] = "obj_enemy";
	global.__objectNames[24] = "obj_phantom";
	global.__objectNames[25] = "obj_skeleton";
	global.__objectNames[26] = "obj_spider";
	global.__objectNames[27] = "obj_mouth";
	global.__objectNames[28] = "obj_eyes";


	// create another array that has the correct entries
	var len = array_length_1d(global.__objectDepths);
	global.__objectID2Depth = [];
	for( var i=0; i<len; ++i ) {
		var objID = asset_get_index( global.__objectNames[i] );
		if (objID >= 0) {
			global.__objectID2Depth[ objID ] = global.__objectDepths[i];
		} // end if
	} // end for


}
