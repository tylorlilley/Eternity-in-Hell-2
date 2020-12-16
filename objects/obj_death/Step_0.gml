if (process_this_frame()) {
	event_inherited();

	var player = instance_place(x, y, global.player);
	var carried_sword = get_carried_item_of_type(obj_sword);
	if (lethal && player && !global.player.dead) {
		if (carried_sword && killable_by_sword) {
			audio_play_sound( death_sound, 10, false );
			var sword_in_ground = instance_create_depth(x, y, 3, obj_sword_in_ground);
			sword_in_ground.image_xscale = carried_sword.image_xscale;
			with carried_sword { instance_destroy(); }
			instance_destroy();
		}
		else {
			global.player.dead = true;
			audio_play_sound( snd_lose, 10, false );
			audio_play_sound( death_sound, 10, false );
			visible = true;
		}
	}
}
