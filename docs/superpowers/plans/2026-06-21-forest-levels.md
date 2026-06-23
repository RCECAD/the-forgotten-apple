# Forest Levels Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar 3 levels de plataforma na floresta + o framework (tileset compartilhado, kit de hazards, importer ASCII→tilemap, base script) que permite construí-los por texto.

**Architecture:** Levels são cenas com um `TileMapLayer` cujo conteúdo é gerado por um EditorScript `@tool` a partir de mapas ASCII em `.txt`. Hazards/plataformas/maçãs são cenas reutilizáveis instanciadas pelo importer. Os 3 levels herdam um `forest_level.gd` comum (câmera, portas, spawn, pause).

**Tech Stack:** Godot 4.6, GDScript. Sem framework de teste — verificação é estática (leitura/grep) + checklist manual no editor.

## Global Constraints

- Engine Godot 4.6; renderer `gl_compatibility`. (de `project.godot`)
- Célula do tilemap = **16px**. Tiles usam polígonos `-8..8`.
- Layers de física: `GROUND` = bit 1 (valor `1`), `PLAYER` = bit 2 (valor `2`). Tileset/chão em layer 1; player em layer 2; Areas que detectam player usam `collision_mask = 2`.
- Player está no grupo `"player"` e expõe `take_damage(amount, source_position)`, `heal(amount)`, `set_input_enabled(bool)`.
- Autoloads disponíveis: `SceneTransition`, `GameState`, `GameSettings`, `DialogManager`, `InventoryManager`, `LetterViewer`, `GameOver`.
- **Sem commits com Co-Authored-By** (preferência do usuário).
- **O ambiente não tem Godot no PATH** — nenhum passo deste plano roda o editor. O "bake" e o playtest são feitos pelo usuário; cada task marca claramente o que é verificação estática (automática) vs. checklist de editor (manual do usuário).
- Nomes de tiles iniciais (ajustáveis no editor depois): topo-grama = atlas `(5,4)`; fill = atlas `(0,8)`. Source id = `0`. Textura `res://assets/textures/tileset.png`.

---

## Task 1: Tileset compartilhado `forest_tileset.tres`

**Files:**
- Create: `assets/textures/forest_tileset.tres`

**Interfaces:**
- Produces: recurso `TileSet` com `physics_layer_0` (`collision_layer=1`, `collision_mask=2`) e um `TileSetAtlasSource` (source id `0`) sobre `tileset.png`, com dois tiles de colisão limpos: topo `(5,4)` (polígono fino no topo) e fill `(0,8)` (polígono caixa cheia), **sem** `linear_velocity`.

- [ ] **Step 1: Criar o recurso**

Conteúdo de `assets/textures/forest_tileset.tres`:

```
[gd_resource type="TileSet" load_steps=3 format=3 uid="uid://forest_tileset_tfa"]

[ext_resource type="Texture2D" uid="uid://hhaoe042w28g" path="res://assets/textures/tileset.png" id="1_tex"]

[sub_resource type="TileSetAtlasSource" id="atlas_0"]
texture = ExtResource("1_tex")
5:4/0 = 0
5:4/0/physics_layer_0/polygon_0/points = PackedVector2Array(-8, -8, 8, -8, 8, -6.4749136, -8, -6.4749136)
0:8/0 = 0
0:8/0/physics_layer_0/polygon_0/points = PackedVector2Array(-8, -8, 8, -8, 8, 8, -8, 8)

[resource]
physics_layer_0/collision_layer = 1
physics_layer_0/collision_mask = 2
sources/0 = SubResource("atlas_0")
```

- [ ] **Step 2: Verificação estática**

Run: `grep -c "physics_layer_0/polygon_0" assets/textures/forest_tileset.tres`
Expected: `2` (dois tiles com colisão).
Run: `grep -c "linear_velocity" assets/textures/forest_tileset.tres`
Expected: `0` (nenhuma velocidade residual).

- [ ] **Step 3: Commit**

```bash
git add assets/textures/forest_tileset.tres
git commit -m "feat: tileset compartilhado da floresta"
```

---

## Task 2: Cena de espinho `Hazard`

**Files:**
- Create: `scenes/hazards/hazard.gd`
- Create: `scenes/hazards/hazard.tscn`

**Interfaces:**
- Consumes: player `take_damage(amount, source_position)`; grupo `"player"`.
- Produces: cena `hazard.tscn` (raiz `Area2D` name `Hazard`) que dá 1 de dano no player ao toque. Pertence ao grupo `"baked"` quando instanciada pelo importer (o importer adiciona ao grupo).

- [ ] **Step 1: Script**

`scenes/hazards/hazard.gd`:

```gdscript
extends Area2D

@export var damage: int = 1

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
```

- [ ] **Step 2: Cena**

`scenes/hazards/hazard.tscn` (sprite = fatia de espinho do tileset; região é um ponto de partida ajustável no editor):

```
[gd_scene load_steps=3 format=3 uid="uid://hazard_tfa"]

[ext_resource type="Script" path="res://scenes/hazards/hazard.gd" id="1_s"]
[ext_resource type="Texture2D" uid="uid://hhaoe042w28g" path="res://assets/textures/tileset.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="shape"]
size = Vector2(14, 8)

[node name="Hazard" type="Area2D"]
script = ExtResource("1_s")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
region_enabled = true
region_rect = Rect2(48, 112, 16, 16)
offset = Vector2(0, 0)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, 4)
shape = SubResource("shape")
```

- [ ] **Step 3: Verificação estática**

Run: `grep -E "collision_mask = 2|take_damage" scenes/hazards/hazard.gd`
Expected: ambas as linhas presentes.

- [ ] **Step 4: Commit**

```bash
git add scenes/hazards/hazard.gd scenes/hazards/hazard.tscn
git commit -m "feat: hazard de espinho"
```

---

## Task 3: Cena `MovingPlatform`

**Files:**
- Create: `scenes/hazards/moving_platform.gd`
- Create: `scenes/hazards/moving_platform.tscn`

**Interfaces:**
- Produces: cena `moving_platform.tscn` (raiz `AnimatableBody2D` name `MovingPlatform`) que oscila entre `position` e `position + travel`, carregando o player. `@export travel: Vector2`, `@export duration: float`.

- [ ] **Step 1: Script**

`scenes/hazards/moving_platform.gd`:

```gdscript
extends AnimatableBody2D

@export var travel: Vector2 = Vector2(48, 0)
@export var duration: float = 2.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var start := position
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start + travel, duration)
	tween.tween_property(self, "position", start, duration)
```

- [ ] **Step 2: Cena**

`scenes/hazards/moving_platform.tscn` (sprite = fatia da plataforma de madeira do tileset; ajustável):

```
[gd_scene load_steps=3 format=3 uid="uid://moving_platform_tfa"]

[ext_resource type="Script" path="res://scenes/hazards/moving_platform.gd" id="1_s"]
[ext_resource type="Texture2D" uid="uid://hhaoe042w28g" path="res://assets/textures/tileset.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="shape"]
size = Vector2(48, 12)

[node name="MovingPlatform" type="AnimatableBody2D"]
script = ExtResource("1_s")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
region_enabled = true
region_rect = Rect2(176, 32, 48, 16)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("shape")
```

- [ ] **Step 3: Verificação estática**

Run: `grep -E "collision_layer = 1|sync_to_physics" scenes/hazards/moving_platform.gd`
Expected: ambas presentes.

- [ ] **Step 4: Commit**

```bash
git add scenes/hazards/moving_platform.gd scenes/hazards/moving_platform.tscn
git commit -m "feat: plataforma movel"
```

---

## Task 4: Cena `DeathZone`

**Files:**
- Create: `scenes/hazards/death_zone.gd`
- Create: `scenes/hazards/death_zone.tscn`

**Interfaces:**
- Consumes: autoload `GameOver.show_game_over()`; grupo `"player"`.
- Produces: cena `death_zone.tscn` (raiz `Area2D` name `DeathZone`) que mata o player ao entrar. O importer redimensiona/posiciona a colisão por level.

- [ ] **Step 1: Script**

`scenes/hazards/death_zone.gd`:

```gdscript
extends Area2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_node("/root/GameOver").call("show_game_over")
```

- [ ] **Step 2: Cena**

`scenes/hazards/death_zone.tscn`:

```
[gd_scene load_steps=3 format=3 uid="uid://death_zone_tfa"]

[ext_resource type="Script" path="res://scenes/hazards/death_zone.gd" id="1_s"]

[sub_resource type="RectangleShape2D" id="shape"]
size = Vector2(2000, 64)

[node name="DeathZone" type="Area2D"]
script = ExtResource("1_s")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("shape")
```

- [ ] **Step 3: Verificação estática**

Run: `grep "GameOver" scenes/hazards/death_zone.gd`
Expected: `get_node("/root/GameOver").call("show_game_over")`.

- [ ] **Step 4: Commit**

```bash
git add scenes/hazards/death_zone.gd scenes/hazards/death_zone.tscn
git commit -m "feat: death zone de queda"
```

---

## Task 5: Cena de maçã `apple_collectible.tscn`

**Files:**
- Create: `scenes/items/apple_collectible.tscn`

**Interfaces:**
- Consumes: `scenes/items/apple_collectible.gd` (já existe: `Area2D`, cura 1 ao toque, `queue_free`).
- Produces: cena `apple_collectible.tscn` instanciável pelo importer no char `A`.

- [ ] **Step 1: Cena**

`scenes/items/apple_collectible.tscn`:

```
[gd_scene load_steps=4 format=3 uid="uid://apple_collectible_tfa"]

[ext_resource type="Script" path="res://scenes/items/apple_collectible.gd" id="1_s"]
[ext_resource type="Texture2D" uid="uid://cm35d8lnjw038" path="res://assets/player/all-assets/apple.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="shape"]
radius = 8.0

[node name="AppleCollectible" type="Area2D"]
collision_layer = 0
collision_mask = 2
script = ExtResource("1_s")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("shape")
```

- [ ] **Step 2: Verificação estática**

Run: `grep -E "apple_collectible.gd|apple.png" scenes/items/apple_collectible.tscn`
Expected: ambas as referências presentes.

- [ ] **Step 3: Commit**

```bash
git add scenes/items/apple_collectible.tscn
git commit -m "feat: cena da maca coletavel"
```

---

## Task 6: Base script `forest_level.gd`

**Files:**
- Create: `scenes/levels/forest_level.gd`

**Interfaces:**
- Consumes: `SceneTransition.transition_to(path, marker)`, `SceneTransition.consume_spawn_marker()`; nós esperados na cena: `Ground` (`TileMapLayer`) com filho `Player`, `Camera2D`, `ExitDoor` (`Area2D`), `EntrySpawn` (`Marker2D`), `UI/PauseMenu`, `Player/InteractPrompt` (`Label`).
- Produces: comportamento comum de level (câmera, porta, spawn, pause) herdado por `level_2/3/4`. `@export next_scene_path: String`, `@export next_spawn_marker: String` (nome do marker, no level seguinte, onde o player deve aparecer).

- [ ] **Step 1: Script**

`scenes/levels/forest_level.gd`:

```gdscript
extends Node2D

@export var next_scene_path: String = ""
@export var next_spawn_marker: String = ""

@onready var _player: CharacterBody2D = $Ground/Player
@onready var _camera: Camera2D = $Camera2D
@onready var _exit_door: Area2D = $ExitDoor
@onready var _entry_spawn: Marker2D = $EntrySpawn
@onready var _interact_prompt: Label = $Ground/Player/InteractPrompt
@onready var _pause_menu: Control = $UI/PauseMenu

const CAMERA_SMOOTH_SPEED := 6.0

var _is_transitioning := false

func _ready() -> void:
	_interact_prompt.visible = false
	_exit_door.monitoring = true
	_apply_spawn_marker()

func _process(delta: float) -> void:
	if _is_transitioning:
		_interact_prompt.visible = false
		return

	_interact_prompt.visible = _exit_door.overlaps_body(_player)

	var smooth := 1.0 - exp(-CAMERA_SMOOTH_SPEED * delta)
	_camera.global_position = _camera.global_position.lerp(
		_player.global_position.round(), smooth
	)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	if event.is_action_pressed("ui_cancel") and !_pause_menu.visible:
		_pause_menu.open_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _exit_door.overlaps_body(_player):
		if next_scene_path == "":
			return
		_is_transitioning = true
		_interact_prompt.visible = false
		get_node("/root/SceneTransition").transition_to(next_scene_path, next_spawn_marker)

func _apply_spawn_marker() -> void:
	var marker_name: String = get_node("/root/SceneTransition").consume_spawn_marker()
	if marker_name == "" or marker_name != _entry_spawn.name:
		return
	_player.global_position = _entry_spawn.global_position
	_camera.global_position = _player.global_position.round()
```

- [ ] **Step 2: Verificação estática**

Run: `grep -E "next_scene_path|consume_spawn_marker|open_menu" scenes/levels/forest_level.gd`
Expected: as três presentes.

- [ ] **Step 3: Commit**

```bash
git add scenes/levels/forest_level.gd
git commit -m "feat: base script dos levels de floresta"
```

---

## Task 7: Importer `@tool` `layout_baker.gd`

**Files:**
- Create: `scenes/levels/tools/layout_baker.gd`

**Interfaces:**
- Consumes: na cena editada, o root deve ter `meta("layout_path")` (caminho do `.txt`) e um filho `Ground` (`TileMapLayer`) com o tileset compartilhado atribuído.
- Produces: ao rodar no editor, pinta tiles `#`/`=`, instancia `^`/`M`/`A`, posiciona `P`/`<`/`>`, e cria/atualiza `DeathZone`. Idempotente (limpa o que gerou antes via grupo `"baked"`).

- [ ] **Step 1: Script**

`scenes/levels/tools/layout_baker.gd`:

```gdscript
@tool
extends EditorScript

const CELL := 16
const SOURCE_ID := 0
const TOP_ATLAS := Vector2i(5, 4)
const FILL_ATLAS := Vector2i(0, 8)

const HAZARD := preload("res://scenes/hazards/hazard.tscn")
const MOVING_PLATFORM := preload("res://scenes/hazards/moving_platform.tscn")
const APPLE := preload("res://scenes/items/apple_collectible.tscn")
const DEATH_ZONE := preload("res://scenes/hazards/death_zone.tscn")

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		push_error("Abra a cena do level antes de rodar o baker.")
		return
	if not root.has_meta("layout_path"):
		push_error("O root da cena precisa de meta 'layout_path'.")
		return

	var layout_path: String = root.get_meta("layout_path")
	var text := FileAccess.get_file_as_string(layout_path)
	if text == "":
		push_error("Layout vazio ou nao encontrado: %s" % layout_path)
		return

	var layer := root.get_node_or_null("Ground") as TileMapLayer
	if layer == null:
		push_error("A cena precisa de um TileMapLayer chamado 'Ground'.")
		return

	_clear_previous(root, layer)

	var rows := text.split("\n", false)
	var max_x := 0
	var max_y := rows.size()
	for y in range(rows.size()):
		var row: String = rows[y]
		max_x = maxi(max_x, row.length())
		for x in range(row.length()):
			var c := row[x]
			var world := Vector2(x * CELL + CELL * 0.5, y * CELL + CELL * 0.5)
			match c:
				"#":
					layer.set_cell(Vector2i(x, y), SOURCE_ID, TOP_ATLAS)
				"=":
					layer.set_cell(Vector2i(x, y), SOURCE_ID, FILL_ATLAS)
				"^":
					_spawn(root, HAZARD, world)
				"M":
					_spawn(root, MOVING_PLATFORM, world)
				"A":
					_spawn(root, APPLE, world)
				"P":
					_place_marker(root, "PlayerSpawn", world)
				"<":
					_place_marker(root, "EntrySpawn", world)
				">":
					_place_door(root, world)

	_place_death_zone(root, max_x, max_y)
	print("Bake concluido: %d linhas, largura %d." % [max_y, max_x])

func _clear_previous(root: Node, layer: TileMapLayer) -> void:
	layer.clear()
	for node in _collect_baked(root):
		node.free()

func _collect_baked(node: Node) -> Array:
	var found: Array = []
	for child in node.get_children():
		if child.is_in_group("baked"):
			found.append(child)
		else:
			found.append_array(_collect_baked(child))
	return found

func _spawn(root: Node, scene: PackedScene, world: Vector2) -> void:
	var node := scene.instantiate() as Node2D
	root.add_child(node)
	node.owner = root
	node.global_position = world
	node.add_to_group("baked", true)

func _place_marker(root: Node, marker_name: String, world: Vector2) -> void:
	var marker := root.get_node_or_null(marker_name) as Marker2D
	if marker == null:
		marker = Marker2D.new()
		marker.name = marker_name
		root.add_child(marker)
		marker.owner = root
	marker.global_position = world

func _place_door(root: Node, world: Vector2) -> void:
	var door := root.get_node_or_null("ExitDoor") as Area2D
	if door == null:
		push_warning("ExitDoor nao existe na cena; criando um basico.")
		door = Area2D.new()
		door.name = "ExitDoor"
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(20, 40)
		col.shape = shape
		door.add_child(col)
		root.add_child(door)
		door.owner = root
		col.owner = root
	door.global_position = world

func _place_death_zone(root: Node, max_x: int, max_y: int) -> void:
	var zone := root.get_node_or_null("DeathZone") as Area2D
	if zone == null:
		zone = DEATH_ZONE.instantiate() as Area2D
		root.add_child(zone)
		zone.owner = root
	var width := maxf(max_x * CELL + 200, 400)
	var col := zone.get_node("CollisionShape2D") as CollisionShape2D
	(col.shape as RectangleShape2D).size = Vector2(width, 64)
	zone.global_position = Vector2(max_x * CELL * 0.5, (max_y + 4) * CELL)
```

- [ ] **Step 2: Verificação estática**

Run: `grep -E "set_cell|get_edited_scene_root|add_to_group..baked" scenes/levels/tools/layout_baker.gd`
Expected: as três presentes.

- [ ] **Step 3: Commit**

```bash
git add scenes/levels/tools/layout_baker.gd
git commit -m "feat: importer ASCII->tilemap"
```

---

## Task 8: Layouts ASCII dos 3 levels

**Files:**
- Create: `scenes/levels/layouts/level_2.txt`
- Create: `scenes/levels/layouts/level_3.txt`
- Create: `scenes/levels/layouts/level_4.txt`

**Interfaces:**
- Produces: 3 mapas ASCII. Vãos respeitam a calibração: 1 pulo ≤ 3 células, pulo-duplo ≤ 5 células. Cada char é uma célula 16px.

- [ ] **Step 1: Level 2 — "Orla da Floresta"**

`scenes/levels/layouts/level_2.txt`:

```
............................................
............................................
............................................
..............A.................A...........
............########......########..........
............========......========..........
....<...............MM......................
..########...####........####........####..>
..========...====........====........====..
.........^^..............^^.................
############################################
============================================
```

- [ ] **Step 2: Level 3 — "Mata Fechada"**

`scenes/levels/layouts/level_3.txt`:

```
..................................................
....<.........................................A...
..####....MM..........MM..............########....
..====................................========....
...........####...^^...####.......................
...........====........====...............MM......
......A.........................####..............>
..####.................^^^^......====....####.....
..====..........................########.====.....
.................................========..........
##########......................########..........
==========......................========..........
```

- [ ] **Step 3: Level 4 — "A Encruzilhada"**

`scenes/levels/layouts/level_4.txt` (bifurcação: corredor de cima = falso → espinhos; corredor de baixo = verdadeiro → porta):

```
..............................................
....<.........................................
..######......................................
..======......######..........................
.............=======..........................
.......................^^^^^^^^...............
.......................########...............
.......................========...............
..######......................................
..======......................................
.............................########........>
.............................========.........
..######......................................
..======......######..........................
.............=======..........................
##############################################
==============================================
```

- [ ] **Step 4: Verificação estática**

Run: `for f in scenes/levels/layouts/level_*.txt; do echo "$f:"; grep -c "" "$f"; done`
Expected: cada arquivo lista sua contagem de linhas (não vazio).
Run: `grep -l "P\|<" scenes/levels/layouts/level_2.txt`
Expected: `level_2.txt` (tem spawn de entrada).

- [ ] **Step 5: Commit**

```bash
git add scenes/levels/layouts/
git commit -m "feat: layouts ASCII dos levels 2-4"
```

---

## Task 9: Esqueleto das cenas `level_2/3/4.tscn`

**Files:**
- Create: `scenes/levels/level_2.tscn`
- Create: `scenes/levels/level_3.tscn`
- Create: `scenes/levels/level_4.tscn`

**Interfaces:**
- Consumes: `forest_level.gd`, `forest_tileset.tres`, `player.tscn`, `pause_menu.tscn`, `health_ui.tscn`.
- Produces: cenas com `Ground` (TileMapLayer + tileset + Player), `Camera2D`, `UI/PauseMenu`, `HUD/HealthUI`, `EntrySpawn`, `ExitDoor`, e `meta("layout_path")` apontando pro `.txt`. `next_scene_path` encadeado: 2→3, 3→4, 4→`final_level.tscn`.

- [ ] **Step 1: `level_2.tscn`**

```
[gd_scene load_steps=6 format=3 uid="uid://level_2_tfa"]

[ext_resource type="Script" path="res://scenes/levels/forest_level.gd" id="1_s"]
[ext_resource type="TileSet" uid="uid://forest_tileset_tfa" path="res://assets/textures/forest_tileset.tres" id="2_ts"]
[ext_resource type="PackedScene" uid="uid://dxrmb8kjqeort" path="res://scenes/player/player.tscn" id="3_player"]
[ext_resource type="PackedScene" uid="uid://dl2lvutrpved5" path="res://scenes/ui/pause_menu.tscn" id="4_pause"]
[ext_resource type="PackedScene" uid="uid://cpd8mc3n3xrpt" path="res://scenes/ui/health_ui.tscn" id="5_health"]

[node name="Level2" type="Node2D"]
script = ExtResource("1_s")
next_scene_path = "res://scenes/levels/level_3.tscn"
next_spawn_marker = "EntrySpawn"
metadata/layout_path = "res://scenes/levels/layouts/level_2.txt"

[node name="Ground" type="TileMapLayer" parent="."]
tile_set = ExtResource("2_ts")

[node name="Player" parent="Ground" instance=ExtResource("3_player")]
position = Vector2(40, 100)

[node name="InteractPrompt" type="Label" parent="Ground/Player"]
visible = false
offset_left = -20.0
offset_top = -40.0
text = "E"

[node name="EntrySpawn" type="Marker2D" parent="."]
position = Vector2(40, 100)

[node name="ExitDoor" type="Area2D" parent="."]
position = Vector2(600, 100)

[node name="CollisionShape2D" type="CollisionShape2D" parent="ExitDoor"]

[node name="Camera2D" type="Camera2D" parent="."]

[node name="UI" type="CanvasLayer" parent="."]

[node name="PauseMenu" parent="UI" instance=ExtResource("4_pause")]

[node name="HUD" type="CanvasLayer" parent="."]

[node name="HealthUI" parent="HUD" instance=ExtResource("5_health")]
```

- [ ] **Step 2: `level_3.tscn`**

Copie o conteúdo de `level_2.tscn` e altere: `uid` → `uid://level_3_tfa`; `[node name="Level2"` → `[node name="Level3"`; `next_scene_path = "res://scenes/levels/level_4.tscn"`; `metadata/layout_path = "res://scenes/levels/layouts/level_3.txt"`.

- [ ] **Step 3: `level_4.tscn`**

Copie o conteúdo de `level_2.tscn` e altere: `uid` → `uid://level_4_tfa`; `[node name="Level2"` → `[node name="Level4"`; `next_scene_path = "res://scenes/levels/final_level.tscn"`; `metadata/layout_path = "res://scenes/levels/layouts/level_4.txt"`.

- [ ] **Step 4: Verificação estática**

Run: `grep -h "next_scene_path" scenes/levels/level_2.tscn scenes/levels/level_3.tscn scenes/levels/level_4.tscn`
Expected: encadeamento 3 → 4 → final.
Run: `grep -h "layout_path" scenes/levels/level_*.tscn`
Expected: cada cena aponta pro seu `.txt`.

- [ ] **Step 5: Commit**

```bash
git add scenes/levels/level_2.tscn scenes/levels/level_3.tscn scenes/levels/level_4.tscn
git commit -m "feat: esqueleto das cenas level 2-4"
```

---

## Task 10: Wiring `tend → level_2` + diálogo da encruzilhada

**Files:**
- Modify: `scenes/levels/tend_level.gd` (`_finish_cutscene`, ~linha 196-211)

**Interfaces:**
- Consumes: `SceneTransition.transition_to(path, marker)`.
- Produces: ao fim da cutscene do lobo, transição automática pra `level_2.tscn`; o lobo dá uma dica (verdadeira/falsa) que prepara a encruzilhada do level_4.

- [ ] **Step 1: Editar `_finish_cutscene`**

Em `scenes/levels/tend_level.gd`, no fim de `_finish_cutscene()`, depois de `_wolf.visible = false`, troque `_unlock_player()` + `_state = ...` pelo bloco abaixo (mantém o sinal, adiciona a dica e a transição):

```gdscript
	_wolf.visible = false
	_state = CutsceneState.FINISHED
	dialogue_finished.emit()
	await get_node("/root/DialogManager").start_dialog([
		"Quando a trilha se partir em duas, suba.",
		"O alto é sempre mais seguro... ou foi o que ele disse."
	])
	get_node("/root/SceneTransition").transition_to(
		"res://scenes/levels/level_2.tscn", "EntrySpawn"
	)
```

(O caminho de cima no level_4 é o falso — a dica do lobo é a mentira do GDD.)

- [ ] **Step 2: Verificação estática**

Run: `grep -E "level_2.tscn|Quando a trilha" scenes/levels/tend_level.gd`
Expected: ambas presentes.

- [ ] **Step 3: Commit**

```bash
git add scenes/levels/tend_level.gd
git commit -m "feat: lobo encaminha pro level 2 com dica enganosa"
```

---

## Task 11 (manual — usuário): Bake e playtest no editor

> Esta task **não** é executada pelo agente (precisa do Godot). É o checklist que o usuário roda no editor após as tasks 1-10.

- [ ] Abrir `level_2.tscn`. Confirmar que `Ground` tem o `forest_tileset.tres`. Rodar `scenes/levels/tools/layout_baker.gd` (File → Run, ou botão Run do EditorScript). Repetir pra `level_3` e `level_4`.
- [ ] Rodar o baker 2× em um level → confirmar que não duplica nós (idempotência).
- [ ] Ajustar `region_rect` dos sprites de Hazard/MovingPlatform se a fatia do tileset não bater visualmente.
- [ ] Playtest do fluxo: lobo (tend) → level_2 → level_3 → level_4. Cada porta leva ao próximo com spawn correto.
- [ ] Checklist por level: spawn certo; todo buraco mata via DeathZone; espinho dá dano+knockback; plataforma móvel carrega o player; câmera segue sem mostrar fora.
- [ ] Level_4: caminho de cima (dica do lobo) leva a espinhos/morte; caminho de baixo leva à porta.
- [ ] Definir `run/main_scene` ou ponto de entrada conforme necessário; criar `final_level.tscn` (fora deste plano).
```
