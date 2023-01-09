if (holder == noone || holder == global.controller) { event_inherited(); ; }
else if (holder.object_index != obj_player) { draw_while_carried(draw_y_offset, carried); }

