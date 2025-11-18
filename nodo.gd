class_name Nodo

var id
var adyacentes = []
var is_origin := false
var posicion

func _init(id, posicion) -> void:
	self.id = id
	self.posicion = posicion
	
func addAdyacente(nodo: Nodo):
	self.adyacentes.append(nodo)
	self.adyacentes.sort_custom(func(a: Nodo, b: Nodo): return a.id < b.id)
