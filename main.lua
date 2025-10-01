--[[Main.lua
    Author: Jonathan Pazmino
]]

io.stdout:setvbuf("no")

-------------------------------------------------------------------------------
-- LIBRARIES LOAD
-------------------------------------------------------------------------------
require("Libraries.jp_GUI_library.jpGUIlib")

page_create(3, "MainMenu", false, false, globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")

-------------------------------------------------------------------------------
-- CORE FUNCTIONS BELOW THIS LINE (CALLBACKS)
-------------------------------------------------------------------------------

local utc = {}
local TopRightTimer = 0
local utcPrintString = ""
local lastSavedCountDownTime = 0

local timer = {
    mode = "COUNT UP",   -- "COUNT UP" or "COUNT DOWN"
    duration = 90,       -- only used in COUNT DOWN mode (seconds)
    t = 0,               -- current time (seconds)
    running = false
}

local font

local function format_time(s)
    if s < 0 then s = 0 end
    local minutes = math.floor(s / 60)
    local seconds = math.floor(s % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

local visRhTimerInputBox = false

-------------------------------------------------------------------------------
-- LOVE CALLBACKS
-------------------------------------------------------------------------------
function love.load()
    page_switch("IntialBooting", 3, 2, false)

    font = love.graphics.newFont(20)
    love.graphics.setFont(font)

    -- initialize starting time
    timer.t = 0
end

function love.update(dt)
    utc = os.date("!*t")
    utcPrintString = string.format(
        "UTC:\n%04d-%02d-%02d\n%02d:%02d:%02d",
        utc.year, utc.month, utc.day, utc.hour, utc.min, utc.sec
    )

    jpGUI_update(dt)

    -- topright timer
    if not timer.running then return end

    if timer.mode == "COUNT UP" then
        timer.t = timer.t + dt
    else -- COUNT DOWN
        timer.t = timer.t - dt
        if timer.t <= 0 then
            timer.t = 0
            timer.running = false
            for i, j in ipairs(lib_buttons) do
                if j.name == "pauseRHTopTimer" and j.state == 2  then
                    j.state = 1
                end
            end
        end
    end
end

function love.draw()
    drawPages()
    jpGUI_draw()
end

-------------------------------------------------------------------------------
-- GENERAL FUNCTIONS BELOW THIS LINE
-------------------------------------------------------------------------------
function drawPages()
    -- pageBackGround_draw must be added on top in order to change bg color
    pageBackground_draw()
    mainMenuDisplay()
end

function OpenMainMenuPage(position)
    page_switch("LoadingMainMenu", 3, 1, false)
end

-------------------------------------------------------------------------------
-- MAIN MENU DISPLAY
-------------------------------------------------------------------------------
function mainMenuDisplay()
    local fontSize = 12
    local thisPageName = "MainMenu"

    -- BUTTONS

    drawButtons("resetRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/resetButton_pushed.png", "Sprites/resetButton_released.png",
        "Sprites/resetButton_deactivated.png", .95, .3, "RT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "resetRHTopTimer", 1
    )

    drawButtons("pauseRHTopTimer", "MainMenu", "toggle",
        "Sprites/pausePlayButton_pressed.png", "Sprites/pausePlayButton_released.png",
        "Sprites/pausePlayButton_deactivated.png", .725, .3, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "pauseRHTopTimer", 1
    )

    drawButtons("modeSelectRHTopTimer", "MainMenu", "toggle",
        "Sprites/timerModeButton_down.png", "Sprites/timerModeButton_up.png",
        "Sprites/timerModeButton_deactivated.png", .55, .3, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "modeSelectRHTopTimer", 1
    )

    drawButtons("incrsMinRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/minIncreaseButton_pressed.png", "Sprites/minIncreaseButton_released.png",
        "Sprites/invisibleBox.png", .5, .05, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "incrsMinRHTopTimer", 0
    )

    drawButtons("dcrsMinRHTopTimer", "MainMenu", "pushonoff",
       "Sprites/minDecreaseButton_pressed.png", "Sprites/minDecreaseButton_released.png",
        "Sprites/invisibleBox.png", .5, .15, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "dcrsMinRHTopTimer", 0
    )

    drawButtons("incrsSecRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/minIncreaseButton_pressed.png", "Sprites/minIncreaseButton_released.png",
        "Sprites/invisibleBox.png", .90, .05, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "incrsSecRHTopTimer", 0
    )

    drawButtons("dcrsSecRHTopTimer", "MainMenu", "pushonoff",
       "Sprites/minDecreaseButton_pressed.png", "Sprites/minDecreaseButton_released.png",
        "Sprites/invisibleBox.png", .90, .15, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "dcrsSecRHTopTimer", 0
    )

    ------------------------------------------------------------------------
    -- TEXT BOXES
    ------------------------------------------------------------------------
    -- UTC TOP LEFT
    outputTxtBox_draw("utcData", thisPageName, "Sprites/invisibleBox.png",
        .05, .05, "LT",
        globApp.safeScreenArea.w * .4, globApp.safeScreenArea.h * .2,
        {.7, .7, .7, .85}, utcPrintString, fontSize
    )

    -- TIMER TOP RIGHT CORNER
    local text = timer.mode .. "\nTIMER:\nM " .. format_time(timer.t) .. " S"
    outputTxtBox_draw("timerTopRight", thisPageName, "Sprites/invisibleBox.png",
        .90, .05, "RT",
        globApp.safeScreenArea.w * .3, globApp.safeScreenArea.h * .2,
        {1, 1, 0, 1}, text, fontSize
    )
end

-------------------------------------------------------------------------------
-- TIMER CONTROL FUNCTIONS
-------------------------------------------------------------------------------
function resetRHTopTimer()
    timer.running = false
    if timer.mode == "COUNT DOWN" then
    	timer.t = lastSavedCountDownTime
    elseif timer.mode == "COUNT UP" then
    	timer.t = 0
    end 
    for i, j in ipairs(lib_buttons) do
        if j.name == "pauseRHTopTimer" and j.state == 2  then
            j.state = 1
        end
    end
end

function pauseRHTopTimer()
    timer.running = not timer.running
end

function incrsMinRHTopTimer()
    timer.t = timer.t + 60
    saveCountdownTime ()
end

function dcrsMinRHTopTimer()
    timer.t = timer.t - 60
    saveCountdownTime ()
end

function incrsSecRHTopTimer()
    timer.t = math.max(0, timer.t + 1)
    saveCountdownTime ()
end


function dcrsSecRHTopTimer()
    timer.t = math.max(0, timer.t - 1)
    saveCountdownTime ()
end

function modeSelectRHTopTimer()
    timer.mode = (timer.mode == "COUNT UP") and "COUNT DOWN" or "COUNT UP"
    
    if timer.mode == "COUNT DOWN" then
        activateButton("incrsMinRHTopTimer")
        activateButton("dcrsMinRHTopTimer")
        activateButton("incrsSecRHTopTimer")
        activateButton("dcrsSecRHTopTimer")
      timer.t = lastSavedCountDownTime
    else

    	timer.t = 0
        deactiveButton("incrsMinRHTopTimer")
        deactiveButton("dcrsMinRHTopTimer")
        deactiveButton("incrsSecRHTopTimer")
        deactiveButton("dcrsSecRHTopTimer")
    end
    for i, j in ipairs(lib_buttons) do
        if j.name == "pauseRHTopTimer" and j.state == 2  then
            j.state = 1
        end
    end
    timer.running = false
end


function saveCountdownTime ()

	lastSavedCountDownTime = timer.t

end