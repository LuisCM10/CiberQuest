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
var prob_conexion = 0.2

# ------ Variables de control ------
var vertActual : Vertice
var origen : Vertice = null
var destino : Vertice = null
var lineasConexion = []
var lineasRecorrido = []
# recorrido
var recorri = false

# disjkstra
var dijkstra = false
# reconstruccion
var reconstrucion = true
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
			if indice_ady > i:
				lineasConexion.append(crearLinea(vertice, 2, indice_ady))

#---------------- Metodos de click a boton de nodos y lineas de conexiones -------------------------
func _on_nodo_clicked(vertice : Vertice):
	vertActual = vertice
	if start and recorri:
		if not UserRecorrido.has(vertActual):
			UserRecorrido.append(vertActual)
			lblrecor.text = str(recorStr())
		else:
			lblIntruc.text = "El nodo "+ str(vertActual.id) + " ya se encuentra en el recorrido"

func _on_arista_clicked(linea: conexion):
	var label : Label = linea.label
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
	var pos_a = vertice.posicion + Vector2(40, 40) / 2
	var pos_b = node_b.posicion + Vector2(40, 40) / 2
	var radius_a = max(24, 46) / 2
	var radius_b = max(24, 46) / 2
	var dir = (pos_b - pos_a).normalized()
	var start_point = pos_a + dir * radius_a
	var end_point = pos_b - dir * radius_b
	var anim = 1
	var color = Color(0, 0, 0)
	
	match name:
		LINEA_DE_CONEXION_NODOS:
			linea.name = str(vertice.id) + "_" + str(node_b.id)
			linea.grafo = grafo
			linea.connect("linea_presionada", Callable(self, "_on_linea_presionada"))
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
		
func mostrarLabel(tipo):
	var linea : conexion
	for x in grafo.vertices:
		for y in x.adyacentes:
			if has_node(tipo + "_" + str(x.id) + "_" + str(y.id)):            
				linea = get_node(tipo + "_" + str(x.id) + "_" + str(y.id))
			if has_node(tipo + "_" + str(y.id) + "_" + str(x.id)):
				linea = get_node(tipo + "_" + str(y.id) + "_" + str(x.id))
			if linea:
				linea.configurarLabelPeso()
				linea.label.visible = true

func borrarLineas(tipo):
	var linea : conexion
	for x in grafo.vertices:
		for y in x.adyacentes:
			if has_node(tipo + "_" + str(x.id) + "_" + str(y.id)):            
				linea = get_node(tipo + "_" + str(x.id) + "_" + str(y.id))
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
# -------------------------------- Recorrido ------------------------------------

func dibujarRecorrido(node, prev) -> void:
	if prev < 0:
		return
	if not node.adyacentes.has(UserRecorrido[prev]) or not UserRecorrido[prev].adyacentes.has(node) :
		dibujarRecorrido(node, prev-1)
		return
	var x = UserRecorrido[prev]
	if recorrido.is_empty():
		return
	if recorrido[UserRecorrido.size()-1] == UserRecorrido[UserRecorrido.size()-1]:
		crearLinea(x, 5, node, LINEA_DE_RECORRIDO_NODOS)
		await get_tree().create_timer(2).timeout
		return
	lblIntruc.text = "El nodo " + str(UserRecorrido[UserRecorrido.size-1].id) + " no esta en su posicion correcta. Elige el nodo correcto"
	var linea = crearLinea(x, 5, node, false, LINEA_DE_RECORRIDO_NODOS)
	UserRecorrido.remove_at(node)
	lblrecor.text = str(recorStr())
	await get_tree().create_timer(10).timeout
	borrarLinea(LINEA_DE_RECORRIDO_NODOS, linea)
	

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
		self.recorrido = grafo.bfs(vertActual)
	if reconstrucion:
		start = true
		mostrarLabel(LINEA_DE_CONEXION_PESOS_NODOS)
		lblIntruc.text = "Es hora de reconstruir el camino. Suerte!"


func _on_btn_enviar_pressed() -> void:
	if recorri and start:
		dibujarRecorrido(vertActual, UserRecorrido.size()-1)	
		pass # Replace with function body.
