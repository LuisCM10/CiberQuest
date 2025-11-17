extends Node
@onready var NivelActual = 1

func getNivel() -> int:
	return NivelActual
	
func avanzarNivel():
	NivelActual += 1
