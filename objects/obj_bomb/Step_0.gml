event_inherited();
if process_this_frame() {
	if (!carried && fuse_timer > 0) {
		fuse_timer -= 1;
		if (fuse_timer % 4 == 0) { play_sound(snd_fuse); visible = false; }
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
			else { visible = true; }
		}
	}
}

