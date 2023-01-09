event_inherited();
if process_this_frame() {
	if (!carried) {
		if (fuse_timer > 0) {
			fuse_timer -= 1;
			if (fuse_timer % 4 == 0) { play_sound(snd_fuse, false); visible = false; }
			else { visible = true; }
			if (fuse_timer == 0) {
				play_sound(snd_explosion, false);
				shoot_fireball(x-8, y-8);
				shoot_fireball(x+0, y-8);
				shoot_fireball(x+8, y-8);
				shoot_fireball(x-8, y-4);
				shoot_fireball(x+0, y-4);
				shoot_fireball(x+8, y-4);
				shoot_fireball(x-8, y);
				shoot_fireball(x+0, y);
				shoot_fireball(x+8, y);
				shoot_fireball(x-8, y+4);
				shoot_fireball(x+0, y+4);
				shoot_fireball(x+8, y+4);
				shoot_fireball(x-8, y+8);
				shoot_fireball(x+0, y+8);
				shoot_fireball(x+8, y+8);
				if (!special) { instance_destroy(); }
			}
		}
		else { 
			visible = true; 
			// Light bomb fuses with torches and lava
			var torch = instance_place(x, y, obj_torch), lava = instance_place(x, y, obj_lava) ;
			if (lava != noone || (torch != noone && torch.light_source != noone)) {
				play_sound(snd_torchlight, true);
				fuse_timer = 4*irandom_range(5,8);
			}
		}
	}
}

