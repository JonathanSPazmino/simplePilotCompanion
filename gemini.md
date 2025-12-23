# Project Overview: simplePilotCompanion

This is a LÖVE2D application designed as a pilot's companion tool.

## Key Features:

*   **Timer Functionality:**
    *   Supports both "COUNT UP" and "COUNT DOWN" modes.
    *   Triggers an alarm (screen blink, vibration, beep sound) when a countdown timer reaches zero.
    *   Includes an "Acknowledge Alarm" button to stop the alarm.
*   **UTC Display:** Shows the current Coordinated Universal Time.
*   **Altitude and Time Calculation:**
    *   Allows user input for `selectedAltitude` (in feet) and `selectedTime` (in minutes).
    *   Calculates and displays a `requiredFPM` (feet per minute) based on the selected altitude and time.
*   **Custom GUI:** Utilizes a custom GUI library (`Libraries/jp_GUI_library`) for interactive elements like buttons, text boxes, and scroll bars.

## Core Components:

*   **`main.lua`**: The primary entry point for the application, handling game loops, timer logic, UTC updates, and integration with the GUI library.
*   **`Libraries/jp_GUI_library/`**: Contains the custom GUI framework that renders and manages all user interface elements.
*   **`Sounds/beep.wav`**: The audio file played during the timer alarm.
*   **`Sprites/`**: Directory containing all image assets for the GUI buttons and other visual components.

This application provides essential tools for pilots, focusing on timing, navigation data (UTC), and flight planning calculations (FPM).