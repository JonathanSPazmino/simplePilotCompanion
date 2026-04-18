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
local lastUtcSec = -1 -- Add a variable to track the last updated second
local lastSavedCountDownTime = 0
local font

-- Pre-defined colors to avoid creating tables in love.update
local colorRed = {1, 0, 0, 1}
local colorGray = {0.2, 0.2, 0.2, 1}
local colorYellow = {1, 1, 0, 1}

-- Timer object
local timer = {
    mode = "COUNT UP",   -- Options: "COUNT UP" or "COUNT DOWN"
    duration = 90,       -- Default countdown duration (in seconds)
    t = 0,               -- Current timer value (in seconds)
    running = false      -- Timer running state
}

-- Dirty-flag sentinels: values that can never match real state on first frame.
local _prevTimerT        = -1
local _prevTimerMode     = ""
local _prevAltitude      = -1
local _prevTime          = -1
local _prevDegree        = -1e9
local _prevWindDir       = -1
local _prevWindSpeed     = -1
local _prevWindGust      = -1
local _prevKnobPos       = -1

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
    selectedAltitude      = 0
    selectedTime          = 0
    selectedDegree        = 0
    selectedKnobPos       = 36
    selectedWindDirection = 360
    selectedWindSpeed     = 0
    selectedWindGust      = 0

    ---------------------------------------------------------------------------
    -- BUTTONS
    ---------------------------------------------------------------------------
    gui_button_create("resetRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/resetButton_pushed.png", "Sprites/resetButton_released.png",
        "Sprites/resetButton_deactivated.png", .90, .15, "RT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "resetRHTopTimer", globApp.BUTTON_STATES.RELEASED, true
    )

    gui_button_create("pauseRHTopTimer", "MainMenu", "toggle",
        "Sprites/pausePlayButton_pressed.png", "Sprites/pausePlayButton_released.png",
        "Sprites/pausePlayButton_deactivated.png", .75, .15, "CT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "pauseRHTopTimer", globApp.BUTTON_STATES.RELEASED, true
    )

    gui_button_create("modeSelectRHTopTimer", "MainMenu", "toggle",
        "Sprites/timerModeButton_down.png", "Sprites/timerModeButton_up.png",
        "Sprites/timerModeButton_deactivated.png", .6, .15, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "modeSelectRHTopTimer", globApp.BUTTON_STATES.RELEASED, true
    )

    gui_button_create("incrsMinRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/minIncreaseButton_pressed.png", "Sprites/minIncreaseButton_released.png",
        "Sprites/invisibleBox.png", .5, .05, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "incrsMinRHTopTimer", globApp.BUTTON_STATES.DEACTIVATED, true
    )

    gui_button_create("dcrsMinRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/minDecreaseButton_pressed.png", "Sprites/minDecreaseButton_released.png",
        "Sprites/invisibleBox.png", .5, .15, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "dcrsMinRHTopTimer", globApp.BUTTON_STATES.DEACTIVATED, true
    )

    gui_button_create("incrsSecRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/secIncreaseButton_pressed.png", "Sprites/secIncreaseButton_released.png",
        "Sprites/invisibleBox.png", .92, .05, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "incrsSecRHTopTimer", globApp.BUTTON_STATES.DEACTIVATED, true
    )

    gui_button_create("dcrsSecRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/secDecreaseButton_pressed.png", "Sprites/secDecreaseButton_released.png",
        "Sprites/invisibleBox.png", .92, .15, "LT",
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "width"),
        smartScaling("inverse", 0.08, .08, .08, 0.08, 1, "height"),
        "dcrsSecRHTopTimer", globApp.BUTTON_STATES.DEACTIVATED, true
    )


    gui_button_create("acknowlegeAlarm", "MainMenu", "pushonoff", --MUST BE DRAWED AFTR TEXTBOX
       "Sprites/ackButton_pushed.png", "Sprites/ackButton_released.png",
        "Sprites/invisibleBox.png", 
        .90, .05, "RT",
        globApp.safeScreenArea.w * .3, globApp.safeScreenArea.h * .1,
        "acknowlegeAlarm", globApp.BUTTON_STATES.DEACTIVATED, true
    )
	
	---------------------------------------------------------------------------
    -- TEXT BOXES
    ---------------------------------------------------------------------------
    gui_outputTextBox_create("utcData", "MainMenu", "Sprites/invisibleBox.png",
        .05, .05, "LT",
        globApp.safeScreenArea.w * .4, globApp.safeScreenArea.h * .1,
        colorYellow, utcPrintString, 12
    )

    local text = timer.mode .. "\nTIMER:\nM " .. format_time(timer.t) .. " S"
    gui_outputTextBox_create("timerTopRight", "MainMenu", "Sprites/invisibleBox.png",
        .90, .05, "RT",
        globApp.safeScreenArea.w * .3, globApp.safeScreenArea.h * .1,
        colorYellow, text, 12
    )

    local textAltSlctd = "Alt:\n" .. selectedAltitude .. " FT"
    
    gui_outputTextBox_create("selectedAltitudeBox", "MainMenu", "Sprites/invisibleBox.png",
        .5, .6, "CC",
        globApp.safeScreenArea.w * .20, globApp.safeScreenArea.h * .08,
        colorYellow, textAltSlctd, 12
    )
    local textTimeSlctd = "time:\n" .. selectedTime .. " min"
    
    gui_outputTextBox_create("selectedTimeBox", "MainMenu", "Sprites/invisibleBox.png",
        .15, .6, "CC",
        globApp.safeScreenArea.w * .20, globApp.safeScreenArea.h * .08,
        colorYellow, textTimeSlctd, 12
    )

    local textDegreeSlctd = "deg:\n" .. string.format("%.2f", selectedDegree) .. "°"

    gui_outputTextBox_create("selectedDegreeBox", "MainMenu", "Sprites/invisibleBox.png",
        .82, .6, "CC",
        globApp.safeScreenArea.w * .20, globApp.safeScreenArea.h * .08,
        colorYellow, textDegreeSlctd, 12
    )

    local requiredFPM = 0
    if selectedTime > 0 then
        requiredFPM = math.ceil(selectedAltitude / selectedTime)
    end
    local requiredFPMtext = "req:\n" .. requiredFPM .. " fpm"

    gui_outputTextBox_create("requiredFPM", "MainMenu", "Sprites/invisibleBox.png",
        .33, .8, "CC",
        globApp.safeScreenArea.w * .2, globApp.safeScreenArea.h * .1,
        colorYellow, requiredFPMtext, 12
    )

    local requiredDistance = 0
    if selectedDegree > 0 and selectedAltitude > 0 then
        requiredDistance = math.floor(selectedAltitude / (math.tan(math.rad(selectedDegree)) * 6076.115) + 0.5)
    end
    local requiredDistText = "req dist:\n" .. requiredDistance .. " nm"

    gui_outputTextBox_create("requiredDistance", "MainMenu", "Sprites/invisibleBox.png",
        .66, .8, "CC",
        globApp.safeScreenArea.w * .2, globApp.safeScreenArea.h * .1,
        colorYellow, requiredDistText, 12
    )

    ---------------------------------------------------------------------------
    -- ROTARY KNOB
    ---------------------------------------------------------------------------
    gui_dualRotaryKnob_create(
        "runwayKnob", "MainMenu",
        0.26, 0.30, "CC",
        globApp.safeScreenArea.w * 0.47,
        -- Outer knob: wind direction (36 detents, 360°/10°/20°…/350°)
        36, 0,
        "Sprites/knob_runway_released.png", "Sprites/runwayNumber_pushed.png",
        "mainKnobChanged",
        36, 0,
        "Sprites/knob_wind_released.png", "Sprites/knob_wind_pushed.png",
        "windKnobChanged",
        -- Inner knob: runway (36 detents, RWY 36/01/02…/35)
        
        true
    )

    gui_outputTextBox_create("crosswindData", "MainMenu", "Sprites/invisibleBox.png",
        .26, .435, "CT",
        globApp.safeScreenArea.w * .46, globApp.safeScreenArea.h * .12,
        colorYellow, "WIND: 36000KT", 11
    )


    ----------------------------------------------------------------------------
    --SCROLLBARS
    ----------------------------------------------------------------------------

  local scrollbarSprites = {
    up_active = "Libraries/jp_GUI_library/librarySprites/jpLoveGUI_UpArrowButton_pushed.png",
    up_inactive = "Libraries/jp_GUI_library/librarySprites/jpLoveGUI_UpArrowButton_released.png",
    down_active = "Libraries/jp_GUI_library/librarySprites/jpLoveGUI_downArrowButton_pushed.png",
    down_inactive = "Libraries/jp_GUI_library/librarySprites/jpLoveGUI_downArrowButton_released.png",
    left_active = "Libraries/jp_GUI_library/librarySprites/jpLoveGUI_leftArrowButton_pushed.png",
    left_inactive = "Libraries/jp_GUI_library/librarySprites/jpLoveGUI_leftArrowButton_released.png",
    right_active = "Libraries/jp_GUI_library/librarySprites/jpLoveGUI_rightArrowButton_pushed.png",
    right_inactive = "Libraries/jp_GUI_library/librarySprites/jpLoveGUI_rightArrowButton_released.png",
    thumb = "Sprites/screw.png",
    frame = "Sprites/txtBox001_NotFocused.png"
   }


    --LEFT TO RIGHT
    gui_scrollBar_create ("timeScale", "MainMenu",
        0.16, 0.65, 30, 185, "CT", 5, 26, 1,
        "independent", "vertical", 26, "roundSelectedTime", {frame =  "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"},true)

    gui_scrollBar_create ("altScale", "MainMenu",
        0.50, 0.65, 30, 185, "CT", 5, 52, 1,
        "independent", "vertical", 52, "roundSelectedAltitude", {frame =  "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"},true)

    gui_scrollBar_create ("deg", "MainMenu",
        0.82, 0.65, 30, 185, "CT", 5, 33, 1,
        "independent", "vertical", 33, "roundSelectedDegree", {frame =  "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"},true)

    local knobSize    = globApp.safeScreenArea.w * 0.45
    local windSBTopY  = 0.32 - (knobSize * 0.5) / globApp.safeScreenArea.h
    local windGustSBX = 0.62 + 35 / globApp.safeScreenArea.w
    gui_scrollBar_create ("windSpeed", "MainMenu",
        0.62, windSBTopY, 30, math.floor(knobSize), "CT", 5, 46, 1,
        "independent", "vertical", 46, "windSpeedChanged",
        {frame = "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"}, true)

    gui_scrollBar_create ("windGust", "MainMenu",
        windGustSBX, windSBTopY, 30, math.floor(knobSize), "CT", 5, 61, 1,
        "independent", "vertical", 61, "windGustChanged",
        {frame = "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"}, true)

    local windLabelY = windSBTopY + math.floor(knobSize) / globApp.safeScreenArea.h + 0.025
    gui_outputTextBox_create("windSpeedGustLabel", "MainMenu", "Sprites/invisibleBox.png",
        (0.62 + windGustSBX) / 2, windLabelY, "CT",
        90, globApp.safeScreenArea.h * 0.065,
        colorYellow, "wind:\nspeed  gust", 12
    )



    page_switch("IntialBooting", 3, 2, false)

    font = love.graphics.newFont(20)
    love.graphics.setFont(font)

    -- Initialize starting time
    timer.t = 0

    -- Load beep sound
    beepSound = love.audio.newSource("Sounds/beep.wav", "static")

    selectedAltitude = 0
    selectedTime = 0
end

function love.update(dt)
    -- Update UTC clock string only when the second changes
    utc = os.date("!*t")
    if utc.sec ~= lastUtcSec then
        utcPrintString = string.format(
            "UTC:\n%04d-%02d-%02d\n%02d:%02d:%02d",
            utc.year, utc.month, utc.day, utc.hour, utc.min, utc.sec
        )
        lastUtcSec = utc.sec
        gui_updateOutputTextBoxText("utcData", utcPrintString)
    end

    if timer.t ~= _prevTimerT or timer.mode ~= _prevTimerMode then
        gui_updateOutputTextBoxText("timerTopRight", timer.mode .. "\nTIMER:\nM " .. format_time(timer.t) .. " S")
        _prevTimerT, _prevTimerMode = timer.t, timer.mode
    end

    if selectedAltitude ~= _prevAltitude then
        gui_updateOutputTextBoxText("selectedAltitudeBox", "Alt:\n" .. selectedAltitude .. " FT")
        _prevAltitude = selectedAltitude
    end

    if selectedTime ~= _prevTime then
        gui_updateOutputTextBoxText("selectedTimeBox", "time:\n" .. selectedTime .. " min")
        _prevTime = selectedTime
    end

    if selectedDegree ~= _prevDegree then
        gui_updateOutputTextBoxText("selectedDegreeBox", "deg:\n" .. string.format("%.2f", selectedDegree) .. "°")
        _prevDegree = selectedDegree
    end

    if selectedAltitude ~= _prevAltitude or selectedTime ~= _prevTime then
        local requiredFPM = 0
        if selectedTime > 0 then requiredFPM = math.ceil(selectedAltitude / selectedTime) end
        gui_updateOutputTextBoxText("requiredFPM", "req:\n" .. requiredFPM .. " fpm")
    end

    if selectedAltitude ~= _prevAltitude or selectedDegree ~= _prevDegree then
        local requiredDistance = 0
        if selectedDegree > 0 and selectedAltitude > 0 then
            requiredDistance = math.floor(selectedAltitude / (math.tan(math.rad(selectedDegree)) * 6076.115) + 0.5)
        end
        gui_updateOutputTextBoxText("requiredDistance", "req dist:\n" .. requiredDistance .. " nm")
    end

    -- Update sentinels for the combined checks above.
    _prevAltitude, _prevTime, _prevDegree = selectedAltitude, selectedTime, selectedDegree

    if selectedWindDirection ~= _prevWindDir or selectedWindSpeed ~= _prevWindSpeed or
       selectedWindGust ~= _prevWindGust or selectedKnobPos ~= _prevKnobPos then
        local windDir = string.format("%03d", selectedWindDirection)
        local windSpd = string.format("%02d", selectedWindSpeed)
        local hasGust = selectedWindGust > selectedWindSpeed
        local windLine
        if hasGust then
            windLine = "WIND: " .. windDir .. windSpd .. "G" .. string.format("%02d", selectedWindGust) .. "KT"
        else
            windLine = "WIND: " .. windDir .. windSpd .. "KT"
        end
        local rwyLine = "RWY: " .. string.format("%02d", selectedKnobPos)
        local susXW, susSide, susHT, susLabel = calcWindComponents(selectedWindDirection, selectedWindSpeed, selectedKnobPos * 10)
        local susLine = "SUS XW:" .. susXW .. susSide .. " " .. susLabel .. ":" .. susHT
        local crosswindText = windLine .. "\n" .. rwyLine .. "\n" .. susLine
        if hasGust then
            local gstXW, gstSide, gstHT, gstLabel = calcWindComponents(selectedWindDirection, selectedWindGust, selectedKnobPos * 10)
            crosswindText = crosswindText .. "\nGST XW:" .. gstXW .. gstSide .. " " .. gstLabel .. ":" .. gstHT
                         .. "\nGust Factor: " .. (selectedWindGust - selectedWindSpeed)
        end
        gui_updateOutputTextBoxText("crosswindData", crosswindText)
        _prevWindDir, _prevWindSpeed, _prevWindGust, _prevKnobPos =
            selectedWindDirection, selectedWindSpeed, selectedWindGust, selectedKnobPos
    end

    -- Update GUI
    jpGUI_update(dt)

    if blink.active == false then
            gui_button_setState( "acknowlegeAlarm", "deactivated" )
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
                gui_button_setState("acknowlegeAlarm", "released")
                alarmButtonsDeactivation()
                for _, btn in ipairs(globApp.objects.buttons) do
                    if btn.name == "pauseRHTopTimer" and btn.state == globApp.BUTTON_STATES.PRESSED then
                        btn.state = globApp.BUTTON_STATES.RELEASED
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
                globApp.appColor = colorRed -- red
                -- Vibrate device if capable
                if love.system.vibrate then
                    love.system.vibrate(0.1) -- short vibration
                end
                -- Play beep sound
                if beepSound then
                    love.audio.play(beepSound)
                end
            else
                globApp.appColor = colorGray -- normal gray
            end
        end
    end

    --handles play button state during countdown based on timer
    if timer.t <= 0 then 
        for _, btn in ipairs(globApp.objects.buttons) do
            if btn.name == "modeSelectRHTopTimer" and btn.state == globApp.BUTTON_STATES.PRESSED then
                gui_button_setState ( "pauseRHTopTimer", "deactivated")
            end
        end
    end
end

function love.draw()
    drawPages()
    jpGUI_draw ()
    
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
    -- TEXT BOXES
    ---------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------
    -- SCROLLBARS
    ----------------------------------------------------------------------------




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

    gui_button_setState( "modeSelectRHTopTimer", "deactivated" )
    gui_button_setState( "incrsMinRHTopTimer", "deactivated" )
    gui_button_setState( "dcrsMinRHTopTimer", "deactivated" )
    gui_button_setState( "incrsSecRHTopTimer", "deactivated" )
    gui_button_setState( "dcrsSecRHTopTimer", "deactivated" )
    gui_button_setState( "pauseRHTopTimer", "deactivated" )
    gui_button_setState( "resetRHTopTimer", "deactivated" )

end

function alarmAcklgBtnsActiation ()

    gui_button_setState( "modeSelectRHTopTimer", "pushed" )
    gui_button_setState( "incrsMinRHTopTimer", "released" )
    gui_button_setState( "dcrsMinRHTopTimer", "released" )
    gui_button_setState( "incrsSecRHTopTimer", "released" )
    gui_button_setState( "dcrsSecRHTopTimer", "released" )
    gui_button_setState( "pauseRHTopTimer", "released" )
    gui_button_setState( "resetRHTopTimer", "released" )

end


function resetRHTopTimer()
    timer.running = false
    if timer.mode == "COUNT DOWN" then
        timer.t = lastSavedCountDownTime
        gui_button_setState ("pauseRHTopTimer", "released")
    else
        timer.t = 0
    end
    blink.active = false -- stop blink
    globApp.appColor = {0.2, 0.2, 0.2, 1} -- keep normal color
    for _, btn in ipairs(globApp.objects.buttons) do
        if btn.name == "pauseRHTopTimer" and btn.state == globApp.BUTTON_STATES.PRESSED then
btn.state = globApp.BUTTON_STATES.RELEASED
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
        gui_button_setState( "incrsMinRHTopTimer", "released" )
        gui_button_setState( "dcrsMinRHTopTimer", "released" )
        gui_button_setState( "incrsSecRHTopTimer", "released" )
        gui_button_setState( "dcrsSecRHTopTimer", "released" )
        timer.t = lastSavedCountDownTime
    else
        timer.t = 0
        gui_button_setState( "incrsMinRHTopTimer", "deactivated" )
        gui_button_setState( "dcrsMinRHTopTimer", "deactivated" )
        gui_button_setState( "incrsSecRHTopTimer", "deactivated" )
        gui_button_setState( "dcrsSecRHTopTimer", "deactivated" )
        gui_button_setState( "pauseRHTopTimer", "released")
    end

    -- for _, btn in ipairs(lib_buttons) do
    --     if btn.name == "pauseRHTopTimer" and btn.state == globApp.BUTTON_STATES.PRESSED then
    --         btn.state = 1
    --     end
    -- end

    timer.running = false
end

function saveCountdownTime()
    lastSavedCountDownTime = math.max(0, timer.t)
end

function roundSelectedAltitude (pos)
    selectedAltitude = math.max(0, math.floor(51 * (1 - pos) + 0.5)) * 1000
end


function roundSelectedTime (pos)
    selectedTime = math.max(0, math.floor(25 * (1 - pos) + 0.5))
end

function roundSelectedDegree (pos)
    selectedDegree = math.floor(32 * (1 - pos) + 0.5) * 0.25
end

function calcWindComponents(windDir, windSpd, rwyHeading)
    local relAngle = math.rad(windDir - rwyHeading)
    local sinA = math.sin(relAngle)
    local cosA = math.cos(relAngle)
    local xw    = math.abs(math.floor(windSpd * sinA + 0.5))
    local ht    = math.floor(windSpd * cosA + 0.5)
    local side  = (sinA >= 0) and "R" or "L"
    local label = (ht >= 0) and "HW" or "TW"
    return xw, side, math.abs(ht), label
end

function windSpeedChanged(pos)
    selectedWindSpeed = math.floor(45 * (1 - pos) + 0.5)
end

function windGustChanged(pos)
    local range = 60 - selectedWindSpeed
    selectedWindGust = selectedWindSpeed + math.floor(range * (1 - pos) + 0.5)
end

-- Inner knob callback: runway selector.
-- Detent 0 (12 o'clock) = RWY 36; detents 1-35 = RWY 01-35 clockwise.
function mainKnobChanged(pos)
    local index     = math.floor(pos * 36 + 0.5) % 36
    selectedKnobPos = (index == 0) and 36 or index
end

-- Outer knob callback: wind direction.
-- Same detent layout as runway but values are runway × 10 (10°–360°).
-- Detent 0 (12 o'clock) = 360°; detents 1-35 = 10°, 20°, …, 350°.
function windKnobChanged(pos)
    local index           = math.floor(pos * 36 + 0.5) % 36
    local runway          = (index == 0) and 36 or index
    selectedWindDirection = runway * 10
end

