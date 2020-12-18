/// @function								generate_chest();
/// @param		{real} x_pos				The x position at which to create the chest
/// @param		{real} y_pos				The y position at which to create the chest
/// @param		{index} obj_index			The type of object to fill the chest with
/// @param		{boolean} is_special		Whether or not the contained item is a special item
function generate_chest(x_pos, y_pos, obj_index, is_special) {
        var chest = instance_create_depth(x_pos, y_pos, 5, obj_chest)
        chest.contents = obj_index;
		chest.special = (is_special && !ds_list_contains(global.controller.spawned_special_items, obj_index));
		return chest;
}