extends Node2D
@onready var boton_inicio = $BtnMision3

func _on_btn_mision_3_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
	


func _on_btn_mision_4_pressed() -> void:
	get_tree().change_scene_to_file("res://mision4/Nivel_4.tscn")
