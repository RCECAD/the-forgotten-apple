# AGENTS.md

## Projeto

Este repositório contém *The Forgotten Apple*, um jogo 2D em Godot 4.6 com foco em narrativa, exploração e fases de plataforma na floresta.

Antes de alterar gameplay ou conteúdo narrativo, leia:

- `docs/gdd.md`
- `project.godot`
- `scenes/player/player.gd`
- `scenes/player/game_state.gd`
- os scripts da fase que será modificada em `scenes/levels/`

Para trabalho nos novos levels de floresta, leia também:

- `docs/superpowers/specs/2026-06-21-forest-levels-design.md`
- `docs/superpowers/plans/2026-06-21-forest-levels.md`

## Stack e Execução

- Engine: Godot 4.6.
- Linguagem: GDScript.
- Cena inicial: `res://scenes/ui/splash_screen.tscn`.
- Resolução base: 1280x720.
- Stretch: viewport.
- Renderer: `gl_compatibility`.
- Filtro padrão de textura: nearest/pixel art.

O ambiente de automação pode não ter `godot` no `PATH`. Se não houver Godot disponível, faça validação estática por leitura, `rg`, checagem de recursos e consistência de paths. Deixe claro no resultado quando playtest ou bake no editor não foram executados.

## Convenções de Código

- Use tabs para indentação em `.gd`, seguindo o padrão dos scripts existentes.
- Prefira tipagem GDScript quando o contexto local já usa tipos.
- Mantenha scripts de fase simples e específicos; extraia base comum apenas quando houver duplicação real.
- Use os autoloads existentes em vez de criar singletons novos sem necessidade.
- Não faça refactors amplos junto com mudanças de conteúdo.
- Não altere `.import` manualmente.
- Evite editar dados binários de `TileMapLayer` em `.tscn`; para novos levels de floresta, prefira o pipeline ASCII planejado.

## Autoloads

Autoloads definidos em `project.godot`:

- `SceneTransition`: fade, troca de cena, reload e spawn marker.
- `GameSettings`: aplicação de configurações, principalmente áudio.
- `GameState`: vida do player e progresso narrativo global.
- `DialogManager`: exibição de diálogos e bloqueio de input.
- `InventoryManager`: inventário, carta e apresentação de coleta.
- `LetterViewer`: visualização da carta.
- `GameOver`: fluxo de game over.

Use esses pontos de integração antes de criar sistemas paralelos.

## Gameplay Atual

O player:

- pertence ao grupo `player`;
- expõe `take_damage(amount, source_position)`;
- expõe `heal(amount)`;
- expõe `set_input_enabled(enabled)`;
- tem 3 pontos de vida por padrão;
- pode andar, correr, pular, fazer pulo duplo e abaixar;
- não possui ataque, dash ou defesa ativa.

Hazards e inimigos devem ser desenhados para desvio e leitura de movimento, não para combate.

## Inputs

Use as ações do Input Map, não teclas hardcoded, exceto onde o código existente já faz isso por escolha local.

- `move_left`
- `move_right`
- `jump`
- `down`
- `interact`
- `dialog_advance`
- `inventory`
- `ui_cancel`

## Estrutura de Pastas

- `assets/`: arte, áudio, fontes, texturas e tema global.
- `scenes/player/`: player e estado global associado.
- `scenes/levels/`: fases e scripts de fase.
- `scenes/ui/`: menus, diálogos, inventário, transição, carta e game over.
- `scenes/interactables/`: objetos interativos.
- `scenes/items/`: coletáveis.
- `scenes/enemies/`: inimigos.
- `docs/`: GDD, specs e planos.

## Fluxo Narrativo Atual

Fluxo implementado:

`splash/menu -> bedroom -> kitchen -> level_1 -> cabin/tend`

Fluxo planejado:

`bedroom -> kitchen -> level_1 -> tend -> level_2 -> level_3 -> final_scene -> hidden_room`

Preserve a motivação central: a garota procura a avó depois de encontrar sinais de que ela não voltou.

## Levels de Floresta

Para novos levels de floresta:

- Célula do tilemap: 16 px.
- Vão seguro de pulo simples: até 3 células.
- Vão com pulo duplo: até 5 células.
- Degrau vertical recomendado: até 2,5 células.
- Não dependa de combate para resolver obstáculos.
- Use maçãs como cura pontual.
- Use espinhos, quedas, abelhas e plataformas móveis como obstáculos principais.

Pipeline planejado:

- `assets/textures/forest_tileset.tres`
- `scenes/levels/layouts/*.txt`
- `scenes/levels/tools/layout_baker.gd`
- `scenes/levels/forest_level.gd`
- hazards reutilizáveis em `scenes/hazards/`

Legenda planejada:

| Char | Significado |
| --- | --- |
| `.` | vazio |
| `#` | topo de chão |
| `=` | preenchimento sólido |
| `^` | espinho |
| `M` | plataforma móvel |
| `A` | maçã |
| `P` | spawn inicial |
| `<` | entrada |
| `>` | saída |

## UI e Diálogos

- Use `DialogManager.start_dialog(...)` para diálogos.
- Diálogos devem bloquear input do player enquanto ativos.
- Verifique `DialogManager`, `InventoryManager` e `LetterViewer` antes de aceitar interação em fase.
- Prompts de interação devem aparecer apenas quando a ação estiver disponível.
- `SceneTransition.transition_to(...)` deve ser usado para troca de cena com fade.

## Áudio

- Aplique configurações com `GameSettings.apply_audio()` quando a cena inicia áudio próprio.
- Evite iniciar várias trilhas concorrentes sem parada ou fade.
- Sons existentes ficam em `assets/sfx/`.

## Validação

Quando Godot estiver disponível:

- Abrir o projeto no editor.
- Rodar a cena inicial.
- Testar fluxo da fase alterada.
- Confirmar ausência de erros no Output.
- Verificar transições, pause, diálogos e controle do player.

Quando Godot não estiver disponível:

- Use `rg` para validar paths `res://`.
- Leia `.tscn` e `.gd` relacionados.
- Verifique se scripts referenciados existem.
- Verifique se sinais, grupos e métodos chamados existem.
- Informe que a validação foi estática.

## Git

- Não reverta mudanças que não foram feitas por você.
- Não use comandos destrutivos sem pedido explícito.
- Não inclua `Co-Authored-By` em commits.
- Antes de finalizar uma tarefa com edição, rode `git status --short` e reporte os arquivos alterados.
