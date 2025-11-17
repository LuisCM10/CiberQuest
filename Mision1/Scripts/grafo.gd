extends Node

class_name Grafo

# Atributos
var vertices = []  # Array de vértices
var matriz_adya = []  # Array para matriz de adyacencia
var matriz_peso = []
var matriz_capa_max = []
var matriz_capa_usa = []

# Constructor
func _init():
	self.vertices = []

# Métodos
func add_vertice(vertice: Vertice):
	self.vertices.append(vertice)

func connect_vertice(verti1: Vertice, verti2: Vertice, peso = 0, capacidad = 0):
	if matriz_adya.is_empty():
		# Inicializar matriz 2D con tamaño dinámico
		matriz_adya = []
		for i in range(vertices.size()):
			matriz_adya.append([])
			matriz_peso.append([])
			matriz_capa_max.append([])
			matriz_capa_usa.append([])
			for j in range(vertices.size()):
				matriz_adya[i].append(0)
				matriz_peso[i].append(0)
				matriz_capa_max[i].append(0)
				matriz_capa_usa[i].append(0)
				
	
	verti1.addAdyacente(verti2)
	verti2.addAdyacente(verti1)
	matriz_adya[verti1.id][verti2.id] = 1
	matriz_peso[verti1.id][verti2.id] = peso
	matriz_capa_max[verti1.id][verti2.id] = capacidad

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


func addFlujo(verti1, verti2, capacidad_usa) -> int:
	if matriz_capa_usa[verti1.id][verti2.id] + capacidad_usa > matriz_capa_max[verti1.id][verti2.id]:
		matriz_capa_usa[verti1.id][verti2.id] = capacidad_usa
		return matriz_capa_max[verti1.id][verti2.id] - matriz_capa_usa[verti1.id][verti2.id]
	return 0

func getFlujoUsado(verti1, verti2) -> int:
	return matriz_capa_usa[verti1.id][verti2.id]
	
func getFlujoMax(verti1, verti2) -> int:
	return matriz_capa_max[verti1.id][verti2.id]
	
func getPeso(verti1, verti2) -> int:
	return matriz_peso[verti1.id][verti2.id]
		
