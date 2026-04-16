--[[
    Library: lib_rotaryKnobs.lua
    Author: Jonathan Pazmino
    Description: Handles creation, drawing, and interaction for rotary knob controls.
                 Knobs have discrete detent positions and are rotated by touch/mouse drag.
                 Architecture mirrors lib_buttons.lua / lib_scrollBar.lua.
]]

--------------------------------------------------------------------------------
-- LIBRARY TABLE
--------------------------------------------------------------------------------

globApp.objects.rotaryKnobs = {}

--------------------------------------------------------------------------------
-- PRIVATE CONSTANTS
--------------------------------------------------------------------------------

-- Full 360° circle: detents are distributed evenly with no hard stops.
-- Continuous rotation in either direction wraps from last detent back to first.
local _KNOB_FULL_CIRCLE = math.pi * 2

-- Absolute pixel radius below which touch-drag is ignored.
-- This prevents the atan2 singularity right at the pivot (where 1 px of movement
-- could represent a huge angle change).  Everything outside this tiny dead zone —
-- including well outside the knob circle — is fully tracked, so the user can drag
-- their finger far from the knob to achieve finer rotational precision.
-- (atan2 physics: same physical dx/dy → smaller angle delta at larger radius.)
local _KNOB_CENTER_DEAD_ZONE_PX = 6

--------------------------------------------------------------------------------
-- PRIVATE HELPERS
--------------------------------------------------------------------------------

local function _getActivePageName()
    for _, page in ipairs(pages) do
        if page.index == globApp.currentPageIndex then
            return page.name
        end
    end
    return ""
end

-- Convert a normalized position (0-1) to a draw angle in radians.
-- Position 0 → angle 0 → sprite drawn un-rotated (indicator at 12 o'clock if sprite
-- has indicator pointing up).  Positions increase clockwise around the full circle.
local function _positionToAngle(position)
    return position * _KNOB_FULL_CIRCLE
end

-- Snap a raw angle (radians, any value) to the nearest of N evenly-spaced detents
-- distributed around the full 360° circle.  Wraps past the last detent back to the
-- first, so the knob has no hard stops.
-- Returns: snappedPosition (0 to (N-1)/N), detentIndex (0-based integer, 0 to N-1).
local function _snapToDetent(rawAngle, numDetents)
    if numDetents < 1 then return 0, 0 end
    -- Normalise to [0, 2π) regardless of how many full rotations rawAngle contains.
    local normalized = rawAngle % _KNOB_FULL_CIRCLE
    -- Each detent spans 2π/N radians; find the nearest one and wrap the index.
    local rawIndex = normalized / _KNOB_FULL_CIRCLE * numDetents
    local index    = math.floor(rawIndex + 0.5) % numDetents
    return index / numDetents, index
end

-- (Re)compute all screen-space geometry from the knob's stored original values.
-- Called once at creation and again whenever the window is resized.
local function _calculateGeometry(knob)
    local dims = gui_getObjectScaledDimensions(
        knob.original.widthRatio,
        knob.original.heightRatio,
        knob.original.aspectRatio
    )
    knob.size = dims.width  -- knobs are square; width == height

    local pos = relativePosition(
        knob.original.anchorPoint,
        knob.original.x, knob.original.y,
        knob.size, knob.size,
        globApp.safeScreenArea.x, globApp.safeScreenArea.y,
        globApp.safeScreenArea.w, globApp.safeScreenArea.h
    )
    knob.x       = pos[1]
    knob.y       = pos[2]
    knob.centerX = knob.x + knob.size * 0.5
    knob.centerY = knob.y + knob.size * 0.5

    -- Pre-compute draw scale and image-space origin for rotation around center.
    -- Both sprites must be the same pixel dimensions; use imgReleased as reference.
    local iw, ih     = knob.imgReleased:getDimensions()
    knob.scaleX      = knob.size / iw
    knob.scaleY      = knob.size / ih
    knob.imgOriginX  = iw * 0.5
    knob.imgOriginY  = ih * 0.5
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

--[[
    Creates a new rotary knob and registers it in globApp.objects.rotaryKnobs.

    PARAMETERS
    id              string   — unique identifier
    page            string   — page name this knob belongs to
    x               number   — horizontal position as a fraction of the safe area (0-1)
    y               number   — vertical position as a fraction of the safe area (0-1)
    anchorPoint     string   — anchor point string (e.g. "CC", "LT", "RT"…)
    size            number   — knob diameter in pixels (use globApp.safeScreenArea.w * ratio)
    numDetents      number   — number of discrete click-stop positions (minimum 2)
    initialPosition number   — starting position as a fraction 0-1 (snapped to nearest detent)
    spriteReleased  string   — path to the knob sprite shown when the knob is NOT focused
    spriteFocused   string   — path to the knob sprite shown while the knob IS focused (held)
    callbackFunc    string   — name of a global function called with the current position (0-1)
                              whenever the selected detent changes
    hapticEnabled   boolean  — whether haptic feedback fires on the initial tap
]]
function gui_rotaryKnob_create(id, page, x, y, anchorPoint, size, numDetents, initialPosition, spriteReleased, spriteFocused, callbackFunc, hapticEnabled)

    local knob = {}

    knob.id            = id
    knob.page          = page
    knob.objectType    = "rotaryKnob"
    knob.numDetents    = math.max(2, numDetents)
    knob.hapticEnabled = (hapticEnabled == true)
    knob.callbackFunc  = callbackFunc
    knob.isFocused        = false
    knob.focusTouchId     = nil
    knob._prevDetentIndex = -1
    knob._grabAngleOffset = 0   -- angle between finger and knob.angle at press time

    -- Load the two knob face sprites (released = idle, focused = held/active).
    knob.imgReleased = love.graphics.newImage(spriteReleased)
    knob.imgFocused  = love.graphics.newImage(spriteFocused)

    -- Store original relative values so resize() can recalculate correctly.
    knob.original = {
        x           = x,
        y           = y,
        anchorPoint = anchorPoint,
        widthRatio  = size / globApp.safeScreenArea.w,
        heightRatio = size / globApp.safeScreenArea.h,
        aspectRatio = 1.0   -- knobs are always square
    }

    -- Snap the initial position (0-1 fraction of the circle) to the nearest detent.
    -- Convert to an angle first so _snapToDetent receives radians as expected.
    local clampedPos = math.max(0, math.min(1, initialPosition or 0))
    knob.position, knob.detentIndex = _snapToDetent(clampedPos * _KNOB_FULL_CIRCLE, knob.numDetents)
    knob.angle = _positionToAngle(knob.position)
    knob._prevDetentIndex = knob.detentIndex

    -- Compute initial screen-space geometry.
    _calculateGeometry(knob)

    -- Resize method — called by gui_handle_resize() on window size changes.
    function knob:resize()
        _calculateGeometry(self)
    end
    knob.resize = knob.resize

    table.insert(globApp.objects.rotaryKnobs, knob)
    globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1
end


--[[
    Draws all rotary knobs that belong to the specified page.
    The sprite switches between the released and focused images based on focus state.
    The sprite is drawn rotated around its center to reflect the current detent angle.
]]
function gui_rotaryKnob_draw(pageName)
    for _, knob in ipairs(globApp.objects.rotaryKnobs) do
        if knob.page == pageName then
            -- Select sprite based on whether the knob is currently held.
            local img = knob.isFocused and knob.imgFocused or knob.imgReleased
            love.graphics.setColor(1, 1, 1, 1)
            -- knob.angle = 0 at position 0 → sprite drawn un-rotated → indicator at 12 o'clock
            -- (assumes the sprite has its indicator pointing straight up in the image file).
            love.graphics.draw(
                img,
                knob.centerX, knob.centerY,       -- draw position = knob center
                knob.angle,                        -- rotation angle (radians)
                knob.scaleX,  knob.scaleY,         -- scale to fill the knob size
                knob.imgOriginX, knob.imgOriginY   -- rotate from image center
            )
            love.graphics.reset()
        end
    end
end


--[[
    Call from mouse/touch PRESSED handlers.
    Hit-tests the circular knob boundary, focuses the knob, and fires one haptic pulse.
    The initial press must land within the knob circle; subsequent drag is unrestricted.

    touchId  — "mouse" for mouse input, or the LÖVE touch id for touch input.
]]
function gui_rotaryKnob_pressed(touchId, x, y)
    local activePageName = _getActivePageName()
    for _, knob in ipairs(globApp.objects.rotaryKnobs) do
        if knob.page ~= activePageName then goto continue end

        -- Hit-test: initial press must land within the circular knob boundary.
        local dx   = x - knob.centerX
        local dy   = y - knob.centerY
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist <= knob.size * 0.5 then
            if not knob.isFocused then
                knob.isFocused        = true
                knob.focusTouchId     = touchId
                knob._prevDetentIndex = knob.detentIndex
                -- Record angular offset so the grab point follows the finger absolutely.
                knob._grabAngleOffset = math.atan2(y - knob.centerY, x - knob.centerX) - knob.angle
                if knob.hapticEnabled then gui_haptic_vibrate() end
            end
        end

        ::continue::
    end
end


--[[
    Call from mouse/touch MOVED handlers.
    Once a knob is focused the pointer is tracked anywhere on screen — not just
    within the knob circle.  Uses absolute angle tracking: the grab point on the knob
    follows the finger exactly, and no drift accumulates across frames.  Dragging further
    from the knob center naturally gives finer precision (same dx/dy → smaller angle at
    larger radius).  Haptic is NOT fired here; it fires exactly once on the initial press.

    touchId  — must match the id used in gui_rotaryKnob_pressed to be processed.
    dx, dy   — unused; kept for a consistent call signature with the LÖVE callbacks.
]]
function gui_rotaryKnob_moved(touchId, x, y, dx, dy)
    for _, knob in ipairs(globApp.objects.rotaryKnobs) do
        if knob.focusTouchId ~= touchId then goto continue end
        if not knob.isFocused            then goto continue end

        local cx, cy = knob.centerX, knob.centerY

        -- Skip only when the pointer is within the tiny absolute dead zone right at
        -- the pivot to avoid the atan2 singularity.  Dragging anywhere else —
        -- including well outside the knob circle — is fully processed.
        local dist = math.sqrt((x - cx)^2 + (y - cy)^2)
        if dist < _KNOB_CENTER_DEAD_ZONE_PX then goto continue end

        -- Compute the target angle from the absolute finger angle minus the grab offset
        -- recorded at press time.  This makes the grab point follow the finger exactly:
        -- drag your finger to 3 o'clock and the point you originally grabbed ends there.
        -- No delta accumulation means no drift.  _snapToDetent normalises to [0, 2π)
        -- internally so the result wraps seamlessly past the last detent to the first.
        local fingerAngle         = math.atan2(y - cy, x - cx)
        local snappedPos, snapIdx = _snapToDetent(fingerAngle - knob._grabAngleOffset, knob.numDetents)

        knob.position    = snappedPos
        knob.detentIndex = snapIdx
        knob.angle       = _positionToAngle(snappedPos)

        -- Fire the callback only when the detent actually changes.
        if snapIdx ~= knob._prevDetentIndex then
            knob._prevDetentIndex = snapIdx
            if knob.callbackFunc then
                local cb = _G[knob.callbackFunc]
                if cb and type(cb) == "function" then
                    cb(knob.position)
                end
            end
        end

        ::continue::
    end
end


--[[
    Call from mouse/touch RELEASED handlers.
    Releases focus from any knob owned by the given touchId.
    The knob sprite reverts to the released image and the last selected detent is kept.
]]
function gui_rotaryKnob_released(touchId)
    for _, knob in ipairs(globApp.objects.rotaryKnobs) do
        if knob.focusTouchId == touchId then
            knob.isFocused    = false
            knob.focusTouchId = nil
        end
    end
end
