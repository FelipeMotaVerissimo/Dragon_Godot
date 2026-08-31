---

## 1. As duas fases

**KameHouse.** 1392 px de terreno pintado, 4,8 telas de largura.
Mapa inspirado em Dragon Ball na casa do Mestre Kame, onde você tem que chegar ao fim pulando nas plataformas

**forest.** 1632 px de terreno pintado, 5,7 telas de largura.
É um mapa de floresta padrão onde novamente ele pula sobre plataformas e pedaços de terras elevados

Alem das duas fases existe a **KingKaioh**, que nao e uma fase: e o terceiro
destino, uma cena curta como easteregg

---

## 2. O parallax

**KameHouse** -- cinco camadas:

| Camada | motion_scale |
|---|---|
| 5-sky | (0, 0) |
| 4 | (0.1, 0.2) |
| 3 | (0.2, 0.2) |
| 2 | (0.3, 0.3) |
| 5 | (0.3, 0.3) |

**forest** -- seis camadas:

| Camada | motion_scale |
|---|---|
| 6 | (0.1, 0.1) |
| 5 | (0.2, 0.2) |
| 4 | (0.3, 0.3) |
| 3 | (0.4, 0.4) |
| 2 | (0.5, 0.5) |
| 1 | (1, 0.1) |

A regra seguida foi a basica: quanto mais distante do jogador, menor o
`motion_scale`. O ceu da KameHouse em (0, 0) fica completamente parado, e as
camadas vao acelerando conforme se aproximam.

Eu fui testando os numeros para ver o que ficava melhor então acabou mudando bastante do começo

Duas observacoes honestas sobre esta parte:

- A camada `1` da forest esta em `motion_scale.x = 1.0`. Em 1.0 ela acompanha o
  mundo exatamente e deixa de funcionar como fundo -- vira cenario. Vale baixar
  para 0.8 ou 0.9 se a intencao era que ela ainda fosse fundo.
- Os valores de y estao preenchidos, mas como nenhuma fase sobe, eles nunca sao
  exercidos em jogo.

---

## 3. A area escondida

Fica na KameHouse, perto do fim

A pista e a entrada: Eu deixei ela perto do final e de uma forma que não fosse tão facil de achar

**A implementacao** usa um `TileMapLayer` chamado `HiddenArea`, com
`z_index = 2` e `collision_enabled = false`. O jogador tem `z_index = 0`, entao a
parede desenha por cima dele: ao entrar, o personagem some atras da rocha, e a
camada nao o impede de passar.

Alem disso ha um `Area2D` chamado `Hidden_Triggers` dentro da camada. Quando o
jogador entra nele, um `Tween` leva o `modulate:a` da camada inteira a zero em
0,3 s, e devolve a 1 quando ele sai -- ou seja, a parede desaparece suavemente
enquanto ele esta dentro. Medido: opacidade 1,00 antes, 0,00 com o jogador
dentro, 1,00 depois de sair.


---

## 4. A camera

Escolhi **camera como cena propria**, em `entities/camera_2d.tscn`, que acha o
jogador pelo grupo `player` em vez de ser filha dele.

O que eu perderia com a outra forma: sendo filha do personagem, a camera so
existe onde o personagem existe, e nao da para apontar para outra coisa em tempo
de execucao -- um chefe, um evento, uma sala parada.

Os limites nao sao escritos a mao. O `camera.gd` percorre a cena, soma os
retangulos pintados de todas as `TileMapLayer` pelo `get_used_rect()` e converte
para pixels pelo `tile_size`. Se a fase crescer, o limite acompanha sozinho.
Quando a fase e mais baixa que a tela -- que e o caso das duas --, a caixa e
alargada na vertical para caber, senao a camera nao teria para onde ir e a
imagem travaria torta.

A KingKaioh nao tem TileMapLayer nenhuma, entao para ela o script cai num segundo
criterio: soma os retangulos dos `Sprite2D` visiveis. Resultado medido:

| Cena | Limites | Tamanho |
|---|---|---|
| KameHouse | esq 1, dir 1841, topo 41, base 249 | 1840 x 208 |
| forest | esq -17, dir 1615, topo 24, base 232 | 1632 x 208 |
| KingKaioh | esq -1, dir 426, topo 0, base 208 | 427 x 208 |

O projeto usa `stretch/mode = "canvas_items"` com `scale_mode = "integer"`, que
amplia por numero inteiro e evita o pixel art borrar.

---

## 5. A transicao

O colisor e uma cena so, `entities/passage.tscn`: um `Area2D` com um
`CollisionShape2D` e o script `scripts/passage.gd`. Ela aparece quatro vezes no
projeto, e o que muda entre as copias sao apenas dois campos do inspetor.

| Cena | No | Destino | Ponto de chegada |
|---|---|---|---|
| KameHouse | `passage` | KingKaioh | `Inicio` |
| KameHouse | `FimDaFase` | forest | `Inicio` |
| KingKaioh | `passage` | KameHouse | `KingKaioh` |
| forest | `passage` | KameHouse | `Inicio` |

O `destino` e um caminho de arquivo (`@export_file`) e nao um `PackedScene`. Se
fosse `PackedScene`, a KameHouse guardaria a forest embutida e a forest guardaria
a KameHouse: cada uma tentaria carregar a outra ja na abertura, em ciclo.

O `ponto_de_chegada` existe porque `change_scene_to_file` nao tem como saber de
onde o jogador veio -- ele sempre nasce na posicao em que o no `player` foi salvo
no arquivo. Cada fase tem um `PontosDeChegada` com `Marker2D` nomeados; o colisor
diz qual quer; o autoload `Transicao` leva esse nome de uma cena para a outra; e
o `scripts/nivel.gd`, na raiz de cada fase, le o nome e move o jogador.

Camadas de fisica nomeadas em Configuracoes do Projeto:

| Bit | Nome | Quem esta nela | Quem ela enxerga |
|---|---|---|---|
| 1 | `terreno` | TileSets das fases | ninguem |
| 2 | `jogador` | `player` | `terreno` |
| 3 | `transicao` | `passage` | `jogador` |

O colisor tem `collision_layer = 4` e `collision_mask = 2`. So enxerga o jogador
-- o cenario pode encostar nele a vontade que nada acontece.

### Por que a troca nao pode ser chamada direto na deteccao

`body_entered` nao e um aviso que chega depois: ele e emitido **durante** o passo
de fisica, enquanto o servidor ainda percorre a lista de corpos daquele quadro.
Trocar de cena ali significa mandar a engine liberar a arvore inteira -- jogador,
cenario, o proprio colisor que acabou de disparar -- no meio dessa varredura. O
servidor continua o passo lendo objetos que deixaram de existir, e o resultado vai
de erro vermelho no painel a travamento.

Por isso a troca vai por `call_deferred`: a chamada fica na fila e so executa
quando o quadro termina, com a fisica encerrada e a arvore livre.

---

## 6. O que travou

O que mais fiquei confuso foi -- a fase trocava e voltava sozinha.** O sintoma era "encosto na
passagem e nao acontece nada". Registrando a cena quadro a quadro:

```
quadro  1  ->  KameHouse
quadro 27  ->  KingKaioh
quadro 31  ->  KameHouse
```

Ia e voltava em 4 quadros, rapido demais para o olho ver. A causa: o
`Serpent_Way`, que e o cenario da KingKaioh, e um `StaticBody2D` parado em cima
da passagem de la. `body_entered` dispara para **qualquer** corpo fisico, e
cenario e corpo fisico. Como tudo estava em `layer 1 / mask 1`, o chao disparava
a transicao. Resolvido nomeando as camadas e deixando a passagem enxergar so o
jogador.


---