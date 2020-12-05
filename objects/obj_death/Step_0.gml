event_inherited();

if (lethal && instance_place(x, y, global.player) && !global.player.dead) {
    global.player.dead = true;
    sound_play(snd_lose);
    sound_play(death_sound);
}

