# Gemini Code Assistant Project Analysis

## Project Overview

This project is a LÖVE2D application written in Lua. It appears to be a companion tool for pilots, providing a simple interface for a flight timer and other in-flight calculations.

**Key Features:**

*   **Timer:** A versatile timer that can count up or down. The countdown timer triggers an alarm when it reaches zero.
*   **UTC Clock:** Displays the current Coordinated Universal Time.
*   **Vertical Speed Calculator:** Calculates the required feet per minute (FPM) to reach a target altitude in a given amount of time.
*   **Custom GUI:** The application uses a custom GUI library for its user interface components.

## Building and Running

To run this application, you need to have LÖVE 2D installed on your system. You can download it from the official website: [https://love2d.org/](https://love2d.org/)

Once LÖVE 2D is installed, you can run the application by executing the following command in the project's root directory:

```bash
love .
```

Alternatively, you can drag the project folder onto the LÖVE 2D application icon.

## Development Conventions

The project follows standard Lua coding conventions. The code is organized into modules, with `main.lua` serving as the main entry point. The GUI components are managed by a custom library located in the `Libraries/jp_GUI_library` directory. All the assets are stored in the `Sprites` and `Sounds` directories.
