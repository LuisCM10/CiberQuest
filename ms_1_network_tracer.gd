extends Control

@onready var PanGrafo = $PanGrafo
@onready var LabelPista = $Panel2/PanelPista/ColorRect/LabelPista
@onready var LabelName = $Panel2/PanelInfoServer/PanLabelName/LabelName
@onready var LabelFunct = $Panel2/PanelInfoServer/ColorRect/LabelFunct
@onready var PanInfo = $Panel2
@onready var PanPista = $Panel2/PanelPista
@onready var BotBFS = $Panel/ButtonBFS
@onready var BotDFS = $Panel/ButtonDFS
@onready var BotSig = $Panel/ButtonSig
@onready var LabelIntru = $Panel/Label
# Número de servidores
var num_servidores = 10

# Probabilidad de conexión (0.0 a 1.0)
var prob_conexion = 0.3

# Grafo inicializado
var grafo = Grafo.new()

# Vertice inicial del recorrido o elegido actual para informacion
var VertIni : Vertice
# Variable de control del recorrido
var in_recorrido = false
var visitados = []
var recorrido = []
var cola = []
var pila = []
var ite = 0
var dfs = false
var bfs = false
var origin
var json_data


func _ready():
	# Crear vértices con datos del JSON (carga el JSON como antes)
	var file = FileAccess.open("res://data/servidores.json", FileAccess.READ)
	json_data = JSON.parse_string(file.get_as_text())
	file.close()
	
	for i in range(json_data.size()):
		var vertice = Vertice.new(i, json_data[i]["name"], json_data[i]["functionality"], json_data[i]["is_origin"], json_data[i]["hidden_message"])
		var angle = (2 * PI * i) / 10
		var x = 400 + 250 * cos(angle)
		var y = 250 + 250 * sin(angle)
		var positions = Vector2(x, y)
		vertice.posicion = positions
		grafo.add_vertice(vertice)
		
	
	# Generar conexiones aleatorias
	for i in range(num_servidores):
		var vertic1 = grafo.searchVertice(i)
		for j in range(i + 1, num_servidores):
			if randf() < prob_conexion:
				var vertic2 = grafo.searchVertice(j)
				grafo.connect_vertice(vertic1, vertic2)
						
	dibujar_grafo()
	PanInfo.visible = false
	PanPista.visible = false

		
func _on_servidor_clicked(index: int):
	if !PanInfo.visible:
		PanInfo.visible = true
	VertIni = grafo.searchVertice(index)
	LabelName.text = VertIni.name
	LabelFunct.text = VertIni.funcionalidad
	if PanPista.visible and not recorrido.has(VertIni):
		PanPista.visible = false
	elif not PanPista.visible and recorrido.has(VertIni):
		PanPista.visible = true
	
		
func _process(delta: float) -> void:
	if in_recorrido and recorrido.has(VertIni):
		LabelPista.text = VertIni.pista
		
	if recorrido.has(origin):
		BotSig.text = "Seguir a la siguiente mision"
		LabelName.text = origin.name
		LabelFunct.text = origin.funcionalidad
		LabelPista.text = "“Rastreo completado. Has encontrado el nodo raíz del virus. Siguiente misión: calcular la ruta más segura para aislarlo.”"
		LabelIntru.text = "Bien hecho. Has detectado el nodo raiz del virus"

func _on_button_bfs_pressed() -> void:
	in_recorrido = true
	# Establece el nodo infectado
	var origin_index = randi() % grafo.vertices.size()
	origin = grafo.vertices[origin_index]
	while origin == VertIni:
		origin_index = randi() % grafo.vertices.size()
		origin = grafo.vertices[origin_index]
	origin.is_origin = true
	bfs = true
	BotBFS.visible = false
	BotDFS.visible = false
	PanPista.visible = true
	cola.append(VertIni)
	visitados.append(VertIni)
	BFS()

func BFS () :
	var top = ite +3
	while ite < top or cola.is_empty():
		var node = cola.pop_front()
		recorrido.append(node)
		if node.is_origin:
			ite = top
		var sprite : Sprite2D = get_node(node.name + "Sprite")
		
		if not recorrido.is_empty():
			for x in recorrido:
				var color 
				if x.is_origin:
					color = Color(255,0,0)
				else: 
					color = Color(0.185, 0.416, 1.0, 1.0)
				if x.adyacentes.has(node):
					var line :Line2D = get_node(x.name + "_" + node.name)
					if line == null:
						line = get_node(node.name + "_" + x.name)					
					line.default_color = color
					line.width = 5
					await get_tree().create_timer(0.5).timeout	
		for neighbor in node.adyacentes:
			if not visitados.has(neighbor):
				visitados.append(VertIni)
				cola.append(neighbor)
		
		ite+=1
	return recorrido
	

func _on_button_dfs_pressed() -> void:
	if VertIni:
		in_recorrido = true
		var origin_index = randi() % grafo.vertices.size()
		origin = grafo.vertices[origin_index]
		while origin == VertIni:
			origin_index = randi() % grafo.vertices.size()
			origin = grafo.vertices[origin_index]
		origin.is_origin = true
		dfs = true	
		BotBFS.visible = false
		BotDFS.visible = false
		PanPista.visible = true
		LabelIntru.text = "Haz elegido iniciar la busqueda con "+VertIni.name+". \nHas encontrado una pista en los nodos recorridos, leela para guiarte bien"
		pila.append(VertIni)
		visitados.append(VertIni)
		DFS()
	else:
		LabelIntru.text = "Elige un nodo para comenzar la busqueda"
		 # Replace with function body.
	
func DFS () -> Array:
	var top = ite + 3
	while ite < top or pila.is_empty():
		var node = pila.pop_back()  # Sacar del final (comportamiento de pila)
		recorrido.append(node)
		if node.is_origin:
			ite = top
		var sprite : Sprite2D = get_node(node.name + "Sprite")
		if not recorrido.is_empty():
			for x in recorrido:
				var color 
				if x.is_origin:
					color = Color(255,0,0)
				else: 
					color = Color(0.185, 0.416, 1.0, 1.0)
				#sprite.draw_circle(sprite.position,35.7,color)
				if x.adyacentes.has(node):
					var line :Line2D
					if has_node(x.name + "_" + node.name):
						line = get_node(x.name + "_" + node.name)
					else:
						line = get_node(node.name + "_" + x.name)
					line.default_color = color
					line.width = 5
					await get_tree().create_timer(0.5).timeout		
		for neighbor in node.adyacentes:
			if not visitados.has(neighbor):
				visitados.append(VertIni)
				pila.append(neighbor)
		ite += 1 
	return recorrido


func _on_button_sig_pressed() -> void:
	if recorrido.has(origin):
		get_tree().quit()
	elif dfs:
		DFS()
	elif bfs:
		BFS()
	pass # Replace with function body.


func _on_button_exit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
	
	
func dibujar_grafo():
	for i in range(grafo.vertices.size()):
		var vertice = grafo.vertices[i]
		# Crear sprite para el nodo
		var sprite = Sprite2D.new()
		sprite.name = vertice.name + "Sprite"
		sprite.texture = load(json_data[i]["icon"])  # Carga icono del JSON
		sprite.position = vertice.posicion + Vector2(37.5, 37.5)
		sprite.scale = Vector2(0.8, 0.8)
		add_child(sprite)
		
		var button = Button.new()
		button.name = vertice.name + "Button"
		button.size = Vector2(75, 75)
		button.position = vertice.posicion
		button.flat = true
		button.connect("pressed", Callable(self, "_on_servidor_clicked").bind(i))
		add_child(button)
		# Dibujar conexiones (líneas)
		for ady in vertice.get_adyacencia():
			var indice_ady = grafo.vertices.find(ady)
			if indice_ady > i:  # Evita duplicar líneas
				var linea = Line2D.new()
				
				var node_b = grafo.searchVertice(indice_ady)
				var pos_a = vertice.posicion + Vector2(75, 75) / 2
				var pos_b = node_b.posicion + Vector2(75, 75) / 2
				var radius_a = max(75,75) / 2
				var radius_b = max(75,75) / 2
				var dir = (pos_b - pos_a).normalized()		
				var start_point = pos_a + dir * radius_a
				var end_point = pos_b - dir * radius_b
				linea.name = vertice.name + "_"+ node_b.name
				linea.points = [start_point, end_point]
				linea.width = 2
				linea.default_color = Color(0.0, 0.0, 0.0, 1.0)
				add_child(linea)
