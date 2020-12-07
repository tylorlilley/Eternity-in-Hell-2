var offset = irandom(7);
if (offset == 0) { y -= 16; }
if (offset == 1) { x += 16; }
if (offset == 2) { y += 16; }
if (offset == 3) { x -= 16; }

if (offset == 4 || offset == 5) { lethal = false; }
else { lethal = true; }

if ((instance_number(obj_mouth) > 0) && instance_find(obj_mouth, 0).id == id) { audio_play_sound( snd_squelch, 10, false ); }

