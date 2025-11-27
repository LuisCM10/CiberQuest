extends Control

signal edge_selected(edge)

var node_a
var node_b
var weight: int
var selected := false
var is_correct := false
var is_wrong := false

const LINE_WIDTH = 3.0
const CLICK_MARGIN = 15.0  # Reducido para más precisión

func _ready():
	# Configurar para recibir eventos de mouse
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	add_to_group("edge_lines")
	
	# Asegurar que procese input
	set_process_input(true)

func connect_nodes(a, b, w: int):
	if a == null or b == null:
		push_error("❌ ERROR: Nodos nulos en connect_nodes")
		queue_free()
		return
	
	node_a = a
	node_b = b
	weight = w
	
	# Calcular el área que contiene la línea
	var start = a.posicion
	var end = b.posicion
	
	var min_x = min(start.x, end.x) - CLICK_MARGIN
	var min_y = min(start.y, end.y) - CLICK_MARGIN
	var max_x = max(start.x, end.x) + CLICK_MARGIN
	var max_y = max(start.y, end.y) + CLICK_MARGIN
	
	position = Vector2(min_x, min_y)
	var size = Vector2(max_x - min_x, max_y - min_y)
	custom_minimum_size = size
	self.size = size
	
	# IMPORTANTE: Asegurar que este control esté por encima de otros
	z_index = 5
	
	queue_redraw()

func _draw():
	if node_a == null or node_b == null:
		return
	
	var color = Color(0.1, 0.1, 0.1)  # Negro por defecto
	if is_correct:
		color = Color(0.0, 0.8, 0.0)  # Verde brillante
	elif is_wrong:
		color = Color(0.9, 0.0, 0.0)  # Rojo brillante
	elif selected:
		color = Color(0.0, 0.5, 1.0)  # Azul cuando seleccionado
	
	var start = node_a.posicion - position
	var end = node_b.posicion - position
	
	# Dibujar línea
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
	
	# Fondo para el texto
	
	
	# Texto
	draw_string(font, label_pos - Vector2(text_size.x/2, -text_size.y/2), 
			   text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0, 0, 0))

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Verificar precisión del click
		var mouse_pos = get_local_mouse_position()
		if is_point_near_line(mouse_pos):
			print("🔵 Edge CLICK PRECISO: ", node_a.id, " - ", node_b.id, " | Peso: ", weight)
			selected = true
			edge_selected.emit(self)
			queue_redraw()
			get_viewport().set_input_as_handled()

# Función de detección PRECISA de click en la línea
func is_point_near_line(point: Vector2) -> bool:
	if node_a == null or node_b == null:
		return false
	
	var start = node_a.posicion - position
	var end = node_b.posicion - position
	
	# Vector de la línea
	var line_vec = end - start
	var line_length = line_vec.length()
	
	if line_length == 0:
		return false
		
	var line_dir = line_vec / line_length
	
	# Vector del punto al inicio de la línea
	var point_vec = point - start
	
	# Proyección del punto sobre la línea
	var projection = point_vec.dot(line_dir)
	
	# Si la proyección está fuera del segmento, calcular distancia a los extremos
	if projection < 0:
		return point.distance_to(start) <= CLICK_MARGIN
	elif projection > line_length:
		return point.distance_to(end) <= CLICK_MARGIN
	else:
		# Calcular el punto más cercano en la línea
		var closest_point = start + line_dir * projection
		var distance = point.distance_to(closest_point)
		
		# Solo retornar true si está suficientemente cerca de la línea
		return distance <= CLICK_MARGIN

func _on_mouse_entered():
	selected = true
	queue_redraw()

func _on_mouse_exited():
	selected = false
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
