with (death_box) { 
	x = round(other.x/8)*8;
	y = round(other.y/8)*8;
}
if (instance_exists(torch)) { set_instance_to_same_position(torch);  torch.image_xscale = 0.5; }
//with (torch) { 
	//x = round(other.x/8)*8;
	//y = round(other.y/8)*8;
//}