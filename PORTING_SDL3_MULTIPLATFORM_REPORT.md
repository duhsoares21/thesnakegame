# Relatorio de portabilidade: Win32/MASM para SDL3, Linux e macOS

Data da analise: 2026-08-08  
Escopo analisado: projeto `Snake` na subpasta `Snake`, atualmente em x64 Assembly MASM, Win32, GDI, XInput e `Beep`.

## 1. Resumo executivo

A aplicacao e portavel para SDL3, Linux e macOS, mas nao por substituicao mecanica de chamadas Win32. O projeto atual tem tres acoplamentos fortes:

1. Plataforma: criacao de janela, message loop, timers, pintura, fontes, icone, fechamento de janelas e dimensoes de cliente estao todos baseados em Win32.
2. Graficos/input/audio: renderizacao usa GDI, controle usa XInput e audio usa `Beep`.
3. Toolchain/ABI: o codigo esta escrito em MASM com convencao Windows x64, usando `RCX`, `RDX`, `R8`, `R9`, shadow space e sintaxe/recursos especificos de MASM.

Minha conclusao: manter Assembly ainda e viavel tecnicamente para Linux x86-64 e macOS Intel, mas vira um projeto de portabilidade de medio/alto esforco. Para macOS nativo em Apple Silicon, a historia muda: x64 Assembly nao basta. Seria necessario portar a logica para AArch64 Assembly, usar C como camada principal e/ou aceitar execucao x86-64 via Rosetta onde aplicavel. Se o objetivo e multiplataforma pratico, distribuivel e de manutencao simples, reescrever em C com SDL3 tende a valer mais a pena. Se o objetivo pessoal e aprender e preservar a preferencia por Assembly, a abordagem mais saudavel e manter a logica do jogo em Assembly e mover plataforma/render/input/audio para uma camada C/SDL3, com wrappers ABI-estaveis.

## 2. Fontes externas consultadas

- SDL3 wiki: SDL e uma biblioteca multiplataforma para audio, teclado, mouse, joystick e graficos; suporta oficialmente Windows, macOS, Linux, iOS e Android. Fonte: https://wiki.libsdl.org/SDL3/FrontPage
- SDL3 `SDL_CreateWindow`: janela SDL usa titulo UTF-8, largura, altura e flags; o tamanho pedido pode diferir do tamanho efetivo; em HiDPI e preciso considerar tamanho em coordenadas de janela versus pixels. Fonte: https://wiki.libsdl.org/SDL3/SDL_CreateWindow
- SDL3 render API: fornece primitivas 2D, retangulos preenchidos, texturas e `SDL_RenderPresent`, e deve ser chamada na thread principal. Fonte: https://wiki.libsdl.org/SDL3/CategoryRender
- SDL3 migration guide: headers mudaram para `<SDL3/...>`, CMake deve linkar `SDL3::SDL3`, funcoes camel-case passaram majoritariamente a retornar `bool`, `SDL_main.h` mudou, audio SDL3 usa principalmente `SDL_AudioStream`, e a propria documentacao desaconselha `RDTSC` em aplicacoes modernas, sugerindo contadores de performance. Fonte: https://wiki.libsdl.org/SDL3/README-migration
- Microsoft x64 calling convention: Windows x64 passa os quatro primeiros argumentos inteiros/pointers em `RCX`, `RDX`, `R8`, `R9`, exige shadow store para quatro parametros de registrador, e define os registradores volateis/nao volateis. Fonte: https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention
- NASM manual: NASM gera formatos `macho64` para Mach-O/macOS e `elf64` para ELF/Linux, alem de outros formatos. Fonte: https://www.nasm.us/doc/nasm09.html

## 3. Inventario tecnico do projeto atual

### 3.1 Arquivos de entrada e build

- `Snake.slnx`: solucao Visual Studio com plataformas `x64` e `x86`, mas o codigo real e x64.
- `Snake/Snake.vcxproj`: projeto MSBuild/Visual Studio com `BuildCustomizations\masm.props` e `masm.targets`; linka como aplicacao Windows; em Release x64 adiciona `XInput.lib` do DirectX SDK June 2010.
- `Snake/Resource.rc`, `resource.h`, `icon.ico`: recursos Windows, incluindo icone via Win32 resource compiler.

Impacto: Linux/macOS nao usam `.vcxproj`, MASM targets nem `.rc` do Windows. Sera necessario criar build novo, idealmente CMake + NASM, ou Makefiles separados.

### 3.2 Plataforma/janelas

Arquivos principais:

- `main.asm`: janela/menu principal, classe Win32, `MainWndProc`, `GetMessageW`, `TranslateMessage`, `DispatchMessageW`, `SetTimer`, `WM_PAINT`, `WM_TIMER`, `WM_KEYDOWN`, `LoadIconW`.
- `game.asm`: janela de gameplay separada, `WndProc`, timers de jogo, `BeginPaint`/`EndPaint`, invalidacao de janela, fechamento/retorno ao menu.
- `window_data.inc`: constantes Win32 (`WM_*`, `WS_*`, `HT*`, offsets de `WNDCLASSEXW`, offsets de argumentos extras de `CreateWindowExW`).
- `basic_data.inc`: `RECT`, `PAINTSTRUCT`, typedefs `HWND`, `HDC`, `HINSTANCE`, timers.

Impacto: esta parte praticamente deve ser reescrita. SDL3 nao usa `WNDCLASSEXW`, `WndProc`, `WM_*`, `HDC`, `BeginPaint`, `SetTimer` Win32 nem `GetMessageW`.

### 3.3 Renderizacao

Arquivos:

- `render.asm`: GDI double-buffering com `GetDC`, `CreateCompatibleDC`, `CreateCompatibleBitmap`, `SelectObject`, `BitBlt`, `CreateSolidBrush`, `FillRect`, `DeleteObject`.
- `hud.asm`: texto com GDI/User32: `SetBkMode`, `SetTextColor`, `DrawTextW`.
- `render_data.inc`: `RENDER_CONTEXT` guarda `WindowDC`, `RenderDC`, `BackBitmap`, `OldBitmap`, `ScreenWidth`, `ScreenHeight`.

Impacto: renderizacao deve ser substituida por `SDL_Renderer`/`SDL_Texture` ou por uma superficie/pixel buffer. A escolha mais simples e `SDL_Renderer`:

- `InitRender` vira criacao de `SDL_Window` + `SDL_Renderer` ou recebe handles ja criados.
- `BeginRender` vira `SDL_SetRenderDrawColor` + `SDL_RenderClear`.
- `DrawRectangle`/`FillRectangle` viram `SDL_RenderFillRect`.
- `EndRender` vira `SDL_RenderPresent`.
- `GetRenderDC` deixa de existir; todos os chamadores devem receber/usar um ponteiro `SDL_Renderer`.

Texto HUD e o ponto mais trabalhoso dentro do render: SDL3 base nao substitui `DrawTextW` com fonte TrueType. Opcoes:

1. Usar `SDL3_ttf`: melhor para manter fontes, textos e layout parecido.
2. Usar `SDL_RenderDebugText`: suficiente para debug, mas nao para visual final bonito.
3. Implementar bitmap font propria: boa para Assembly puro, mas exige criar atlas/fonte e rotina de blit.
4. Evitar texto dinamico via imagens: funciona para poucos digitos/labels, mas e menos flexivel.

### 3.4 Input

Arquivos:

- `input.asm`: teclado via `WM_KEYDOWN` e controle via `XInputGetState`.
- `input_data.inc`: virtual-key codes Win32 (`VK_*`) e flags XInput (`XINPUT_GAMEPAD_*`).
- `game_state_machine.asm`: interpreta `VK_RETURN`, setas, escape, Start/Back/D-pad.

Impacto:

- Teclado deve migrar para eventos SDL3, por exemplo `SDL_EVENT_KEY_DOWN` e keycodes/scancodes SDL.
- Controle deve migrar de XInput para SDL Gamepad/Joystick API. Isso remove dependencia DirectX SDK e funciona em Linux/macOS.
- O modelo atual consulta controle em timer a cada 16 ms; em SDL3, da para processar eventos de controle e/ou consultar estado no loop.
- E recomendavel normalizar input para acoes internas independentes de plataforma: `ACTION_START`, `ACTION_PAUSE`, `ACTION_QUIT`, `ACTION_RIGHT`, `ACTION_LEFT`, `ACTION_UP`, `ACTION_DOWN`.

### 3.5 Audio

Arquivo:

- `audio.asm`: usa `Beep(frequency, duration)` para notas simples e intro.

Impacto:

- `Beep` nao existe como API portavel.
- SDL3 audio mudou bastante e usa `SDL_AudioStream` como caminho principal.
- Para manter notas sintetizadas, seria preciso gerar ondas PCM (ex.: seno ou quadrada) e enviar ao stream de playback.
- Alternativa mais simples: trocar notas por efeitos `.wav` pequenos e tocar via SDL3 audio ou SDL3_mixer.

Complexidade: baixa se usar efeitos prontos; media se sintetizar as notas em tempo real; alta se tentar preservar exatamente o comportamento bloqueante de `Beep`, pois isso congelaria o loop se reproduzido literalmente. O ideal e tornar o audio nao bloqueante.

### 3.6 Logica de jogo reaproveitavel

Mais reaproveitaveis:

- `snake.asm`: movimento, crescimento, vidas, velocidade.
- `snake_controller.asm`: regras de direcao e trava de input.
- `snake_state_machine.asm`: estados da cobra, colisao, pontuacao, audio/eventos.
- `food.asm`: contador e spawn de comida.
- `hud.asm`: `AddScore`, `ConvertIntToString`, labels de score/velocidade, exceto `DrawHUD`.

Parcialmente acoplados:

- `collision.asm`: `WallCollision` chama `GetClientRect(gameHWND, &ClientRect)`. Deve receber largura/altura logicas do tabuleiro ou usar constantes independentes de janela.
- `snake.asm` e `food.asm`: desenham chamando `DrawRectangle`; a logica pode ficar, mas desenho deveria sair para uma camada de render.
- `snake_state_machine.asm`: chama audio diretamente (`PlayNote`, `PlayIntroBGM`). Melhor transformar em eventos de audio ou chamadas para API portavel.

## 4. Arquitetura recomendada para a porta SDL3

### 4.1 Separar dominio e plataforma

Criar fronteiras claras:

- Core gameplay: estado da cobra, comida, score, colisao, regras de velocidade.
- Input normalizado: transforma teclado/gamepad em acoes de jogo.
- Platform layer SDL3: janela, loop, tempo, renderizacao, audio, recursos.
- Build layer: CMake/NASM/Clang/GCC/MSVC conforme plataforma.

O objetivo e que a logica nao conheca `SDL_Window`, `SDL_Renderer`, `HWND`, `HDC`, eventos Win32 nem structs nativas de OS.

### 4.2 Modelo de loop

Hoje:

- `main.asm` cria menu e entra em `GetMessageW`.
- `SetTimer` dispara input/blink/game ticks.
- `WM_PAINT` faz render.
- O jogo abre outra janela e esconde a janela de menu.

Recomendado em SDL3:

- Uma unica janela SDL com estado `MENU` ou `PLAYING`.
- Loop unico:
  - Poll events.
  - Atualiza input.
  - Acumula delta time.
  - Atualiza cobra quando acumulador >= velocidade atual.
  - Atualiza blink do menu quando acumulador >= 500 ms.
  - Renderiza a tela atual.
  - `SDL_RenderPresent`.

Motivo: duas janelas complicam macOS/Linux sem necessidade. O jogo visualmente pode se comportar igual usando apenas modos de tela dentro da mesma janela.

### 4.3 Resolucao e coordenadas

Hoje:

- Menu: 600x600.
- Gameplay: 600x645 ou 606x654 em alguns pontos.
- HUD: 45 px.
- Tile: 20 px.
- Spawn da comida: faixa `2..29` multiplicada por 20, encaixando em grade.

Recomendado:

- Definir dimensoes logicas fixas: `GAME_WIDTH = 600`, `GAME_HEIGHT = 645`, `HUD_HEIGHT = 45`, `BOARD_HEIGHT = 600`, `TILE = 20`.
- Usar render logical presentation/scale do SDL3 para lidar com HiDPI e resize.
- Nao depender do tamanho real da janela para colisao; usar tamanho logico do tabuleiro.
- Se permitir resize, escalar mantendo aspect ratio. Se nao permitir, criar janela nao-resizable.

### 4.4 Render SDL3

Substituicoes conceituais:

- GDI `HDC` -> `SDL_Renderer *`.
- `RECT` Win32 -> `SDL_FRect` ou `SDL_Rect`.
- `CreateSolidBrush` + `FillRect` -> `SDL_SetRenderDrawColor` + `SDL_RenderFillRect`.
- Back buffer GDI + `BitBlt` -> back buffer interno do renderer + `SDL_RenderPresent`.
- `DrawTextW` -> `SDL3_ttf`, bitmap font ou debug text.
- Cores GDI `00RRGGBBh`/BGR-like devem ser revisadas para RGBA SDL.

Atencao: o codigo atual usa constantes de cor no formato que funciona com `CreateSolidBrush`/GDI. SDL usa canais separados, entao sera preciso revisar todas as cores:

- Fundo branco: `00FFFFFFh` -> RGB 255,255,255.
- HUD preto: `00000000h` -> RGB 0,0,0.
- Verde atual: `0077ff00h` pode estar em ordem BGR/GDI, nao necessariamente igual em SDL.

### 4.5 Texto e fontes

Hoje:

- `CreateFontW` usa nomes de fonte do Windows: `Karmatic Arcade`, `Kristen ITC`.
- Strings sao UTF-16 (`dw 'S','c','o','r','e',0`).
- `DrawTextW` centraliza em `RECT`.

SDL3:

- `SDL_CreateWindow` usa titulo UTF-8.
- SDL_ttf usa arquivos `.ttf`, nao nomes instalados no Windows.
- Linux/macOS nao terao `Kristen ITC` nem a fonte arcade necessariamente.

Tarefas necessarias:

- Incluir fontes como assets do projeto ou trocar por fonte livre distribuivel.
- Converter labels para UTF-8 se o render de texto for via SDL_ttf.
- Definir um wrapper `DrawTextCentered(renderer, text_id/string, rect, color, font_id)`.
- Remover dependencia de `CreateFontW`, `SelectObject`, `SetBkMode`, `SetTextColor`, `DrawTextW`.

### 4.6 Input SDL3

Substituicoes:

- `WM_KEYDOWN` -> `SDL_EVENT_KEY_DOWN`.
- `VK_RETURN` -> keycode SDL de Return.
- `VK_ESCAPE` -> keycode SDL de Escape.
- `VK_LEFT/RIGHT/UP/DOWN` -> keycodes ou scancodes SDL.
- `XInputGetState` -> SDL Gamepad API.
- `XINPUT_GAMEPAD_DPAD_*`, `START`, `BACK` -> botoes SDL de gamepad.

Recomendado:

- Criar uma tabela de mapeamento para acoes internas.
- Tratar repeticao de tecla (`repeat`) conforme desejado; o jogo atual bloqueia input duplicado do controle via `PrevButtons`, mas teclado pode repetir via OS.
- Preservar `isInputLocked` para impedir inversoes multiplas entre ticks.
- Detectar controle conectado/desconectado via eventos SDL.

### 4.7 Audio SDL3

Substituicoes:

- `PlayNote(freq, duration)` nao deve bloquear a thread principal.
- Criar sistema `QueueTone(freq, duration_ms)` que gera amostras PCM e empilha em `SDL_AudioStream`.
- Inicializar audio com `SDL_Init(SDL_INIT_AUDIO)` ou junto com video/gamepad.
- Abrir stream de playback padrao.

Opcao com menor risco:

- Gerar tons simples como onda quadrada em buffer S16 mono/stereo.
- Colocar buffers no stream.
- Evitar callbacks inicialmente.

Opcao com melhor qualidade:

- Usar SDL3_mixer e assets de audio.

### 4.8 Tempo e aleatoriedade

Hoje:

- Timers Win32 (`SetTimer`) dirigem input, blink e game loop.
- Seed/spawn usa `rdtsc` em `game.asm`.
- A propria documentacao do SDL3 migration guide recomenda evitar `RDTSC` em aplicacoes modernas e usar contadores de performance.

Recomendado:

- Usar `SDL_GetTicksNS`, `SDL_GetPerformanceCounter` e `SDL_GetPerformanceFrequency`.
- Para random, usar PRNG interno mantido pelo jogo, seedado por contador SDL ou fonte portavel.
- Remover dependencia de `rdtsc`, especialmente porque:
  - Nao existe em AArch64.
  - Pode variar por CPU/virtualizacao/power management.
  - Nao e a abstracao correta para tempo de jogo.

## 5. MASM, NASM e diferencas de ABI

### 5.1 Estado atual: Windows x64 ABI

O codigo atual segue a ABI Windows x64:

- Parametros inteiros/pointers 1..4: `RCX`, `RDX`, `R8`, `R9`.
- Retorno: `RAX`.
- Caller aloca shadow space; no projeto aparece repetidamente `sub rsp, 28h` antes de chamadas.
- Registradores nao volateis no Windows incluem `RBX`, `RBP`, `RDI`, `RSI`, `RSP`, `R12`-`R15`.

Isso aparece em praticamente todos os modulos. Portanto, qualquer chamada direta para SDL3 em Linux/macOS precisara usar a ABI System V AMD64, nao a Windows.

### 5.2 Linux/macOS x86-64: System V AMD64 ABI

Para Linux e macOS Intel, a ABI comum usa:

- Parametros inteiros/pointers 1..6: `RDI`, `RSI`, `RDX`, `RCX`, `R8`, `R9`.
- Retorno: `RAX`.
- Nao ha shadow space Windows.
- Ha red zone de 128 bytes em muitos contextos de userland.
- Registradores callee-saved principais: `RBX`, `RBP`, `R12`-`R15` (diferente de Windows, `RDI`/`RSI` nao sao preservados).

Consequencia: nao basta converter sintaxe MASM para NASM. Toda chamada externa e toda funcao exportada que recebe parametros precisam ser revisadas.

### 5.3 macOS Intel: detalhes adicionais

- Objeto: Mach-O `macho64`.
- Linker: `clang`/`ld64`, linkando contra SDL3 e libc.
- Simbolos C em Mach-O tradicionalmente aparecem com underscore no nome externo (`_main`, `_SDL_Init`, etc.) quando escritos diretamente em assembly, dependendo do fluxo de montagem/link.
- PIE e enderecamento RIP-relative devem ser tratados com cuidado. Em NASM, `default rel` costuma ser desejavel para x86-64 moderno.
- App bundle pode ser necessario para distribuicao polida no macOS, com `Info.plist`, icone e atributos como HiDPI.

### 5.4 Linux x86-64

- Objeto: ELF64.
- Linker: `gcc`/`clang` ou `ld`, preferencialmente via CMake.
- SDL3 via `find_package(SDL3 CONFIG REQUIRED)` ou `pkg-config sdl3`.
- Simbolos C normalmente nao usam underscore prefix.
- Distribuicao pode exigir lidar com SDL dinamico, rpath, AppImage/Flatpak/deb/rpm ou instrucao de dependencia do sistema.

### 5.5 Windows com NASM

Se quiser manter Windows tambem:

- NASM pode gerar `win64`.
- ABI continua Windows x64.
- Chamar SDL3 no Windows ainda usa `RCX`, `RDX`, `R8`, `R9` e shadow space.
- Seria possivel migrar de MASM para NASM sem trocar ABI em Windows, mas isso nao resolve Linux/macOS.

### 5.6 Conversao MASM -> NASM

Areas afetadas:

- `INCLUDELIB` deve sair do assembly e ir para o build/linker.
- `INCLUDE file.inc` vira `%include "file.inc"`.
- `STRUCT ... ENDS` MASM deve virar macros/struc NASM.
- `PROC`/`ENDP`, `PUBLIC`, `EXTERN Foo:PROC`, `TYPEDEF`, `LOCAL`, `SIZEOF`, acesso `[rax].STRUCT.field` e inicializadores como `RECT <>` precisam ser reescritos.
- Diretivas `.data`, `.data?`, `.code` viram `section .data`, `section .bss`, `section .text`.
- Strings `dw "S","c",...` devem ser revisadas, principalmente se migrar para UTF-8.
- Enderecamento global precisa ser RIP-relative para PIE/ASLR, especialmente em macOS.
- Macros de chamada podem ajudar muito:
  - `CALL_WIN64 func, a,b,c,d,...`
  - `CALL_SYSV func, a,b,c,d,...`
  - ou melhor: evitar chamadas SDL diretas em Assembly e chamar wrappers C simples.

Complexidade: alta se converter tudo de uma vez. Menor se primeiro criar wrappers C e manter a maior parte da logica Assembly com uma ABI interna bem definida.

### 5.7 macOS Apple Silicon / ARM64

Este e o maior ponto de decisao.

O codigo atual e x86-64 Assembly. macOS atual roda majoritariamente em Apple Silicon. Para entregar binario nativo universal:

- Parte x86-64: NASM `macho64` ou outro assembler x86-64.
- Parte arm64: reescrever a logica em AArch64 Assembly ou C.
- Build universal: compilar/linkar duas arquiteturas e combinar com `lipo`, ou usar CMake/Xcode com `CMAKE_OSX_ARCHITECTURES="x86_64;arm64"`.

Se nao houver porta AArch64:

- Voce pode produzir binario macOS x86-64 e depender de Rosetta em Macs Apple Silicon, quando disponivel.
- Isso nao e o mesmo que suporte nativo macOS moderno.

Conclusao especifica: Assembly continua viavel para Linux x86-64 e macOS Intel. Para macOS Apple Silicon nativo, Assembly x64 deixa de ser uma preferencia pessoal de sintaxe e vira uma exigencia de escrever uma segunda implementacao em AArch64 ou mover parte substancial para C.

## 6. Plano detalhado de migracao mantendo Assembly

### Fase 0: Congelar comportamento atual

Mesmo sem alterar a implementacao agora, antes de portar seria bom registrar:

- Tamanho das janelas e area util.
- FPS/tick esperado.
- Cores exatas.
- Fontes usadas.
- Regras de input.
- Sequencias de audio.
- Regras de colisao, spawn e crescimento.

Tambem vale criar screenshots/gifs de referencia.

### Fase 1: Criar build multiplataforma paralelo

Tarefas:

- Introduzir CMake na raiz ou em pasta nova.
- Detectar SDL3.
- Definir targets por plataforma:
  - Windows: MSVC/NASM ou MSVC/MASM temporariamente.
  - Linux: Clang/GCC + NASM `elf64`.
  - macOS Intel: Clang + NASM `macho64`.
  - macOS ARM64: C ou AArch64 Assembly.
- Remover dependencia de `.vcxproj` como fonte unica de build.
- Mover libs (`user32.lib`, `gdi32.lib`, `kernel32.lib`, `xinput.lib`) para legado Windows apenas.

### Fase 2: Definir interface de plataforma

Criar funcoes de plataforma chamadas pela logica:

- `Platform_Init`
- `Platform_Shutdown`
- `Platform_PollActions`
- `Platform_GetTicks`
- `Platform_Clear`
- `Platform_DrawRect`
- `Platform_DrawTextCentered`
- `Platform_Present`
- `Platform_PlayTone`

Idealmente implementadas em C usando SDL3, com assinatura simples de inteiros e ponteiros.

### Fase 3: Normalizar game state

Tarefas:

- Remover dependencia de duas janelas.
- `GAME_STATE_MENU` e `GAME_STATE_PLAYING` passam a ser telas dentro do mesmo loop.
- `CallMenu`, `Game`, `MainWndProc`, `WndProc` deixam de ser entry points de OS e viram handlers internos.
- Pausa deixa de matar/recriar timer Win32 e passa a pausar acumulador/update.

### Fase 4: Portar render

Tarefas:

- Substituir `DrawRectangle`/`FillRectangle` por wrapper SDL.
- Separar `DrawSnake` e `DrawFood` da dependencia de `HDC`.
- Reescrever `DrawHUD`.
- Criar assets/fontes portaveis.
- Validar HiDPI: usar tamanho logico e tamanho em pixels corretamente.
- Garantir que o tabuleiro continua alinhado a celulas de 20 px.

### Fase 5: Portar input

Tarefas:

- Criar enum interna de acoes.
- SDL keyboard -> acoes.
- SDL gamepad -> acoes.
- Conectar/desconectar controle.
- Tratar repeat/debounce.
- Preservar `InputType` para HUD (`KEYBOARD`/`XBOX CONTROLLER`, talvez renomear para `GAMEPAD`).

### Fase 6: Portar audio

Tarefas:

- Inicializar SDL audio.
- Implementar gerador de tom.
- Garantir audio nao bloqueante.
- Reproduzir `PlayIntroBGM` por fila de tons.
- Reproduzir efeitos de movimento/comida.

### Fase 7: Portar tempo/random/colisao

Tarefas:

- Remover `rdtsc`.
- Usar contador SDL para seed e delta time.
- `WallCollision` deve usar dimensoes logicas, nao `GetClientRect`.
- Revisar bug/ambiguidade atual: `SetupSnake` seta `SnakeHeadY` para `0`, enquanto os segmentos usam `SNAKE_START_Y`; isso pode afetar colisao/spawn ao portar. Nao e necessario corrigir agora, mas deve ser validado na porta.

### Fase 8: Converter MASM para NASM ou isolar MASM

Opcoes:

1. Converter tudo para NASM.
   - Melhor para Linux/macOS x86-64.
   - Maior esforco inicial.

2. Manter MASM no Windows e criar NASM equivalente para Unix.
   - Evita quebrar Windows agora.
   - Duplica manutencao de Assembly.

3. Mover core para C e usar Assembly so em rotinas pontuais.
   - Melhor custo/beneficio tecnico.
   - Menos alinhado a preferencia pessoal por Assembly.

4. Criar uma DSL/macro layer que gere MASM/NASM.
   - Complexo demais para o tamanho do jogo, provavelmente nao vale.

### Fase 9: Empacotamento

Linux:

- Build dinamico com SDL3 do sistema, ou empacotar SDL.
- Testar X11/Wayland.
- Testar controle via SDL gamepad database.
- Opcional: AppImage/Flatpak.

macOS:

- Gerar `.app`.
- Incluir `Info.plist`.
- Incluir icone `.icns`.
- Lidar com SDL3 `.dylib`/framework.
- Definir assinatura/notarizacao se distribuir fora do ambiente local.
- Decidir Intel-only, ARM64-only ou universal.

## 7. Matriz de esforco

| Area | Assembly + SDL3 x86-64 | Assembly + SDL3 universal macOS | C + SDL3 |
| --- | --- | --- | --- |
| Build | Alto | Muito alto | Baixo/medio |
| ABI | Alto | Muito alto | Baixo |
| Janela/event loop | Medio | Medio | Baixo |
| Render retangulos | Medio | Medio | Baixo |
| Texto/fontes | Medio | Medio | Medio |
| Input teclado | Medio | Medio | Baixo |
| Gamepad | Medio | Medio | Baixo/medio |
| Audio | Medio | Medio | Medio |
| Linux | Viavel | N/A | Muito viavel |
| macOS Intel | Viavel | Parte do universal | Muito viavel |
| macOS Apple Silicon | Nao nativo | Alto: requer AArch64/C | Muito viavel |
| Manutencao futura | Alta carga | Muito alta carga | Baixa/medio |

Estimativa qualitativa:

- Porta Assembly x86-64 para Linux + macOS Intel: 3 a 6 semanas em ritmo focado, dependendo do quanto de NASM/wrappers C for usado.
- Porta Assembly universal incluindo Apple Silicon nativo: 6 a 12+ semanas, porque ha uma segunda arquitetura Assembly ou uma migracao parcial para C.
- Reescrita C + SDL3 preservando comportamento: 1 a 3 semanas para uma versao fiel, dependendo do polimento de texto/audio/empacotamento.

## 8. Vale mais a pena C ou Assembly?

### C + SDL3

Vantagens:

- SDL3 e C nativamente.
- ABI, linkagem, headers, structs e chamadas externas ficam naturais.
- Linux/macOS/Windows ficam muito mais simples.
- Apple Silicon vira apenas uma arquitetura de compilacao, nao uma reescrita.
- Debug e sanitizers ficam melhores.
- Menos risco de bugs de stack alignment, shadow space, red zone e registradores nao preservados.

Desvantagens:

- Perde parte do objetivo pessoal do projeto.
- Menos exercicio de baixo nivel.
- Pode parecer uma reescrita mais convencional.

### Assembly + SDL3

Vantagens:

- Preserva o espirito do projeto.
- Continua sendo excelente exercicio de ABI, linker, formato de objeto, plataforma e arquitetura.
- Para x86-64, e tecnicamente viavel.
- O core atual de gameplay pode ser reaproveitado em boa medida se for bem isolado.

Desvantagens:

- SDL3 tem API C grande; chamar diretamente de Assembly e trabalhoso.
- NASM conversion nao e trivial.
- Linux/macOS usam ABI diferente de Windows.
- macOS ARM64 exige AArch64 Assembly ou camada C.
- Texto, audio e empacotamento ficam mais custosos.
- Manutencao por plataforma aumenta bastante.

Conclusao: se a meta principal e ter Snake multiplataforma robusto, C + SDL3 vale mais a pena. Se a meta principal e aprendizado e satisfacao pessoal com Assembly, Assembly ainda e viavel, mas eu recomendo uma arquitetura hibrida: SDL3/plataforma em C, logica do jogo em Assembly, e talvez render basico em Assembly chamando wrappers C pequenos. Isso preserva o sabor baixo nivel sem transformar cada API SDL em uma luta de ABI.

## 9. Caminho recomendado

Recomendacao pratica:

1. Nao tentar portar a implementacao Win32 diretamente.
2. Criar uma nova camada SDL3 em C.
3. Transformar input em acoes internas.
4. Transformar render em comandos simples: limpar, retangulo, texto, apresentar.
5. Manter o core Assembly inicialmente, mas converter MASM -> NASM apenas depois que as fronteiras estiverem claras.
6. Para macOS Apple Silicon, decidir cedo:
   - aceitar Intel/Rosetta no primeiro momento;
   - ou mover core para C;
   - ou escrever versao AArch64 Assembly.

Recomendacao por objetivo:

- Objetivo "quero multiplataforma com menor dor": reescrever em C + SDL3.
- Objetivo "quero preservar Assembly e aprender": camada SDL3 em C + core em NASM x86-64, Linux/macOS Intel primeiro.
- Objetivo "quero macOS moderno nativo e Assembly": projeto maior, com AArch64 Assembly ou arquitetura dual-core por CPU.

## 10. Checklist completo de trabalho futuro

- Criar build CMake.
- Adicionar SDL3 como dependencia.
- Definir estrategia de assets.
- Remover dependencia obrigatoria de Visual Studio/MSBuild.
- Remover dependencia de `Resource.rc`.
- Migrar icone para formatos por plataforma.
- Criar janela SDL.
- Criar renderer SDL.
- Criar loop unico SDL.
- Implementar delta time/acumuladores.
- Substituir `SetTimer`.
- Substituir `GetMessageW`/`DispatchMessageW`.
- Substituir `WndProc`.
- Substituir `WM_KEYDOWN`.
- Substituir `XInputGetState`.
- Substituir `Beep`.
- Substituir GDI DC/bitmap/brush.
- Substituir `DrawTextW`.
- Substituir fontes Windows por assets.
- Trocar UTF-16 interno por UTF-8 ou criar conversao.
- Normalizar input para acoes.
- Normalizar coordenadas logicas.
- Remover `GetClientRect` da colisao.
- Remover `rdtsc`.
- Revisar stack alignment em todas as chamadas.
- Revisar registradores preservados em todas as funcoes.
- Converter MASM structs/macros para NASM.
- Criar wrappers ABI para Windows x64 e System V AMD64, se necessario.
- Definir suporte ou nao a macOS ARM64 nativo.
- Criar pipeline Linux.
- Criar pipeline macOS.
- Testar teclado em layouts diferentes.
- Testar gamepads SDL em Linux/macOS.
- Testar HiDPI no macOS.
- Testar Wayland/X11 no Linux.
- Testar audio sem bloquear o loop.
- Validar comportamento contra screenshots/referencia atual.

