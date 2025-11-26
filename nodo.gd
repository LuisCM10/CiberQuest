class_name Nodo

var id
var adyacentes = []
var is_origin := false
var posicion
var global_position

func _init(ide, posicin) -> void:
	self.id = ide
	self.posicion = posicin
	self.global_position = posicin
	
func addAdyacente(nodo: Nodo):
	self.adyacentes.append(nodo)
	self.adyacentes.sort_custom(func(a: Nodo, b: Nodo): return a.id < b.id)
