extends Node
@onready var NivelActual = 2

func getNivel() -> int:
	return NivelActual
	
func avanzarNivel():
	NivelActual += 1
