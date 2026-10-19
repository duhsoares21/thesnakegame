# Guia generico de conversao MASM -> NASM

Data: 2026-08-08  
Escopo: guia geral para converter codigo x64 Assembly escrito em MASM para NASM. Este documento nao converte o codigo do projeto; ele mostra equivalencias, cuidados e exemplos pequenos.

## 1. Ideia central

MASM e NASM montam Assembly x86/x64, mas usam modelos de sintaxe diferentes. A conversao normalmente envolve:

- Trocar diretivas de arquivo, secoes e simbolos.
- Reescrever structs, locals, includes e constantes.
- Remover `INCLUDELIB` do Assembly e mover bibliotecas para o comando de link.
- Ajustar chamadas externas conforme a ABI da plataforma.
- Revisar enderecamento global, principalmente em Linux/macOS com PIE/RIP-relative.

Se a plataforma continuar Windows x64, a calling convention continua sendo a do Windows. Se o NASM for usado em Linux/macOS x64, a calling convention muda para System V AMD64.

## 2. Tabela rapida MASM -> NASM

| Recurso | MASM | NASM |
| --- | --- | --- |
| Secao de codigo | `.code` | `section .text` |
| Secao de dados inicializados | `.data` | `section .data` |
| Secao de dados nao inicializados | `.data?` | `section .bss` |
| Include | `INCLUDE arquivo.inc` | `%include "arquivo.inc"` |
| Link de biblioteca | `INCLUDELIB user32.lib` | Remover; passar ao linker |
| Exportar simbolo | `PUBLIC Funcao` | `global Funcao` |
| Importar simbolo | `EXTERN Funcao:PROC` | `extern Funcao` |
| Constante textual | `NOME equ 123` | `NOME equ 123` ou `%define NOME 123` |
| Inicio de proc | `Funcao PROC` | `Funcao:` |
| Fim de proc | `Funcao ENDP` | Sem equivalente; usar comentario opcional |
| Fim do arquivo | `END` | Sem equivalente obrigatorio |
| Tipo QWORD | `Valor QWORD 0` | `Valor dq 0` |
| Tipo DWORD | `Valor DWORD 0` | `Valor dd 0` |
| Tipo WORD | `Valor WORD 0` | `Valor dw 0` |
| Tipo BYTE | `Valor BYTE 0` | `Valor db 0` |
| Array inicializado | `Arr QWORD 10 dup(0)` | `Arr times 10 dq 0` |
| Buffer nao inicializado | `Buf BYTE 64 dup(?)` | `Buf resb 64` em `.bss` |
| String ASCII | `Msg db "Hello",0` | `Msg db "Hello",0` |
| String UTF-16 simples | `Msg dw "O","K",0` | `Msg dw 'O','K',0` ou bytes gerados por ferramenta |
| Tamanho de simbolo | `SIZEOF MinhaStruct` | Definir manualmente com `struc`/`endstruc` ou equ |
| Struct | `RECT STRUCT ... RECT ENDS` | `struc RECT ... endstruc` |
| Campo de struct | `[rax].RECT.left` | `[rax + RECT.left]` |
| Inicializar struct | `Rect RECT <0,0,10,10>` | `Rect: istruc RECT ... iend` ou `dd 0,0,10,10` |
| Local automatico | `LOCAL x:QWORD` | Reservar stack manualmente ou usar macros |
| Comentario | `; comentario` | `; comentario` |
| Offset/endereco | `lea rdx, Label` | `lea rdx, [rel Label]` ou `lea rdx, [Label]` conforme formato |
| Acesso global | `mov rax, Valor` | `mov rax, [rel Valor]` para memoria; `mov rax, Valor` para imediato/endereco depende do caso |

## 3. Exemplo minimo de arquivo

MASM:

```asm
.data
Counter QWORD 0

.code
PUBLIC AddOne

AddOne PROC
    mov rax, Counter
    inc rax
    mov Counter, rax
    ret
AddOne ENDP

END
```

NASM:

```asm
default rel

section .data
Counter dq 0

section .text
global AddOne

AddOne:
    mov rax, [Counter]
    inc rax
    mov [Counter], rax
    ret
```

## 4. Includes e bibliotecas

MASM permite declarar bibliotecas dentro do arquivo:

```asm
INCLUDELIB kernel32.lib
INCLUDE basic_data.inc

EXTERN ExitProcess:PROC
```

Em NASM, o arquivo Assembly normalmente so declara includes e simbolos:

```asm
%include "basic_data.inc"

extern ExitProcess
```

A biblioteca vai para o link:

```powershell
nasm -f win64 main.asm -o main.obj
link main.obj kernel32.lib /subsystem:console /entry:main
```

No Linux:

```sh
nasm -f elf64 main.asm -o main.o
gcc main.o -o app
```

## 5. Dados e arrays

MASM:

```asm
Value64 QWORD 123
Value32 DWORD 456
Value16 WORD  7
Value8  BYTE  1

Numbers QWORD 4 dup(0)
Buffer  BYTE 64 dup(?)
```

NASM:

```asm
section .data
Value64 dq 123
Value32 dd 456
Value16 dw 7
Value8  db 1

Numbers times 4 dq 0

section .bss
Buffer resb 64
```

## 6. Structs

MASM:

```asm
RECT STRUCT
    left   SDWORD ?
    top    SDWORD ?
    right  SDWORD ?
    bottom SDWORD ?
RECT ENDS

MyRect RECT <0, 0, 100, 100>
```

NASM:

```asm
struc RECT
    .left   resd 1
    .top    resd 1
    .right  resd 1
    .bottom resd 1
endstruc

section .data
MyRect:
    istruc RECT
        at RECT.left,   dd 0
        at RECT.top,    dd 0
        at RECT.right,  dd 100
        at RECT.bottom, dd 100
    iend
```

Acesso a campo:

```asm
; MASM
mov eax, [rdx].RECT.right

; NASM
mov eax, [rdx + RECT.right]
```

Para structs simples, tambem e aceitavel declarar diretamente:

```asm
MyRect dd 0, 0, 100, 100
```

## 7. PROC, PUBLIC e EXTERN

MASM:

```asm
PUBLIC Sum
EXTERN OtherFunc:PROC

Sum PROC
    add rcx, rdx
    mov rax, rcx
    ret
Sum ENDP
```

NASM:

```asm
global Sum
extern OtherFunc

Sum:
    add rcx, rdx
    mov rax, rcx
    ret
```

Atencao: esse exemplo preserva registradores de argumentos Windows x64. Em Linux/macOS, os dois primeiros argumentos normalmente seriam `rdi` e `rsi`.

## 8. Calling convention: Windows x64

Se o destino NASM for Windows x64, a regra geral permanece:

- Arg 1: `RCX`
- Arg 2: `RDX`
- Arg 3: `R8`
- Arg 4: `R9`
- Demais argumentos: stack
- Caller reserva 32 bytes de shadow space.
- Antes de `call`, stack precisa estar alinhada corretamente.

Exemplo NASM chamando uma funcao Windows com dois argumentos:

```asm
extern SomeWinFunc

section .text
global CallIt

CallIt:
    sub rsp, 40        ; 32 bytes shadow space + alinhamento comum
    mov rcx, 10
    mov rdx, 20
    call SomeWinFunc
    add rsp, 40
    ret
```

Chamada com mais de quatro argumentos:

```asm
; SomeFunc(a, b, c, d, e)
sub rsp, 48
mov rcx, 1
mov rdx, 2
mov r8,  3
mov r9,  4
mov qword [rsp + 32], 5
call SomeFunc
add rsp, 48
```

## 9. Calling convention: Linux/macOS x64

Se o destino for Linux ou macOS x64, a ABI muda:

- Arg 1: `RDI`
- Arg 2: `RSI`
- Arg 3: `RDX`
- Arg 4: `RCX`
- Arg 5: `R8`
- Arg 6: `R9`
- Demais argumentos: stack
- Nao existe shadow space Windows.
- `RBX`, `RBP`, `R12`-`R15` devem ser preservados pelo callee.

Exemplo:

```asm
extern puts

default rel

section .data
Msg db "Hello", 0

section .text
global main

main:
    push rbp
    mov rbp, rsp

    lea rdi, [Msg]
    call puts

    xor eax, eax
    pop rbp
    ret
```

## 10. Locals e stack

MASM:

```asm
MyProc PROC
    LOCAL Temp:QWORD

    mov Temp, 123
    mov rax, Temp
    ret
MyProc ENDP
```

NASM, manual:

```asm
MyProc:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov qword [rbp - 8], 123
    mov rax, [rbp - 8]

    add rsp, 16
    pop rbp
    ret
```

Voce tambem pode criar macros NASM para padronizar prologo/epilogo, mas no inicio e melhor escrever manualmente para evitar bugs escondidos.

## 11. Enderecos, memoria e `default rel`

Em MASM, e comum escrever:

```asm
lea rdx, Label
mov rax, GlobalValue
mov GlobalValue, rax
```

Em NASM x64 moderno, prefira:

```asm
default rel

lea rdx, [Label]
mov rax, [GlobalValue]
mov [GlobalValue], rax
```

Sem `default rel`, use `rel` explicitamente:

```asm
lea rdx, [rel Label]
mov rax, [rel GlobalValue]
```

Regra pratica:

- `mov rax, [GlobalValue]` le memoria.
- `mov rax, GlobalValue` carrega um valor imediato/endereco, dependendo do formato e relocacao.
- `lea rax, [rel GlobalValue]` carrega endereco RIP-relative.

## 12. Macros simples uteis

NASM permite macros que ajudam a reduzir repeticao.

Exemplo para chamada Windows x64 simples:

```asm
%macro call_win64_0 1
    sub rsp, 40
    call %1
    add rsp, 40
%endmacro

%macro call_win64_2 3
    sub rsp, 40
    mov rcx, %2
    mov rdx, %3
    call %1
    add rsp, 40
%endmacro
```

Uso:

```asm
call_win64_2 SomeFunc, 10, 20
```

Para System V, uma macro equivalente nao deve reservar shadow space:

```asm
%macro call_sysv_2 3
    mov rdi, %2
    mov rsi, %3
    call %1
%endmacro
```

## 13. Constantes e expressoes

MASM:

```asm
TILE_SIZE equ 20
BOARD_W   equ TILE_SIZE * 30
```

NASM:

```asm
TILE_SIZE equ 20
BOARD_W   equ TILE_SIZE * 30
```

Ou:

```asm
%define TILE_SIZE 20
%define BOARD_W   (TILE_SIZE * 30)
```

Regra pratica:

- `equ` cria uma constante numerica/simbolica.
- `%define` cria substituicao de pre-processador.

## 14. Diferencas comuns que quebram conversao

### 14.1 Tamanho de operando

MASM muitas vezes infere tamanho por simbolo:

```asm
mov Counter, rax
```

NASM geralmente precisa de colchetes e, as vezes, tamanho:

```asm
mov [Counter], rax
mov qword [Counter], 0
```

### 14.2 Colchetes sao importantes

```asm
mov rax, Counter     ; endereco/imediato
mov rax, [Counter]   ; conteudo da memoria
```

### 14.3 Nomes de simbolos no macOS

Em Mach-O/macOS, simbolos C geralmente usam `_` externo:

```asm
global _main
extern _puts

_main:
    lea rdi, [rel Msg]
    call _puts
    xor eax, eax
    ret
```

No Linux, normalmente:

```asm
global main
extern puts
```

### 14.4 Registradores preservados

Nao copie prologos/epilogos cegamente. Confira a ABI:

- Windows x64 preserva `RBX`, `RBP`, `RDI`, `RSI`, `R12`-`R15`.
- System V preserva `RBX`, `RBP`, `R12`-`R15`.

### 14.5 Shadow space

Shadow space existe no Windows x64. Nao existe em Linux/macOS System V.

## 15. Checklist de conversao

- Trocar `.code`, `.data`, `.data?` por `section`.
- Trocar `INCLUDE` por `%include`.
- Remover `INCLUDELIB`.
- Trocar `PUBLIC` por `global`.
- Trocar `EXTERN Nome:PROC` por `extern Nome`.
- Trocar `QWORD/DWORD/WORD/BYTE` em dados por `dq/dd/dw/db`.
- Trocar `dup(?)` por `resb/resw/resd/resq` em `.bss`.
- Trocar `dup(valor)` por `times N d* valor`.
- Converter `PROC/ENDP` para labels.
- Converter `STRUCT/ENDS` para `struc/endstruc` ou offsets manuais.
- Converter acessos `[reg].STRUCT.field` para `[reg + STRUCT.field]`.
- Converter `LOCAL` para stack manual.
- Revisar todas as chamadas externas.
- Revisar ABI: Windows x64 ou System V.
- Revisar alinhamento de stack antes de `call`.
- Revisar registradores callee-saved.
- Revisar enderecamento global com `default rel`/`rel`.
- Mover bibliotecas para CMake/Makefile/linker.
- Montar um arquivo pequeno primeiro antes de converter tudo.

## 16. Recomendacao pratica

Nao tente converter tudo em uma passada. A ordem mais segura e:

1. Converter includes de constantes e structs.
2. Converter um modulo sem chamadas externas.
3. Converter um modulo com chamadas internas.
4. Converter um modulo com chamadas de API externa.
5. Criar macros de chamada apenas depois de entender os padroes repetidos.
6. Validar cada objeto no linker antes de avancar para o proximo.

Para projetos que chamam muitas APIs de sistema, considere criar wrappers C pequenos. Isso reduz drasticamente a quantidade de chamadas ABI complexas escritas direto em Assembly.

