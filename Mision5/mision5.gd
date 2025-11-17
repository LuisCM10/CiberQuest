extends Control

# -----Constantes----- 
const LINEA_DE_CONEXION_NODOS = "conexion"
const LINEA_DE_RECORRIDO_NODOS = "recorrido"
const LINEA_DE_CONEXION_PESOS_NODOS = "Pesos"
const LINEA_DE_DIJKSTRA_NODOS = "dijkstra"
const LINEA_DE_RECONSTRUCCION_NODOS = "reconstruccion"
const LINEA_DE_CONEXION_CAPACIDAD_NODOS = "Capacidad"
const LINEA_DE_FLUJO_NODOS = "flujo"
const LINEA_DE_FLUJO_MAX_NODOS = "flujoMaximo"


# -----Variables Visuales--------
@onready var panelGrafo = $PanGrafo
@onready var sizes = [panelGrafo.size[0] * 0.46, panelGrafo.size[1] * 0.44]
@onready var lblIntruc = $VBoxContainer/LblIntruccion
@onready var lblTime = $VBoxContainer/LblTime
@onready var lblrecor = $VBoxContainer/lblRecorrido

# ----- Variables de generacion --------
@onready var grafo = Grafo.new()
var num_vertices = 10
var prob_conexion = 0.5

# ------ Variables de control ------
var vertActual : Vertice
var origen : Vertice = null
var destino : Vertice = null
# recorrido
var recorri = true

# disjkstra
var dijkstra = false
# reconstruccion
var reconstrucion = false
var parent = []
# flujo
var flujo = false

# respuestas
var recorrido = []
var UserRecorrido = []

# 
var start = false
var ite = 0
var cont = 0
var iteAnt = 0
var turno = false

func _ready():
	# Crear vértices (sin cambios)
	for i in range(num_vertices):
		var vertice = Vertice.new(i)
		var angle = (2 * PI * i) / 10
		var x = 145 + sizes[0] * cos(angle)
		var y = 85 + sizes[1] * sin(angle)
		var positions = Vector2(x, y)
		vertice.posicion = positions
		grafo.add_vertice(vertice)
		
	# Conectar vértices con pesos y capacidades aleatorios
	for i in range(num_vertices):
		var vertic1 = grafo.searchVertice(i)
		for j in range(num_vertices):
			if i != j:
				if randf() < prob_conexion:
					var vertic2 = grafo.searchVertice(j)
					# Generar peso aleatorio (ej. entre 1 y 10)
					var peso = randf_range(1.0, 10.0)
					# Generar capacidad aleatoria (ej. entre 1 y 20)
					var capacidad = randi_range(1, 20)
					# Conectar con peso y capacidad (ajusta según tu método connect_vertice)
					grafo.connect_vertice(vertic1, vertic2, peso, capacidad)
	dibujar_grafo()

func dibujar_grafo():
	for i in range(grafo.vertices.size()):
		var vertice = grafo.vertices[i]
				
		var button = Button.new()
		button.name = str(vertice.id) + "Button"
		button.text = str(vertice.id)
		button.size = Vector2(32, 32)
		button.add_theme_color_override("icon_normal_color", Color(255,255,255,1))
		button.add_theme_color_override("icon_pressed_color", Color(0.349, 0.387, 0.459, 1.0))
		button.add_theme_color_override("icon_hover_color", Color(182.389, 182.389, 182.389, 1.0))
		button.position = vertice.posicion
		button.flat = true
		button.connect("pressed", Callable(self, "_on_nodo_clicked").bind(vertice))
		panelGrafo.add_child(button)
		# Dibujar conexiones (líneas)
		for ady in vertice.get_adyacencia():
			var indice_ady = grafo.vertices.find(ady)
			if not has_node(str(ady.id) + "_" + str(vertice.id)):
				crearLinea(vertice, 2, indice_ady)

#---------------- Metodos de click a boton de nodos y lineas de conexiones -------------------------
func _on_nodo_clicked(vertice : Vertice):
	vertActual = vertice
	if start and recorri and turno and cont < ite:
		if not UserRecorrido.has(vertActual):
			UserRecorrido.append(vertActual)
			lblrecor.text = str(recorStr())			
			dibujarRecorrido(vertActual, UserRecorrido.size()-1)			
		else:
			lblIntruc.text = "El nodo "+ str(vertActual.id) + " ya se encuentra en el recorrido"

func _on_arista_clicked(linea: conexion):
	var label : Label = obtenerLabelCapacidad(linea)
	vertActual = linea.destino
	print(linea.id)
	if start and recorri:
		if UserRecorrido.has(linea.origen):
			UserRecorrido.append(vertActual)
			cont+=1
	if start and reconstrucion:
		kruskal_click(linea)


# ------------------- Kruskal -----------------------------
func kruskal_click(linea : conexion):
	var n1 = find(linea.origen)
	var n2 = find(linea.destino)

	if n1 != n2:
		union(n1, n2)
		recorrido.append(linea)
		crearLinea(linea.origen, 3, linea.destino, LINEA_DE_RECONSTRUCCION_NODOS, grafo.getPeso(linea.origen, linea.destino))
	else:
		crearLinea(linea.origen, 3, linea.destino, LINEA_DE_RECONSTRUCCION_NODOS, grafo.getPeso(linea.origen, linea.destino))
		cont += 1
		if cont >= 5:
			#show_defeat_message()
			pass
		await get_tree().create_timer(0.5).timeout
		borrarLinea(LINEA_DE_RECONSTRUCCION_NODOS, linea)

	if recorrido.size() == num_vertices - 1:
		#Victoria
		pass

func find(i : Vertice):
	if parent[i.id] != i:
		parent[i.id] = find(parent[i.id])
	return parent[i.id]
	
func union(a, b):
	var ra = a
	var rb = b
	if ra != rb:
		parent[rb.id] = ra
		
func start_kruskal():
	reconstrucion = true
	start = true
	recorrido.clear()
	UserRecorrido.clear()
	
# ----------------- Configuraciones Lineas ------------------------------------

func crearLinea(vertice, width, indice_ady,correcto = true, name = LINEA_DE_CONEXION_NODOS, peso: float = 0.0, capacidad: float = 0.0, lineaRef : conexion= null):
	var linea = conexion.new()
	var node_b
	if indice_ady is int:
		node_b = grafo.searchVertice(indice_ady)
	else:
		node_b = indice_ady
	var pos_a = vertice.posicion + Vector2(32, 32) / 2
	var pos_b = node_b.posicion + Vector2(32, 32) / 2
	var radius_a = max(24, 32) / 2
	var radius_b = max(24, 32) / 2
	var dir = (pos_b - pos_a).normalized()        
	var start_point = pos_a + dir * radius_a
	var end_point = pos_b - dir * radius_b
	var anim = 1
	var color = Color(0, 0, 0)
	
	match name:
		LINEA_DE_CONEXION_NODOS:
			linea.name = str(vertice.id) + "_" + str(node_b.id)
			linea.connect("edge_selected", Callable(self, "_on_arista_clicked"))
			linea.start_point = end_point
			linea.end_point = start_point
			linea.origen = vertice
			linea.destino = node_b
		LINEA_DE_DIJKSTRA_NODOS:
			color = Color(0.906, 0.686, 0.0, 1.0)
			if lineaRef:
				linea.start_point = lineaRef.start_point
				linea.end_point = lineaRef.end_point
				linea.origen = lineaRef.origen
				linea.destino = lineaRef.destino
			else:
				if has_node(vertice.id + "_" + node_b.id):            
					linea.start_point = start_point
					linea.end_point = end_point    
				else:
					linea.start_point = start_point
					linea.end_point = end_point
			linea.tipo = name
			linea.name = name + "_" + lineaRef.name
		LINEA_DE_FLUJO_MAX_NODOS:
			color = Color(0.833, 0.066, 0.064, 1.0)
			if has_node(str(vertice.id) + "_" + str(node_b.id)):            
				linea.start_point = start_point
				linea.end_point = end_point    
			else:
				linea.start_point = start_point
				linea.end_point = end_point
			linea.tipo = name
			linea.name = name + "_" + lineaRef.name
		LINEA_DE_FLUJO_NODOS:
			color = Color(0.0, 0.541, 0.448, 1.0)
			if not correcto:
				color = Color(1.0, 0.0, 0.102, 1.0)
			if has_node(str(vertice.id) + "_" + str(node_b.id)):            
				linea.start_point = start_point
				linea.end_point = end_point    
			else:
				linea.start_point = start_point
				linea.end_point = end_point
			linea.tipo = name
			linea.name = name + "_" + lineaRef.name
		LINEA_DE_RECONSTRUCCION_NODOS:
			color = Color(0.488, 0.504, 0.378, 1.0)
			if not correcto:
				color = Color(1.0, 0.0, 0.102, 1.0)
			if lineaRef:
				linea.start_point = lineaRef.start_point
				linea.end_point = lineaRef.end_point
				linea.origen = lineaRef.origen
				linea.destino = lineaRef.destino
			if has_node(str(vertice.id) + "_" + str(node_b.id)):            
				linea.start_point = start_point
				linea.end_point = end_point    
			else:
				linea.start_point = start_point
				linea.end_point = end_point
			linea.name = name + "_" + lineaRef.name
		LINEA_DE_RECORRIDO_NODOS:
			anim = 0.6
			if lineaRef:
				linea.start_point = lineaRef.start_point
				linea.end_point = lineaRef.end_point
				linea.origen = lineaRef.origen
				linea.destino = lineaRef.destino
			if has_node(str(vertice.id) + "_" + str(node_b.id)):            
				linea.start_point = start_point
				linea.end_point = end_point   
				linea.origen = vertice
				linea.destino = node_b
			else:
				linea.start_point = start_point
				linea.end_point = end_point
				linea.origen = node_b
				linea.destino = vertice
			linea.tipo = name
			linea.name = name + "_" + str(vertice.id) + "_" + str(node_b.id)
			if indice_ady.is_origin:
				color = Color(255,0,0)
			else: 
				color = Color(0.185, 0.416, 1.0, 1.0)
	linea.width = width
	linea.default_color = color
	linea.duracion = anim
	panelGrafo.add_child(linea)
	return linea
		
func añadirLabelLineas (vert1, vert2, tipo, valor, capacidad_usada = 0):
	var label = Label.new()
	var linea
	if has_node(str(vert1.id) + "_" + str(vert2.id)):            
		linea = get_node(str(vert1.id) + "_" + str(vert2.id))   
	else:
		linea = get_node(str(vert2.id) + "_" + str(vert1.id))
				
	match tipo:
		LINEA_DE_CONEXION_PESOS_NODOS:
			configurarLabelPeso(label, valor)			
		LINEA_DE_CONEXION_CAPACIDAD_NODOS:
			configurarLabelCapacidad(label, valor, capacidad_usada)
	# Calcular posición: punto medio entre start_point y end_point
	var mid_point = (linea.start_point + linea.end_point) / 2
	label.position = mid_point
	# Calcular rotación: ángulo de la línea (para alinear el texto)
	var direction = linea.end_point - linea.start_point
	var angle = atan2(direction.y, direction.x)  # Ángulo en radianes
	label.rotation = angle  # Rota el Label para que el texto siga la dirección
	# Nombre para el Label 
	label.name = "label_"+ tipo + "_" + linea.name
	linea.add_child(label)
	
func configurarLabelPeso(label: Label, peso: float):
	label.text = str(peso)
	label.add_theme_font_size_override("font_size", 12)  # Tamaño de fuente (ajusta si es necesario)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(0, 0, 0)  # Color del texto (negro; cambia si quieres otro)

func configurarLabelCapacidad(label: Label, capacidad: float, capacidad_usada):
	label.text = "%d / %d" % [capacidad_usada, capacidad]
	label.add_theme_font_size_override("font_size", 12)  # Tamaño de fuente (ajusta si es necesario)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(0, 0, 0)  # Color del texto (negro; cambia si quieres otro)

func generarLabels(tipo):
	for i in range(grafo.vertices.size()):
		var vertice = grafo.vertices[i]
		for ady in vertice.get_adyacencia():
			var indice_ady = grafo.vertices.find(ady)
			if indice_ady > i:  # Evita duplicar labels
				match tipo:
					LINEA_DE_CONEXION_PESOS_NODOS:
						añadirLabelLineas(vertice, ady, tipo, grafo.getPeso(vertice, ady))
					LINEA_DE_CONEXION_CAPACIDAD_NODOS:
						añadirLabelLineas(vertice, ady, tipo, grafo.getFlujoMax(vertice, ady), grafo.getFlujoUsado(vertice, ady))

func borrarLineas(tipo):
	var linea : conexion
	for x in grafo.vertices:
		for y in x.adyacentes:
			if has_node(tipo + "_" + str(x.id) + "_" + str(y.id)):            
				linea = get_node(tipo + "_" + str(x.id) + "_" + str(y.id))
				linea.queue_free()
			if has_node(tipo + "_" + str(y.id) + "_" + str(x.id)):
				linea = get_node(tipo + "_" + str(y.id) + "_" + str(x.id))
			if linea:
				linea.queue_free()
			linea = null
			
func borrarLinea(tipo, linea):
	var lint
	if has_node(tipo + "_" + linea.name):
		lint = get_node(tipo + "_" + linea.name)
		lint.queue_free()
			
func borrarLabels(tipo):
	var linea : conexion
	var label : Label
	for x in grafo.vertices:
		for y in x.adyacentes:
			if has_node(str(x.id) + "_" + str(y.id)):            
				linea = get_node(str(x.id) + "_" + str(y.id))
			if has_node(str(y.id) + "_" + str(x.id)):
				linea = get_node(str(y.id) + "_" + str(x.id))
			if linea:
				label = get_node("label_"+ tipo + "_" + linea.name)
				label.queue_free()
	
func actualizarLabelCapacidad(label: Label, nueva_capacidad_usada: int, capacidad_maxima: int):
	label.text = "%d / %d" % [nueva_capacidad_usada, capacidad_maxima]
	
func obtenerLabelCapacidad(linea: conexion) -> Label:
	var nombre_label = "label_" + linea.name  # Construye el nombre del Label
	if panelGrafo.has_node(nombre_label):
		return panelGrafo.get_node(nombre_label) as Label
	else:
		print("Error: Label no encontrado para la línea '" + linea.name + "'")
		return null
		
# -------------------------------- Recorrido ------------------------------------

func dibujarRecorrido(node, prev) -> void:
	if prev < 0:
		return
	if not node.adyacentes.has(recorrido[prev]):
		dibujarRecorrido(node, prev-1)
		return
	var x = recorrido[prev]
	if recorrido[UserRecorrido.size-1] != UserRecorrido[UserRecorrido.size-1]:
		lblIntruc.text = "El nodo " + str(UserRecorrido[UserRecorrido.size-1].id) + " no esta en su posicion correcta. Elige el nodo correcto"
		lblrecor.text = str(recorStr())
		var linea = crearLinea(x, 5, node, false, LINEA_DE_RECORRIDO_NODOS)
		UserRecorrido.remove_at(x)
		await get_tree().create_timer(1).timeout
		borrarLinea(LINEA_DE_RECORRIDO_NODOS, linea)
		return
	crearLinea(x, 5, node, LINEA_DE_RECORRIDO_NODOS)

func recorStr() -> Array:
	var recor = []
	for x in UserRecorrido:
		recor.append(x.id)
	return recor

# ------------------------- Botones De control de juego ------------------------
func _on_btn_iniciar_pressed() -> void:
	if recorri:		
		if not vertActual:
			lblIntruc.text = "Por fvavor selecciona un nodo para comenzar"
			return
		var origin_index = randi() % grafo.vertices.size()
		origen = grafo.vertices[origin_index]
		while origen == vertActual or vertActual.adyacentes.has(origen):
			origin_index = randi() % grafo.vertices.size()
			origen = grafo.vertices[origin_index]
		origen.is_origin = true	
		start = true
		UserRecorrido.append(vertActual)
		lblIntruc.text = "Es hora de encontrar el recorrido desde el nodo "+ str(vertActual.id)
		lblrecor.text = str(recorStr())
		recorrido = grafo.bfs(vertActual)
	if reconstrucion:
		start = true
		generarLabels(LINEA_DE_CONEXION_PESOS_NODOS)
		lblIntruc.text = "Es hora de reconstruir el camino. Suerte!"


func _on_btn_enviar_pressed() -> void:
	if recorri:
		pass # Replace with function body.
