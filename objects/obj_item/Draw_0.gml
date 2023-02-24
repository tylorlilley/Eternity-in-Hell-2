if (!is_existing_instance(holder) || (holder.object_index == obj_hands && !holder.activated)) { event_inherited(); }
else { draw_while_carried(); }
