extends Control

signal edge_selected(edge)

var node_a
var node_b
var weight: int
var selected := false
var is_correct := false
var is_wrong := false

const LINE_WIDTH = 4.0
const CLICK_MARGIN = 10.0  # Margen para hacer click cerca de la línea

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	add_to_group("edge_lines")

func connect_nodes(a, b, w: int):
	if a == null or b == null:
		push_error("❌ ERROR: Nodos nulos en connect_nodes")
		queue_free()
		return
	
	node_a = a
	node_b = b
	weight = w
	
	var start = a.posicion
	var end = b.posicion
	
	# Calcular el rectángulo que contiene la línea con margen
	var min_x = min(start.x, end.x) - CLICK_MARGIN
	var min_y = min(start.y, end.y) - CLICK_MARGIN
	var max_x = max(start.x, end.x) + CLICK_MARGIN
	var max_y = max(start.y, end.y) + CLICK_MARGIN
	
	position = Vector2(min_x, min_y)
	var size = Vector2(max_x - min_x, max_y - min_y)
	custom_minimum_size = size
	self.size = size
	
	queue_redraw()

func _draw():
	if node_a == null or node_b == null:
		return
	
	var color = Color(0.1, 0.1, 0.1)
	if is_correct:
		color = Color(0.0, 0.8, 0.0)
	elif is_wrong:
		color = Color(0.9, 0.0, 0.0)
	
	var start = node_a.posicion - position
	var end = node_b.posicion - position
	
	draw_line(start, end, color, LINE_WIDTH)
	
	# Dibujar peso
	var center = (start + end) / 2
	var dir = (end - start).normalized()
	var perp = Vector2(-dir.y, dir.x)
	var label_pos = center + perp * 20
	
	var text = str(weight)
	var font = ThemeDB.fallback_font
	var font_size = 16
	
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, label_pos - Vector2(text_size.x/2, -text_size.y/2), 
			   text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0))

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Verificar si el click fue realmente cerca de la línea
		if is_point_near_line(get_local_mouse_position()):
			print("🔵 Edge clickeada: ", node_a.id, " - ", node_b.id, " | Peso: ", weight)
			edge_selected.emit(self)
			get_viewport().set_input_as_handled()

# FUNCIÓN CLAVE: Verifica si un punto está cerca de la línea
func is_point_near_line(point: Vector2) -> bool:
	if node_a == null or node_b == null:
		return false
	
	var start = node_a.posicion - position
	var end = node_b.posicion - position
	
	# Calcular distancia del punto a la línea usando proyección vectorial
	var line_vec = end - start
	var line_length = line_vec.length()
	var line_dir = line_vec.normalized()
	
	var point_vec = point - start
	var projection = point_vec.dot(line_dir)
	
	# Si la proyección está fuera del segmento, calcular distancia a los extremos
	if projection < 0:
		return point.distance_to(start) <= CLICK_MARGIN
	elif projection > line_length:
		return point.distance_to(end) <= CLICK_MARGIN
	else:
		# Calcular punto más cercano en la línea
		var closest_point = start + line_dir * projection
		var distance = point.distance_to(closest_point)
		return distance <= CLICK_MARGIN

# También verificar en mouse_entered/exited para mejor feedback visual
func _on_mouse_entered():
	queue_redraw()

func _on_mouse_exited():
	queue_redraw()

func set_correct(value: bool):
	is_correct = value
	is_wrong = not value
	queue_redraw()

func set_wrong():
	is_correct = false
	is_wrong = true
	queue_redraw()

func is_selected() -> bool:
	return selected

func _compare_to(other) -> int:
	return weight - other.weight
