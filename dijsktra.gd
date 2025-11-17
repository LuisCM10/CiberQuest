const INF = 999999

# Clase auxiliar para representar un nodo con ID y distancia
class Nodo:
	var id: int
	var dist: int
	
	func _init(id: int, dist: int):
		self.id = id
		self.dist = dist

# Método Dijkstra adaptado
func dijkstra(adj_matrix: Array, source: int) -> Array:
	var n = adj_matrix.size()
	
	# Inicializar distancias a infinito y visitados a false
	var dist = []
	dist.resize(n)
	dist.fill(INF)
	var visited = []
	visited.resize(n)
	visited.fill(false)
	
	# Inicializar la cola con el vértice de origen
	var queue = []  # Simula cola con Array
	queue.append(Nodo.new(source, 0))
	
	# Mientras la cola no esté vacía
	while queue.size() > 0:
		# Extraer el vértice con la menor distancia (nota: en esta implementación, no es priority queue)
		var v = queue.pop_front()        
		# Si el vértice ya ha sido visitado, ignorarlo
		if visited[v.id]:
			continue        
		# Marcar el vértice como visitado
		visited[v.id] = true        
		# Actualizar la distancia de los vértices adyacentes
		for i in range(n):
			if not visited[i] and adj_matrix[v.id][i] != 0:
				var new_dist = dist[v.id] + adj_matrix[v.id][i]                
				# Si la nueva distancia es menor que la distancia actual, actualizarla
				if new_dist < dist[i]:
					dist[i] = new_dist
					# Añadir a la cola con la nueva distancia
					queue.append(Nodo.new(i, dist[i]))
	
	return dist
