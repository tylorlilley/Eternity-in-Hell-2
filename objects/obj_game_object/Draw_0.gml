if (sprite_index != -1) {
	// Anything drawn in front of giant worms and bushes, such as a projectile or a carried item, is never hidden
	if (depth <= GIANT_WORM_DEPTH && depth <= BUSH_DEPTH) { draw_self(); exit; }

	// An object is hidden when visible solids, or bushes, cover all four quadrants of its spot, as long as it's drawn
	// behind them. Solids are never hidden this way, and bushes only by solids.

	var _is_solid = (object_index == obj_solid || object_index == obj_illusion_wall || object_is_ancestor(object_index, obj_solid));
	var _solid_at_quadrant = get_instance_at_each_quadrant(obj_solid);
	var _covered_by_solid = ((is_existing_instance(_solid_at_quadrant[0]) && _solid_at_quadrant[0].visible) &&
							(is_existing_instance(_solid_at_quadrant[1]) && _solid_at_quadrant[1].visible) &&
							(is_existing_instance(_solid_at_quadrant[2]) && _solid_at_quadrant[2].visible) &&
							(is_existing_instance(_solid_at_quadrant[3]) && _solid_at_quadrant[3].visible) &&
							depth > GIANT_WORM_DEPTH)
	
	var _is_bush = (object_index == obj_bush);
	var _covered_by_bush = (instance_number(obj_bush) > 0 && depth > BUSH_DEPTH && is_covered_at_each_quadrant_by(obj_bush));

	// Skip drawing sprite completely if covered by a bush or solid
    var _covered = false;
	if ((!_is_solid && !_is_bush && _covered_by_bush) || (!_is_solid && _covered_by_solid)) { _covered = true; }

	// Draw main sprite
	if (!_covered) { draw_self(); }
}