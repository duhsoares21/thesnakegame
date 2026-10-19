# Relatorio de portabilidade: Linux x64 com NASM

Data da analise: 2026-08-08  
Escopo: criar uma versao separada para Linux x86-64 usando NASM. A versao Windows atual em MASM/Win32 permanece exatamente como esta.

## 1. Resumo executivo

Portar este Snake para Linux x64 com NASM e tecnicamente mais direto que macOS, porque o alvo continua x86-64 nativo e o ecossistema aceita bem binarios ELF com Assembly. A dificuldade principal nao e CPU, e sim escolher a pilha grafica/input/audio.

- Com SDL3: esforco medio. E o caminho mais curto para janela, teclado, gamepad, render 2D e audio.
- Sem SDL, usando APIs Linux nativas/baixo nivel: esforco alto. O maior problema e que "Linux desktop nativo" hoje significa lidar com X11 e Wayland, ou escolher apenas um. Audio tambem pode ser ALSA, PulseAudio, PipeWire ou JACK. Para jogo pequeno, escrever tudo direto em Xlib/Wayland/ALSA aumenta muito a superficie de erro.

Conclusao: uma versao Linux separada em NASM e viavel e ate agradavel se SDL3 ficar responsavel por plataforma. Sem SDL, eu recomendaria mirar primeiro X11 + XRender/Xft ou Xlib puro + ALSA, sabendo que isso nao cobre Wayland nativo; para cobrir Wayland corretamente, o esforco sobe bastante.

## 2. Fontes externas consultadas

- Xlib: Xlib e uma interface C de baixo nivel para o protocolo X Window System; apps clientes falam com o servidor X por uma conexao. Fonte: https://xorg.freedesktop.org/releases/current/doc/libX11/libX11/libX11.html
- Wayland: Wayland e um protocolo e uma implementacao de biblioteca C para clientes falarem com um compositor. Fonte: https://wayland.freedesktop.org/docs/html/
- ALSA PCM: a API PCM usa estados para definir a fase de comunicacao entre app e biblioteca; playback passa por estados como open/setup/prepared/running/xrun. Fonte: https://www.alsa-project.org/alsa-doc/alsa-lib/pcm.html
- PipeWire: PipeWire e um framework multimidia de baixo nivel com processamento em grafo, negociacao de formatos/buffers e baixa latencia. Fonte: https://docs.pipewire.org/
- SDL3: SDL suporta oficialmente Linux e fornece acesso a audio, teclado, mouse, joystick e graficos. Fonte: https://wiki.libsdl.org/SDL3/FrontPage
- NASM: NASM suporta formato `elf64` para Linux/Unix System V. Fonte: https://www.nasm.us/doc/nasm09.html

## 3. Premissas do port Linux

- Windows continua como esta, com MASM e Win32.
- Linux tera target proprio em NASM.
- Arquitetura alvo: x86-64, ABI System V AMD64.
- Nao ha obrigacao de compartilhar codigo de plataforma com macOS.
- Build recomendado: NASM + `clang`/`gcc` como driver de link, via Makefile ou CMake.

## 4. Impacto tecnico imediato

### 4.1 ABI Linux x86-64

O codigo atual usa Windows x64:

- Argumentos: `RCX`, `RDX`, `R8`, `R9`.
- Shadow space.
- Preservacao Windows de registradores.

Linux usa System V AMD64:

- Argumentos inteiros/pointers: `RDI`, `RSI`, `RDX`, `RCX`, `R8`, `R9`.
- Sem shadow space.
- Red zone de 128 bytes pode existir em userland, mas e melhor nao depender dela no inicio.
- Callee-saved: `RBX`, `RBP`, `R12`-`R15`.
- Simbolos C sem underscore prefix.

Resultado: as chamadas externas e interfaces entre modulos precisam ser reescritas. Funcoes internas tambem devem padronizar uma ABI propria para evitar confusao.

### 4.2 MASM -> NASM

Mesmas conversoes gerais:

- `INCLUDE` -> `%include`.
- `INCLUDELIB` removido.
- `.code/.data/.data?` -> `section`.
- `PROC/ENDP/PUBLIC/EXTERN` -> labels, `global`, `extern`.
- `STRUCT`, `LOCAL`, `SIZEOF`, acesso a campos e inicializadores MASM precisam virar NASM.
- Dados globais devem usar RIP-relative com `default rel` quando apropriado.
- Constantes Win32 devem sair da versao Linux.

Linux e menos exigente que macOS em simbolos Mach-O/underscore, mas ainda exige disciplina com PIC/PIE se quiser build moderno.

## 5. Port Linux com SDL3

### 5.1 Arquitetura recomendada

Criar uma versao separada:

- `src_linux_nasm/` para core em NASM.
- `platform_linux_sdl.c` para SDL3.
- `CMakeLists.txt` ou Makefile Linux.
- Assets portaveis: fonte `.ttf`, sons ou gerador de tons.

Interface entre NASM e C:

- `platform_init`
- `platform_shutdown`
- `platform_poll_action`
- `platform_get_ticks_ns`
- `platform_draw_rect`
- `platform_draw_text_centered`
- `platform_play_tone`
- `platform_present`

Evitar chamadas diretas SDL em todo o Assembly reduz muito o trabalho de ABI.

### 5.2 Substituicoes por area

Janela/event loop:

- Win32 message loop sai.
- SDL event loop entra.
- Menu e gameplay podem ser estados numa janela unica.

Render:

- GDI sai.
- SDL renderer entra.
- Texto via SDL_ttf ou bitmap font.

Input:

- `WM_KEYDOWN` e XInput saem.
- SDL keyboard e SDL gamepad entram.
- Evita lidar manualmente com evdev, libinput, udev e gamepad mappings.

Audio:

- `Beep` sai.
- SDL audio stream ou SDL_mixer entra.

Tempo/random:

- `SetTimer` e `rdtsc` saem.
- SDL ticks/performance counter entram.

### 5.3 Dificuldade

Esforco: medio.

O que consome tempo:

- Conversao MASM -> NASM.
- Ajuste de ABI.
- Separar plataforma da logica.
- Texto e assets.

O que SDL simplifica muito:

- X11 vs Wayland.
- Gamepad.
- Audio backend.
- HiDPI/escalas.
- Packaging com dependencia unica conhecida.

Estimativa qualitativa:

- Prototipo jogavel: 1 a 2 semanas.
- Paridade visual/audio: 2 a 4 semanas.
- Pacote distribuivel simples: +2 a 5 dias.

## 6. Port Linux sem SDL, usando APIs nativas/baixo nivel

### 6.1 Escolha 1: X11/Xlib apenas

Esse e o caminho nativo Linux mais simples.

Componentes:

- Janela/eventos: Xlib (`XOpenDisplay`, janela, event mask, loop de eventos).
- Render 2D:
  - Xlib primitives: preencher retangulos com GC.
  - XShm para framebuffer mais eficiente, se necessario.
  - Cairo opcional para desenho 2D mais confortavel.
- Texto:
  - Xft/fontconfig/freetype para texto decente.
  - Xlib core fonts sao antigos e limitados.
- Teclado:
  - XKeyEvent + XKB para mapeamento moderno.
- Gamepad:
  - evdev direto, joystick API antiga `/dev/input/js*`, ou libevdev.
- Audio:
  - ALSA PCM direto ou PulseAudio/PipeWire.

Vantagens:

- Mais simples que Wayland.
- Funciona sob X11 e tambem sob XWayland em muitas sessoes Wayland.
- APIs C chamaveis de NASM via wrappers C.

Desvantagens:

- Nao e Wayland nativo.
- Xlib e baixo nivel e cheia de detalhes.
- Texto/gamepad/audio ainda sao trabalhosos.

Esforco: medio/alto.

### 6.2 Escolha 2: Wayland nativo

Componentes:

- `wayland-client`.
- `xdg-shell` para janela desktop moderna.
- Buffers via `wl_shm` para software rendering ou EGL/Vulkan para GPU.
- Input via `wl_keyboard`, `wl_pointer`, `wl_seat`.
- Frame callbacks para ritmo de render.

Vantagens:

- Nativo em desktops Linux modernos.
- Modelo mais atual.

Desvantagens:

- Mais boilerplate que Xlib para uma janela simples.
- Protocolos complementares precisam ser gerados/incluidos.
- Desenho de software exige buffers compartilhados e lifecycle correto.
- Gamepad nao vem de Wayland; ainda precisa evdev/libinput/SDL-like layer.
- Texto/audio continuam externos.

Esforco: alto/muito alto.

### 6.3 Escolha 3: DRM/KMS framebuffer direto

Possivel, mas nao recomendado para este objetivo.

Componentes:

- DRM/KMS para modos de video.
- evdev/libinput para teclado/controle.
- ALSA/PipeWire para audio.
- Permissoes/logind/seat management.

Vantagens:

- Muito baixo nivel.
- Sem servidor grafico.

Desvantagens:

- Nao e app desktop normal.
- Problemas de permissao e integracao.
- Excesso de complexidade para Snake.

Esforco: muito alto.

### 6.4 Audio Linux sem SDL

Opcoes:

- ALSA direto:
  - Mais baixo nivel.
  - Disponivel como base do stack Linux.
  - Requer configurar PCM params, buffers, recuperacao de underrun.
- PulseAudio:
  - Ainda comum em desktops, mas cada vez mais mediado/substituido por PipeWire.
- PipeWire:
  - Moderno, poderoso e baixa latencia.
  - API mais complexa para um jogo simples.
- libao/miniaudio:
  - Nao sao "nativas puras" do sistema, mas reduzem dor.

Para um port sem SDL e sem outra biblioteca maior, ALSA e o caminho mais direto, mas nao o mais amigavel para usuario desktop moderno. PipeWire e moderno, mas provavelmente exagerado.

### 6.5 Gamepad Linux sem SDL

Opcoes:

- `/dev/input/js*`: simples, mas antigo e limitado.
- evdev/libevdev: mais moderno, exige lidar com devices, permissoes, hotplug/udev.
- hidraw: baixo demais.

Aqui SDL entrega muito valor, porque gamepad mapping e hotplug multiplos sao surpreendentemente chatos.

## 7. Arquivos do projeto atual afetados conceitualmente

Reaproveitaveis com conversao NASM/ABI:

- `snake.asm`
- `snake_controller.asm`
- `food.asm`
- `snake_state_machine.asm`
- partes logicas de `hud.asm`

Reescrita quase total:

- `main.asm`
- `game.asm`
- `render.asm`
- `input.asm`
- `audio.asm`
- `window_data.inc`
- partes Win32 de `basic_data.inc`
- partes VK/XInput de `input_data.inc`
- `render_data.inc`

Parcial:

- `collision.asm`: remover `GetClientRect`; usar dimensoes logicas.

## 8. Build Linux separado

Com SDL:

- NASM: `nasm -f elf64`.
- Link: `clang`/`gcc`.
- Dependencias: SDL3, opcional SDL3_ttf.
- Build: CMake ou Makefile com `pkg-config sdl3`.

Sem SDL com X11:

- NASM: `nasm -f elf64`.
- Link: `clang`/`gcc`.
- Dependencias provaveis:
  - `libX11`
  - `libXft`/`fontconfig`/`freetype` para texto decente
  - `alsa-lib`
  - `libevdev`/`udev` se quiser gamepad moderno
  - opcional `cairo`

Sem SDL com Wayland:

- Dependencias provaveis:
  - `wayland-client`
  - protocolos `xdg-shell`
  - possivelmente `wayland-scanner` no build
  - `alsa-lib` ou PipeWire
  - `libevdev`/`udev`
  - cairo/pixman ou EGL/Vulkan para render

## 9. Comparacao Linux com e sem SDL

| Criterio | Linux + NASM + SDL3 | Linux + NASM + X11/ALSA/etc. | Linux + NASM + Wayland/PipeWire/etc. |
| --- | --- | --- | --- |
| Janela/eventos | Baixo | Medio | Alto |
| Render retangulos | Baixo | Baixo/medio | Medio/alto |
| Texto | Medio | Medio/alto | Medio/alto |
| Teclado | Baixo | Medio | Medio |
| Gamepad | Baixo/medio | Alto | Alto |
| Audio | Medio | Medio/alto | Alto |
| Build | Medio | Medio/alto | Alto |
| Compatibilidade desktop | Alta | Boa via X11/XWayland | Boa, mas mais trabalhosa |
| Esforco total | Medio | Alto | Muito alto |

## 10. Estimativas

Linux + NASM + SDL3:

- Prototipo jogavel: 1 a 2 semanas.
- Paridade visual/audio: 2 a 4 semanas.
- Distribuicao simples: +2 a 5 dias.

Linux + NASM + X11 + ALSA:

- Prototipo jogavel com teclado e retangulos: 2 a 3 semanas.
- Texto decente, audio e controle: 4 a 7 semanas.
- Robustez em distros diferentes: +1 a 2 semanas.

Linux + NASM + Wayland + audio/gamepad nativos:

- Prototipo: 3 a 5 semanas.
- Paridade e robustez: 7 a 10+ semanas.

## 11. Recomendacao final para Linux

Se a meta e uma versao Linux separada, sem mexer no Windows:

1. Use NASM x86-64 para a logica.
2. Use SDL3 para janela/render/input/audio, pelo menos na primeira versao.
3. Use wrappers C pequenos para simplificar chamadas e manter o Assembly focado no jogo.
4. Se quiser uma versao "nativa Linux sem SDL" por aprendizado, comece por X11 + Xlib + ALSA, nao Wayland. Depois avalie Wayland como segunda etapa.

Sem SDL, a escolha mais realista e X11 porque o jogo e 2D simples e muitos ambientes Wayland ainda rodam apps X11 via XWayland. Wayland nativo e tecnicamente mais moderno, mas aumenta demais o custo para pouca vantagem nesse jogo especifico.

