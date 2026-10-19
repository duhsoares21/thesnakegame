# Comparativo MASM vs NASM - colisao inferior e spawn da comida

Data da analise: 2026-08-09

Projetos comparados:

- MASM: `C:\Users\edusc\source\repos\Snake\Snake`
- NASM: `C:\Users\edusc\CLionProjects\SnakeGame`

Escopo: leitura comparativa dos arquivos de colisao, comida, renderizacao, dados da janela e fluxo principal. Nenhuma correcao foi aplicada nos fontes.

## Resumo

A diferenca mais clara e diretamente ligada ao problema da comida esta em `food.asm`: a versao NASM zera `rdx` antes da segunda divisao usada para calcular `SpawnPointY`. Como `rax` ja foi substituido pelo primeiro resto, esse `xor rdx, rdx` faz o segundo resto ficar igual ao primeiro. Na pratica, a comida tende a nascer com `X == Y`, isto e, presa a uma diagonal do tabuleiro.

O problema de colisao na parte de baixo parece vir de uma combinacao de dois modelos de coordenadas que precisam permanecer perfeitamente sincronizados:

- a cobra e a comida usam coordenadas logicas sem HUD;
- o desenho soma `HUD_AREA` no eixo Y;
- a colisao usa `GetClientRect` e subtrai `HUD_AREA` e `SNAKE_MOVEMENT_CELL`;
- a janela e criada com tamanho externo fixo, sem `AdjustWindowRect`, enquanto o renderer usa dimensoes internas fixas.

No NASM, isso fica mais sensivel porque o projeto CMake realmente compila `game.asm` junto com o restante e usa o linker com configuracao diferente da do projeto Visual Studio/MASM. Se o `ClientRect.bottom` real nao bater exatamente com o `ScreenHeight` esperado pelo jogo, a margem inferior passa a ser calculada em uma altura diferente da area desenhada.

## Achado 1 - bug direto no Y da comida na versao NASM

Arquivo NASM: `C:\Users\edusc\CLionProjects\SnakeGame\food.asm`

Trecho relevante:

- linha 105: `xor rdx, rdx`
- linha 107: `mov rcx, MAX_RANDOM_VALUE`
- linha 110: `mov r12, rax`
- linha 113: `xor rdx, rdx`
- linha 115: `mov rcx, MAX_RANDOM_VALUE`
- linha 118: `mov r13, rax`
- linhas 127-128: `imul r12, SNAKE_MOVEMENT_CELL` / `imul r13, SNAKE_MOVEMENT_CELL`
- linhas 164-165: salva `SpawnPointX` e `SpawnPointY`

Comparacao MASM:

- `C:\Users\edusc\source\repos\Snake\Snake\food.asm`, linha 109: zera `rdx` antes da primeira divisao.
- Depois da primeira divisao, a MASM faz `mov rax, rdx`, salva em `r12`, e executa a segunda divisao sem outro `xor rdx, rdx`.

Efeito pratico no NASM:

1. A primeira divisao calcula `r12 = seed % 29`.
2. O codigo faz `rax = r12`.
3. O NASM zera `rdx` novamente.
4. A segunda divisao calcula `r13 = r12 % 29`.
5. Como `r12` ja esta entre 0 e 28, `r13` fica igual a `r12`.

Resultado: `SpawnPointY` vira o mesmo indice de `SpawnPointX`, e depois ambos sao multiplicados por `SNAKE_MOVEMENT_CELL`. Isso explica spawn repetitivo/diagonal e a sensacao de geracao errada da comida.

Observacao: o MASM tambem nao e um gerador ideal, porque reaproveita o mesmo seed para os dois eixos, mas o NASM introduziu uma alteracao semantica que torna o segundo eixo dependente diretamente do primeiro.

## Achado 2 - `MIN_RANDOM_VALUE` existe, mas nao e usado

Arquivos:

- MASM: `C:\Users\edusc\source\repos\Snake\Snake\food_data.inc`
- NASM: `C:\Users\edusc\CLionProjects\SnakeGame\includes\food_data.inc`

Ambos definem:

- `MIN_RANDOM_VALUE equ 2`
- `MAX_RANDOM_VALUE equ 29`
- `RANDOM_RANGE equ (MAX_RANDOM_VALUE - MIN_RANDOM_VALUE + 1)`

Mas `SpawnFood` usa apenas `MAX_RANDOM_VALUE` no divisor. Assim, os indices gerados podem ser `0..28`, nao `2..29`. Depois da multiplicacao por `20`, isso permite spawn em `0` e `20`, apesar da constante sugerir que a intencao era comecar em `2`.

Esse ponto nao e exclusivo do NASM, mas contribui para comida aparecer em posicoes que provavelmente nao eram pretendidas.

## Achado 3 - colisao inferior depende do `ClientRect.bottom`, mas desenho usa altura fixa

Arquivo NASM: `C:\Users\edusc\CLionProjects\SnakeGame\collision.asm`

Trecho relevante:

- linha 63: chama `GetClientRect`
- linha 109: le `ClientRect.bottom`
- linha 110: subtrai `HUD_AREA`
- linha 111: subtrai `SNAKE_MOVEMENT_CELL`
- linha 122: compara `rdx` com o limite inferior calculado
- linha 123: considera colisao se passar desse limite

Arquivos de desenho/janela:

- `C:\Users\edusc\CLionProjects\SnakeGame\game.asm`, linhas 212-213: `gameRender` usa `600 x 645`.
- `C:\Users\edusc\CLionProjects\SnakeGame\game.asm`, linhas 325-326: a janela e criada com `rc.right = 606` e `rc.bottom = 654`.
- `C:\Users\edusc\CLionProjects\SnakeGame\snake.asm`, linha 294: o desenho da cobra soma `HUD_AREA` ao Y logico.
- `C:\Users\edusc\CLionProjects\SnakeGame\food.asm`, linha 189: o desenho da comida tambem soma `HUD_AREA`.

Modelo atual:

```text
Y logico da cobra/comida + HUD_AREA = Y desenhado na janela
limite inferior logico = ClientRect.bottom - HUD_AREA - SNAKE_MOVEMENT_CELL
```

Esse modelo so funciona perfeitamente se `ClientRect.bottom` for a mesma altura que a area desenhada pelo renderer. Mas a janela e criada com tamanho externo fixo, nao com tamanho de cliente ajustado. Em Win32, `CreateWindowExW` recebe largura/altura da janela inteira, incluindo bordas e barra de titulo. Portanto, o `ClientRect.bottom` real pode ser menor que `645`.

Se o renderer considera `645`, mas `GetClientRect` retorna algo menor, a colisao inferior acontece antes da cobra chegar visualmente ao fundo desenhado. Se o inverso acontecer em algum ambiente/configuracao, a cobra pode entrar na area inferior indevida antes de colidir.

## Achado 4 - ha uma diferenca de build que pode expor divergencias

NASM:

- `C:\Users\edusc\CLionProjects\SnakeGame\CMakeLists.txt`, linha 9: compila `main.asm` e `game.asm` no executavel.
- linha 17: usa `LINKER:/SUBSYSTEM:WINDOWS` e `LINKER:/ENTRY:main`.

MASM:

- `C:\Users\edusc\source\repos\Snake\Snake\Snake.vcxproj`, linhas 119 e 141: tambem define `main` como entry point.
- linhas 156-157: `game.asm` aparece com `FileType` como `Document`.
- linhas 171-172: `main.asm` tambem aparece com `FileType` como `Document`.

Isso merece verificacao no Visual Studio, porque o `.vcxproj` sugere que nem todos os arquivos listados como MASM sao necessariamente compilados do mesmo modo que no CMake/NASM. Mesmo que o fluxo de execucao seja equivalente na pratica, a diferenca de toolchain/linker/subsystem pode alterar manifest, DPI awareness, metrica de janela e tamanho real de cliente.

Para a colisao inferior, qualquer diferenca pequena em `GetClientRect` impacta diretamente o limite calculado.

## Achado 5 - coordenada inicial da cabeca nao bate com o primeiro segmento

Arquivos:

- NASM: `C:\Users\edusc\CLionProjects\SnakeGame\snake.asm`
- MASM: `C:\Users\edusc\source\repos\Snake\Snake\snake.asm`

No setup:

- NASM linha 121: o segmento recebe `SNAKE_START_Y`.
- NASM linha 128: `SnakeHeadY` recebe `0`.
- MASM linha 115: o segmento recebe `SNAKE_START_Y`.
- MASM linha 122: `SnakeHeadY` recebe `0`.

Isso nao e uma diferenca entre MASM e NASM, mas e relevante para diagnostico: antes da primeira movimentacao, a cabeca logica usada pela colisao nao representa o mesmo Y do primeiro segmento desenhado. Como ambos herdam esse comportamento, ele nao explica sozinho o problema especifico do NASM, mas pode amplificar sintomas no primeiro tick, no primeiro spawn ou apos reset.

## Causa mais provavel

Para comida:

1. Causa direta: `xor rdx, rdx` extra no NASM antes da segunda divisao em `food.asm`.
2. Consequencia: `SpawnPointY` fica igual a `SpawnPointX`, gerando comida em diagonal/repetida.
3. Causa secundaria: `MIN_RANDOM_VALUE` e `RANDOM_RANGE` nao sao usados.

Para colisao inferior:

1. Causa mais provavel: o limite inferior usa `GetClientRect`, mas o desenho/render usa dimensoes fixas (`600 x 645`) e a janela e criada por tamanho externo (`606 x 654`) sem ajustar o tamanho de cliente.
2. A conta `ClientRect.bottom - HUD_AREA - SNAKE_MOVEMENT_CELL` e correta apenas se `ClientRect.bottom` representar exatamente a altura jogavel visual esperada.
3. A diferenca de toolchain NASM/CMake pode estar tornando essa diferenca visivel, especialmente por manifest/subsystem/metrica de janela.

## Pontos para confirmar em runtime

Sem alterar a logica, os valores que confirmariam o diagnostico sao:

- valor real de `ClientRect.bottom` logo apos `GetClientRect` em `WallCollision`;
- valor de `r11` apos `sub HUD_AREA` e `sub SNAKE_MOVEMENT_CELL`;
- valores finais de `SpawnPointX` e `SpawnPointY` apos `SaveSpawnPoint`;
- verificar se no NASM `SpawnPointX == SpawnPointY` acontece repetidamente.

## Correcoes sugeridas para uma etapa posterior

Nao aplicadas neste levantamento.

- Em `food.asm` NASM, revisar a segunda divisao para gerar Y a partir de outro estado pseudoaleatorio, ou manter intencionalmente a mesma semantica do MASM se o objetivo for port 1:1.
- Usar `RANDOM_RANGE` e somar `MIN_RANDOM_VALUE` ao resultado para respeitar as constantes existentes.
- Tornar o tamanho do client area explicito com `AdjustWindowRectEx` ou calcular `gameRender.ScreenHeight` a partir de `GetClientRect`.
- Centralizar a altura logica jogavel em uma unica constante ou funcao: `playfieldHeight = clientHeight - HUD_AREA`.
- Alinhar `SnakeHeadY` inicial com `SNAKE_START_Y`, caso a intencao seja que a cabeca logica sempre represente o primeiro segmento.
