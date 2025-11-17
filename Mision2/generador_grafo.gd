extends Control

var num_nodos = 7
var adj_matrix = []
var nodo_start = 0
var nemesis_node = -1

var nemesis_icon : Texture2D = preload("res://Mision2/btnNemesis.png")

var posiciones = []            # posiciones de cada nodo
var camino_optimo = []         # lista de nodos del camino de Dijkstra
var nodo_actual = 0            # dónde está el jugador
var esperando_click = false

@onready var container = $Panel  # Cambiado a $Panel directamente
var grafo = Grafo.new()
# Nuevos nodos para sonidos
@onready var sonido_boton = $SonidoBoton 
@onready var sonido_perder = $SonidoPerder
@onready var musica_aparicion = $MusicaAparicion

# Variable para almacenar el grafo generado (para no regenerarlo al reiniciar)
var grafo_generado = false
var animacion_activa = false  # Nuevo: Para controlar si la animación de aparición está activa

func _ready():
	if not grafo_generado:
		_generar_grafo()
		grafo_generado = true
	_generar_posiciones()
	_crear_botones()
	# _conectar_nodos() quitado inicialmente, se llama después de la animación
	_calcular_camino_optimo()
	_elegir_nemesis()
	_iniciar_animacion_aparicion()
	nodo_actual = nodo_start
	esperando_click = false

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
				if randf() < 0.3:
					adj_matrix[i].append(randi() % 10 + 1)
				else:
					adj_matrix[i].append(0)

# ────────────────────────────────────────────────
# GENERAR POSICIONES EN CÍRCULO (ADAPTADO PARA EVITAR SUPERPOSICIONES Y SALIRSE DE PANTALLA)
# ────────────────────────────────────────────────
func _generar_posiciones():
	posiciones.clear()
	var center = Vector2(480, 270)  # Centro aproximado del contenedor (ajusta si el Panel tiene otro tamaño)
	var radius = 200  # Radio del círculo (ajusta para que quepa en 800x500, dejando margen para botones de 40x40)

	for i in range(num_nodos):
		var angle = (2 * PI * i) / num_nodos
		var x = center.x + radius * cos(angle) - 150
		var y = center.y + radius * sin(angle) - 50
		posiciones.append(Vector2(x, y))

# ────────────────────────────────────────────────
# CREAR BOTONES DE NODOS (ADAPTADO DEL CÓDIGO ORIGINAL)
# ────────────────────────────────────────────────
func _crear_botones():
	if container:
		for c in container.get_children():
			c.queue_free()
	else:
		print("Error: Panel no encontrado. Asegúrate de que $Panel exista.")

	for i in range(num_nodos):
		# Usar TextureButton para simular botones circulares con textura (puedes reemplazar con Polygon2D si prefieres, pero Polygon2D no es interactivo por defecto)
		var b = TextureButton.new()
		b.name = str(i)
		b.position = posiciones[i]
		b.size = Vector2(40, 40)
		b.stretch_mode = TextureButton.STRETCH_SCALE  # Escalar textura para forma circular
		# Asigna una textura circular por defecto (puedes crear una textura PNG de círculo blanco o transparente)
		# b.texture_normal = preload("res://ruta/a/textura_circulo.png")  # Agrega esto si tienes una textura
		b.disabled = true
		b.connect("pressed", Callable(self, "_seleccionar_nodo").bind(i))
		if container:
			container.add_child(b)

# ────────────────────────────────────────────────
# DIBUJAR LÍNEAS DIRIGIDAS (USANDO crearLinea DEL CÓDIGO ORIGINAL)
# ────────────────────────────────────────────────
func _conectar_nodos():
	if container:
		for l in container.get_children():
			if l is Line2D or l is conexion:  # Ajusta según el tipo de línea
				l.queue_free()
	else:
		print("Error: Panel no encontrado.")

	for i in range(num_nodos):
		for j in range(num_nodos):
			if adj_matrix[i][j] > 0:
				crearLinea(i, j, Color("808080"), 3)

# Función para crear líneas dirigidas (COPIADA Y ADAPTADA DEL CÓDIGO ORIGINAL)
func crearLinea(vertice, indice_ady, color, width, name = "conexion"):
	var linea = conexion.new()  # Asume que 'conexion' es un script personalizado para líneas
	
	# Crear objetos Vertice temporales para asignar a linea.origen y linea.destino (ya que esperan objetos Vertice, no ints)
	var origen_vert = Vertice.new(vertice, str(vertice), "", false, "")
	origen_vert.posicion = posiciones[vertice]
	var destino_vert = Vertice.new(indice_ady, str(indice_ady), "", false, "")
	destino_vert.posicion = posiciones[indice_ady]
	
	var pos_a = posiciones[vertice] + Vector2(20, 20)  # Centro aproximado del botón (40x40 / 2)
	var pos_b = posiciones[indice_ady] + Vector2(20, 20)
	var radius_a = 20  # Radio aproximado del círculo
	var radius_b = 20
	var dir = (pos_b - pos_a).normalized()
	var start_point = pos_a + dir * radius_a
	var end_point = pos_b - dir * radius_b
	var anim = 1
	if name == "conexion":
		linea.name = origen_vert.name + "_" + destino_vert.name
		linea.start_point = start_point
		linea.end_point = end_point
		linea.origen = origen_vert
		linea.destino = destino_vert
	else:
		anim = 0.6
		linea.start_point = start_point
		linea.end_point = end_point
		linea.origen = origen_vert
		linea.destino = destino_vert
		linea.tipo = name
		linea.name = name + "_" + origen_vert.name + "_" + destino_vert.name
	linea.width = width
	linea.default_color = color
	linea.duracion = anim
	container.add_child(linea)

# ────────────────────────────────────────────────
# IMPLEMENTACIÓN DE DIJKSTRA
# ────────────────────────────────────────────────
func dijkstra(start):
	var dist = []
	var prev = []
	var visited = []
	
	for i in range(num_nodos):
		dist.append(999999 if i != start else 0)
		prev.append(-1)
		visited.append(false)
	
	for iteration in range(num_nodos):
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
	
	nemesis_node = -1
	var max_dist = -1
	for i in range(num_nodos):
		if dist[i] < 999999 and dist[i] > max_dist:
			max_dist = dist[i]
			nemesis_node = i
	
	if nemesis_node == -1:
		nemesis_node = randi() % num_nodos
	
	camino_optimo = _reconstruir_camino(prev, nemesis_node)

func _reconstruir_camino(prev, destino):
	var camino = []
	var actual = destino
	while actual != -1:
		camino.append(actual)
		actual = prev[actual]
	camino.reverse()
	if camino.size() == 0 or camino[0] != nodo_start:
		camino = []
	return camino

# ────────────────────────────────────────────────
# MARCAR NEMESIS
# ────────────────────────────────────────────────
func _elegir_nemesis():
	if not container:
		return
	var boton = container.get_node(str(nemesis_node))
	if not boton:
		return
	if nemesis_icon:
		boton.texture_normal = nemesis_icon

# Nuevo: Iniciar animación de aparición de nemesis
func _iniciar_animacion_aparicion():
	animacion_activa = true
	if musica_aparicion:
		musica_aparicion.play()
	
	var boton = container.get_node(str(nemesis_node))
	if boton:
		_parpadear_boton_temporal(boton)
	
	await get_tree().create_timer(3.0).timeout
	_terminar_animacion_aparicion()

func _parpadear_boton_temporal(boton: TextureButton):
	var tween = get_tree().create_tween()
	tween.set_loops(6)
	tween.tween_property(boton, "modulate", Color(1, 1, 1, 0.3), 0.5)
	tween.tween_property(boton, "modulate", Color(1, 1, 1, 1), 0.5)

func _terminar_animacion_aparicion():
	animacion_activa = false
	if musica_aparicion:
		musica_aparicion.stop()

	var boton = container.get_node(str(nemesis_node))
	if boton:
		boton.texture_normal = null  # Remover la textura de Nemesis
	
	# Mostrar aristas
	_conectar_nodos()
	
	for c in container.get_children():
		if c is TextureButton:
			c.disabled = false
	
	esperando_click = true

# ────────────────────────────────────────────────
# JUEGO: SELECCIONAR NODOS
# ────────────────────────────────────────────────
func _seleccionar_nodo(nodo):
	if not esperando_click or animacion_activa:
		return
	
	# Verificar si el nodo está conectado al actual (no permitir avanzar si no lo está)
	if adj_matrix[nodo_actual][nodo] == 0:
		return  # No hacer nada si no está conectado
	
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
		_colorear_arista(nodo_actual, nodo, Color.RED)  # Dibujar arista roja si es incorrecto
		if sonido_perder:
			sonido_perder.play()
		await get_tree().create_timer(1).timeout
		_reiniciar()

# ────────────────────────────────────────────────
# COLOREAR ARISTA (USANDO crearLinea PARA DIBUJAR EL CAMINO)
# ────────────────────────────────────────────────
func _colorear_arista(origen, destino, color):
	crearLinea(origen, destino, color, 5, "recorrido")  # Dibuja la arista del camino elegido

# ────────────────────────────────────────────────
# REINICIAR (MANTIENE EL GRAFO)
# ────────────────────────────────────────────────
func _reiniciar():
	posiciones.clear()
	if container:
		for l in container.get_children():
			if l is Line2D or l is conexion:
				l.queue_free()
		for c in container.get_children():
			if c is TextureButton:
				c.queue_free()
	_ready()
