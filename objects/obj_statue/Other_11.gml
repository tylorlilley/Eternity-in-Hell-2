/// @description Step

// Determine initial direction if not set
if (dir == directions.none) {
	if (!place_meeting(x, y-8, obj_solid)) { dir = directions.up; } 
	else if (!place_meeting(x+8, y, obj_solid)) { dir = directions.right; } 
	else if (!place_meeting(x, y+8, obj_solid)) { dir = directions.down; } 
	else if (!place_meeting(x-8, y, obj_solid)) { dir = directions.left; }
	else { covered = true; }
}
	
// Setup direction spot
var x_pos = x, y_pos = y;
switch (dir) {
	case directions.up: { y_pos -= 8; break; }
	case directions.right: { x_pos += 8; break; }
	case directions.down: { y_pos += 8; break; }
	case directions.left: { x_pos -= 8; break; }
}
	
// Determine whether statue is covered
var prev_covered = covered;
covered = place_meeting(x_pos, y_pos, obj_solid);
	
if (!covered) {
	image_index = 0
	image_angle = dir * -90;
	shoot_timer = (prev_covered) ? irandom_range(8, 24) : shoot_timer-1;
	if (shoot_timer <= 0) {
		shoot_timer = irandom_range(8, 24);
		shoot_fireball(x_pos, y_pos, false);
	}
}
else if (image_index == 0) {
	image_index = 1;
	play_sound(snd_give_up, false);
}
	
event_inherited();
