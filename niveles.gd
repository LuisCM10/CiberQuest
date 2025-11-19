extends Node2D
@onready var boton_inicio = $BtnMision3
@onready var BotonMis = [$BtnMision1, $BtnMision2, $BtnMision3, $BtnMision4, $BtnMision5]
@onready var BloqueMis = [0,$BloqueoMis2, $BloqueoMis3, $BloqueoMis4, $BloqueoMis5]

func _ready() -> void:
	var i = ControlGame.getNivel()-1
	while i > 0:
		BloqueMis[i].visible = false
		i-=1
	i = ControlGame.getNivel()
	while i < BotonMis.size():
		BotonMis[i].disabled = true
		i+=1



func _on_btn_mision_3_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
	


func _on_btn_mision_4_pressed() -> void:
	get_tree().change_scene_to_file("res://mision4/Nivel_4.tscn")


func _on_btn_mision_1_pressed() -> void:
	get_tree().change_scene_to_file("res://Mision1/Scenes/Mision1.tscn")


func _on_btn_mision_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Mision2/mision_2.tscn")


func _on_btn_mision_5_pressed() -> void:
	get_tree().change_scene_to_file("res://msn5/msn5.tscn")
