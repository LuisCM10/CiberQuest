extends Node2D

const NODE_COUNT = 6
const MAX_WEIGHT = 20
const MAX_WRONG_CLICKS = 3

# Escenario
var nodes = []
var edges = []
var selected_edges = []

# Kruskal
var parent = []

# Prim
var prim_included = []

# Algoritmo actual: "prim" o "kruskal"
var current_algo = ""

# Contador de errores
var wrong_clicks := 0

# Tamaño base del viewport y factor de escala
var base_width := 480
var base_height := 270
var scale_factor := 1.0

# UI (CanvasLayer)
@onready var btn_prim = $CanvasLayer/BtnPrim
@onready var btn_kruskal = $CanvasLayer/BtnKruskal
@onready var lbl_warning = $CanvasLayer/lbl_warning
@onready var btn_retry = $CanvasLayer/btn_retry
@onready var lbl_victory = $CanvasLayer/VictoryLabel
@onready var musica_mision3 = $"musicaMision3"

# --- NUEVO: Ayuda ---
@onready var boton_ayuda = $CanvasLayer/BotonAyuda
@onready var panel_ayuda = $CanvasLayer/PanelAyuda
@onready var label_explicacion = $CanvasLayer/PanelAyuda/LabelExplicacion
@onready var boton_continuar = $CanvasLayer/PanelAyuda/BotonContinuar


func _ready():
	lbl_warning.text = "Las redes están dañadas! Elige un algoritmo 
             para reconstruirlas."
	lbl_warning.visible = true

	btn_prim.pressed.connect(_on_btn_prim_pressed)
	btn_kruskal.pressed.connect(_on_btn_kruskal_pressed)
	btn_retry.pressed.connect(_on_btn_retry_pressed)

	btn_retry.visible = false
	lbl_victory.visible = false

	panel_ayuda.visible = false
	boton_ayuda.pressed.connect(_on_boton_ayuda_pressed)
	boton_continuar.pressed.connect(_on_boton_continuar_pressed)

	var window_size = get_viewport_rect().size
	var scale_x = window_size.x / base_width
	var scale_y = window_size.y / base_height
	scale_factor = min(scale_x, scale_y)

	if MusicaGlobal.musica and MusicaGlobal.musica.playing:
		MusicaGlobal.musica.stop()
	musica_mision3.play()


# ---------------- Botones ----------------
func _on_btn_prim_pressed():
	current_algo = "prim"
	_start_game()

func _on_btn_kruskal_pressed():
	current_algo = "kruskal"
	_start_game()

func _start_game():
	btn_prim.visible = false
	btn_kruskal.visible = false
	lbl_warning.visible = false
	wrong_clicks = 0
	lbl_victory.visible = false

	for e in edges:
		e.queue_free()
	edges.clear()
	for n in nodes:
		n.queue_free()
	nodes.clear()
	selected_edges.clear()
	prim_included.clear()

	generate_graph()
	var musica_global = get_tree().get_root().get_node_or_null("musica")
	if musica_global and musica_global.playing:
		musica_global.stop()

	musica_mision3.play()


# ---------------- Grafo ----------------
func generate_graph():
	var window_size = get_viewport_rect().size
	var offset_y = -window_size.y * 0.1
	var center = window_size / 2 + Vector2(0, offset_y)
	var radius = min(window_size.x, window_size.y) * 0.35

	for i in range(NODE_COUNT):
		var node_scene = preload("res://node_point.tscn").instantiate()
		var angle = TAU * i / NODE_COUNT
		node_scene.position = center + Vector2(cos(angle), sin(angle)) * radius
		add_child(node_scene)
		nodes.append(node_scene)

	for i in range(NODE_COUNT):
		for j in range(i + 1, NODE_COUNT):
			var w = randi_range(1, MAX_WEIGHT)
			var edge_scene = preload("res://edge_line.tscn").instantiate()
			edge_scene.connect_nodes(nodes[i], nodes[j], w)
			edge_scene.connect("edge_selected", Callable(self, "_on_edge_selected"))
			edge_scene.update_scale(scale_factor)
			add_child(edge_scene)
			edges.append(edge_scene)

	parent.resize(NODE_COUNT)
	for i in range(NODE_COUNT):
		parent[i] = i

	prim_included.append(nodes[0])


# ---------------- Selección de aristas ----------------
func _on_edge_selected(edge):
	if current_algo == "kruskal":
		kruskal_click(edge)
	elif current_algo == "prim":
		prim_click(edge)


# ---------------- Kruskal ----------------
func kruskal_click(edge):
	var n1 = nodes.find(edge.node_a)
	var n2 = nodes.find(edge.node_b)

	if find(n1) != find(n2):
		union(n1, n2)
		selected_edges.append(edge)
		edge.set_correct(true)
	else:
		edge.set_correct(false)
		wrong_clicks += 1
		if wrong_clicks >= MAX_WRONG_CLICKS:
			show_defeat_message()
		await get_tree().create_timer(0.5).timeout
		edge.set_correct(false)

	if selected_edges.size() == NODE_COUNT - 1:
		show_victory_message()


func find(i):
	if parent[i] != i:
		parent[i] = find(parent[i])
	return parent[i]


func union(a, b):
	var ra = find(a)
	var rb = find(b)
	if ra != rb:
		parent[rb] = ra


# ---------------- Prim ----------------
func prim_click(edge):
	var a_in = edge.node_a in prim_included
	var b_in = edge.node_b in prim_included

	if not ((a_in and not b_in) or (b_in and not a_in)):
		mark_wrong(edge)
		return

	var min_edge = get_prim_min_edge()
	if is_same_edge(edge, min_edge):
		mark_correct(edge)
		if a_in:
			prim_included.append(edge.node_b)
		else:
			prim_included.append(edge.node_a)
	else:
		mark_wrong(edge)

	if prim_included.size() == NODE_COUNT:
		show_victory_message()


func get_prim_min_edge() -> EdgeLine:
	var min_edge: EdgeLine = null
	for e in edges:
		var a_in = e.node_a in prim_included
		var b_in = e.node_b in prim_included
		if (a_in and not b_in) or (b_in and not a_in):
			if min_edge == null or e.weight < min_edge.weight:
				min_edge = e
	return min_edge


func is_same_edge(e1: EdgeLine, e2: EdgeLine) -> bool:
	if e1 == null or e2 == null:
		return false
	return ((e1.node_a == e2.node_a and e1.node_b == e2.node_b) or
			(e1.node_a == e2.node_b and e1.node_b == e2.node_a)) and e1.weight == e2.weight


func mark_correct(edge):
	edge.set_correct(true)


func mark_wrong(edge):
	edge.set_correct(false)
	wrong_clicks += 1
	if wrong_clicks >= MAX_WRONG_CLICKS:
		show_defeat_message()


# ---------------- Mensajes ----------------
func show_victory_message():
	lbl_victory.text = "                                       Reconstrucción completada! 
                           Todos los servidores vuelven a estar sincronizados."
	lbl_victory.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://niveles.tscn")


func show_defeat_message():
	lbl_victory.text = "                          Has seleccionado 3 aristas incorrectas. ¡Has perdido!"
	lbl_victory.visible = true
	btn_retry.visible = true
	for e in edges:
		e.set_pickable(false)


# ---------------- Reintentar ----------------
func _on_btn_retry_pressed():
	for e in edges:
		e.queue_free()
	edges.clear()

	for n in nodes:
		n.queue_free()
	nodes.clear()

	selected_edges.clear()
	prim_included.clear()
	wrong_clicks = 0
	lbl_victory.visible = false

	btn_prim.visible = true
	btn_kruskal.visible = true
	lbl_warning.visible = true
	btn_retry.visible = false

# ---------------- Ayuda ----------------
func _on_boton_ayuda_pressed():
	panel_ayuda.visible = true
	# Ocultar botones y labels cuando se abre ayuda
	btn_prim.visible = false
	btn_kruskal.visible = false
	btn_retry.visible = false
	lbl_warning.visible = false
	lbl_victory.visible = false

func _on_boton_continuar_pressed():
	panel_ayuda.visible = false
	# Volver a mostrar los botones y labels al cerrar ayuda
	btn_prim.visible = true
	btn_kruskal.visible = true
	lbl_warning.visible = true
