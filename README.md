# Snake Game - x64 Assembly

A classic Snake game written entirely in **x64 Assembly (MASM)** using the native Windows API.

This project is a learning and experimentation project focused on building a complete small game from the ground up without using a game engine, framework, or runtime library.

The goal is to explore low-level Windows development, graphics rendering, input handling, memory management, and game architecture using Assembly language.

---
## Compatibility

### Supported on 64-bit Windows Only 

| Platform | Status |
| --- | --- |
| Windows 11 x64 | ✅ Supported |
| Windows 10 x64 | ✅ Supported |
| Windows 8 x64 | ✅ Supported |
| Windows Vista x64 | ✅ Supported |
| Windows 7 x64 | ✅ Supported |
| Windows XP x64 | ✅ Supported |

- DirectX June 2010 is required to play the game; DirectX is available as a separate download on the [releases page](https://github.com/duhsoares21/thesnakegame/releases).
- Windows 8 and newer officialy supports Xbox One and Xbox Series X|S Controllers; Windows 7 and older officialy supports Xbox 360 Controllers, but drivers might be required;

The game targets the native Windows x64 environment.

---

## About The Game

This is a modern implementation of the classic Snake game.

## Screenshots

### Main Menu
<img width="600" height="630" alt="20260720-0517-04 5567350" src="https://github.com/user-attachments/assets/e2087251-789c-4a74-b0c2-659702706310" />

### In Game
<img width="590" height="642" alt="image" src="https://github.com/user-attachments/assets/6e653b1e-5c9d-4ba3-b2a8-9a2350e9f197" />

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

Because I like to suffer, yay! Just kidding. 

Assembly is a passion of mine and I always wanted to learn and do something meaningful with it. So there it is.

---

## License

This project is available for educational purposes.
Feel free to study, modify, and experiment with the source code.
