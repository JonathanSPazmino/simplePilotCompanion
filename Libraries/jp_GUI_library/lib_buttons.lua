--[[
    Library: lib_buttons.lua
    Author: Jonathan Pazmino
    Description: Handles creation, state, drawing, and interaction for all GUI buttons.
]]

--------------------------------------------------------------------------------
-- LIBRARY TABLE
--------------------------------------------------------------------------------

globApp.objects.buttons = {}

--------------------------------------------------------------------------------
-- PRIVATE HELPER FUNCTIONS
--------------------------------------------------------------------------------

--[[ Returns the name of the currently active page. ]]
local function _getActivePageName()
    for _, page in ipairs(pages) do
        if page.index == globApp.currentPageIndex then
            return page.name
        end
    end
    return ""
end

--[[ Checks if a given coordinate (x, y) is within the bounds of a button. ]]
local function _isPressed(button, x, y)
    return x >= button.myx and x <= button.myMaxx and y >= button.myy and y <= button.myMaxy
end

--[[ Invokes a button's callback function if it exists. ]]
local function _executeCallback(button)
    if button.callbackFunc then
        -- _G is a table containing all global variables.
        -- This is a safe way to call a global function by its name stored as a string.
        local callback = _G[button.callbackFunc]
        if callback and type(callback) == "function" then
            callback(button.state)
        else
            print("Button '" .. button.name .. "' callback function '" .. button.callbackFunc .. "' not found.")
        end
    else
        -- This is not an error, some buttons might not have callbacks.
        -- print("Button '" .. button.name .. "' has no callback function assigned.")
    end
end


--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

--[[
    Creates a new button and adds it to the global button list.
]]
function gui_button_create(label, page, buttonType, imgPressed, imgReleased, imgDeactivated, x, y, anchorPoint, width, height, callbackFunc, initialState)
    local newButton = {}

    newButton.name = label
    newButton.page = page
    newButton.objectType = "button"
    newButton.type = buttonType -- "toggle" or "pushonoff"

    -- Store images in a sub-table for cleaner state-based drawing.
    newButton.images = {
        [globApp.BUTTON_STATES.DEACTIVATED] = love.graphics.newImage(imgDeactivated),
        [globApp.BUTTON_STATES.RELEASED] = love.graphics.newImage(imgReleased),
        [globApp.BUTTON_STATES.PRESSED] = love.graphics.newImage(imgPressed)
    }

    newButton.mywidth = width
    newButton.myheight = height
    newButton.anchorPoint = anchorPoint

    -- This position is updated in gui_buttons_update during a window resize.
    local myPositions = relativePosition(newButton.anchorPoint, x, y, newButton.mywidth, newButton.myheight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h)
    newButton.myx = myPositions[1]
    newButton.myy = myPositions[2]

    -- Pre-calculate scaling factors and max coordinates for efficiency.
    local baseImage = newButton.images[globApp.BUTTON_STATES.RELEASED] or newButton.images[globApp.BUTTON_STATES.PRESSED]
    newButton.factorWidth = newButton.mywidth / baseImage:getWidth()
    newButton.factorHeight = newButton.myheight / baseImage:getHeight()
    newButton.myMaxx = newButton.myx + newButton.mywidth
    newButton.myMaxy = newButton.myy + newButton.myheight

    newButton.deactivated = (initialState == globApp.BUTTON_STATES.DEACTIVATED)
    newButton.state = initialState
    newButton.callbackFunc = callbackFunc

    table.insert(globApp.objects.buttons, newButton)
    globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1
end

--[[
    Draws all buttons that belong to the specified page.
]]
function gui_buttons_draw(pageName)
    for _, button in ipairs(globApp.objects.buttons) do
        if button.page == pageName then
            local imageToDraw = button.images[button.state]
            if imageToDraw then
                love.graphics.draw(imageToDraw, button.myx, button.myy, 0, button.factorWidth, button.factorHeight)
            end
        end
    end
end

--[[
    Updates button positions and sizes when the window is resized.
]]
function gui_buttons_update()
    if globApp.resizeDetected then
        for _, btns in ipairs(globApp.objects.buttons) do
            if btns.objectType == "button" then
                if globApp.lastSafeScreenArea and globApp.lastSafeScreenArea.w > 0 then
                    local lastSafe = globApp.lastSafeScreenArea

                    -- Reverse engineer the original relative position from the absolute coordinates
                    local originalXRatio, originalYRatio
                    local anchor = string.upper(btns.anchorPoint)

                    if anchor == "LT" or anchor == "LC" or anchor == "LB" then
                        originalXRatio = (btns.myx - lastSafe.x) / lastSafe.w
                    elseif anchor == "CT" or anchor == "CC" or anchor == "CB" then
                        originalXRatio = (btns.myx + btns.mywidth / 2 - lastSafe.x) / lastSafe.w
                    elseif anchor == "RT" or anchor == "RC" or anchor == "RB" then
                        originalXRatio = (btns.myx + btns.mywidth - lastSafe.x) / lastSafe.w
                    end

                    if anchor == "LT" or anchor == "CT" or anchor == "RT" then
                        originalYRatio = (btns.myy - lastSafe.y) / lastSafe.h
                    elseif anchor == "LC" or anchor == "CC" or anchor == "RC" then
                        originalYRatio = (btns.myy + btns.myheight / 2 - lastSafe.y) / lastSafe.h
                    elseif anchor == "LB" or anchor == "CB" or anchor == "RB" then
                        originalYRatio = (btns.myy + btns.myheight - lastSafe.y) / lastSafe.h
                    end

                    -- Calculate size ratios relative to previous safe area
                    local oldWidthRatio = btns.mywidth / lastSafe.w
                    local oldHeightRatio = btns.myheight / lastSafe.h

                    -- Set new absolute size based on the new safe area
                    btns.mywidth = oldWidthRatio * globApp.safeScreenArea.w
                    btns.myheight = oldHeightRatio * globApp.safeScreenArea.h

                    -- Get new absolute position using the consistent relative values
                    local myPositions = relativePosition(
                        btns.anchorPoint, originalXRatio, originalYRatio,
                        btns.mywidth, btns.myheight,
                        globApp.safeScreenArea.x, globApp.safeScreenArea.y,
                        globApp.safeScreenArea.w, globApp.safeScreenArea.h
                    )

                    btns.myx = myPositions[1]
                    btns.myy = myPositions[2]

                    -- Update derived properties
                    local baseImage = btns.images[globApp.BUTTON_STATES.RELEASED] or btns.images[globApp.BUTTON_STATES.PRESSED]
                    btns.factorWidth = btns.mywidth / baseImage:getWidth()
                    btns.factorHeight = btns.myheight / baseImage:getHeight()
                    btns.myMaxx = btns.myx + btns.mywidth
                    btns.myMaxy = btns.myy + btns.myheight
                end
            end
        end
    end
end

--[[
    Handles the logic for when a mouse button or touch event is pressed down.
]]
function gui_button_pressed(x, y, button, istouch)
    -- We only care about left-click or a touch event.
    if button ~= 1 then return end

    local activePageName = _getActivePageName()

    for _, p in ipairs(globApp.objects.buttons) do
        if p.page == activePageName and p.state ~= globApp.BUTTON_STATES.DEACTIVATED and _isPressed(p, x, y) then
            if p.type == "toggle" then
                if p.state == globApp.BUTTON_STATES.RELEASED then
                    p.state = globApp.BUTTON_STATES.PRESSED
                    _executeCallback(p)
                elseif p.state == globApp.BUTTON_STATES.PRESSED then
                    p.state = globApp.BUTTON_STATES.RELEASED
                    _executeCallback(p)
                end
            elseif p.type == "pushonoff" then
                if p.state == globApp.BUTTON_STATES.RELEASED then
                    p.state = globApp.BUTTON_STATES.PRESSED
                    -- For pushonoff, callback is usually on release.
                end
            end
        end
    end
end

--[[
    Handles the logic for when a mouse button or touch event is released.
]]
function gui_button_released(x, y, button, istouch)
    if button ~= 1 then return end

    local activePageName = _getActivePageName()
    for _, p in ipairs(globApp.objects.buttons) do
        if p.page == activePageName and p.type == "pushonoff" then
            if p.state == globApp.BUTTON_STATES.PRESSED then
                p.state = globApp.BUTTON_STATES.RELEASED
                _executeCallback(p)
            end
        end
    end
end

--[[
    Sets the state of a specific button by its name.
    States: "deactivated", "released", "pushed"
]]
function gui_button_setState(buttonName, state)
    local targetState
    if state == "deactivated" then
        targetState = globApp.BUTTON_STATES.DEACTIVATED
    elseif state == "released" then
        targetState = globApp.BUTTON_STATES.RELEASED
    elseif state == "pushed" then
        targetState = globApp.BUTTON_STATES.PRESSED
    else
        return -- Invalid state string
    end

    for _, b in ipairs(globApp.objects.buttons) do
        if b.name == buttonName then
            b.state = targetState
            b.deactivated = (targetState == globApp.BUTTON_STATES.DEACTIVATED)
            return
        end
    end
end