# The Forgotten Apple - Game Design Document

**Versão:** 0.1  
**Data:** 2026-06-21  
**Engine:** Godot 4.6  
**Plataforma alvo:** PC, com configuração de projeto marcada para Mobile  
**Gênero:** aventura 2D narrativa com plataforma  
**Status:** em desenvolvimento

## Visão Geral

*The Forgotten Apple* é uma aventura 2D inspirada em contos de fadas, com foco em exploração, diálogos e travessia de plataforma. A jogadora controla uma garota que sai de casa para procurar sua avó depois de encontrar sinais de que algo está errado.

O jogo combina cenas internas mais narrativas, como quarto, cozinha, cabana e tenda, com fases de floresta voltadas a plataforma, perigos ambientais e leitura de caminhos. O clima deve ser de conto familiar tensionado por estranhamento: aconchegante no início, progressivamente mais incerto na floresta.

## Pilares de Design

- **Narrativa simples e direta:** a motivação principal é encontrar a avó. Os diálogos devem revelar contexto sem interromper demais o ritmo.
- **Floresta como ameaça:** o desafio vem de observar terreno, evitar criaturas e escolher caminhos com cuidado.
- **Controles enxutos:** mover, correr, pular, pulo duplo, abaixar, interagir e inventário.
- **Progressão legível:** cada nova fase deve introduzir ou combinar obstáculos de forma conservadora.
- **Estética artesanal:** pixel art, fundos de floresta e interiores, UI simples e temática.

## Premissa

A protagonista acorda tarde e lembra que deveria ajudar a avó com tarefas da casa e uma torta. Na cozinha, encontra uma nota recente e percebe que a avó não voltou quando deveria. Contra a orientação de esperar em casa, decide sair para procurá-la.

A busca leva a garota até a floresta, onde encontra uma cabana, uma tenda e um lobo misterioso. O lobo não se apresenta como inimigo direto, mas fala sobre os perigos da floresta, dá avisos ambíguos e reforça o tema de que pressa e escolhas fáceis podem levar ao erro.

## Personagens

### Garota

Protagonista jogável. É determinada, preocupada com a avó e impulsionada pela necessidade de agir. Sua vulnerabilidade é mecânica e narrativa: ela não ataca, apenas atravessa, observa e evita perigos.

### Avó

Figura ausente que motiva a jornada. Está associada à casa, à torta e às instruções deixadas para a garota. A fase final prevista deve resolver o mistério ligado a ela.

### Lobo

Personagem ambíguo encontrado na tenda. Ele conhece a floresta e alerta a protagonista sobre caminhos enganosos, criaturas e sinais falsos. Deve funcionar como guia duvidoso, não como ameaça de combate.

## Fluxo Atual de Jogo

1. **Splash / Menu:** entrada do jogo.
2. **Quarto:** introdução narrativa. A garota acorda e decide se apressar.
3. **Cozinha:** interação com a carta/lista, coleta do item de carta e abertura do inventário.
4. **Floresta - Level 1:** primeira área externa, com cabana e entrada para a tenda.
5. **Cabana:** área interna conectada de volta à floresta.
6. **Tenda:** cutscene com o lobo e avisos sobre a floresta.
7. **Levels 2, 3 e 4:** planejados para expandir a travessia de plataforma.
8. **Fase final:** planejada, fora do escopo atual; deve envolver puzzle/forno/avó.

## Mecânicas Principais

### Movimento

- Andar para esquerda e direita.
- Correr segurando Shift.
- Pular.
- Pulo duplo.
- Abaixar.
- Câmera acompanha a personagem nas fases externas.

### Interação

- Tecla `E` para interagir.
- Prompts aparecem quando a personagem está próxima de portas ou itens interativos.
- Diálogos bloqueiam o controle do jogador até terminarem.

### Inventário

- Tecla `I` abre/fecha o inventário.
- A carta é coletada na cozinha.
- A carta pode ser visualizada pelo sistema de `LetterViewer`.

### Vida e Dano

- Vida padrão: 3.
- Dano reduz vida e aplica invulnerabilidade temporária, piscada visual e knockback.
- Maçãs curam 1 ponto de vida.
- Ao chegar a 0 de vida, o jogo chama a tela de game over.

### Plataforma e Perigos

- O jogador não possui ataque, dash ou defesa ativa.
- Inimigos e hazards devem ser evitados, não derrotados.
- Perigos previstos:
  - Espinhos.
  - Quedas mortais.
  - Abelhas patrulhando.
  - Plataformas móveis.

## Controles

| Ação | Entrada |
| --- | --- |
| Mover | `A/D` ou setas |
| Correr | `Shift` |
| Pular | `W`, `Espaço` ou seta para cima |
| Abaixar | `S` ou seta para baixo |
| Interagir | `E` |
| Avançar diálogo | `E`, `Enter` ou `Espaço` |
| Inventário | `I` |
| Pausa | `Esc` |

## Parâmetros do Player

Valores atuais em `scenes/player/player.gd`:

| Parâmetro | Valor |
| --- | --- |
| Gravidade | `1000` |
| Velocidade andando | `90` |
| Velocidade correndo | `155` |
| Força do pulo | `-300` |
| Máximo de pulos | `2` |
| Vida inicial | `3` |
| Invulnerabilidade após dano | `0.9s` |
| Bloqueio de controle após dano | `0.26s` |

Considerando tiles de 16 px:

- Um pulo simples alcança aproximadamente 3 células de altura.
- Um vão seguro para pulo simples deve ficar em até 3 células.
- Um vão para pulo duplo deve ficar em até 5 células.
- Degraus verticais para cima devem ficar em até aproximadamente 2,5 células.

## Estrutura de Fases

### Quarto

Função: introdução narrativa e primeiro uso de porta/interação.  
Conteúdo: diálogo inicial sobre acordar tarde, limpar a casa e ajudar a avó.

### Cozinha

Função: motivação da jornada.  
Conteúdo: carta/lista de compras, coleta do item de carta, abertura do visualizador de carta e decisão de procurar a avó.

### Floresta - Level 1

Função: primeira área externa e hub curto.  
Conteúdo: porta para cabana, entrada automática para a tenda e ambientação da floresta.

### Cabana

Função: área interna conectada ao Level 1.  
Conteúdo: retorno para a floresta usando spawn marker específico.

### Tenda

Função: encontro narrativo com o lobo.  
Conteúdo: cutscene com diálogo, troca visual para imagem da floresta e aviso sobre perigos e caminhos enganosos.

## Levels Planejados de Floresta

Os levels 2, 3 e 4 devem usar layouts ASCII em texto para facilitar autoria sem depender de edição manual de `TileMapLayer` no arquivo `.tscn`.

### Level 2 - Orla da Floresta

Objetivo: introduzir plataforma com segurança.

- Vãos simples e pulo duplo.
- Primeiros espinhos.
- Uma plataforma móvel curta.
- Maçãs posicionadas no caminho.
- Sem escolha mortal.

### Level 3 - Mata Fechada

Objetivo: combinar obstáculos.

- Plataformas móveis encadeadas.
- Vãos com espinhos abaixo.
- Seções com queda mortal.
- Abelhas patrulhando entre plataformas.
- Verticalidade leve.

### Level 4 - A Encruzilhada

Objetivo: clímax de plataforma e escolha temática.

- Bifurcação ligada aos avisos do lobo.
- Caminho falso leva a espinhos ou queda mortal.
- Caminho verdadeiro permite progresso.
- Sinalização por placa, diálogo curto ou composição visual.
- Saída aponta para a fase final.

## Pipeline de Autoria de Levels

O plano técnico atual propõe:

- `assets/textures/forest_tileset.tres` como tileset compartilhado.
- Layouts em `scenes/levels/layouts/*.txt`.
- Importer `@tool` em `scenes/levels/tools/layout_baker.gd`.
- Cenas reutilizáveis para hazards:
  - `scenes/hazards/hazard.tscn`
  - `scenes/hazards/moving_platform.tscn`
  - `scenes/hazards/death_zone.tscn`
- Script base `scenes/levels/forest_level.gd` para câmera, portas, spawn, pausa e áudio.

Legenda planejada dos layouts:

| Char | Significado |
| --- | --- |
| `.` | vazio |
| `#` | topo de chão |
| `=` | preenchimento sólido |
| `^` | espinho |
| `M` | plataforma móvel |
| `A` | maçã |
| `P` | spawn inicial |
| `<` | entrada vindo do level anterior |
| `>` | saída para o próximo level |

## Direção Visual

- Pixel art 2D.
- Personagem com animações de idle, walk, run, jump, fall, abaixar e levantar.
- Floresta com parallax e atmosfera mais escura/incerta.
- Interiores com leitura clara e objetos de história.
- UI com caixas de diálogo, menu de pausa, inventário e tela de game over.

## Direção de Áudio

Áudios presentes no projeto:

- Passos em grama.
- Passos em madeira.
- Vento.
- Hum de interior.
- Zumbido de abelha.
- Som de coleta/papel.
- Trilha sonora principal.

O áudio deve reforçar contraste entre casa/interiores e floresta. Ajustes de volume passam por `GameSettings`.

## Arquitetura Atual

### Autoloads

| Autoload | Responsabilidade |
| --- | --- |
| `SceneTransition` | Fade, troca de cena, reload e spawn marker |
| `GameSettings` | Configurações, principalmente áudio |
| `GameState` | Vida e progresso narrativo global |
| `DialogManager` | Controle de diálogos e bloqueio do player |
| `InventoryManager` | Inventário e coleta da carta |
| `LetterViewer` | Visualização da carta |
| `GameOver` | Tela de game over |

### Pastas Principais

| Pasta | Conteúdo |
| --- | --- |
| `assets/` | arte, fontes, áudio, temas e texturas |
| `scenes/player/` | player e estado global de vida/progresso |
| `scenes/levels/` | fases e scripts de fase |
| `scenes/ui/` | menus, diálogos, inventário, transições e game over |
| `scenes/interactables/` | objetos interativos |
| `scenes/items/` | itens coletáveis |
| `scenes/enemies/` | inimigos |
| `docs/` | documentação, specs e planos |

## Restrições de Escopo

- Não há combate do player no design atual.
- O lobo não deve virar boss no escopo descrito.
- A fase final ainda não está definida neste GDD.
- O bake dos layouts ASCII precisa ser feito no editor Godot por quem tiver o Godot disponível.
- Sem framework automatizado de testes Godot configurado no repositório.

## Checklist de Validação Manual

- Fluxo quarto -> cozinha -> floresta funciona.
- Carta pode ser coletada, visualizada e mantida no inventário.
- Diálogos bloqueiam e restauram input corretamente.
- Pausa funciona nas fases jogáveis.
- Dano reduz vida, aplica knockback e chama game over em 0.
- Maçãs curam sem ultrapassar vida máxima.
- Transições com spawn marker posicionam o player corretamente.
- Levels de floresta não exigem saltos além dos limites definidos.
- Caminho falso do Level 4 mata ou bloqueia progresso de forma clara.

## Referências Internas

- Spec de levels de floresta: `docs/superpowers/specs/2026-06-21-forest-levels-design.md`
- Plano de implementação de levels: `docs/superpowers/plans/2026-06-21-forest-levels.md`
- Configuração Godot: `project.godot`
- Player: `scenes/player/player.gd`
- Estado global: `scenes/player/game_state.gd`
