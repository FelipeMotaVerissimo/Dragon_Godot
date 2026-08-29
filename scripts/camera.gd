extends Camera2D

## Segue o nó que estiver no grupo "player".
##
## A câmera não é filha do jogador de propósito: assim dá para trocar o alvo
## em tempo de execução — num chefe, numa cinemática, num segundo jogador —
## sem mexer na cena do personagem.

var alvo: Node2D


func _ready() -> void:
	buscar_alvo()
	if alvo != null:
		# Sem isto a câmera faz um voo desde a origem no primeiro quadro.
		global_position = alvo.global_position


func _physics_process(_delta: float) -> void:
	if alvo == null:
		return
	# Em _physics_process, e não em _process: o jogador se move em
	# _physics_process, a 60 Hz fixos. Seguir no _process faz a câmera
	# amostrar a posição em momentos que não correspondem ao passo da
	# física, e o resultado na tela é o personagem tremendo.
	#
	# global_position, e não position: a câmera e o jogador podem estar em
	# ramos diferentes da árvore, e aí position seria relativo a pais distintos.
	global_position = alvo.global_position


func buscar_alvo() -> void:
	var nos := get_tree().get_nodes_in_group("player")
	if nos.is_empty():
		push_error("Camera2D: nenhum nó no grupo 'player'")
		return
	alvo = nos[0]
