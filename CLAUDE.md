# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the App

```bash
love .        # Run from the project root directory
```

LÖVE2D must be installed. No build step, no external dependencies — pure Lua + LÖVE2D standard library.

## Running Unit Tests

Unit tests live in `Libraries/jp_GUI_library/lib_unitTests.lua` and are invoked via `gdsGUI_executeAllUnitTests("Blank")` inside `jpGUIlib.lua`. They run automatically at load time when the dev settings enable them.

## Architecture

### Two-layer structure

**Application layer** (`main.lua`, `conf.lua`): The pilot companion app itself — UTC clock, dual-mode timer (count up/down), altitude/time selectors, FPM calculator, alarm system.

**GUI framework** (`Libraries/jp_GUI_library/`): A reusable, self-contained GUI library. `jpGUIlib.lua` is the loader that requires all 14 modules. This library is independent of the application logic.

### GUI library modules

| Module | Purpose |
|--------|---------|
| `lib_general.lua` | Core utilities, DPI scaling, resize detection, `globApp` state |
| `lib_buttons.lua` | Button objects: creation, drawing, click/touch handling |
| `lib_pages.lua` | Page/screen management and navigation |
| `lib_scrollBar.lua` | Vertical/horizontal scrollbars, discrete stepping, drag, sprites |
| `lib_table.lua` | Sortable/filterable data table display |
| `lib_inputTxtBox.lua` | Text input fields with validation |
| `lib_outputTxtBox.lua` | Read-only text display boxes |
| `lib_drawGrid.lua` | Grid rendering for scrollable content |
| `lib_saveLoad.lua` | Persistent save/load |
| `lib_timeControl.lua` | Time-based event triggers |
| `lib_appFrame.lua` | Application frame/window management |
| `lib_images.lua` | Image asset caching |
| `lib_unitTests.lua` | Dev testing utilities |
| `lib_devSettings.lua` | Developer mode and debug flags |

### Key design patterns

- **`globApp` table**: Global state object holding colors, UI objects, screen dimensions, safe area insets, and app-wide flags. Defined in `lib_general.lua`.
- **Object-oriented UI elements**: Each widget (button, scrollbar, textbox, etc.) is a Lua table with methods. Created via constructor functions in their respective modules.
- **Callback-based events**: UI interactions call named functions (e.g., `pauseRHTopTimer()`, `roundSelectedAltitude()`) rather than inline logic.
- **Page-based navigation**: Screens are registered as pages; switching pages is handled by `lib_pages.lua`.
- **Responsive resize**: All elements recalculate dimensions on window resize. The resize pattern is centralized in `lib_general.lua`.
- **Sprite support on scrollbars**: Scrollbar buttons and tracks can use PNG sprites from `Sprites/` instead of procedural drawing.

### LÖVE2D callbacks

`main.lua` implements the standard LÖVE callbacks:
- `love.load()` — initializes `globApp`, loads assets, builds UI
- `love.update(dt)` — timer logic, alarm state, UTC clock
- `love.draw()` — delegates to GUI library draw calls
- `love.resize()` — triggers responsive layout recalculation
- `love.touchpressed/moved/released`, `love.mousepressed/moved/released` — input routing

### Window config

Defined in `conf.lua`: 320×617 base resolution, LÖVE 11.3, audio and graphics modules enabled.
