class_name  conexion extends Line2D

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


	
