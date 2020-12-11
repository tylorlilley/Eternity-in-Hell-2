if (process_this_frame()) {
	event_inherited();

	if ((instance_place(x,y,global.player) || instance_place(x,y,obj_enemy)) && !occupied) ||
	   (!instance_place(x,y,global.player) && !instance_place(x,y,obj_enemy) && occupied) ||
	   (instance_place(x,y,obj_enemy) && irandom(15) == 0 && instance_place(x,y,obj_enemy).lethal) {
	    obj_bush_rustle();
	}
}
