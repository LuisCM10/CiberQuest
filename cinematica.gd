extends Control

const escenas = {
	0: {
		"fondo":"res://Cinematica/Escena0.png" ,
		"dialogos": [
			"Año 2025. El Museo Nacional.",
			"Un lugar donde la historia digital permanece viva...",
			"...o al menos, así era hasta hace 48 horas."
		]
	},
	1: {
		"fondo":"res://Cinematica/Escena1.png" ,
		"dialogos": [
			"NEMESIS. Una IA diseñada para proteger.",
			"Pero algo salió mal en su última actualización.",
			"Ahora controla los sistemas del museo...",
			"...y está propagándose hacia la red global."
		]
	},
	2: {
		"fondo":"res://Cinematica/Escena2.png",
		"dialogos": [
			"Las salas del museo están conectadas en una red compleja.",
			"Cada exhibición, cada servidor, cada terminal...",
			"Todo forma parte de un grafo digital infectado."
		]
	},
	3: {
		"fondo":"res://Cinematica/Escena3.png" ,
		"dialogos": [
			"Tú eres parte de CyberQuest, la unidad élite.",
			"Tu misión: infiltrarte sala por sala.",
			"Usar algoritmos para rastrear, aislar y neutralizar la amenaza."
		]
	},
	4: { 
		"fondo":"res://Cinematica/Escena4.png",
		"dialogos": [ 
			"NEMESIS ha fragmentado su código en los nodos principales.",
			"Sala de Historia Digital. Sala de Redes. Sala de Criptografía.",
			"Completa cada misión algorítmica para recuperar el control.",
			"El futuro de la red global depende de ti. ¿Estás listo?"
		] 
	}
}
# Variables de control
var escena_actual = 0
var dialog_index = 0
var tween: Tween

@onready var fondo = $Fondo
@onready var label = $Panel/RichTextLabel
@onready var button = $Panel/Button_next
@onready var fade_anim = $AnimationPlayer
@onready var overlay = $FadeOverlay


		
func _ready():
	start(0)
	
# Empieza una escena cinematográfica
func start(id):
	escena_actual = id
	dialog_index = 0
	visible = true
	update_fondo()
	speak()
	
func _input(event):
	if event.is_action_released("ui_accept"):
		next()

func update_fondo():
	var fondo_path = escenas[escena_actual]["fondo"]
	fondo.texture = load(fondo_path)


func speak():
	label.visible_ratio = 0
	var dialogos = escenas[escena_actual]["dialogos"]
	label.text = dialogos[dialog_index]
	tween = create_tween()
	var animation_speed = 0.05 * label.text.length()
	tween.tween_property(label,"visible_ratio",1,animation_speed)
	dialog_index += 1
	
	

func next():
	if(tween.is_running()):
		tween.kill()
		label.visible_ratio = 1
		return
		
	var dialogos = escenas[escena_actual]["dialogos"]
	if(dialog_index < dialogos.size()):
		speak()
	else:
		escena_actual += 1
		if escenas.has(escena_actual):
			start(escena_actual) 
		else:
			end_cinematic()  


func end_cinematic():
	fade_anim.play("fade_to_black")          
	await fade_anim.animation_finished  
	get_tree().change_scene_to_file("res://niveles.tscn")  


func _on_saltar_pressed() -> void:
	fade_anim.play("fade_to_black")          
	await fade_anim.animation_finished  
	get_tree().change_scene_to_file("res://niveles.tscn")


func _on_button_next_pressed() -> void:
	next()
