if (process_this_frame()) {
	event_inherited();
	if (global.player.x == x && global.player.y == y) { global.player.hidden = true; }
	if ((instance_place(x,y,global.player) || instance_place(x,y,obj_enemy)) && !occupied) ||
	   (!instance_place(x,y,global.player) && !instance_place(x,y,obj_enemy) && occupied) ||
	   (instance_place(x,y,obj_enemy) && get_random_chance_out_of(16) && instance_place(x,y,obj_enemy).lethal) {
	    rustle_bush();
	}
}
