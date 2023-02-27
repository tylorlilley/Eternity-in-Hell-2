#define window_get_showborder
return _window_get_showborder(window_handle());

#define window_set_showborder
var showborder = argument0;

if (os_type != os_linux && showborder) {
  var ww = window_get_width();
  var wh = window_get_height();
} else if (os_type == os_linux) {
  var ww = window_get_width();
  var wh = window_get_height();
}

_window_set_showborder(window_handle(), showborder);
if (os_type != os_linux && showborder) { window_set_size(ww, wh); }
else if (os_type == os_linux) { window_set_size(ww, wh); }
