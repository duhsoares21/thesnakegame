# Relatorio de portabilidade: macOS x64/Rosetta com NASM

Data da analise: 2026-08-08  
Escopo: criar uma versao separada para macOS usando NASM x86-64. A versao Windows atual em MASM/Win32 permanece exatamente como esta. Em Macs Apple Silicon, o alvo considerado e binario x86-64 rodando via Rosetta, nao ARM64 nativo.

## 1. Resumo executivo

Portar este Snake para macOS x64 com NASM e viavel, mas a dificuldade muda muito dependendo da escolha de API:

- Com SDL3: esforco medio. A maior dor fica em converter MASM para NASM/System V ABI e adaptar render/input/audio para wrappers SDL. A parte macOS especifica fica pequena.
- Sem SDL, usando APIs nativas Apple: esforco alto a muito alto. Voce precisaria lidar com AppKit/Cocoa para janela/eventos, Core Graphics ou Metal para render, Core Text/Quartz para texto, GameController/IOKit para controle, Core Audio/Audio Queue para audio e empacotamento `.app`. Chamar frameworks Objective-C diretamente de Assembly e possivel em tese, mas pouco ergonomico e fragil; o caminho realista seria usar stubs C/Objective-C finos.

Conclusao: para uma versao macOS separada em NASM, eu recomendaria NASM para a logica do jogo e uma camada C/Objective-C minima. Se quiser minimizar esforco, use SDL3. Se quiser "nativo Apple", use AppKit + Core Graphics/Metal via Objective-C wrappers, mas aceite que a maior parte da plataforma nao sera Assembly puro.

## 2. Fontes externas consultadas

- Apple Rosetta: Rosetta permite rodar apps com instrucoes x86_64 em Apple Silicon. Fonte: https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment
- Apple Support Rosetta: a Apple informa que Rosetta permite Macs Apple Silicon rodarem apps Intel, mas tambem alerta que suporte a Rosetta terminara em uma versao futura do macOS. Fonte: https://support.apple.com/en-us/102527
- Apple Metal: Metal fornece acesso direto a GPU nos dispositivos Apple. Fonte: https://developer.apple.com/documentation/metal
- Apple Audio Queue Services: Audio Queue Services e uma interface C do Audio Toolbox/Core Audio para playback e gravacao. Fonte: https://developer.apple.com/documentation/audiotoolbox/audio-queue-services
- SDL3: SDL suporta oficialmente macOS e fornece acesso a audio, teclado, mouse, joystick e graficos. Fonte: https://wiki.libsdl.org/SDL3/FrontPage
- NASM: NASM suporta formato `macho64` para Mach-O/macOS. Fonte: https://www.nasm.us/doc/nasm09.html

## 3. Premissas do port macOS

- Windows continua intocado em MASM, GDI, Win32, XInput e `Beep`.
- macOS tera uma arvore/target proprio, em NASM.
- O codigo Assembly macOS sera x86-64.
- Apple Silicon sera suportado por Rosetta, nao por binario ARM64 nativo.
- Nao ha meta de compartilhar a mesma camada de plataforma entre Linux/macOS, embora a logica possa ser copiada/adaptada.
- Build recomendado: `clang` como linker/driver e NASM gerando objetos `macho64`.

## 4. Impacto tecnico imediato

### 4.1 ABI

O projeto atual usa Windows x64:

- Argumentos: `RCX`, `RDX`, `R8`, `R9`.
- Shadow space de 32 bytes, normalmente aparecendo como `sub rsp, 28h`.
- `RDI` e `RSI` sao callee-saved no Windows.

macOS x86-64 usa System V AMD64:

- Argumentos inteiros/pointers: `RDI`, `RSI`, `RDX`, `RCX`, `R8`, `R9`.
- Nao ha shadow space Windows.
- Stack deve estar alinhado corretamente para chamadas C.
- `RDI` e `RSI` sao caller-saved; `RBX`, `RBP`, `R12`-`R15` sao callee-saved.
- Simbolos C em Mach-O normalmente exigem underscore externo, por exemplo `_main`.

Resultado: toda funcao que recebe parametros e toda chamada externa precisa ser revisada. A porta nao e so trocar `PROC` por labels NASM.

### 4.2 Sintaxe MASM -> NASM

Conversoes necessarias:

- `INCLUDE` -> `%include`.
- `INCLUDELIB` sai do Assembly e vai para o link.
- `.code`, `.data`, `.data?` -> `section .text`, `section .data`, `section .bss`.
- `PROC`/`ENDP`, `PUBLIC`, `EXTERN Foo:PROC` -> `global`, `extern`, labels.
- `STRUCT`/`ENDS`, `LOCAL`, `SIZEOF`, inicializadores `<>` e acesso `[rax].STRUCT.field` precisam virar macros/`struc` NASM ou offsets manuais.
- Strings UTF-16 usadas pelo Win32 devem virar UTF-8 se a camada macOS/SDL trabalhar com strings C.
- Enderecamento global deve usar RIP-relative, idealmente `default rel`.

### 4.3 Rosetta

Rosetta facilita a primeira entrega em Apple Silicon porque permite rodar x86-64. Mas ha implicacoes:

- Nao e suporte nativo ARM64.
- Futuro de longo prazo e menos seguro, ja que a propria Apple alerta que Rosetta terminara em uma versao futura.
- Performance deste Snake nao deve ser problema; o jogo e leve.
- Empacotamento pode ser Intel-only `.app`; usuarios Apple Silicon precisam de Rosetta instalado/disponivel.

## 5. Port macOS com SDL3

### 5.1 Arquitetura recomendada

Criar uma versao macOS separada com:

- `src_macos_nasm/` para core Assembly em NASM.
- `platform_macos_sdl.c` para janela/eventos/render/audio SDL3.
- `CMakeLists.txt` ou Makefile macOS.
- Assets proprios: fonte `.ttf`, icone `.icns` opcional, sons ou gerador de tons.

O Assembly chamaria funcoes C simples:

- `platform_draw_rect(x, y, w, h, rgba)`
- `platform_draw_text_centered(text_id, x, y, w, h, rgba)`
- `platform_play_tone(freq, duration_ms)`
- `platform_get_ticks_ns()`
- `platform_poll_action()`

Isso evita chamar dezenas de funcoes SDL direto de NASM.

### 5.2 Substituicoes por area

Janela/eventos:

- `CreateWindowExW`, `RegisterClassExW`, `WndProc`, `GetMessageW` saem.
- SDL cria uma janela unica e processa `SDL_Event`.
- Menu e jogo viram estados dentro da mesma janela.

Render:

- GDI/DC/BitBlt saem.
- SDL renderer desenha retangulos e apresenta frame.
- `DrawTextW` deve virar SDL_ttf ou bitmap font.

Input:

- `WM_KEYDOWN` e XInput saem.
- SDL keyboard/gamepad gera acoes internas.
- `InputType` pode continuar existindo, mas o texto provavelmente deveria virar `KEYBOARD`/`GAMEPAD`.

Audio:

- `Beep` sai.
- SDL3 audio stream toca tons sintetizados ou pequenos WAVs.

Tempo/random:

- `SetTimer` e `rdtsc` saem.
- SDL ticks/performance counter entram.

### 5.3 Dificuldade

Esforco: medio.

O que consome tempo:

- Converter MASM para NASM e System V ABI.
- Separar codigo de render/input/audio da logica.
- Texto com fonte portavel.
- Build macOS e `.app`.

O que fica simples por causa do SDL:

- Janela.
- Teclado.
- Gamepad.
- Audio portavel.
- HiDPI, fullscreen/resizable se desejado.

Estimativa qualitativa:

- Primeiro prototipo jogavel: 1 a 2 semanas.
- Paridade visual/audio com a versao Windows: 2 a 4 semanas.
- App bundle polido: +2 a 5 dias.

## 6. Port macOS sem SDL, usando APIs nativas

### 6.1 Caminho nativo realista

Para macOS nativo sem SDL, a arquitetura mais realista e:

- NASM para core do jogo.
- Objective-C/C para AppKit e ponte com frameworks Apple.
- AppKit para `NSApplication`, `NSWindow`, event loop e teclado.
- Core Graphics/Quartz 2D para render 2D simples, ou Metal se quiser render moderno.
- Core Text para texto.
- Audio Queue Services/Core Audio para tons/efeitos.
- GameController framework para controle moderno, ou IOKit HID para caminho mais baixo nivel.

Chamar Objective-C diretamente de NASM via `objc_msgSend` e possivel, mas exigiria:

- Conhecer runtime Objective-C.
- Gerenciar selectors/classes.
- Respeitar ABI de chamadas Objective-C.
- Lidar com ARC/manual retain/release se houver objetos.
- Montar strings/classes/selectors corretamente.

Isso e uma quantidade de risco que nao combina com o tamanho do jogo. Wrappers Objective-C pequenos sao muito mais sensatos.

### 6.2 Render nativo: Core Graphics vs Metal

Core Graphics:

- Mais simples para retangulos 2D e texto.
- Bom encaixe para jogo Snake simples.
- Performance suficiente.
- Render no contexto de view/AppKit.

Metal:

- Mais moderno e alinhado ao macOS atual.
- Excessivo para retangulos 2D, mas viavel.
- Exige device, command queue, pipeline, buffers, shaders ou uma camada MetalKit.
- Chamar de Assembly diretamente e impratico; wrappers C++/Objective-C seriam quase obrigatorios.

Recomendacao sem SDL: Core Graphics + Core Text, nao Metal, a menos que o objetivo seja especificamente aprender Metal.

### 6.3 Audio nativo

Opcoes:

- Audio Queue Services: API C, boa para buffers PCM e tons sintetizados.
- AVFoundation: mais alto nivel, Objective-C, melhor para assets.
- Core Audio Audio Units: poderoso, mas excessivo.

Para preservar `PlayNote(freq, duration)`, Audio Queue com geracao PCM e o caminho mais direto.

### 6.4 Gamepad nativo

Opcoes:

- GameController framework: ideal para controles modernos.
- IOKit HID: mais baixo nivel e muito mais trabalhoso.

Recomendacao: GameController via Objective-C wrapper.

### 6.5 Dificuldade

Esforco: alto a muito alto.

Principais dificuldades:

- Criar app macOS correto sem SDL.
- Misturar NASM com Objective-C runtime/frameworks.
- Texto/fonte/layout.
- Gamepad nativo.
- Audio nativo nao bloqueante.
- App bundle, Info.plist, icone, assinatura opcional.

Estimativa qualitativa:

- Prototipo com janela + retangulos + teclado: 2 a 3 semanas.
- Paridade com jogo atual incluindo texto, audio e gamepad: 5 a 8 semanas.
- Versao polida distribuivel: +1 a 2 semanas.

## 7. Arquivos do projeto atual afetados conceitualmente

Reaproveitaveis com adaptacao NASM/ABI:

- `snake.asm`
- `snake_controller.asm`
- `food.asm`
- `snake_state_machine.asm`
- parte logica de `hud.asm`

Reescrita quase total:

- `main.asm`
- `game.asm`
- `render.asm`
- parte de desenho de `hud.asm`
- `input.asm`
- `audio.asm`
- `window_data.inc`
- `basic_data.inc` na parte Win32
- `input_data.inc` na parte VK/XInput
- `render_data.inc` se usar SDL/Core Graphics

Parcial:

- `collision.asm`: trocar `GetClientRect` por dimensoes logicas fixas.

## 8. Build macOS separado

Com SDL:

- NASM: `nasm -f macho64`.
- Link: `clang`.
- Dependencias: SDL3, opcional SDL3_ttf.
- Bundle: `.app` com binario x86-64, assets e `Info.plist`.

Sem SDL:

- NASM: `nasm -f macho64`.
- Objective-C: `clang -ObjC`.
- Frameworks provaveis:
  - `AppKit`
  - `CoreGraphics`
  - `CoreText`
  - `AudioToolbox`
  - `GameController`
  - opcional `Metal`, `MetalKit`, `QuartzCore`
- Bundle `.app` praticamente obrigatorio para experiencia normal.

## 9. Comparacao macOS com e sem SDL

| Criterio | macOS + NASM + SDL3 | macOS + NASM + APIs nativas |
| --- | --- | --- |
| Janela/eventos | Baixo/medio | Alto |
| Render retangulos | Baixo | Medio com Core Graphics, alto com Metal |
| Texto | Medio | Medio/alto |
| Teclado | Baixo | Medio |
| Gamepad | Baixo/medio | Alto |
| Audio | Medio | Medio/alto |
| Build | Medio | Alto |
| App bundle | Medio | Medio/alto |
| Assembly direto | Viavel com wrappers pequenos | Pouco pratico sem wrappers Objective-C |
| Esforco total | Medio | Alto/muito alto |

## 10. Recomendacao final para macOS

Se o objetivo e ter uma versao macOS separada e jogavel mantendo a alma Assembly:

1. Use NASM x86-64 para a logica.
2. Use SDL3 para plataforma.
3. Use wrappers C finos para reduzir atrito de ABI.
4. Gere app Intel x86-64 e documente que em Apple Silicon roda via Rosetta.

Se o objetivo e aprender macOS nativo:

1. Use NASM para core.
2. Use Objective-C wrappers para AppKit/Core Graphics/Core Text/Audio Queue/GameController.
3. Evite Metal inicialmente.
4. Aceite que essa versao sera significativamente mais trabalhosa que a versao SDL.

