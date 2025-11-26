extends Area2D
class_name EdgeLine

signal edge_selected(edge)

var node_a
var node_b
var weight: int
var selected := false
var is_correct := false
var is_wrong := false  

var scale_factor := 1.0  

func _ready():
	connect("input_event", Callable(self, "_on_input_event"))

func connect_nodes(a, b, w: int):
	node_a = a
	node_b = b
	weight = w
	selected = false
	is_correct = false
	is_wrong = false
	_update_collision()
	queue_redraw()

func update_scale(factor):
	scale_factor = factor
	queue_redraw()

func _update_collision():
	if node_a == null or node_b == null:
		return
	var start = node_a.global_position * scale_factor
	var end = node_b.global_position * scale_factor
	var length = start.distance_to(end)
	var angle = (end - start).angle()
	$CollisionShape2D.position = (start + end) * 0.5
	$CollisionShape2D.rotation = angle
	$CollisionShape2D.shape.extents = Vector2(length * 0.5, 5 * scale_factor)  # grosor ajustado

func _draw():
	if node_a == null or node_b == null:
		return
	
	# Color según estado
	var color = Color(0.7,0.7,0.7)
	if is_correct:
		color = Color(0,1,0)
	elif is_wrong:
		color = Color(1,0,0)
	
	# Posiciones de los nodos sin escalar
	var start = node_a.global_position
	var end = node_b.global_position
	
	# Dibujar la línea escalada en grosor
	draw_line(start, end, color, 3 * scale_factor)
	
	# Vector de la arista
	var dir = (end - start).normalized()
	#058
	# Posición del peso: 40% desde nodo A hacia B
	var t = 0.61
	var pos_peso = start.lerp(end, t)
	
	# Desplazamiento perpendicular para que el texto no se superponga
	var perp = Vector2(-dir.y, dir.x)
	pos_peso += perp * 3 * scale_factor
	
	# Dibujar el peso con tamaño escalado
	var font = ThemeDB.fallback_font
	@warning_ignore("narrowing_conversion")
	draw_string(font, pos_peso, str(weight), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12 * scale_factor, Color.DIM_GRAY)

@warning_ignore("unused_parameter")
func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		selected = true
		if not is_correct:
			is_wrong = true
		emit_signal("edge_selected", self)
		queue_redraw()

func set_correct(value: bool):
	is_correct = value
	selected = true
	is_wrong = not value
	queue_redraw()

func is_selected() -> bool:
	return selected

# Comparación por peso (para algoritmos como Kruskal)
func _compare_to(other: EdgeLine) -> int:
	return weight - other.weight
