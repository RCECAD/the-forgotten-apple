# Design — Levels de floresta (The Forgotten Apple)

**Data:** 2026-06-21
**Autor:** Rafael (+ Claude)
**Status:** aprovado para implementação

## Objetivo

Adicionar pelo menos 3 levels de plataforma na floresta, mais o framework que permite
construí-los de forma autorável por texto. A fase final (puzzle/forno/vovó) fica fora
deste spec.

O problema central que motivou o spec: as plataformas atuais (`level_1`) usam um
`TileMapLayer` cujo `tile_map_data` no `.tscn` é um blob binário (PackedByteArray base64),
inviável de editar como texto à mão. Sem um método autorável por texto, ninguém além de
quem domina o editor consegue produzir levels.

## Restrições conhecidas

- O ambiente de desenvolvimento (Claude) **não tem o Godot no PATH** — só escreve arquivos
  texto (`.tscn`, `.gd`, `.tres`, `.txt`). Não roda o editor nem gera dados binários de tilemap.
- Player só tem: mover, pular, pulo-duplo, abaixar. **Sem ataque, sem dash.** Todo level é
  travessia + desviar. Inimigos (abelha) não podem ser derrotados, só evitados.
- O `tileset.png` é uma cena de floresta pintada, não um tileset modular limpo. Só alguns
  tiles "casam" bem como chão genérico.

## Física do player (calibração de level design)

Constantes em `scenes/player/player.gd`:
- `GRAVITY = 1000`, `JUMP_FORCE = -300`, `MAX_JUMPS = 2`
- `WALK_SPEED = 90`, `RUN_SPEED = 155`

Derivado (célula do tilemap = 16px):
- Altura de 1 pulo ≈ 45px ≈ **~3 células**. Tempo ao ápice 0.3s.
- Alcance horizontal de 1 pulo (ida e volta ao mesmo nível): WALK ~54px (~3 células),
  RUN ~93px (~6 células).
- Pulo-duplo estende ar-tempo e alcance.

Limites conservadores para os layouts:
- Vão de 1 pulo: **≤ 3 células**.
- Vão de pulo-duplo: **≤ 5 células**.
- Degrau vertical pra cima por pulo: **≤ 2,5 células**.

## Arquitetura

### Pipeline de construção (ASCII → tilemap)

1. **Tileset compartilhado:** extrair o `TileSet` hoje embutido inline em `level_1.tscn`
   para `assets/textures/forest_tileset.tres`. Os 3 levels novos referenciam esse recurso.
   `level_1.tscn` permanece como está (evita regressão); migrá-lo é follow-up opcional.

2. **Layouts em texto:** um arquivo por level em `scenes/levels/layouts/` (`level_2.txt`,
   `level_3.txt`, `level_4.txt`). Legenda:

   | Char | Significado | Ação do importer |
   |------|-------------|------------------|
   | `.`  | vazio | nada |
   | `#`  | chão-topo (grama, colisão fina no topo) | pinta tile de topo |
   | `=`  | fill sólido (colisão cheia) | pinta tile de fill |
   | `^`  | espinho | instancia `Hazard.tscn` na célula |
   | `M`  | plataforma móvel | instancia `MovingPlatform.tscn` na célula |
   | `A`  | maçã (cura) | instancia `apple_collectible` na célula |
   | `P`  | spawn inicial | posiciona marker `PlayerSpawn` |
   | `<`  | spawn de entrada (vindo do level anterior) | posiciona marker de entrada |
   | `>`  | porta de saída (próximo level) | posiciona `ExitDoor` (Area2D) |

   Cada linha do `.txt` = uma fileira de células; coluna = posição x. Célula 16px.

3. **Importer `@tool`:** `scenes/levels/tools/layout_baker.gd` (EditorScript).
   - Lê o `.txt` de um level e o `TileMapLayer` alvo da cena aberta.
   - Pinta `#`/`=` via `TileMapLayer.set_cell()` (a API cuida do encoding binário).
   - Instancia as cenas dos chars especiais (`^`, `M`, `A`) como filhos da cena, na posição
     da célula.
   - Posiciona os markers `P`, `<`, `>`.
   - **Idempotente:** antes de pintar, limpa as células e remove os nós previamente gerados
     (marcados por grupo `baked`), pra rodar 2× sem duplicar.
   - Cria/atualiza 1 `DeathZone` dimensionado pela largura do layout, abaixo da fileira mais baixa.

   Execução: abrir a cena do level no Godot, rodar o EditorScript (1× por level). É o único
   passo de editor — feito por quem tem o Godot (não pelo Claude).

### Kit reutilizável (cenas novas)

| Cena | Nó raiz | Comportamento |
|------|---------|---------------|
| `scenes/hazards/hazard.tscn` | Area2D | `body_entered` no grupo `player` → `take_damage(1, global_position)`. Reusa knockback/i-frames do player. Sprite = fatia do tileset. |
| `scenes/hazards/moving_platform.tscn` | AnimatableBody2D | Props `@export travel: Vector2`, `@export duration: float`. Loop ida-e-volta (tween). `sync_to_physics = true` → carrega o player. `collision_layer = GROUND`. |
| `scenes/hazards/death_zone.tscn` | Area2D | `body_entered` no player → morte instantânea → `GameOver.show_game_over()`. Resolve queda no vazio. |

### Base script dos levels

`scenes/levels/forest_level.gd` — herdado pelos 3 levels novos (elimina o copy-paste
apontado na análise de gaps). Responsabilidades:
- Câmera segue o player (x + y) com limites derivados dos bounds do level.
- Parallax de background.
- Abrir pause (`ui_cancel`); prompt de interação nas portas.
- `interact` na porta de saída → `SceneTransition.transition_to(next_scene_path, entry_marker)`.
- Aplicar spawn marker na entrada (reusa `SceneTransition.consume_spawn_marker`).
- Wiring do `DeathZone`, vento/música.
- `@export next_scene_path: String` por level.

Cada level = cena (`level_2.tscn` etc.) com `forest_level.gd` + um `TileMapLayer` (pra bake)
+ config mínima.

## Encadeamento no fluxo

```
bedroom → kitchen → level_1 (floresta) → tend (lobo)
        → level_2 → level_3 → level_4 → [final_level.tscn — fase final, fora deste spec]
```

Wiring novo:
- `tend_level.gd`: hoje não transiciona ao fim da cutscene. Após `dialogue_finished` (lobo
  some), adicionar saída → `level_2.tscn` (porta ou auto-transição).
- `level_4` saída → `res://scenes/levels/final_level.tscn` (placeholder; a fase final é
  construída lá por quem faz os puzzles).

## Conteúdo dos 3 levels (progressão)

Dificuldade crescente, só travessia.

**Level 2 — "Orla da Floresta"** (intro suave)
- Ensina o vão + pulo-duplo sobre 1 buraco. Primeiros espinhos no chão. 1 plataforma móvel
  curta. Maçãs no caminho. Sem escolha mortal. Horizontal.

**Level 3 — "Mata Fechada"** (aperta)
- Plataformas móveis encadeadas, vão com espinhos embaixo, 1 seção de buraco mortal.
  Abelhas patrulhando entre plataformas (desviar). Leve verticalidade.

**Level 4 — "A Encruzilhada"** (provação / clímax do platforming)
- Bifurcação após uma placa/fork: 1 caminho (a "dica" do lobo) é **falso** → espinhos/queda
  mortal; o caminho **verdadeiro** → progresso. Liga às dicas verdadeiras/falsas do lobo (GDD).
- A escolha é puro layout: dois corredores; o errado tem hazard/DeathZone, o certo segue.
- Sinalização via sprite de placa ou diálogo curto do lobo (reusa `DialogManager`).
- Termina na porta pra fase final.

## Testing

Sem framework de teste no Godot → verificação manual (feita no editor por quem tem o Godot).

- **Importer:** rodar 2× no mesmo `.txt` → mesmo resultado, sem duplicar nós (idempotência).
- **Checklist por level:**
  - spawn de entrada correto vindo do level anterior;
  - todo buraco tem `DeathZone` abaixo;
  - espinho dá dano + knockback;
  - plataforma móvel carrega o player;
  - porta transiciona pra próxima cena com o spawn certo;
  - câmera respeita os limites (não mostra fora do level).
- **Level 4:** caminho falso mata; caminho verdadeiro progride.

## Escopo

**Entregue (texto, pelo Claude):**
- `forest_tileset.tres`
- importer `@tool` (`layout_baker.gd`)
- kit: `hazard.tscn`/`.gd`, `moving_platform.tscn`/`.gd`, `death_zone.tscn`/`.gd`
- `apple_collectible.tscn` (criar se não existir — hoje só há o `.gd`; o importer precisa de uma cena pra instanciar no char `A`)
- `forest_level.gd`
- esqueleto das cenas `level_2/3/4.tscn`
- 3 layouts ASCII
- wiring `tend → level_2` e `level_4 → final_level.tscn`

**Fora:**
- Fase final (puzzle/forno/vovó).
- SFX, música, ajustes finos.
- O bake no editor e a validação manual (feitos por quem tem o Godot).

## Riscos

| Risco | Mitigação |
|-------|-----------|
| Claude não roda o bake nem vê o resultado | Importer simples + idempotente + checklist claro; bake feito no editor |
| Tileset pintado (não modular) → bordas podem não casar | Mapear poucos tiles seguros (topo-grama + fill); ajuste fino visual no editor |
| Level design "no escuro" (sem rodar) | Layouts conservadores nas distâncias de pulo, calibrados pela física do player |
| Plataforma móvel + física do player | `AnimatableBody2D` com `sync_to_physics` (padrão Godot) |
