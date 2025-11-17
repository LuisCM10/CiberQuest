extends Control

var num_nodos = 12
var adj_matrix = []
var nodo_start = 0
var nemesis_node = -1

var nemesis_icon : Texture2D = preload("res://Mision2/btnNemesis.png")

var posiciones = []            # posiciones de cada nodo
var camino_optimo = []         # lista de nodos del camino de Dijkstra
var nodo_actual = 0            # dónde está el jugador
var esperando_click = false

@onready var container = $Panel/Container
@onready var lineas = $Lineas

# Nuevos nodos para sonidos
@onready var sonido_boton = $SonidoBoton  # Asume que tienes un AudioStreamPlayer llamado SonidoBoton
@onready var sonido_perder = $SonidoPerder  # Asume que tienes un AudioStreamPlayer llamado SonidoPerder

# Variable para almacenar el grafo generado (para no regenerarlo al reiniciar)
var grafo_generado = false

func _ready():
	if not grafo_generado:
		_generar_grafo()
		grafo_generado = true
	_generar_posiciones()
	_crear_botones()
	_conectar_nodos()
	_calcular_camino_optimo()
	_elegir_nemesis()
	nodo_actual = nodo_start
	esperando_click = true

# ────────────────────────────────────────────────
# GENERAR GRAFO DIRIGIDO
# ────────────────────────────────────────────────
func _generar_grafo():
	adj_matrix.clear()
	for i in range(num_nodos):
		adj_matrix.append([])
		for j in range(num_nodos):
			if i == j:
				adj_matrix[i].append(0)
			else:
				# 30% de probabilidad de conexión dirigida (de i a j)
				if randf() < 0.3:
					adj_matrix[i].append(randi() % 10 + 1)
				else:
					adj_matrix[i].append(0)

# ────────────────────────────────────────────────
# GENERAR POSICIONES RANDOM DE NODOS
# ────────────────────────────────────────────────
func _generar_posiciones():
	posiciones.clear()
	var w = 800
	var h = 500

	for i in range(num_nodos):
		posiciones.append(Vector2(
			randf() * w + 20,
			randf() * h + 20
		))

# ────────────────────────────────────────────────
# CREAR BOTONES DE NODOS
# ────────────────────────────────────────────────
func _crear_botones():
	for c in container.get_children():
		c.queue_free()

	for i in range(num_nodos):
		var b = Button.new()
		b.text = str(i)
		b.name = str(i)
		b.position = posiciones[i]
		b.size = Vector2(40, 40)  # Tamaño fijo como en el ejemplo
		b.flat = true
		b.connect("pressed", Callable(self, "_seleccionar_nodo").bind(i))
		container.add_child(b)

# ────────────────────────────────────────────────
# DIBUJAR LÍNEAS DIRIGIDAS (ARISTAS CON FLECHAS)
# ────────────────────────────────────────────────
func _conectar_nodos():
	for l in lineas.get_children():
		l.queue_free()

	for i in range(num_nodos):
		for j in range(num_nodos):
			if adj_matrix[i][j] > 0:
				# Usar el método del ejemplo para crear líneas dirigidas
				crearLinea(i, j, Color("808080"), 3)

# Función inspirada en el ejemplo para crear líneas dirigidas
func crearLinea(indice_a, indice_b, color, width, name = "conexion"):
	var linea = conexion.new()
	var pos_a = posiciones[indice_a] + Vector2(20, 20)  # Centro del botón
	var pos_b = posiciones[indice_b] + Vector2(20, 20)
	var radius_a = 20  # Radio aproximado del botón
	var radius_b = 20
	var dir = (pos_b - pos_a).normalized()
	var start_point = pos_a + dir * radius_a
	var end_point = pos_b - dir * radius_b
	
	linea.name = str(indice_a) + "_" + str(indice_b)
	linea.start_point = start_point
	linea.end_point = end_point
	linea.width = width
	linea.default_color = color
	linea.duracion = 1.0  # Animación si aplica
	lineas.add_child(linea)

# ────────────────────────────────────────────────
# IMPLEMENTACIÓN DE DIJKSTRA
# ────────────────────────────────────────────────
func dijkstra(start):
	var dist = []
	var prev = []
	var visited = []
	
	for i in range(num_nodos):
		dist.append(999999 if i != start else 0)  # Usar 999999 en lugar de INF para consistencia
		prev.append(-1)
		visited.append(false)
	
	for iteration in range(num_nodos):  # Cambiado de "for _ in" a "for iteration in" para evitar error
		var u = -1
		var min_dist = 999999
		for i in range(num_nodos):
			if not visited[i] and dist[i] < min_dist:
				min_dist = dist[i]
				u = i
		
		if u == -1:
			break
		
		visited[u] = true
		
		for v in range(num_nodos):
			if adj_matrix[u][v] > 0 and not visited[v]:
				var alt = dist[u] + adj_matrix[u][v]
				if alt < dist[v]:
					dist[v] = alt
					prev[v] = u
	
	return {"dist": dist, "prev": prev}

# ────────────────────────────────────────────────
# CALCULAR EL CAMINO ÓPTIMO CON DIJKSTRA
# ────────────────────────────────────────────────
func _calcular_camino_optimo():
	var result = dijkstra(nodo_start)
	var dist = result["dist"]
	var prev = result["prev"]
	
	# Elegir nemesis: el más lejano (con distancia finita)
	nemesis_node = -1
	var max_dist = -1
	for i in range(num_nodos):
		if dist[i] < 999999 and dist[i] > max_dist:
			max_dist = dist[i]
			nemesis_node = i
	
	if nemesis_node == -1:
		# Si no hay conexiones, elegir uno aleatorio
		nemesis_node = randi() % num_nodos
	
	# Reconstruir camino
	camino_optimo = _reconstruir_camino(prev, nemesis_node)

func _reconstruir_camino(prev, destino):
	var camino = []
	var actual = destino
	while actual != -1:
		camino.append(actual)
		actual = prev[actual]
	camino.reverse()
	if camino.size() == 0 or camino[0] != nodo_start:
		camino = []  # No hay camino
	return camino

# ────────────────────────────────────────────────
# MARCAR NEMESIS
# ────────────────────────────────────────────────
func _elegir_nemesis():
	var boton = container.get_node(str(nemesis_node))
	boton.add_theme_color_override("font_color", Color.RED)
	
	# Colocar icono
	if nemesis_icon:
		boton.icon = nemesis_icon
		boton.icon_scale = Vector2(0.7, 0.7)
		boton.add_theme_constant_override("icon_margin", 2)
	
	# Efecto de parpadeo
	_parpadear_boton(boton)

func _parpadear_boton(boton: Button):
	var tween = get_tree().create_tween()
	tween.set_loops()
	tween.tween_property(boton, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(boton, "modulate", Color(1, 1, 1, 1), 0.5)

# ────────────────────────────────────────────────
# JUEGO: SELECCIONAR NODOS
# ────────────────────────────────────────────────
func _seleccionar_nodo(nodo):
	if not esperando_click:
		return
	
	# Reproducir sonido al presionar botón
	if sonido_boton:
		sonido_boton.play()
	
	var idx = camino_optimo.find(nodo_actual)
	if idx == -1 or idx == camino_optimo.size() - 1:
		return
	
	var siguiente_correcto = camino_optimo[idx + 1]
	
	if nodo == siguiente_correcto:
		_colorear_arista(nodo_actual, nodo, Color.GREEN)
		nodo_actual = nodo
		
		if nodo == nemesis_node:
			print("¡GANASTE!")
			esperando_click = false
	else:
		_colorear_arista(nodo_actual, nodo, Color.RED)
		# Reproducir sonido al perder
		if sonido_perder:
			sonido_perder.play()
		await get_tree().create_timer(1).timeout
		_reiniciar()

# ────────────────────────────────────────────────
# COLOREAR ARISTA
# ────────────────────────────────────────────────
func _colorear_arista(a, b, color):
	var linea_name = str(a) + "_" + str(b)
	if lineas.has_node(linea_name):
		var linea = lineas.get_node(linea_name)
		linea.default_color = color

# ────────────────────────────────────────────────
# REINICIAR (MANTIENE EL GRAFO)
# ────────────────────────────────────────────────
func _reiniciar():
	# Limpiar posiciones, botones y líneas, pero mantener adj_matrix
	posiciones.clear()
	for l in lineas.get_children():
		l.queue_free()
	for c in container.get_children():
		c.queue_free()
	_ready()
