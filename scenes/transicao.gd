extends Node

var _ponto := ""

func ir_para(cena: String, ponto: String) -> void:
	_ponto = ponto
	get_tree().change_scene_to_file(cena)

func consumir_ponto() -> String:
	var p := _ponto
	_ponto = ""
	return p
