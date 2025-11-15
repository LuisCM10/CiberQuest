class_name  conexion extends Line2D

var start_point = [0,0]
var end_point = [100, 100]
var duracion = 1
var progress = 0.0
		
func _ready():    
	points = [start_point,start_point]

func _process(delta: float) -> void:
	if progress < 1.0:
		progress += delta * duracion
		progress = min(progress, 1.0)
		var current_end = start_point.lerp(end_point, progress)
		points = [start_point, current_end]
