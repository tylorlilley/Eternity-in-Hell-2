event_inherited();

image_speed = 1;

dir = -1;
				
// Set initial direction to be away from player if possible
var start_dir = irandom(3);
for (var i = 0; i < 4; i++) {
	var next_dir = ((i+start_dir) % 4)
	if (is_direction_toward(next_dir, global.player)) { dir = get_opposite_dir(next_dir); break; }
}

if (global.difficulty < difficulties.medium) {
	instance_create(x, y, obj_skeleton); 
	instance_destroy();
}
else { play_sound(snd_hiss, false); }
