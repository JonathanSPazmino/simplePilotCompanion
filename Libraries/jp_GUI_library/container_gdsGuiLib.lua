-- container_gdsGuiLib.lua
-- Page-layout system: fixed header/footer zones + single scrollable body containing panels.
--
-- DEVELOPER USAGE (in main.lua):
--
--   -- Optional fixed zones at top/bottom of page (headerHeight = total zone height):
--   gdsGui_container_create("navBar",  "MainMenu", "PILOT COMPANION", 50, 0, "pageHeader")
--   gdsGui_container_create("footBar", "MainMenu", "",                40, 0, "pageFooter")
--
--   -- Body panels (default pageRole "body") auto-size and scroll together:
--   gdsGui_container_create("timerPanel", "MainMenu", "UTC / TIMER", 32, 0)
--   gdsGui_container_addObject("timerPanel", "button",        "myBtn")
--   gdsGui_container_addObject("timerPanel", "outputTextBox", "myLabel")
--   gdsGui_container_addObject("timerPanel", "button",        "footerBtn", "footer")
--   gdsGui_container_finalise("MainMenu")   -- call once after all containers on a page are declared
--
-- addObject role: "scroll" (default) | "header" | "footer"
-- Container pageRole: nil/"body" | "pageHeader" | "pageFooter"
--   pageHeader/pageFooter: fixed zones; their headerHeight param = total zone pixel height.
--   body: auto-sizes to content and participates in page-level scroll.

gdsGui_generateConsoleMessage("info", "Containers initialized")

globApp.objects.containers       = {}
globApp.objects.pageScrollStates = {}  -- keyed by pageName

-- ---------------------------------------------------------------------------
--  PHYSICS CONSTANTS
-- ---------------------------------------------------------------------------
local CONT_FRICTION       = 3.5
local CONT_SPRING_OMEGA   = 18.0
local CONT_SPRING_K       = CONT_SPRING_OMEGA * CONT_SPRING_OMEGA
local CONT_SPRING_C       = 2.0 * CONT_SPRING_OMEGA
local CONT_RUBBER_BAND    = 0.35
local CONT_COAST_STOP_VEL = 8.0
local CONT_BOUNCE_STOP_D  = 0.5
local CONT_BOUNCE_STOP_V  = 5.0

-- ---------------------------------------------------------------------------
--  LAYOUT CONSTANTS
-- ---------------------------------------------------------------------------
local PADDING    = 8    -- px gap around/between objects inside a container
local MIN_ITEM_W = 120  -- px: min item width before layout adds a second column

-- ---------------------------------------------------------------------------
--  PRIVATE — object dimension accessors
-- ---------------------------------------------------------------------------

local function _objWidth(obj)
    if obj.objectType == "button"        then return obj.mywidth        end
    if obj.objectType == "outputTextBox" then return obj.frame.width    end
    if obj.objectType == "scrollBar"     then return obj.original.width end
    if obj.objectType == "rotaryKnob"    then return obj.size           end
    return MIN_ITEM_W
end

local function _objHeight(obj)
    if obj.objectType == "button"        then return obj.myheight        end
    if obj.objectType == "outputTextBox" then return obj.frame.height    end
    if obj.objectType == "scrollBar"     then return obj.original.height end
    if obj.objectType == "rotaryKnob"    then return obj.size            end
    return 40
end

-- ---------------------------------------------------------------------------
--  PRIVATE — position a widget absolutely (used at layout time and on scroll)
-- ---------------------------------------------------------------------------

local function _initObjForContainer(obj, natX, natY)
    if obj.objectType == "button" then
        obj.myx    = math.floor(natX)
        obj.myy    = math.floor(natY)
        obj.myMaxx = obj.myx + obj.mywidth
        obj.myMaxy = obj.myy + obj.myheight

    elseif obj.objectType == "outputTextBox" then
        local dy       = natY - obj.frame.y
        obj.frame.x    = math.floor(natX)
        obj.frame.y    = math.floor(natY)
        obj.bgSprite.x = obj.frame.x
        obj.bgSprite.y = obj.frame.y
        obj.text.x     = obj.frame.x + (obj.frame.width - obj.text.width) / 2
        for _, line in ipairs(obj.text.lines) do
            line.naturalY  = line.naturalY + dy
            line.y         = line.naturalY
            line.isVisible = (line.y + line.height > obj.frame.y) and
                             (line.y < obj.frame.y + obj.frame.height)
        end

    elseif obj.objectType == "scrollBar" then
        local top  = math.floor(natY)
        local left = math.floor(natX)
        if obj.upButton then
            obj.upButton.x   = left
            obj.upButton.y   = top
            obj.downButton.x = left
            obj.downButton.y = top + obj.original.height - obj.downButton.height
            obj.frame.y      = top + obj.upButton.height
        else
            obj.frame.y = top
        end
        obj.frame.x = left
        obj.bar.x   = left
        obj.bar.y   = obj.frame.y + (obj.bar.position * (obj.frame.height - obj.bar.height))

    elseif obj.objectType == "rotaryKnob" then
        obj.x       = math.floor(natX)
        obj.y       = math.floor(natY)
        obj.centerX = obj.x + obj.size * 0.5
        obj.centerY = obj.y + obj.size * 0.5
    end
end

-- Update only the Y coordinate of a widget (called every frame during scroll).
local function _setObjY(obj, newY)
    if obj.objectType == "button" then
        obj.myy    = math.floor(newY)
        obj.myMaxy = obj.myy + obj.myheight

    elseif obj.objectType == "outputTextBox" then
        local dy       = math.floor(newY) - obj.frame.y
        obj.frame.y    = math.floor(newY)
        obj.bgSprite.y = obj.frame.y
        for _, line in ipairs(obj.text.lines) do
            line.y         = line.y + dy
            line.isVisible = (line.y + line.height > obj.frame.y) and
                             (line.y < obj.frame.y + obj.frame.height)
        end

    elseif obj.objectType == "scrollBar" then
        local top = math.floor(newY)
        if obj.upButton then
            obj.upButton.y   = top
            obj.frame.y      = top + obj.upButton.height
            obj.downButton.y = top + obj.original.height - obj.downButton.height
        else
            obj.frame.y = top
        end
        obj.bar.y = obj.frame.y + (obj.bar.position * (obj.frame.height - obj.bar.height))

    elseif obj.objectType == "rotaryKnob" then
        obj.y       = math.floor(newY)
        obj.centerY = obj.y + obj.size * 0.5
    end
end

-- ---------------------------------------------------------------------------
--  PRIVATE — sub-rect geometry
-- ---------------------------------------------------------------------------

local function _computeSubrects(cont)
    local f  = cont.frame
    local hh = cont.headerHeight
    local fh = cont.footerHeight
    cont.headerRect = { x=f.x, y=f.y,                   width=f.width, height=hh }
    cont.scrollRect = { x=f.x, y=f.y + hh,              width=f.width, height=f.height - hh - fh }
    cont.footerRect = { x=f.x, y=f.y + f.height - fh,   width=f.width, height=fh }
end

-- ---------------------------------------------------------------------------
--  PRIVATE — page-level scroll helpers
-- ---------------------------------------------------------------------------

local function _pageScrollLimits(state)
    local minOff = math.min(0, state.bodyArea.height - state.contentHeight)
    return minOff, 0
end

-- Move all body containers on a page by the current page scroll offset.
-- entry.naturalY stores the widget's Y at offsetY == 0 (set at layout time).
local function _applyPageScroll(pageName)
    local state = globApp.objects.pageScrollStates[pageName]
    if not state then return end
    local offsetY = state.scroll.offsetY
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == pageName and cont.pageRole == "body" then
            cont.frame.y = cont.frameNaturalY + offsetY
            _computeSubrects(cont)
            for _, entry in ipairs(cont.objects) do
                _setObjY(entry.ref, entry.naturalY + offsetY)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
--  PRIVATE — layout widgets within a single container
-- ---------------------------------------------------------------------------

local function _layoutObjects(cont)
    local sr     = cont.scrollRect
    local availW = sr.width - 2 * PADDING
    local cols   = math.max(1, math.floor(availW / MIN_ITEM_W))
    local cellW  = math.floor(availW / cols)

    -- Grid-pack scroll-role objects into rows.
    local rows       = {}
    local currentRow = {}
    local col        = 0
    for _, entry in ipairs(cont.objects) do
        if entry.role == "scroll" then
            table.insert(currentRow, entry)
            col = col + 1
            if col >= cols then
                table.insert(rows, currentRow)
                currentRow = {}
                col        = 0
            end
        end
    end
    if #currentRow > 0 then table.insert(rows, currentRow) end

    local cursorY = PADDING
    for _, row in ipairs(rows) do
        local rowH = 0
        for _, entry in ipairs(row) do
            local h = _objHeight(entry.ref)
            if h > rowH then rowH = h end
        end
        for c, entry in ipairs(row) do
            local obj  = entry.ref
            local w    = _objWidth(obj)
            local h    = _objHeight(obj)
            local natX = sr.x + PADDING + (c - 1) * cellW + math.floor((cellW - w) / 2)
            local natY = sr.y + cursorY + math.floor((rowH - h) / 2)
            entry.naturalX = natX
            entry.naturalY = natY
            _initObjForContainer(obj, natX, natY)
        end
        cursorY = cursorY + rowH + PADDING
    end
    cont.contentHeight = cursorY + PADDING

    -- Header-role objects (laid out left-to-right in the header strip).
    local hx = cont.headerRect.x + PADDING
    for _, entry in ipairs(cont.objects) do
        if entry.role == "header" then
            local natY = cont.headerRect.y + math.floor((cont.headerRect.height - _objHeight(entry.ref)) / 2)
            entry.naturalX = hx
            entry.naturalY = natY
            _initObjForContainer(entry.ref, hx, natY)
            hx = hx + _objWidth(entry.ref) + PADDING
        end
    end

    -- Footer-role objects (laid out left-to-right in the footer strip).
    local fx = cont.footerRect.x + PADDING
    for _, entry in ipairs(cont.objects) do
        if entry.role == "footer" then
            local natY = cont.footerRect.y + math.floor((cont.footerRect.height - _objHeight(entry.ref)) / 2)
            entry.naturalX = fx
            entry.naturalY = natY
            _initObjForContainer(entry.ref, fx, natY)
            fx = fx + _objWidth(entry.ref) + PADDING
        end
    end
end

-- ---------------------------------------------------------------------------
--  PRIVATE — page-level layout
-- ---------------------------------------------------------------------------

local function _layoutPage(pageName)
    local sa          = globApp.safeScreenArea
    local orientation = globApp.displayOrientation

    -- Bucket containers by role.
    local headerConts, footerConts, bodyConts = {}, {}, {}
    for _, c in ipairs(globApp.objects.containers) do
        if c.page == pageName then
            if     c.pageRole == "pageHeader" then table.insert(headerConts, c)
            elseif c.pageRole == "pageFooter" then table.insert(footerConts, c)
            else                                   table.insert(bodyConts,   c)
            end
        end
    end

    -- ── pageHeader containers (stacked at top, full width) ──────────────────
    -- For these, headerHeight is the total pixel height of the fixed zone.
    local headerZoneH = 0
    for _, cont in ipairs(headerConts) do
        local h = cont.headerHeight
        cont.frame = { x=sa.x, y=sa.y + headerZoneH, width=sa.w, height=h }
        _computeSubrects(cont)
        _layoutObjects(cont)
        headerZoneH = headerZoneH + h
    end

    -- ── pageFooter containers (stacked at bottom, full width) ───────────────
    local footerZoneH = 0
    for _, cont in ipairs(footerConts) do
        footerZoneH = footerZoneH + cont.headerHeight
    end
    local footerCurY = sa.y + sa.h - footerZoneH
    for _, cont in ipairs(footerConts) do
        local h = cont.headerHeight
        cont.frame = { x=sa.x, y=footerCurY, width=sa.w, height=h }
        _computeSubrects(cont)
        _layoutObjects(cont)
        footerCurY = footerCurY + h
    end

    -- ── Body area (middle zone) ──────────────────────────────────────────────
    local bodyArea = {
        x      = sa.x,
        y      = sa.y + headerZoneH,
        width  = sa.w,
        height = sa.h - headerZoneH - footerZoneH,
    }

    if #bodyConts > 0 then
        local cols = (orientation == "landscape") and math.min(#bodyConts, 3) or 1
        local colW = math.floor(bodyArea.width / cols)

        -- First pass: measure each container's natural height.
        for i, cont in ipairs(bodyConts) do
            local col = (i - 1) % cols
            cont.frame = { x=bodyArea.x + col * colW, y=bodyArea.y, width=colW, height=0 }
            _computeSubrects(cont)
            _layoutObjects(cont)
            cont.frame.height = cont.headerHeight + cont.contentHeight + cont.footerHeight
        end

        -- Second pass: assign final Y positions, re-layout with correct subrects.
        local colCurY = {}
        for c = 1, cols do colCurY[c] = bodyArea.y end

        for i, cont in ipairs(bodyConts) do
            local col = (i - 1) % cols + 1
            cont.frame.y = colCurY[col]
            _computeSubrects(cont)
            _layoutObjects(cont)
            cont.frameNaturalY = cont.frame.y  -- Y at pageScrollOffset == 0
            colCurY[col] = colCurY[col] + cont.frame.height
        end

        -- Total body content height = tallest column.
        local contentH = 0
        for c = 1, cols do
            local colH = colCurY[c] - bodyArea.y
            if colH > contentH then contentH = colH end
        end

        -- Initialise or update the page scroll state for this page.
        if not globApp.objects.pageScrollStates[pageName] then
            globApp.objects.pageScrollStates[pageName] = {
                bodyArea      = bodyArea,
                contentHeight = contentH,
                scroll = {
                    offsetY            = 0,
                    velocityY          = 0,
                    phase              = "idle",
                    isDragging         = false,
                    touchStartedInside = false,
                },
            }
        else
            local state = globApp.objects.pageScrollStates[pageName]
            state.bodyArea      = bodyArea
            state.contentHeight = contentH
            local minOff = math.min(0, bodyArea.height - contentH)
            state.scroll.offsetY   = math.max(minOff, math.min(0, state.scroll.offsetY))
            state.scroll.velocityY = 0
            state.scroll.phase     = "idle"
            _applyPageScroll(pageName)
        end
    end
end

-- ---------------------------------------------------------------------------
--  PRIVATE — drawing helpers
-- ---------------------------------------------------------------------------

local function _setClip(clip)
    if clip then
        love.graphics.setScissor(clip.x, clip.y, clip.width, clip.height)
    end
end

local function _drawWidget(obj, clip)
    local ot = obj.objectType

    if ot == "button" then
        local img = obj.images[obj.state]
        if img then
            love.graphics.draw(img, obj.myx, obj.myy, 0, obj.factorWidth, obj.factorHeight)
        end

    elseif ot == "outputTextBox" then
        if obj.bgSprite and obj.bgSprite.sprite then
            love.graphics.draw(obj.bgSprite.sprite, obj.bgSprite.x, obj.bgSprite.y,
                               0, obj.bgSprite.width, obj.bgSprite.height)
        end
        love.graphics.setFont(obj.text.font)
        for _, line in ipairs(obj.text.lines) do
            if line.isVisible then
                love.graphics.setColor(obj.text.color[1], obj.text.color[2],
                                       obj.text.color[3], obj.text.color[4] or 1)
                love.graphics.printf(line.text, line.x, line.y, line.width, "center")
            end
        end
        love.graphics.reset()

    elseif ot == "scrollBar" then
        gdsGui_scrollBar_drawSingle(obj)

    elseif ot == "rotaryKnob" then
        gdsGui_rotaryKnob_drawSingle(obj)
    end

    -- Restore clip after any widget that may call love.graphics.reset().
    _setClip(clip)
end

local function _drawContainer(cont, clip)
    local f  = cont.frame
    local hr = cont.headerRect
    local fr = cont.footerRect

    _setClip(clip)

    -- Background + border.
    love.graphics.setColor(cont.bgColor[1], cont.bgColor[2], cont.bgColor[3], cont.bgColor[4] or 1)
    love.graphics.rectangle("fill", f.x, f.y, f.width, f.height)
    love.graphics.setColor(cont.borderColor[1], cont.borderColor[2], cont.borderColor[3], 1)
    love.graphics.rectangle("line", f.x, f.y, f.width, f.height)

    -- Header strip.
    if hr.height > 0 then
        love.graphics.setColor(cont.headerColor[1], cont.headerColor[2], cont.headerColor[3], 1)
        love.graphics.rectangle("fill", hr.x, hr.y, hr.width, hr.height)
        if cont.title and cont.title ~= "" then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(cont.title, hr.x + PADDING, hr.y + PADDING,
                                 hr.width - 2 * PADDING, "left")
        end
        for _, entry in ipairs(cont.objects) do
            if entry.role == "header" then
                _drawWidget(entry.ref, clip)
            end
        end
    end

    -- Content (scroll-role) widgets.
    for _, entry in ipairs(cont.objects) do
        if entry.role == "scroll" then
            _drawWidget(entry.ref, clip)
        end
    end

    -- Footer strip.
    if fr.height > 0 then
        _setClip(clip)
        love.graphics.setColor(cont.footerColor[1], cont.footerColor[2], cont.footerColor[3], 1)
        love.graphics.rectangle("fill", fr.x, fr.y, fr.width, fr.height)
        for _, entry in ipairs(cont.objects) do
            if entry.role == "footer" then
                _drawWidget(entry.ref, clip)
            end
        end
    end

    love.graphics.setScissor()
end

-- ---------------------------------------------------------------------------
--  PRIVATE — touch-on-widget hit test
-- ---------------------------------------------------------------------------

local function _isTouchOnWidget(obj, x, y)
    local ot = obj.objectType
    if ot == "button" then
        return x >= obj.myx and x <= obj.myMaxx and y >= obj.myy and y <= obj.myMaxy
    elseif ot == "outputTextBox" then
        return x >= obj.frame.x and x <= obj.frame.x + obj.frame.width and
               y >= obj.frame.y and y <= obj.frame.y + obj.frame.height
    elseif ot == "scrollBar" then
        local top    = obj.upButton   and obj.upButton.y                          or obj.frame.y
        local bottom = obj.downButton and (obj.downButton.y + obj.downButton.height) or (obj.frame.y + obj.frame.height)
        return x >= obj.frame.x and x <= obj.frame.x + obj.frame.width and
               y >= top and y <= bottom
    elseif ot == "rotaryKnob" then
        return x >= obj.x and x <= obj.x + obj.size and y >= obj.y and y <= obj.y + obj.size
    end
    return false
end

-- ---------------------------------------------------------------------------
--  PUBLIC API — creation
-- ---------------------------------------------------------------------------

-- pageRole: nil/"body" | "pageHeader" | "pageFooter"
-- For pageHeader/pageFooter, headerHeight doubles as the total fixed zone height.
function gdsGui_container_create(name, page, title, headerHeight, footerHeight, pageRole)
    local cont = {}
    cont.name          = name
    cont.page          = page
    cont.title         = title or ""
    cont.headerHeight  = headerHeight or 0
    cont.footerHeight  = footerHeight or 0
    cont.pageRole      = pageRole or "body"
    cont.objects       = {}
    cont.contentHeight = 0
    cont.frameNaturalY = 0

    cont.frame      = { x=0, y=0, width=0, height=0 }
    cont.headerRect = { x=0, y=0, width=0, height=0 }
    cont.scrollRect = { x=0, y=0, width=0, height=0 }
    cont.footerRect = { x=0, y=0, width=0, height=0 }

    cont.bgColor     = { 0.18, 0.18, 0.18, 1 }
    cont.headerColor = { 0.25, 0.25, 0.25, 1 }
    cont.footerColor = { 0.22, 0.22, 0.22, 1 }
    cont.borderColor = { 0.35, 0.35, 0.35, 1 }

    table.insert(globApp.objects.containers, cont)
    gdsGui_generateConsoleMessage("info", "Container '" .. name .. "' created on page '" .. page .. "'")
end

-- Assign an existing widget to a container.
-- role: "scroll" (default) | "header" | "footer"
function gdsGui_container_addObject(containerName, objectType, objectName, role)
    local cont
    for _, c in ipairs(globApp.objects.containers) do
        if c.name == containerName then cont = c; break end
    end
    if not cont then
        gdsGui_generateConsoleMessage("error", "gdsGui_container_addObject: container '" .. containerName .. "' not found")
        return
    end

    local obj
    if objectType == "button" then
        for _, o in ipairs(globApp.objects.buttons) do
            if o.name == objectName then obj = o; break end
        end
    elseif objectType == "outputTextBox" then
        for _, o in ipairs(globApp.objects.outputTextBox) do
            if o.name == objectName then obj = o; break end
        end
    elseif objectType == "scrollBar" then
        for _, o in ipairs(globApp.objects.scrollBars) do
            if o.id == objectName then obj = o; break end
        end
    elseif objectType == "rotaryKnob" then
        for _, o in ipairs(globApp.objects.rotaryKnobs) do
            if o.id == objectName then obj = o; break end
        end
    else
        gdsGui_generateConsoleMessage("error", "gdsGui_container_addObject: unsupported objectType '" .. objectType .. "'")
        return
    end

    if not obj then
        gdsGui_generateConsoleMessage("error", "gdsGui_container_addObject: widget '" .. objectName .. "' not found")
        return
    end

    obj.ownerContainer = containerName

    table.insert(cont.objects, {
        ref      = obj,
        role     = role or "scroll",
        naturalX = 0,
        naturalY = 0,
    })
end

-- Call once after all containers on a page are declared, and again on resize.
function gdsGui_container_finalise(pageName)
    _layoutPage(pageName)
end

-- ---------------------------------------------------------------------------
--  PUBLIC API — physics update (page-level scroll)
-- ---------------------------------------------------------------------------

function gdsGui_container_physicsUpdate(dt)
    if not dt or dt <= 0 then return end

    local activePage = gdsGui_page_currentName()
    local state      = globApp.objects.pageScrollStates[activePage]
    if not state then return end

    local s = state.scroll
    if s.isDragging or s.phase == "idle" then return end

    local minOff, maxOff = _pageScrollLimits(state)
    if minOff >= -0.5 then return end  -- content fits; nothing to animate

    if s.phase == "coasting" then
        s.velocityY = s.velocityY * math.exp(-CONT_FRICTION * dt)
        s.offsetY   = s.offsetY   + s.velocityY * dt

        if s.offsetY < minOff or s.offsetY > maxOff then
            s.phase = "bouncing"
        elseif math.abs(s.velocityY) < CONT_COAST_STOP_VEL then
            s.phase     = "idle"
            s.velocityY = 0
        end
        _applyPageScroll(activePage)

    elseif s.phase == "bouncing" then
        local target  = math.max(minOff, math.min(maxOff, s.offsetY))
        local disp    = s.offsetY - target
        local acc     = (-CONT_SPRING_K * disp) + (-CONT_SPRING_C * s.velocityY)
        s.velocityY   = s.velocityY + acc * dt
        s.offsetY     = s.offsetY   + s.velocityY * dt

        if math.abs(s.offsetY - target) < CONT_BOUNCE_STOP_D and
           math.abs(s.velocityY) < CONT_BOUNCE_STOP_V then
            s.offsetY   = target
            s.velocityY = 0
            s.phase     = "idle"
        end
        _applyPageScroll(activePage)
    end
end

-- ---------------------------------------------------------------------------
--  PUBLIC API — touch/mouse scroll (page-level)
-- ---------------------------------------------------------------------------

function gdsGui_container_touchScroll(id, x, y, dx, dy)
    local isGestureActive = (globApp.userInput == "slide") or love.mouse.isDown(1)
    if not isGestureActive then return end

    local activePage = gdsGui_page_currentName()
    local state      = globApp.objects.pageScrollStates[activePage]
    if not state or not state.scroll.touchStartedInside then return end

    local s              = state.scroll
    local minOff, maxOff = _pageScrollLimits(state)
    if minOff >= -0.5 then return end

    s.isDragging = true
    s.phase      = "coasting"

    local newOff = s.offsetY + dy
    if newOff < minOff then
        newOff = minOff + (newOff - minOff) * CONT_RUBBER_BAND
    elseif newOff > maxOff then
        newOff = maxOff + (newOff - maxOff) * CONT_RUBBER_BAND
    end
    s.offsetY = newOff

    local frameDt = love.timer.getDelta()
    if frameDt > 0 then
        local rawVel = dy / frameDt
        s.velocityY  = s.velocityY * 0.5 + rawVel * 0.5
    end

    _applyPageScroll(activePage)
end

function gdsGui_container_touchReleased(x, y)
    local activePage = gdsGui_page_currentName()
    local state      = globApp.objects.pageScrollStates[activePage]
    if not state then return end

    local s = state.scroll
    if s.isDragging then
        s.isDragging         = false
        s.touchStartedInside = false
        local minOff, maxOff = _pageScrollLimits(state)

        if s.offsetY < minOff or s.offsetY > maxOff then
            s.phase = "bouncing"
        elseif math.abs(s.velocityY) > CONT_COAST_STOP_VEL then
            s.phase = "coasting"
        else
            s.phase     = "idle"
            s.velocityY = 0
        end
    end
    s.touchStartedInside = false
end

-- Mark page-level scroll as started when the touch lands in the body area on
-- empty space (not on any widget inside a body container).
function gdsGui_container_markTouchStart(x, y)
    local activePage = gdsGui_page_currentName()
    local state      = globApp.objects.pageScrollStates[activePage]
    if not state then return end

    local ba = state.bodyArea
    if not (x >= ba.x and x <= ba.x + ba.width and
            y >= ba.y and y <= ba.y + ba.height) then
        return
    end

    -- Suppress page scroll when the touch is directly on a widget.
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == activePage and cont.pageRole == "body" then
            for _, entry in ipairs(cont.objects) do
                if _isTouchOnWidget(entry.ref, x, y) then
                    return
                end
            end
        end
    end

    state.scroll.touchStartedInside = true
    state.scroll.velocityY          = 0
end

-- ---------------------------------------------------------------------------
--  PUBLIC API — resize
-- ---------------------------------------------------------------------------

function gdsGui_container_resize(pageName)
    _layoutPage(pageName or gdsGui_page_currentName())
end

-- ---------------------------------------------------------------------------
--  PUBLIC API — draw
-- ---------------------------------------------------------------------------

function gdsGui_container_draw(pageName)
    local state    = globApp.objects.pageScrollStates[pageName]
    local bodyClip = state and state.bodyArea

    -- Pass 1: body containers (clipped to body area so they can't bleed into
    -- the fixed header/footer zones when partially scrolled off-screen).
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == pageName and cont.pageRole == "body" then
            _drawContainer(cont, bodyClip)
        end
    end

    -- Pass 2: fixed pageHeader / pageFooter containers (no clip).
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == pageName and cont.pageRole ~= "body" then
            _drawContainer(cont, nil)
        end
    end

    love.graphics.reset()
end
