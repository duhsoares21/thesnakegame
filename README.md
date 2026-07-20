# Snake Game - x64 Assembly

A classic Snake game written entirely in **x64 Assembly (MASM)** using the native Windows API.

This project is a learning and experimentation project focused on building a complete small game from the ground up without using a game engine, framework, or runtime library.

The goal is to explore low-level Windows development, graphics rendering, input handling, memory management, and game architecture using Assembly language.

---

## About The Game

This is a modern implementation of the classic Snake game.

## Screenshots

### Main Menu
<img width="600" height="630" alt="20260720-0517-04 5567350" src="https://github.com/user-attachments/assets/e2087251-789c-4a74-b0c2-659702706310" />

### Gameplay
<img width="602" height="682" alt="20260720-0519-29 0391815" src="https://github.com/user-attachments/assets/bca193dc-9333-4e3d-bc29-b4010507c1c0" />


Features:

- Classic Snake gameplay
- Main menu system
- Keyboard input support
- Xbox controller support through XInput
- Score tracking
- Food generation
- Snake growth mechanics
- Speed progression
- HUD rendering
- Double-buffered rendering
- Native Windows window management

The game is built as a native Windows executable with no external dependencies.

---

## Technical Details

### Language

- **x64 Assembly (MASM)**

### Platform

- Windows x64

### APIs Used

- Win32 API
- GDI
- XInput
- Kernel32
- User32

### Rendering

The renderer uses:

- GDI device contexts
- Off-screen rendering buffer
- BitBlt-based double buffering

The rendering pipeline:

```
Game State
|
v
Render Commands
|
v
Memory Back Buffer
|
v
BitBlt
|
v
Window
```

---

## Architecture

The project is separated into multiple systems:

```
SnakeGame
|
├── Main Window
│ ├── Window creation
│ ├── Message loop
│ └── Main menu
|
├── Game System
│ ├── Game state machine
│ ├── Snake logic
│ ├── Food system
│ └── Collision handling
|
├── Input System
│ ├── Keyboard input
│ └── Xbox controller input
|
├── Render System
│ ├── Double buffering
│ ├── Drawing primitives
│ └── HUD rendering
|
└── Audio System
    └── Game sounds
```

---

## Requirements

### Minimum Requirements

- Windows XP x64 or newer
- x64 compatible processor

No installation is required.
The executable is standalone.

---

## Compatibility

### Supported

| Platform | Status |
| --- | --- |
| Windows 10 x64 | ✅ Supported |
| Windows 11 x64 | ✅ Supported |
| Windows 8 x64 | ⚠️ Not tested but should work |
| Windows Vista x64 | ⚠️ Not tested but should work |
| Windows 7 x64 | ⚠️ Not tested but should work |
| Windows XP x64 | ✅ Supported |
| Windows x86 | ❌ Not supported |

The game targets the native Windows x64 environment.

---

## Building From Source

### Requirements

- Visual Studio 2022
- MASM x64 tools
- Windows SDK

Install the workload:

```
Desktop development with C++
```

The project requires:

```
Microsoft Macro Assembler (MASM)
Windows SDK
x64 build tools
```

---

## Controls

### Keyboard

| Key | Action |
| --- | --- |
| Enter | Start Game |
| Arrow Keys | Move Snake |
| Escape | Pause |

### Xbox Controller

| Button | Action |
| --- | --- |
| Menu | Start Game / Pause |
| D-Pad | Move Snake |

---

## Why Assembly?

This project was created to explore what is possible when building software at a very low level.

Modern game development usually relies on:

- Game engines
- High-level languages
- Frameworks
- Middleware

While those tools are extremely powerful, Assembly provides a unique perspective:

- Direct CPU control
- Understanding of memory layout
- Manual calling conventions
- Native API interaction
- Minimal executable size

The entire game logic, rendering system, input handling, and window management are implemented manually.

---

## Project Goals

This project is not intended to replace modern game engines.

Instead, it is an exploration of:

- How games worked before large engines existed
- How operating systems expose functionality
- How high-level features are built from low-level primitives
- Learning computer architecture through practical development

---

## License

This project is available for educational purposes.
Feel free to study, modify, and experiment with the source code.
