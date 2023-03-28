extends Control
class_name QmapbspQuakeDraw

var hub : QmapbspQuake1Hub

func draw_quake_text(where : Vector2, text : String,
	add : int = 0, scale_ := Vector2.ONE, center : bool = false
) :
	if text.contains('\n') :
		var nls := text.split('\n')
		for i in nls.size() :
			draw_quake_text(where + Vector2(
				0.0, i * 8 * scale_.y
			), nls[i], add, scale_, center)
		return
		
	if center :
		where -= Vector2(8 * text.length() * 0.5, 0.0) * scale_.x
	var scale_c : float = 8 * scale_.x
	for i in text.length() :
		draw_quake_character(where, text.unicode_at(i) + add, scale_)
		where.x += scale_c
		
const SLIDER_RANGE := 10
func draw_slider(where : Vector2, call : Callable,
	scale_ := Vector2.ONE
) :
	var v : float = call.call()
	v = clampf(v, 0, 1)
	draw_quake_character(where + Vector2(-8, 0), 128, scale_)
	for i in SLIDER_RANGE :
		draw_quake_character(where + Vector2(i * 8.0, 0), 129, scale_)
	draw_quake_character(where + Vector2(SLIDER_RANGE * 8.0, 0), 130, scale_)
	draw_quake_character(where + Vector2((SLIDER_RANGE - 1) * 8.0 * v, 0), 131, scale_)
	
#const CHARSIZE := 0.0625
const CHARSIZE_VEC := Vector2(8, 8)
func draw_quake_character(where : Vector2, num : int, scale_ := Vector2.ONE) :
	var pos := Vector2(num & 15, num >> 4) * 8
	if !hub : return
	draw_texture_rect_region(
		hub.load_as_texture("gfx.wad:CONCHARS"),
		Rect2(where, CHARSIZE_VEC * scale_),
		Rect2(pos, CHARSIZE_VEC)
	)
