--[[ Main.lua
    Author: Jonathan Pazmino
    Description: Core entry file for LÖVE app with timer and GUI integration
]]

io.stdout:setvbuf("no")

-------------------------------------------------------------------------------
-- LIBRARIES LOAD
-------------------------------------------------------------------------------
require("Libraries.jp_GUI_library.jpGUIlib")

-- Create base page
globApp.appColor = {.2, .2, .2, 1} --initializes bg color
page_create(3, "MainMenu", false, false, globApp.appColor, 12, 0, {.5, 1, .6, .6, "LT"}, "max")

-------------------------------------------------------------------------------
-- GLOBAL STATE
-------------------------------------------------------------------------------
local utc = {}
local utcPrintString = ""
local lastSavedCountDownTime = 0
local font

-- Timer object
local timer = {
    mode = "COUNT UP",   -- Options: "COUNT UP" or "COUNT DOWN"
    duration = 90,       -- Default countdown duration (in seconds)
    t = 0,               -- Current timer value (in seconds)
    running = false      -- Timer running state
}

-- Countdown finished blink state
local blink = {active = false, timer = 0, state = false}

-- Load beep sound
local beepSound

-------------------------------------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------------------------------------

-- Format seconds into mm:ss
local function format_time(s)
    if s < 0 then s = 0 end
    local minutes = math.floor(s / 60)
    local seconds = math.floor(s % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

-------------------------------------------------------------------------------
-- LOVE CALLBACKS
-------------------------------------------------------------------------------
function love.load()
    page_switch("IntialBooting", 3, 2, false)

    font = love.graphics.newFont(20)
    love.graphics.setFont(font)

    -- Initialize starting time
    timer.t = 0

    -- Load beep sound
    beepSound = love.audio.newSource("Sounds/beep.wav", "static")
end

function love.update(dt)
    -- Update UTC clock string
    utc = os.date("!*t")
    utcPrintString = string.format(
        "UTC:\n%04d-%02d-%02d\n%02d:%02d:%02d",
        utc.year, utc.month, utc.day, utc.hour, utc.min, utc.sec
    )

    -- Update GUI
    jpGUI_update(dt)

    if blink.active == false then
            setButtonState( "acknowlegeAlarm", "deactivated" )
    end

    -- Skip if timer not running
    if timer.running then
        if timer.mode == "COUNT UP" then
            timer.t = timer.t + dt
        else -- COUNT DOWN
        timer.t = math.max(0, timer.t - dt)

        if timer.t == 0 then
            timer.running = false
            blink.active = true
            setButtonState("acknowlegeAlarm", "released")
            alarmButtonsDeactivation()
            for _, btn in ipairs(lib_buttons) do
                if btn.name == "pauseRHTopTimer" and btn.state == 2 then
                    btn.state = 1
                end
            end
        end
        end
    end

    -- Handle blinking background with vibration and beep
    if blink.active then
        blink.timer = blink.timer + dt
        if blink.timer > 0.5 then
            blink.timer = 0
            blink.state = not blink.state

            if blink.state then
                globApp.appColor = {1, 0, 0, 1} -- red
                -- Vibrate device if capable
                if love.system.vibrate then
                    love.system.vibrate(0.1) -- short vibration
                end
                -- Play beep sound
                if beepSound then
                    love.audio.play(beepSound)
                end
            else
                globApp.appColor = {0.2, 0.2, 0.2, 1} -- normal gray
            end
        end
    end

    --handles play button state during countdown based on timer
    if timer.t <= 0 then 
        for _, btn in ipairs(lib_buttons) do
            if btn.name == "modeSelectRHTopTimer" and btn.state == 2 then
                setButtonState ( "pauseRHTopTimer", "deactivated")
            end
        end
    end
end

function love.draw()
    drawPages()
    jpGUI_draw()
end

-------------------------------------------------------------------------------
-- PAGE DRAWING
-------------------------------------------------------------------------------
function drawPages()
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

    ---------------------------------------------------------------------------
    -- BUTTONS
    ---------------------------------------------------------------------------
    drawButtons("resetRHTopTimer", thisPageName, "pushonoff",
        "Sprites/resetButton_pushed.png", "Sprites/resetButton_released.png",
        "Sprites/resetButton_deactivated.png", .95, .3, "RT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "resetRHTopTimer", 1
    )

    drawButtons("pauseRHTopTimer", thisPageName, "toggle",
        "Sprites/pausePlayButton_pressed.png", "Sprites/pausePlayButton_released.png",
        "Sprites/pausePlayButton_deactivated.png", .725, .3, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "pauseRHTopTimer", 1
    )

    drawButtons("modeSelectRHTopTimer", thisPageName, "toggle",
        "Sprites/timerModeButton_down.png", "Sprites/timerModeButton_up.png",
        "Sprites/timerModeButton_deactivated.png", .55, .3, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "modeSelectRHTopTimer", 1
    )

    drawButtons("incrsMinRHTopTimer", thisPageName, "pushonoff",
        "Sprites/minIncreaseButton_pressed.png", "Sprites/minIncreaseButton_released.png",
        "Sprites/invisibleBox.png", .5, .05, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "incrsMinRHTopTimer", 0
    )

    drawButtons("dcrsMinRHTopTimer", thisPageName, "pushonoff",
        "Sprites/minDecreaseButton_pressed.png", "Sprites/minDecreaseButton_released.png",
        "Sprites/invisibleBox.png", .5, .15, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "dcrsMinRHTopTimer", 0
    )

    drawButtons("incrsSecRHTopTimer", thisPageName, "pushonoff",
        "Sprites/secIncreaseButton_pressed.png", "Sprites/secIncreaseButton_released.png",
        "Sprites/invisibleBox.png", .92, .05, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "incrsSecRHTopTimer", 0
    )

    drawButtons("dcrsSecRHTopTimer", thisPageName, "pushonoff",
        "Sprites/secDecreaseButton_pressed.png", "Sprites/secDecreaseButton_released.png",
        "Sprites/invisibleBox.png", .92, .15, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "dcrsSecRHTopTimer", 0
    )



    ---------------------------------------------------------------------------
    -- TEXT BOXES
    ---------------------------------------------------------------------------
    outputTxtBox_draw("utcData", thisPageName, "Sprites/invisibleBox.png",
        .05, .05, "LT",
        globApp.safeScreenArea.w * .4, globApp.safeScreenArea.h * .2,
        {.7, .7, .7, .85}, utcPrintString, fontSize
    )

    local text = timer.mode .. "\nTIMER:\nM " .. format_time(timer.t) .. " S"
    outputTxtBox_draw("timerTopRight", thisPageName, "Sprites/invisibleBox.png",
        .90, .05, "RT",
        globApp.safeScreenArea.w * .3, globApp.safeScreenArea.h * .2,
        {1, 1, 0, 1}, text, fontSize
    )



    drawButtons("acknowlegeAlarm", thisPageName, "pushonoff", --MUST BE DRAWED AFTR TEXTBOX
       "Sprites/ackButton_pushed.png", "Sprites/ackButton_released.png",
        "Sprites/invisibleBox.png", 
        .90, .05, "RT",
        globApp.safeScreenArea.w * .3, globApp.safeScreenArea.h * .2,
        "acknowlegeAlarm", 0
    )
end

-------------------------------------------------------------------------------
-- TIMER CONTROL FUNCTIONS
-------------------------------------------------------------------------------

function acknowlegeAlarm()
    if blink.active then
        blink.active = false       -- stop blinking
        blink.state = false        -- reset blink state
        globApp.appColor = {0.2, 0.2, 0.2, 1} -- restore normal background
        if beepSound then
            love.audio.stop(beepSound)  -- stop any currently playing beep
        end
    end
    alarmAcklgBtnsActiation ()
end


function alarmButtonsDeactivation ()

    setButtonState( "modeSelectRHTopTimer", "deactivated" )
    setButtonState( "incrsMinRHTopTimer", "deactivated" )
    setButtonState( "dcrsMinRHTopTimer", "deactivated" )
    setButtonState( "incrsSecRHTopTimer", "deactivated" )
    setButtonState( "dcrsSecRHTopTimer", "deactivated" )
    setButtonState( "pauseRHTopTimer", "deactivated" )
    setButtonState( "resetRHTopTimer", "deactivated" )

end

function alarmAcklgBtnsActiation ()

    setButtonState( "modeSelectRHTopTimer", "pushed" )
    setButtonState( "incrsMinRHTopTimer", "released" )
    setButtonState( "dcrsMinRHTopTimer", "released" )
    setButtonState( "incrsSecRHTopTimer", "released" )
    setButtonState( "dcrsSecRHTopTimer", "released" )
    setButtonState( "pauseRHTopTimer", "released" )
    setButtonState( "resetRHTopTimer", "released" )

end


function resetRHTopTimer()
    timer.running = false
    if timer.mode == "COUNT DOWN" then
        timer.t = lastSavedCountDownTime
        setButtonState ("pauseRHTopTimer", "released")
    else
        timer.t = 0
    end
    blink.active = false -- stop blink
    globApp.appColor = {0.2, 0.2, 0.2, 1} -- keep normal color
    for _, btn in ipairs(lib_buttons) do
        if btn.name == "pauseRHTopTimer" and btn.state == 2 then
            btn.state = 1
        end
    end
    
end

function pauseRHTopTimer()
    timer.running = not timer.running
end

function incrsMinRHTopTimer()
    timer.t = timer.t + 60
    saveCountdownTime()
    acknowlegeAlarm()
end

function dcrsMinRHTopTimer()
    timer.t = math.max(0, timer.t - 60)
    saveCountdownTime()
end

function incrsSecRHTopTimer()
    timer.t = timer.t + 1
    saveCountdownTime()
    acknowlegeAlarm()
end

function dcrsSecRHTopTimer()
    timer.t = math.max(0, timer.t - 1)
    saveCountdownTime()
end

function modeSelectRHTopTimer()
    timer.mode = (timer.mode == "COUNT UP") and "COUNT DOWN" or "COUNT UP"
    
    if timer.mode == "COUNT DOWN" then
        setButtonState( "incrsMinRHTopTimer", "released" )
        setButtonState( "dcrsMinRHTopTimer", "released" )
        setButtonState( "incrsSecRHTopTimer", "released" )
        setButtonState( "dcrsSecRHTopTimer", "released" )
        timer.t = lastSavedCountDownTime
    else
        timer.t = 0
        setButtonState( "incrsMinRHTopTimer", "deactivated" )
        setButtonState( "dcrsMinRHTopTimer", "deactivated" )
        setButtonState( "incrsSecRHTopTimer", "deactivated" )
        setButtonState( "dcrsSecRHTopTimer", "deactivated" )
        setButtonState( "pauseRHTopTimer", "released")
    end

    -- for _, btn in ipairs(lib_buttons) do
    --     if btn.name == "pauseRHTopTimer" and btn.state == 2 then
    --         btn.state = 1
    --     end
    -- end

    timer.running = false
end

function saveCountdownTime()
    lastSavedCountDownTime = math.max(0, timer.t)
end


