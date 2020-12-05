event_inherited();

if ((instance_place(x,y,global.player) || instance_place(x,y,obj_enemy)) && !occupied) ||
   (!instance_place(x,y,global.player) && !instance_place(x,y,obj_enemy) && occupied) ||
   (instance_place(x,y,obj_enemy) && irandom(15) == 0) {
    obj_bush_rustle();
}

