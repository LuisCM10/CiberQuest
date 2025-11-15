extends Node2D
class_name NodePoint  #

@export var node_id: int = -1
@export var radius: float = 20.0
var color: Color = Color(0.0, 0.0, 0.0, 1.0)
var font: Font

func _ready():
	font = ThemeDB.fallback_font
	queue_redraw()

func _draw():
	
	draw_circle(Vector2.ZERO, radius, color)

	
	
	

func set_color(new_color: Color):
	color = new_color
	queue_redraw()
