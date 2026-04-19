--[[
    lib_haptics.lua
    Single entry-point for haptic feedback across all GUI objects.
    Safely no-ops on desktop and simulator platforms where vibration is
    not supported — no error is raised regardless of platform.
]]

function gdsGui_haptics_vibrate()
    if love.system and love.system.vibrate then
        pcall(love.system.vibrate, 0.5)
    end
end
