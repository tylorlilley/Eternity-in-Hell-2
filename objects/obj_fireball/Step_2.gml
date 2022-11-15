with (death_box) { x = other.x; y = other.y; } // TODO: Add x part of speed and y part of speed
if (instance_exists(torch)) { set_instance_to_same_position(torch);  torch.image_xscale = 0.5; }
//with (torch) { 
	//x = round(other.x/8)*8;
	//y = round(other.y/8)*8;
//}