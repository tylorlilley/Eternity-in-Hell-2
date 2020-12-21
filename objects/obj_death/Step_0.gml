if (process_this_frame()) {
	event_inherited();

	var player = instance_place(x, y, global.player);
	var carried_sword = get_carried_item_of_type(obj_sword);
	var carried_rosary = get_carried_item_of_type(obj_rosary);
	if (lethal && player && !global.player.dead) {
		if (carried_sword && killable_by_sword) {
			audio_play_sound( death_sound, 10, false );
			with carried_sword { 
				if (!special) 
				{ 
					var sword_in_ground = instance_create_depth(x, y, 3, obj_sword_in_ground);
					sword_in_ground.image_xscale = carried_sword.image_xscale;
					instance_destroy(); 
				} 
			}
			instance_destroy();
		}
		else if (!stopped_by_rosary || !carried_rosary) {
			if (!stopped_by_special_rosary || !carried_rosary || (carried_rosary && !carried_rosary.special)) {
				kill_player();
				audio_play_sound( death_sound, 10, false );
				visible = true;
			}
		}
	}
}
