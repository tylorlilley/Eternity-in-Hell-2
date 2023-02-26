/// @description Step

var fall_asleep = false;
if (awake && !moved && target_path != noone) { fall_asleep = move_ears(); }
else { fall_asleep = !moved; }
	
if (fall_asleep) {
	sprite_index = get_sprite_to_use(spr_ears);
	awake = false;
}
	
event_inherited();