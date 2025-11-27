extends Area2D

signal edge_selected(edge)

var node_a
var node_b
var weight: int
var is_correct := false
var is_wrong := false

const LINE_WIDTH = 6.0
const CLICK_MARGIN = 8.0

# Nodos visuales
var line_node: Line2D
var collision_shape: CollisionShape2D

func _ready():
	# Configurar el Area2D
	monitoring = true
	monitorable = true
	collision_layer = 2
	collision_mask = 2
	
	# Conectar señales
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup_nodes(a, b, w: int):
	node_a = a
	node_b = b
	weight = w
	
	# Calcular posición central
	var start_pos = a.posicion
	var end_pos = b.posicion
	var center = (start_pos + end_pos) / 2
	global_position = center
	
	# Crear y configurar la línea visual
	line_node = Line2D.new()
	line_node.width = LINE_WIDTH
	line_node.default_color = Color(0.2, 0.2, 0.2)
	line_node.z_index = 5
	line_node.add_point(start_pos - center)
	line_node.add_point(end_pos - center)
	add_child(line_node)
	
	# Crear forma de colisión MÁS ANCHA
	collision_shape = CollisionShape2D.new()
	var shape = WorldBoundaryShape2D.new()
	
	# Calcular parámetros de la línea
	var line_vector = end_pos - start_pos
	var line_length = line_vector.length()
	var line_direction = line_vector.normalized()
	var perpendicular = Vector2(-line_direction.y, line_direction.x)
	
	# Crear un rectángulo delgado a lo largo de la línea
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.size = Vector2(line_length, CLICK_MARGIN * 2)  # Ancho: longitud de línea, Alto: margen de click
	
	collision_shape.shape = rectangle_shape
	collision_shape.position = Vector2.ZERO
	collision_shape.rotation = line_direction.angle()
	
	add_child(collision_shape)
	
	# Crear label del peso
	_create_weight_label(start_pos, end_pos, center)
	
	update_appearance()

func _create_weight_label(start_pos: Vector2, end_pos: Vector2, center: Vector2):
	var label = Label.new()
	label.text = str(weight)
	label.z_index = 10
	
	# Posicionar el label perpendicular a la línea
	var line_dir = (end_pos - start_pos).normalized()
	var perp = Vector2(-line_dir.y, line_dir.x)
	var label_offset = perp * 30  # Más alejado de la línea
	
	label.position = label_offset - Vector2(label.size.x / 2, label.size.y / 2)
	
	# Hacer el texto más legible
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	
	add_child(label)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("🎯 CLICK CONFIRMADO en edge: ", node_a.id, " - ", node_b.id, " | Peso: ", weight)
		edge_selected.emit(self)
		get_viewport().set_input_as_handled()  # Importante: evitar múltiples detecciones

func _on_mouse_entered():
	if line_node:
		line_node.default_color = Color(0.0, 0.6, 1.0)
		line_node.width = LINE_WIDTH + 2
	print("🖱️  Mouse SOBRE edge: ", node_a.id, " - ", node_b.id)

func _on_mouse_exited():
	update_appearance()
	print("🖱️  Mouse FUERA edge: ", node_a.id, " - ", node_b.id)

func set_correct(value: bool):
	is_correct = value
	is_wrong = not value
	update_appearance()

func set_wrong():
	is_correct = false
	is_wrong = true
	update_appearance()

func update_appearance():
	if not line_node:
		return
	
	if is_correct:
		line_node.default_color = Color(0.0, 0.8, 0.0)
		line_node.width = LINE_WIDTH + 1
	elif is_wrong:
		line_node.default_color = Color(0.9, 0.0, 0.0)
		line_node.width = LINE_WIDTH + 1
	else:
		line_node.default_color = Color(0.2, 0.2, 0.2)
		line_node.width = LINE_WIDTH

func _compare_to(other) -> int:
	return weight - other.weight
