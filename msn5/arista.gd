class_name Arista extends Area2D

@onready var linea = Line2D.new()
@onready var flecha = Polygon2D.new()

@onready var colission = CollisionShape2D.new()

const LINEA_DE_CONEXION_NODOS = "conexion"
signal linea_presionada(linea)

var origen : Nodo
var destino : Nodo
var duracion = 1
var progress = 0.0
var tamano_flecha = 12.0
var tipo
var funcion = ""
var color
var start_point
var end_point
var line

var selected := false      # si la arista fue seleccionada
var is_correct := false    # si es correcta (verde)
var is_wrong := false      # si es incorrecta (rojo)



func _init(origen, destino, tipo = "Dirigido", color = Color(0,0,0)) -> void:
	self.origen = origen
	self.destino = destino
	self.tipo = tipo
	self.color = color
	
func _ready() -> void:	
	name = str(origen.id) + "_" + str(destino.id)
	line = linea
	add_child(linea)
	if funcion == LINEA_DE_CONEXION_NODOS:
		add_child(colission)
	if tipo == "Dirigido":
		add_child(flecha)
	name = funcion + str(origen.id) + "_" + str(destino.id)
	var shape = RectangleShape2D.new()
	colission.shape = shape
	linea.points = [origen.posicion, origen.posicion]
	linea.default_color = color
	linea.width = 3
	connect("linea_presionada", Callable(self, "_on_input_event"))
	var pos_a = origen.posicion + Vector2(32, 32) / 2
	var pos_b = destino.posicion + Vector2(32, 32) / 2
	var radius_a = max(24, 32) / 2
	var radius_b = max(24, 32) / 2
	var dir = (pos_b - pos_a).normalized()
	start_point = pos_a + dir * radius_a
	end_point = pos_b - dir * radius_b	
	linea.points = [start_point, start_point]
	
func _process(delta: float) -> void:
	if progress < 1.0:
		progress += delta * duracion
		progress = min(progress, 1.0)
		var current_end = linea.points[0].lerp(end_point, progress)
		setPointEnd(current_end)

func actualizarFlecha():
	if not flecha or linea.points.size() < 2:
		return
	var start = linea.points[0]  # start_point
	var end = linea.points[1]    # end_point
	var direction = (end - start).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)	
	# Calcular puntos del triángulo de la flecha al final de la línea
	var base_center = end - direction * tamano_flecha
	var left = base_center - perpendicular * (tamano_flecha / 2)
	var right = base_center + perpendicular * (tamano_flecha / 2)
	flecha.polygon = [end, left, right]
	flecha.color = linea.default_color
	flecha.position = Vector2.ZERO

func setPointEnd(new_end: Vector2):
	linea.points = [linea.points[0], new_end]
	actualizarFlecha()
	_update_collision()

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		selected = true
		if not is_correct:
			is_wrong = true
		emit_signal("linea_presionada", self)
	pass # Replace with function body.

func _update_collision():
	if origen == null or destino == null:
		return
	var start = origen.posicion
	var end = destino.posicion
	var length = start.distance_to(end)
	var angle = (end - start).angle()
	colission.position = (start + end) * 0.5
	colission.rotation = angle
	colission.shape.extents = Vector2(length * 0.5, 5)
		
func _update_line_color():
	if is_correct:
		linea.default_color = Color(0,1,0)  # verde
	elif is_wrong:
		linea.default_color = Color(1,0,0)  # rojo
	else:
		linea.default_color = color        # color original
	
#nuevo
func set_correct(value: bool):
	"""
	Marca la arista como correcta o incorrecta,
	y actualiza el color visualmente.
	"""
	selected = true
	is_correct = value
	is_wrong = not value
	_update_line_color()
	actualizarFlecha()

func is_selected() -> bool:
	return selected
