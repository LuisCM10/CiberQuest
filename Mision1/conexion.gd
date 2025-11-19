class_name  conexion extends Line2D

const LINEA_DE_CONEXION_PESOS_NODOS = "Pesos"
const LINEA_DE_CONEXION_CAPACIDAD_NODOS = "Capacidad"



@onready var label = Label.new()

var flecha: Polygon2D
var start_point = [0,0]
var end_point = [100, 100]
var tamano_flecha: float = 12.0
var origen :Vertice = null
var destino :Vertice = null
var duracion = 1
var progress = 0.0
var tipo = "conexion"
var grafo : Grafo = null
		
func _ready():
	points = [start_point,start_point]	
	label.name = "label_" + self.name
	label.modulate = Color(255,255,255)
	add_child(label)
	label.visible = false
	if not destino.adyacentes.has(origen) or tipo != "conexion":
		flecha = Polygon2D.new()
		add_child(flecha)
		

func _process(delta: float) -> void:
	if progress < 1.0:
		progress += delta * duracion
		progress = min(progress, 1.0)
		var current_end = start_point.lerp(end_point, progress)
		setPointEnd(current_end)


func actualizarFlecha():
	if not flecha or points.size() < 2:
		return
	var start = points[0]  # start_point
	var end = points[1]    # end_point
	var direction = (end - start).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)	
	# Calcular puntos del triángulo de la flecha al final de la línea
	var base_center = end - direction * tamano_flecha
	var left = base_center - perpendicular * (tamano_flecha / 2)
	var right = base_center + perpendicular * (tamano_flecha / 2)
	flecha.polygon = [end, left, right]
	flecha.color = default_color
	flecha.position = Vector2.ZERO

func setPointEnd(new_end: Vector2):
	points = [start_point, new_end]
	actualizarFlecha()
	añadirLabelLineas()

func añadirLabelLineas ():
	match tipo:
		LINEA_DE_CONEXION_PESOS_NODOS:
			configurarLabelPeso()			
		LINEA_DE_CONEXION_CAPACIDAD_NODOS:
			configurarLabelCapacidad()
	# Calcular posición: punto medio entre start_point y end_point
	var mid_point = (start_point + end_point) / 2
	label.position = mid_point
	# Calcular rotación: ángulo de la línea (para alinear el texto)
	var direction = end_point - start_point
	var angle = atan2(direction.y, direction.x)  # Ángulo en radianes
	label.rotation = angle  # Rota el Label para que el texto siga la dirección
	# Nombre para el Label 
	
	
func configurarLabelPeso():
	var peso = grafo.getPeso(origen, destino)
	label.text = str(peso)
	label.add_theme_font_size_override("font_size", 12)  # Tamaño de fuente (ajusta si es necesario)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(0, 0, 0)  # Color del texto (negro; cambia si quieres otro)

func configurarLabelCapacidad():
	var capacidad_usada = grafo.getFlujoUsado(origen, destino)
	var capacidad = grafo.getFlujoMax(origen, destino)
	label.text = "%d / %d" % [capacidad_usada, capacidad]
	label.add_theme_font_size_override("font_size", 12)  # Tamaño de fuente (ajusta si es necesario)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(0, 0, 0)  # Color del texto (negro; cambia si quieres otro)

			
func borrarLabels():
	label.visible = false
	
func actualizarLabelCapacidad(nueva_capacidad_usada: int):
	label.text = "%d / %d" % [nueva_capacidad_usada, grafo.getFlujoMax(origen, destino)]
	
