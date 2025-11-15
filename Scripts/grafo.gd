extends Node

class_name Grafo

# Atributos
var vertices = []  # Array de vértices
var matriz_adya = []  # Array 2D para matriz de adyacencia

# Constructor
func _init():
	self.vertices = []

# Métodos
func add_vertice(vertice: Vertice):
	self.vertices.append(vertice)

func connect_vertice(verti1: Vertice, verti2: Vertice):
	if matriz_adya.is_empty():
		# Inicializar matriz 2D con tamaño dinámico
		matriz_adya = []
		for i in range(vertices.size()):
			matriz_adya.append([])
			for j in range(vertices.size()):
				matriz_adya[i].append(0)
	
	verti1.addAdyacente(verti2)
	verti2.addAdyacente(verti1)
	matriz_adya[verti1.id][verti2.id] = 1

func BFS(inicio: int) -> Array:
	var cola = []  # Simula una cola con array
	var recorrido = []
	var visitados = []
	for i in range(vertices.size()):
		visitados.append(false)
	
	visitados[inicio] = true
	cola.append(inicio)
	
	while !cola.is_empty():
		var actual = cola.pop_front()  # FIFO
		recorrido.append(vertices[actual].get_dato())
		
		for ady in vertices[actual].get_adyacencia():
			var indice = vertices.find(ady)
			if !visitados[indice]:
				visitados[indice] = true
				cola.append(indice)
	
	return recorrido

func searchVertice(id : int) -> Vertice:
	for x in vertices:
		if x.id == id:
			return x
	return null
