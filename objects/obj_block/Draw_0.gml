event_inherited();

/*
// FLICKER WHEN ON TOP OF A RED STAFF HOLDER
if (is_blink_frame()) {
	var blinkers = array_create(0);
	if instance_place(x, y, global.player) {
		with global.player {
			if is_carrying_special_item(obj_staff) { array_push(blinkers, self); }
		}
	}
	var hands = instance_place_all(x, y, obj_hands);
	while (array_length(hands) > 0) {
		var hand = array_pop(hands);
		with hand {
			if is_carrying_special_item(obj_staff) {  array_push(blinkers, self); }
		}
	}

	if (array_length(blinkers) > 0) {
		for (var quadrant = 0; quadrant < 4; quadrant++;) {
			var x_offset = 0, y_offset = 0;
			switch (quadrant) {
				case 0: { y_offset = -8; x_offset = -8; break; }
				case 1: { y_offset = -8; x_offset = 8; break; }
				case 2: { y_offset = 8; x_offset = -8; break; }
				case 3: { y_offset = 8 x_offset = 8; break; }
			}
		
			var prev_sprite_index = sprite_index, place_meeting_blinker = false;
			for (var i = 0; i < array_length(blinkers); i++) {
				if place_meeting(x+x_offset, y+y_offset, blinkers[i]) {
					place_meeting_blinker = true;
					break;
				}
			}
			if (!place_meeting_blinker) {
				var draw_x_pos = (x_offset < 0) ? -8 : 0, draw_y_pos = (y_offset < 0) ? -8 : 0, sprite_x_pos = (x_offset < 0) ? 0 : 8, sprite_y_pos = (y_offset < 0) ? 0 : 8;
				draw_sprite_general(prev_sprite_index, image_index, sprite_x_pos, sprite_y_pos, sprite_width/2, sprite_height/2, x+draw_x_pos, y+draw_y_pos, image_xscale, image_yscale, image_angle, image_blend, image_blend, image_blend, image_blend, image_alpha);
			}
			sprite_index = prev_sprite_index;
		}
	}
	else { event_inherited(); }
}
else { event_inherited(); }
*/