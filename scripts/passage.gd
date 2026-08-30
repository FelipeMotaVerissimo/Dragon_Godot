extends Area2D

@export_file("*.tscn") var destino: String = ""
@export var ponto_de_chegada: String = ""

func _ready() -> void:
	body_entered.connect(_ao_entrar)

func _ao_entrar(_corpo: Node2D) -> void:
	set_deferred("monitoring", false)
	get_tree().change_scene_to_file.call_deferred(destino)
	Transicao.ir_para.call_deferred(destino, ponto_de_chegada)
