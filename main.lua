--[[ Main.lua
    Author: Jonathan Pazmino
    Description: Core entry file for LÖVE app with timer and GUI integration
]]

io.stdout:setvbuf("no")

-------------------------------------------------------------------------------
-- LIBRARIES LOAD
-------------------------------------------------------------------------------
require("Libraries.jp_GUI_library.loader_gdsGuiLib")

APP_VERSION = "1.0.0"

-- Create base pages
globApp.appColor = {.2, .2, .2, 1} --initializes bg color
gdsGui_page_create(3, "MainMenu",           false, false, globApp.appColor, 12, 0, {.5, 1, .6, .6, "LT"}, "max")
gdsGui_page_create(4, "TermsAndConditions", false, false, globApp.appColor, 12, 0, {.5, 1, .6, .6, "LT"}, "max")

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

-- App settings (persisted across sessions): loaded from appSettings.lua if it exists
appSettings = {}

-------------------------------------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------------------------------------

-- Format seconds into mm:ss
function format_time(s)
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
    -- CONTAINERS (created first; widgets self-register during creation)
    ---------------------------------------------------------------------------
    gdsGui_container_create("timerPanel", "MainMenu", "UTC / TIMER",   32, 0)
    gdsGui_container_create("windPanel",  "MainMenu", "RUNWAY / WIND", 32, 0)
    gdsGui_container_create("calcPanel",  "MainMenu", "CALCULATIONS",  32, 0)

    ---------------------------------------------------------------------------
    -- BUTTONS
    -- w/h are fractions of containerRefWidth / containerRefHeight.
    -- For square sprites keep pixW == pixH: h = w * (refW / refH) ≈ w * (320/585).
    -- Small control buttons target ~8% of container width → w=0.08, h=0.044.
    ---------------------------------------------------------------------------
    gdsGui_button_create("resetRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/resetButton_pushed.png", "Sprites/resetButton_released.png",
        "Sprites/resetButton_deactivated.png", 0.90, 0.15, "RT",
        0.08, 0.044,
        "resetRHTopTimer", globApp.BUTTON_STATES.RELEASED, true, "timerPanel"
    )

    gdsGui_button_create("pauseRHTopTimer", "MainMenu", "toggle",
        "Sprites/pausePlayButton_pressed.png", "Sprites/pausePlayButton_released.png",
        "Sprites/pausePlayButton_deactivated.png", 0.75, 0.15, "CT",
        0.08, 0.044,
        "pauseRHTopTimer", globApp.BUTTON_STATES.RELEASED, true, "timerPanel"
    )

    gdsGui_button_create("modeSelectRHTopTimer", "MainMenu", "toggle",
        "Sprites/timerModeButton_down.png", "Sprites/timerModeButton_up.png",
        "Sprites/timerModeButton_deactivated.png", 0.60, 0.15, "LT",
        0.08, 0.044,
        "modeSelectRHTopTimer", globApp.BUTTON_STATES.RELEASED, true, "timerPanel"
    )

    gdsGui_button_create("incrsMinRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/minIncreaseButton_pressed.png", "Sprites/minIncreaseButton_released.png",
        "Sprites/invisibleBox.png", 0.50, 0.05, "LT",
        0.08, 0.044,
        "incrsMinRHTopTimer", globApp.BUTTON_STATES.DEACTIVATED, true, "timerPanel"
    )

    gdsGui_button_create("dcrsMinRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/minDecreaseButton_pressed.png", "Sprites/minDecreaseButton_released.png",
        "Sprites/invisibleBox.png", 0.50, 0.15, "LT",
        0.08, 0.044,
        "dcrsMinRHTopTimer", globApp.BUTTON_STATES.DEACTIVATED, true, "timerPanel"
    )

    gdsGui_button_create("incrsSecRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/secIncreaseButton_pressed.png", "Sprites/secIncreaseButton_released.png",
        "Sprites/invisibleBox.png", 0.92, 0.05, "LT",
        0.08, 0.044,
        "incrsSecRHTopTimer", globApp.BUTTON_STATES.DEACTIVATED, true, "timerPanel"
    )

    gdsGui_button_create("dcrsSecRHTopTimer", "MainMenu", "pushonoff",
        "Sprites/secDecreaseButton_pressed.png", "Sprites/secDecreaseButton_released.png",
        "Sprites/invisibleBox.png", 0.92, 0.15, "LT",
        0.08, 0.044,
        "dcrsSecRHTopTimer", globApp.BUTTON_STATES.DEACTIVATED, true, "timerPanel"
    )

    gdsGui_button_create("acknowlegeAlarm", "MainMenu", "pushonoff",
        "Sprites/ackButton_pushed.png", "Sprites/ackButton_released.png",
        "Sprites/invisibleBox.png",
        0.90, 0.05, "RT",
        0.30, 0.10,
        "acknowlegeAlarm", globApp.BUTTON_STATES.DEACTIVATED, true, "timerPanel"
    )

    ---------------------------------------------------------------------------
    -- TEXT BOXES
    ---------------------------------------------------------------------------
    gdsGui_outputTxtBox_create("utcData", "MainMenu", "Sprites/invisibleBox.png",
        0.05, 0.05, "LT",
        0.40, 0.10,
        colorYellow, utcPrintString, 12, "timerPanel"
    )

    local text = timer.mode .. "\nTIMER:\nM " .. format_time(timer.t) .. " S"
    gdsGui_outputTxtBox_create("timerTopRight", "MainMenu", "Sprites/invisibleBox.png",
        0.90, 0.05, "RT",
        0.30, 0.10,
        colorYellow, text, 12, "timerPanel"
    )

    local textAltSlctd = "Alt:\n" .. selectedAltitude .. " FT"
    gdsGui_outputTxtBox_create("selectedAltitudeBox", "MainMenu", "Sprites/invisibleBox.png",
        0.50, .08, "CC",
        0.20, 0.08,
        colorYellow, textAltSlctd, 12, "calcPanel"
    )

    local textTimeSlctd = "time:\n" .. selectedTime .. " min"
    gdsGui_outputTxtBox_create("selectedTimeBox", "MainMenu", "Sprites/invisibleBox.png",
        0.15, .08, "CC",
        0.20, 0.08,
        colorYellow, textTimeSlctd, 12, "calcPanel"
    )

    local textDegreeSlctd = "deg:\n" .. string.format("%.2f", selectedDegree) .. "°"
    gdsGui_outputTxtBox_create("selectedDegreeBox", "MainMenu", "Sprites/invisibleBox.png",
        0.82, .08, "CC",
        0.20, 0.08,
        colorYellow, textDegreeSlctd, 12, "calcPanel"
    )

    local requiredFPM = 0
    if selectedTime > 0 then
        requiredFPM = math.ceil(selectedAltitude / selectedTime)
    end
    local requiredFPMtext = "req:\n" .. requiredFPM .. " fpm"
    gdsGui_outputTxtBox_create("requiredFPM", "MainMenu", "Sprites/invisibleBox.png",
        0.33, 0.25, "CC",
        0.20, 0.10,
        colorYellow, requiredFPMtext, 12, "calcPanel"
    )

    local requiredDistance = 0
    if selectedDegree > 0 and selectedAltitude > 0 then
        requiredDistance = math.floor(selectedAltitude / (math.tan(math.rad(selectedDegree)) * 6076.115) + 0.5)
    end
    local requiredDistText = "req dist:\n" .. requiredDistance .. " nm"
    gdsGui_outputTxtBox_create("requiredDistance", "MainMenu", "Sprites/invisibleBox.png",
        0.66, 0.25, "CC",
        0.20, 0.10,
        colorYellow, requiredDistText, 12, "calcPanel"
    )

    ---------------------------------------------------------------------------
    -- ROTARY KNOB
    -- size is now a fraction of containerRefWidth (0.47 → 47% of panel width).
    ---------------------------------------------------------------------------
    gdsGui_rotaryKnob_createDual(
        "runwayKnob", "MainMenu",
        0.05, 0.05, "LT",
        0.47,
        36, 0,
        "Sprites/knob_runway_released.png", "Sprites/runwayNumber_pushed.png",
        "mainKnobChanged",
        36, 0,
        "Sprites/knob_wind_released.png", "Sprites/knob_wind_pushed.png",
        "windKnobChanged",
        true, "windPanel"
    )

    gdsGui_outputTxtBox_create("crosswindData", "MainMenu", "Sprites/invisibleBox.png",
        0.26, 0.35, "CT",
        0.46, 0.12,
        colorYellow, "WIND: 36000KT", 11, "windPanel"
    )

    ----------------------------------------------------------------------------
    -- SCROLLBARS
    -- w/h are fractions of containerRefWidth / containerRefHeight.
    -- calcPanel bars: w=0.094 (30/320), h=0.316 (185/585).
    -- windPanel bars: w=0.094, h=0.246 (≈144px ÷ 585).
    -- windSBTopY aligns bar top with knob top: knobCenterY(0.30) - knobH/2,
    -- where knobH = 0.47*refW/refH ≈ 0.257 → top ≈ 0.30 - 0.129 = 0.171.
    ----------------------------------------------------------------------------
    gdsGui_scrollBar_create("timeScale", "MainMenu",
        0.16, .12, 0.094, 0.316, "CT", 5, 26, 1,
        "independent", "vertical", 26, "roundSelectedTime",
        {frame = "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"}, true, "calcPanel")

    gdsGui_scrollBar_create("altScale", "MainMenu",
        0.50, .12, 0.094, 0.316, "CT", 5, 52, 1,
        "independent", "vertical", 52, "roundSelectedAltitude",
        {frame = "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"}, true, "calcPanel")

    gdsGui_scrollBar_create("deg", "MainMenu",
        0.82, .12, 0.094, 0.316, "CT", 5, 33, 1,
        "independent", "vertical", 33, "roundSelectedDegree",
        {frame = "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"}, true, "calcPanel")

    gdsGui_scrollBar_create("windSpeed", "MainMenu",
        0.7, 0.05, 0.094, .30, "CT", 5, 46, 1,
        "independent", "vertical", 46, "windSpeedChanged",
        {frame = "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"}, true, "windPanel")

    gdsGui_scrollBar_create("windGust", "MainMenu",
        0.86, 0.05, 0.094, .30, "CT", 5, 61, 1,
        "independent", "vertical", 61, "windGustChanged",
        {frame = "Sprites/scrollbar_bg.png", thumb = "Sprites/scrollbar_thumb_3.png"}, true, "windPanel")

    gdsGui_outputTxtBox_create("windSpeedGustLabel", "MainMenu", "Sprites/invisibleBox.png",
        0.78, 0.36, "CT",
        0.281, 0.07,
        colorYellow, "wind:\nspeed  gust", 12, "windPanel"
    )



    ---------------------------------------------------------------------------
    -- CONTAINERS
    ---------------------------------------------------------------------------
    gdsGui_container_finalise("MainMenu")

    gdsGui_saveLoad_loadFileContents("appSettings.lua")

    local showTC = (appSettings.tcAcceptedVersion ~= APP_VERSION)
    gdsGui_page_switch("IntialBooting", showTC and 4 or 3, 2, false)

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
        gdsGui_outputTxtBox_setText("utcData", utcPrintString)
    end

    if timer.t ~= _prevTimerT or timer.mode ~= _prevTimerMode then
        gdsGui_outputTxtBox_setText("timerTopRight", timer.mode .. "\nTIMER:\nM " .. format_time(timer.t) .. " S")
        _prevTimerT, _prevTimerMode = timer.t, timer.mode
    end

    local altChanged    = selectedAltitude ~= _prevAltitude
    local timeChanged   = selectedTime     ~= _prevTime
    local degreeChanged = selectedDegree   ~= _prevDegree

    if altChanged then
        gdsGui_outputTxtBox_setText("selectedAltitudeBox", "Alt:\n" .. selectedAltitude .. " FT")
    end

    if timeChanged then
        gdsGui_outputTxtBox_setText("selectedTimeBox", "time:\n" .. selectedTime .. " min")
    end

    if degreeChanged then
        gdsGui_outputTxtBox_setText("selectedDegreeBox", "deg:\n" .. string.format("%.2f", selectedDegree) .. "°")
    end

    if altChanged or timeChanged then
        local requiredFPM = 0
        if selectedTime > 0 then requiredFPM = math.ceil(selectedAltitude / selectedTime) end
        gdsGui_outputTxtBox_setText("requiredFPM", "req:\n" .. requiredFPM .. " fpm")
    end

    if altChanged or degreeChanged then
        local requiredDistance = 0
        if selectedDegree > 0 and selectedAltitude > 0 then
            requiredDistance = math.floor(selectedAltitude / (math.tan(math.rad(selectedDegree)) * 6076.115) + 0.5)
        end
        gdsGui_outputTxtBox_setText("requiredDistance", "req dist:\n" .. requiredDistance .. " nm")
    end

    _prevAltitude, _prevTime, _prevDegree = selectedAltitude, selectedTime, selectedDegree

    if selectedWindDirection ~= _prevWindDir or selectedWindSpeed ~= _prevWindSpeed or
       selectedWindGust ~= _prevWindGust or selectedKnobPos ~= _prevKnobPos then
        local rwyDeg = selectedKnobPos * 10
        local susXW, susSide, susHT, susLabel = calcWindComponents(selectedWindDirection, selectedWindSpeed, rwyDeg)
        local crosswindText
        if selectedWindGust > selectedWindSpeed then
            local gstXW, gstSide, gstHT, gstLabel = calcWindComponents(selectedWindDirection, selectedWindGust, rwyDeg)
            crosswindText = string.format(
                "WIND: %03d%02dG%02dKT\nRWY: %02d\nSUS XW:%d%s %s:%d\nGST XW:%d%s %s:%d\nGust Factor: %d",
                selectedWindDirection, selectedWindSpeed, selectedWindGust,
                selectedKnobPos,
                susXW, susSide, susLabel, susHT,
                gstXW, gstSide, gstLabel, gstHT,
                selectedWindGust - selectedWindSpeed)
        else
            crosswindText = string.format(
                "WIND: %03d%02dKT\nRWY: %02d\nSUS XW:%d%s %s:%d",
                selectedWindDirection, selectedWindSpeed,
                selectedKnobPos,
                susXW, susSide, susLabel, susHT)
        end
        gdsGui_outputTxtBox_setText("crosswindData", crosswindText)
        _prevWindDir, _prevWindSpeed, _prevWindGust, _prevKnobPos =
            selectedWindDirection, selectedWindSpeed, selectedWindGust, selectedKnobPos
    end

    -- Update GUI
    gdsGui_update(dt)

    if blink.active == false then
            gdsGui_button_setState( "acknowlegeAlarm", "deactivated" )
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
                gdsGui_button_setState("acknowlegeAlarm", "released")
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
                gdsGui_button_setState ( "pauseRHTopTimer", "deactivated")
            end
        end
    end
end

function love.draw()
    drawPages()
    gdsGui_draw ()
    
end

-------------------------------------------------------------------------------
-- PAGE DRAWING
-------------------------------------------------------------------------------
function drawPages()
    gdsGui_page_drawBackground()
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

    gdsGui_button_setState( "modeSelectRHTopTimer", "deactivated" )
    gdsGui_button_setState( "incrsMinRHTopTimer", "deactivated" )
    gdsGui_button_setState( "dcrsMinRHTopTimer", "deactivated" )
    gdsGui_button_setState( "incrsSecRHTopTimer", "deactivated" )
    gdsGui_button_setState( "dcrsSecRHTopTimer", "deactivated" )
    gdsGui_button_setState( "pauseRHTopTimer", "deactivated" )
    gdsGui_button_setState( "resetRHTopTimer", "deactivated" )

end

function alarmAcklgBtnsActiation ()

    gdsGui_button_setState( "modeSelectRHTopTimer", "pushed" )
    gdsGui_button_setState( "incrsMinRHTopTimer", "released" )
    gdsGui_button_setState( "dcrsMinRHTopTimer", "released" )
    gdsGui_button_setState( "incrsSecRHTopTimer", "released" )
    gdsGui_button_setState( "dcrsSecRHTopTimer", "released" )
    gdsGui_button_setState( "pauseRHTopTimer", "released" )
    gdsGui_button_setState( "resetRHTopTimer", "released" )

end


function resetRHTopTimer()
    timer.running = false
    if timer.mode == "COUNT DOWN" then
        timer.t = lastSavedCountDownTime
        gdsGui_button_setState ("pauseRHTopTimer", "released")
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
        gdsGui_button_setState( "incrsMinRHTopTimer", "released" )
        gdsGui_button_setState( "dcrsMinRHTopTimer", "released" )
        gdsGui_button_setState( "incrsSecRHTopTimer", "released" )
        gdsGui_button_setState( "dcrsSecRHTopTimer", "released" )
        timer.t = lastSavedCountDownTime
    else
        timer.t = 0
        gdsGui_button_setState( "incrsMinRHTopTimer", "deactivated" )
        gdsGui_button_setState( "dcrsMinRHTopTimer", "deactivated" )
        gdsGui_button_setState( "incrsSecRHTopTimer", "deactivated" )
        gdsGui_button_setState( "dcrsSecRHTopTimer", "deactivated" )
        gdsGui_button_setState( "pauseRHTopTimer", "released")
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
    return selectedAltitude
end


function roundSelectedTime (pos)
    selectedTime = math.max(0, math.floor(25 * (1 - pos) + 0.5))
    return selectedTime
end

function roundSelectedDegree (pos)
    selectedDegree = math.floor(32 * (1 - pos) + 0.5) * 0.25
    return selectedDegree
end

function calcWindComponents(windDir, windSpd, rwyHeading, devMode)
    local relAngle = math.rad(windDir - rwyHeading)
    local sinA = math.sin(relAngle)
    local cosA = math.cos(relAngle)
    local xw    = math.abs(math.floor(windSpd * sinA + 0.5))
    local ht    = math.floor(windSpd * cosA + 0.5)
    local side  = (sinA >= 0) and "R" or "L"
    local label = (ht >= 0) and "HW" or "TW"
    if devMode then return {xw, side, math.abs(ht), label} end
    return xw, side, math.abs(ht), label
end

function windSpeedChanged(pos)
    selectedWindSpeed = math.floor(45 * (1 - pos) + 0.5)
    return selectedWindSpeed
end

function windGustChanged(pos)
    local range = 60 - selectedWindSpeed
    selectedWindGust = selectedWindSpeed + math.floor(range * (1 - pos) + 0.5)
    return selectedWindGust
end

-- Inner knob callback: runway selector.
-- Detent 0 (12 o'clock) = RWY 36; detents 1-35 = RWY 01-35 clockwise.
function mainKnobChanged(pos)
    local index     = math.floor(pos * 36 + 0.5) % 36
    selectedKnobPos = (index == 0) and 36 or index
    return selectedKnobPos
end

-- Outer knob callback: wind direction.
-- Same detent layout as runway but values are runway × 10 (10°–360°).
-- Detent 0 (12 o'clock) = 360°; detents 1-35 = 10°, 20°, …, 350°.
function windKnobChanged(pos)
    local index           = math.floor(pos * 36 + 0.5) % 36
    local runway          = (index == 0) and 36 or index
    selectedWindDirection = runway * 10
    return selectedWindDirection
end

-------------------------------------------------------------------------------
-- TERMS AND CONDITIONS PAGE
-------------------------------------------------------------------------------

function createTermsAndConditionsObjects()
    local thisPageName = "TermsAndConditions"
    local tcText = love.filesystem.read("terms.txt") or "Terms and Conditions text not found."
    local btnW = gdsGui_general_smartScaling("inverse", 0.36, .54, .080, 0.12, 0.22, "width")
    local btnH = gdsGui_general_smartScaling("inverse", 0.36, .54, .080, 0.12, 0.22, "height")
    local libSprites = "Libraries/jp_GUI_library/librarySprites/"

    gdsGui_outputTxtBox_create("tcText", thisPageName, "Sprites/invisibleBox.png",
        .5, .44, "CC",
        globApp.safeScreenArea.w * 0.90, globApp.safeScreenArea.h * 0.72,
        {1, 1, 1, 1}, tcText,
        math.floor(gdsGui_general_smartFontScaling(0.04, 0.055))
    )

    -- Toggle: user acknowledgement of agreement
    gdsGui_button_create("tcAgreementToggle", thisPageName,
        "toggle",
        "Sprites/timerModeButton_down.png",
        "Sprites/timerModeButton_up.png",
        "Sprites/timerModeButton_deactivated.png",
        0.28, 0.91, "CC",
        btnW, btnH,
        "tcAgreementToggled", 1)

    -- PushOnOff: continue to main menu (locked until toggle is acknowledged)
    gdsGui_button_create("tcContinueButton", thisPageName,
        "pushonoff",
        (libSprites .. "jpLoveGUI_yesConfirmButton_pushed.png"),
        (libSprites .. "jpLoveGUI_yesConfirmButton_released.png"),
        (libSprites .. "jpLoveGUI_yesConfirmButton_deactivated.png"),
        0.72, 0.91, "CC",
        btnW, btnH,
        "tcContinuePressed", globApp.BUTTON_STATES.DEACTIVATED)
end

createTermsAndConditionsObjects()

function tcAgreementToggled(newState)
    if newState == globApp.BUTTON_STATES.PRESSED then
        gdsGui_button_setState("tcContinueButton", "released")
    else
        gdsGui_button_setState("tcContinueButton", "deactivated")
    end
end

function tcContinuePressed()
    appSettings.tcAcceptedVersion = APP_VERSION
    love.filesystem.write("appSettings.lua", table.show(appSettings, "appSettings"))
    gdsGui_page_switch("LoadingMainMenu", 3, 1, false)
end

-------------------------------------------------------------------------------
-- APP-SPECIFIC UNIT TESTS
-- Registered here (top-level, after all app functions are defined) so both
-- the "gui" and "app" suites exist when gdsGui_dev_createUnitTestObjects()
-- builds the devUnitTest table below.
-------------------------------------------------------------------------------
gdsGui_unitTests_registerSuite("app", function()

    --------------------------------------------------------------------------
    --  format_time
    --------------------------------------------------------------------------
    gdsGui_dev_testExecute {["id"]="format_time_zero",
        ["funcName"]={"format_time"},
        ["funcParameters"]={0},
        ["funcExpctOutput"]={"00:00"}}

    gdsGui_dev_testExecute {["id"]="format_time_90sec",
        ["funcName"]={"format_time"},
        ["funcParameters"]={90},
        ["funcExpctOutput"]={"01:30"}}

    gdsGui_dev_testExecute {["id"]="format_time_3599sec",
        ["funcName"]={"format_time"},
        ["funcParameters"]={3599},
        ["funcExpctOutput"]={"59:59"}}

    gdsGui_dev_testExecute {["id"]="format_time_negative_clamps_to_zero",
        ["funcName"]={"format_time"},
        ["funcParameters"]={-5},
        ["funcExpctOutput"]={"00:00"}}

    --------------------------------------------------------------------------
    --  calcWindComponents  (returns {xw, side, ht, label} in devMode)
    --------------------------------------------------------------------------
    gdsGui_dev_testExecute {["id"]="calcWindComponents_direct_headwind",
        ["funcName"]={"calcWindComponents"},
        ["funcParameters"]={360, 20, 360},
        ["funcExpctOutput"]={0, "R", 20, "HW"}}

    gdsGui_dev_testExecute {["id"]="calcWindComponents_right_crosswind",
        ["funcName"]={"calcWindComponents"},
        ["funcParameters"]={90, 20, 360},
        ["funcExpctOutput"]={20, "R", 0, "HW"}}

    gdsGui_dev_testExecute {["id"]="calcWindComponents_direct_tailwind",
        ["funcName"]={"calcWindComponents"},
        ["funcParameters"]={180, 20, 360},
        ["funcExpctOutput"]={0, "L", 20, "TW"}}

    gdsGui_dev_testExecute {["id"]="calcWindComponents_left_crosswind",
        ["funcName"]={"calcWindComponents"},
        ["funcParameters"]={270, 20, 360},
        ["funcExpctOutput"]={20, "L", 0, "HW"}}

    gdsGui_dev_testExecute {["id"]="calcWindComponents_calm_wind",
        ["funcName"]={"calcWindComponents"},
        ["funcParameters"]={360, 0, 360},
        ["funcExpctOutput"]={0, "R", 0, "HW"}}

    gdsGui_dev_testExecute {["id"]="calcWindComponents_45deg_right_from_ahead",
        ["funcName"]={"calcWindComponents"},
        ["funcParameters"]={45, 20, 360},
        ["funcExpctOutput"]={14, "R", 14, "HW"}}

    gdsGui_dev_testExecute {["id"]="calcWindComponents_45deg_left_from_ahead",
        ["funcName"]={"calcWindComponents"},
        ["funcParameters"]={315, 20, 360},
        ["funcExpctOutput"]={14, "L", 14, "HW"}}

    --------------------------------------------------------------------------
    --  roundSelectedAltitude  (scrollbar top=0, bottom=1)
    --------------------------------------------------------------------------
    gdsGui_dev_testExecute {["id"]="roundSelectedAltitude_top_pos_51000ft",
        ["funcName"]={"roundSelectedAltitude"},
        ["funcParameters"]={0},
        ["funcExpctOutput"]={51000}}

    gdsGui_dev_testExecute {["id"]="roundSelectedAltitude_bottom_pos_0ft",
        ["funcName"]={"roundSelectedAltitude"},
        ["funcParameters"]={1},
        ["funcExpctOutput"]={0}}

    gdsGui_dev_testExecute {["id"]="roundSelectedAltitude_mid_pos_26000ft",
        ["funcName"]={"roundSelectedAltitude"},
        ["funcParameters"]={0.5},
        ["funcExpctOutput"]={26000}}

    --------------------------------------------------------------------------
    --  roundSelectedTime  (scrollbar top=0 → 25 min, bottom=1 → 0 min)
    --------------------------------------------------------------------------
    gdsGui_dev_testExecute {["id"]="roundSelectedTime_top_pos_25min",
        ["funcName"]={"roundSelectedTime"},
        ["funcParameters"]={0},
        ["funcExpctOutput"]={25}}

    gdsGui_dev_testExecute {["id"]="roundSelectedTime_bottom_pos_0min",
        ["funcName"]={"roundSelectedTime"},
        ["funcParameters"]={1},
        ["funcExpctOutput"]={0}}

    gdsGui_dev_testExecute {["id"]="roundSelectedTime_mid_pos_13min",
        ["funcName"]={"roundSelectedTime"},
        ["funcParameters"]={0.5},
        ["funcExpctOutput"]={13}}

    --------------------------------------------------------------------------
    --  roundSelectedDegree  (scrollbar top=0 → 8.0°, bottom=1 → 0°)
    --------------------------------------------------------------------------
    gdsGui_dev_testExecute {["id"]="roundSelectedDegree_top_pos_8deg",
        ["funcName"]={"roundSelectedDegree"},
        ["funcParameters"]={0},
        ["funcExpctOutput"]={8.0}}

    gdsGui_dev_testExecute {["id"]="roundSelectedDegree_bottom_pos_0deg",
        ["funcName"]={"roundSelectedDegree"},
        ["funcParameters"]={1},
        ["funcExpctOutput"]={0.0}}

    gdsGui_dev_testExecute {["id"]="roundSelectedDegree_mid_pos_4deg",
        ["funcName"]={"roundSelectedDegree"},
        ["funcParameters"]={0.5},
        ["funcExpctOutput"]={4.0}}

    --------------------------------------------------------------------------
    --  windSpeedChanged  (scrollbar top=0 → 45 kt, bottom=1 → 0 kt)
    --------------------------------------------------------------------------
    gdsGui_dev_testExecute {["id"]="windSpeedChanged_top_pos_45kt",
        ["funcName"]={"windSpeedChanged"},
        ["funcParameters"]={0},
        ["funcExpctOutput"]={45}}

    gdsGui_dev_testExecute {["id"]="windSpeedChanged_bottom_pos_0kt",
        ["funcName"]={"windSpeedChanged"},
        ["funcParameters"]={1},
        ["funcExpctOutput"]={0}}

    gdsGui_dev_testExecute {["id"]="windSpeedChanged_mid_pos_23kt",
        ["funcName"]={"windSpeedChanged"},
        ["funcParameters"]={0.5},
        ["funcExpctOutput"]={23}}

    --------------------------------------------------------------------------
    --  windGustChanged  (range relative to selectedWindSpeed; fixed at 0)
    --------------------------------------------------------------------------
    selectedWindSpeed = 0
    gdsGui_dev_testExecute {["id"]="windGustChanged_top_pos_60kt",
        ["funcName"]={"windGustChanged"},
        ["funcParameters"]={0},
        ["funcExpctOutput"]={60}}

    selectedWindSpeed = 0
    gdsGui_dev_testExecute {["id"]="windGustChanged_bottom_pos_0kt",
        ["funcName"]={"windGustChanged"},
        ["funcParameters"]={1},
        ["funcExpctOutput"]={0}}

    selectedWindSpeed = 0
    gdsGui_dev_testExecute {["id"]="windGustChanged_mid_pos_30kt",
        ["funcName"]={"windGustChanged"},
        ["funcParameters"]={0.5},
        ["funcExpctOutput"]={30}}

    --------------------------------------------------------------------------
    --  mainKnobChanged  (36 detents: pos=0 → RWY 36, 1/36 → RWY 01)
    --------------------------------------------------------------------------
    gdsGui_dev_testExecute {["id"]="mainKnobChanged_pos0_rwy36",
        ["funcName"]={"mainKnobChanged"},
        ["funcParameters"]={0},
        ["funcExpctOutput"]={36}}

    gdsGui_dev_testExecute {["id"]="mainKnobChanged_first_detent_rwy01",
        ["funcName"]={"mainKnobChanged"},
        ["funcParameters"]={1/36},
        ["funcExpctOutput"]={1}}

    gdsGui_dev_testExecute {["id"]="mainKnobChanged_mid_rwy18",
        ["funcName"]={"mainKnobChanged"},
        ["funcParameters"]={0.5},
        ["funcExpctOutput"]={18}}

    --------------------------------------------------------------------------
    --  windKnobChanged  (36 detents: pos=0 → 360°, 1/36 → 10°)
    --------------------------------------------------------------------------
    gdsGui_dev_testExecute {["id"]="windKnobChanged_pos0_360deg",
        ["funcName"]={"windKnobChanged"},
        ["funcParameters"]={0},
        ["funcExpctOutput"]={360}}

    gdsGui_dev_testExecute {["id"]="windKnobChanged_first_detent_10deg",
        ["funcName"]={"windKnobChanged"},
        ["funcParameters"]={1/36},
        ["funcExpctOutput"]={10}}

    gdsGui_dev_testExecute {["id"]="windKnobChanged_mid_180deg",
        ["funcName"]={"windKnobChanged"},
        ["funcParameters"]={0.5},
        ["funcExpctOutput"]={180}}

end)

-- Build the unit-test table widget now that both "gui" and "app" suites are registered.
gdsGui_dev_createUnitTestObjects()

