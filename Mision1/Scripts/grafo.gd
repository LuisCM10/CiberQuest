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
func add_vertice(vertice):
	self.vertices.append(vertice)

func connect_vertice(verti1, verti2, peso = 0, capacidad = 0):
	if matriz_adya.is_empty():
		# Inicializar matriz 2D con tamaño dinámico
		matriz_adya = []
		matriz_peso = []
		matriz_capa_max = []
		matriz_capa_usa = []
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

func searchVertice(id : int):
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

func bfs(vertActual) :
	var cola = []
	var recorrido = []
	var visitados = []
	
	cola.append(vertActual)
	visitados.append(vertActual)
	while not cola.is_empty():
		var node = cola.pop_front()
		if node:
			recorrido.append(node)
			for neighbor in node.adyacentes:
				if neighbor not in visitados:
					visitados.append(neighbor)
					cola.append(neighbor)		
			if node.is_origin:
				cola.clear()
	return recorrido
