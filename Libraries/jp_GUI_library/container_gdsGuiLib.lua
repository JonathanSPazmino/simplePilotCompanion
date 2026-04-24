-- container_gdsGuiLib.lua
-- Scrollable widget containers with automatic page-level grid layout.
--
-- DEVELOPER USAGE (in main.lua):
--
--   gdsGui_container_create("myPanel", "MainMenu", "Panel Title", 40, 40)
--   gdsGui_container_addObject("myPanel", "button",        "myButtonName")
--   gdsGui_container_addObject("myPanel", "outputTextBox", "myLabelName")
--   gdsGui_container_addObject("myPanel", "button",        "footerBtn", "footer")
--   gdsGui_container_finalise("MainMenu")   -- call once after all containers on a page are declared
--
-- role parameter on addObject: "scroll" (default) | "header" | "footer"

gdsGui_generateConsoleMessage("info", "Containers initialized")

globApp.objects.containers = {}

-- ---------------------------------------------------------------------------
--  PHYSICS CONSTANTS  (mirrors outputTxtBox values exactly)
-- ---------------------------------------------------------------------------
local CONT_FRICTION        = 3.5
local CONT_SPRING_OMEGA    = 18.0
local CONT_SPRING_K        = CONT_SPRING_OMEGA * CONT_SPRING_OMEGA
local CONT_SPRING_C        = 2.0 * CONT_SPRING_OMEGA
local CONT_RUBBER_BAND     = 0.35
local CONT_COAST_STOP_VEL  = 8.0
local CONT_BOUNCE_STOP_D   = 0.5
local CONT_BOUNCE_STOP_V   = 5.0

-- ---------------------------------------------------------------------------
--  LAYOUT CONSTANTS
-- ---------------------------------------------------------------------------
local PADDING       = 8    -- px gap around/between objects inside a container
local MIN_ITEM_W    = 120  -- px: min item width before the layout adds a second column

-- ---------------------------------------------------------------------------
--  PRIVATE HELPERS — object dimension accessors
-- ---------------------------------------------------------------------------

local function _objWidth(obj)
    if obj.objectType == "button"        then return obj.mywidth        end
    if obj.objectType == "outputTextBox" then return obj.frame.width    end
    if obj.objectType == "scrollBar"     then return obj.original.width end
    if obj.objectType == "rotaryKnob"   then return obj.size           end
    return MIN_ITEM_W
end

local function _objHeight(obj)
    if obj.objectType == "button"        then return obj.myheight         end
    if obj.objectType == "outputTextBox" then return obj.frame.height     end
    if obj.objectType == "scrollBar"     then return obj.original.height  end
    if obj.objectType == "rotaryKnob"   then return obj.size             end
    return 40
end

-- ---------------------------------------------------------------------------
--  PRIVATE HELPERS — move a widget's screen-space Y each frame
-- ---------------------------------------------------------------------------

-- Called once when the widget is first positioned inside a container.
-- Stores per-widget "natural" (zero-scroll) reference data so _setObjY is
-- cheap every frame without touching the widget's own creation data.
local function _initObjForContainer(obj, natX, natY)
    obj.containerNatX = natX
    obj.containerNatY = natY

    if obj.objectType == "button" then
        obj.myx    = math.floor(natX)
        obj.myy    = math.floor(natY)
        obj.myMaxx = obj.myx + obj.mywidth
        obj.myMaxy = obj.myy + obj.myheight

    elseif obj.objectType == "outputTextBox" then
        local dy        = natY - obj.frame.y
        obj.frame.x     = math.floor(natX)
        obj.frame.y     = math.floor(natY)
        obj.bgSprite.x  = obj.frame.x
        obj.bgSprite.y  = obj.frame.y
        obj.text.x      = obj.frame.x + (obj.frame.width - obj.text.width) / 2
        for _, line in ipairs(obj.text.lines) do
            line.naturalY  = line.naturalY + dy
            line.y         = line.naturalY
            line.isVisible = (line.y + line.height > obj.frame.y) and
                             (line.y < obj.frame.y + obj.frame.height)
        end

    elseif obj.objectType == "scrollBar" then
        local top = math.floor(natY)
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

-- Called every frame after physics updates offsetY.
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
--  PRIVATE HELPERS — scroll limits & apply
-- ---------------------------------------------------------------------------

local function _scrollLimits(cont)
    local minOff = math.min(0, cont.scrollRect.height - cont.contentHeight)
    return minOff, 0
end

local function _applyScroll(cont)
    local offsetY = cont.scroll.offsetY
    for _, entry in ipairs(cont.objects) do
        if entry.role == "scroll" then
            _setObjY(entry.ref, entry.naturalY + offsetY)
        end
    end
end

-- ---------------------------------------------------------------------------
--  PRIVATE HELPERS — compute header/scroll/footer sub-rects from frame
-- ---------------------------------------------------------------------------

local function _computeSubrects(cont)
    local f  = cont.frame
    local hh = cont.headerHeight
    local fh = cont.footerHeight
    cont.headerRect = { x = f.x, y = f.y,                     width = f.width, height = hh }
    cont.footerRect = { x = f.x, y = f.y + f.height - fh,     width = f.width, height = fh }
    cont.scrollRect = { x = f.x, y = f.y + hh,                width = f.width, height = f.height - hh - fh }
end

-- ---------------------------------------------------------------------------
--  PRIVATE HELPERS — layout objects within a single container
-- ---------------------------------------------------------------------------

local function _layoutObjects(cont)
    local sr      = cont.scrollRect
    local avail_w = sr.width - 2 * PADDING
    local cols    = math.max(1, math.floor(avail_w / MIN_ITEM_W))
    local cellW   = math.floor(avail_w / cols)

    -- Bucket scroll objects into rows, then position each row using its own max height.
    local rows = {}
    local current_row = {}
    local col = 0
    for _, entry in ipairs(cont.objects) do
        if entry.role == "scroll" then
            table.insert(current_row, entry)
            col = col + 1
            if col >= cols then
                table.insert(rows, current_row)
                current_row = {}
                col = 0
            end
        end
    end
    if #current_row > 0 then table.insert(rows, current_row) end

    local cursor_y = PADDING
    for _, row in ipairs(rows) do
        -- Find tallest object in this row
        local rowH = 0
        for _, entry in ipairs(row) do
            local h = _objHeight(entry.ref)
            if h > rowH then rowH = h end
        end

        for c, entry in ipairs(row) do
            local obj = entry.ref
            local w   = _objWidth(obj)
            local h   = _objHeight(obj)
            local natX = sr.x + PADDING + (c - 1) * cellW + math.floor((cellW - w) / 2)
            local natY = sr.y + cursor_y + math.floor((rowH - h) / 2)
            entry.naturalX = natX
            entry.naturalY = natY
            _initObjForContainer(obj, natX, natY)
        end
        cursor_y = cursor_y + rowH + PADDING
    end
    cont.contentHeight = cursor_y + PADDING

    -- Position header-role objects across the header strip
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

    -- Position footer-role objects across the footer strip
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

    -- Clamp and re-apply current scroll
    local minOff, maxOff = _scrollLimits(cont)
    cont.scroll.offsetY  = math.max(minOff, math.min(maxOff, cont.scroll.offsetY))
    _applyScroll(cont)
end

-- ---------------------------------------------------------------------------
--  PRIVATE HELPERS — page-level container grid layout
-- ---------------------------------------------------------------------------

local function _layoutPage(pageName)
    local conts = {}
    for _, c in ipairs(globApp.objects.containers) do
        if c.page == pageName then
            table.insert(conts, c)
        end
    end
    if #conts == 0 then return end

    local sa          = globApp.safeScreenArea
    local orientation = globApp.displayOrientation  -- "portrait"|"landscape"|"square"

    -- Columns: landscape gets up to min(N, 3); portrait/square → 1
    local cols
    if orientation == "landscape" then
        cols = math.min(#conts, 3)
    else
        cols = 1
    end
    local rows  = math.ceil(#conts / cols)
    local cellW = math.floor(sa.w / cols)
    local cellH = math.floor(sa.h / rows)

    for i, cont in ipairs(conts) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        cont.frame = {
            x      = sa.x + col * cellW,
            y      = sa.y + row * cellH,
            width  = cellW,
            height = cellH,
        }
        _computeSubrects(cont)
        -- Reset scroll when re-laid-out (orientation change etc.)
        cont.scroll.offsetY   = 0
        cont.scroll.velocityY = 0
        cont.scroll.phase     = "idle"
        _layoutObjects(cont)
    end
end

-- ---------------------------------------------------------------------------
--  PRIVATE HELPERS — draw a single widget (called inside container draw)
-- ---------------------------------------------------------------------------

local function _drawWidget(obj)
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
end

-- ---------------------------------------------------------------------------
--  PUBLIC API
-- ---------------------------------------------------------------------------

-- Create a container.  Call gdsGui_container_finalise(page) after all
-- containers on the page have been declared.
function gdsGui_container_create(name, page, title, headerHeight, footerHeight)
    local cont = {}
    cont.name         = name
    cont.page         = page
    cont.title        = title or ""
    cont.headerHeight = headerHeight or 0
    cont.footerHeight = footerHeight or 0
    cont.objects      = {}
    cont.contentHeight = 0

    -- Frame assigned by _layoutPage; placeholders until then
    cont.frame      = { x=0, y=0, width=0, height=0 }
    cont.headerRect = { x=0, y=0, width=0, height=0 }
    cont.scrollRect = { x=0, y=0, width=0, height=0 }
    cont.footerRect = { x=0, y=0, width=0, height=0 }

    cont.scroll = {
        offsetY            = 0,
        velocityY          = 0,
        phase              = "idle",
        isDragging         = false,
        touchStartedInside = false,
        lastTouchY         = 0,
    }

    cont.bgColor     = { 0.18, 0.18, 0.18, 1 }
    cont.headerColor = { 0.25, 0.25, 0.25, 1 }
    cont.footerColor = { 0.22, 0.22, 0.22, 1 }
    cont.borderColor = { 0.35, 0.35, 0.35, 1 }

    table.insert(globApp.objects.containers, cont)
    gdsGui_generateConsoleMessage("info", "Container '" .. name .. "' created on page '" .. page .. "'")
end

-- Assign an existing widget (already created) to a container.
-- role: "scroll" (default) | "header" | "footer"
function gdsGui_container_addObject(containerName, objectType, objectName, role)
    -- Find container
    local cont
    for _, c in ipairs(globApp.objects.containers) do
        if c.name == containerName then cont = c; break end
    end
    if not cont then
        gdsGui_generateConsoleMessage("error", "gdsGui_container_addObject: container '" .. containerName .. "' not found")
        return
    end

    -- Find widget in the appropriate global list
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

    -- Mark as owned so normal draw passes skip it
    obj.ownerContainer = containerName

    local entry = {
        ref      = obj,
        role     = role or "scroll",
        naturalX = 0,
        naturalY = 0,
    }
    table.insert(cont.objects, entry)
end

-- Call once after declaring all containers (and their objects) for a page.
-- Also call again whenever the screen layout needs rebuilding (resize, orientation change).
function gdsGui_container_finalise(pageName)
    _layoutPage(pageName)
end

-- ---------------------------------------------------------------------------
--  PHYSICS UPDATE  (called from gdsGui_update via general_gdsGuiLib)
-- ---------------------------------------------------------------------------

function gdsGui_container_physicsUpdate(dt)
    if not dt or dt <= 0 then return end

    local activePage = gdsGui_page_currentName()

    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == activePage and not cont.scroll.isDragging
           and cont.scroll.phase ~= "idle" then

            local minOff, maxOff = _scrollLimits(cont)
            local canScroll      = (minOff < -0.5)
            if not canScroll then goto continue_cont end

            if cont.scroll.phase == "coasting" then
                cont.scroll.velocityY = cont.scroll.velocityY * math.exp(-CONT_FRICTION * dt)
                cont.scroll.offsetY   = cont.scroll.offsetY   + cont.scroll.velocityY * dt

                if cont.scroll.offsetY < minOff or cont.scroll.offsetY > maxOff then
                    cont.scroll.phase = "bouncing"
                elseif math.abs(cont.scroll.velocityY) < CONT_COAST_STOP_VEL then
                    cont.scroll.phase     = "idle"
                    cont.scroll.velocityY = 0
                end
                _applyScroll(cont)

            elseif cont.scroll.phase == "bouncing" then
                local target    = math.max(minOff, math.min(maxOff, cont.scroll.offsetY))
                local disp      = cont.scroll.offsetY - target
                local acc       = (-CONT_SPRING_K * disp) + (-CONT_SPRING_C * cont.scroll.velocityY)
                cont.scroll.velocityY = cont.scroll.velocityY + acc * dt
                cont.scroll.offsetY   = cont.scroll.offsetY   + cont.scroll.velocityY * dt

                local newDisp = math.abs(cont.scroll.offsetY - target)
                if newDisp < CONT_BOUNCE_STOP_D and math.abs(cont.scroll.velocityY) < CONT_BOUNCE_STOP_V then
                    cont.scroll.offsetY   = target
                    cont.scroll.velocityY = 0
                    cont.scroll.phase     = "idle"
                end
                _applyScroll(cont)
            end

            ::continue_cont::
        end
    end
end

-- ---------------------------------------------------------------------------
--  TOUCH / MOUSE SCROLL  (called from general_gdsGuiLib)
-- ---------------------------------------------------------------------------

function gdsGui_container_touchScroll(id, x, y, dx, dy)
    local isGestureActive = (globApp.userInput == "slide") or love.mouse.isDown(1)
    if not isGestureActive then return end

    local activePage = gdsGui_page_currentName()

    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == activePage and cont.scroll.touchStartedInside then
            local sr = cont.scrollRect
            local minOff, maxOff = _scrollLimits(cont)
            if minOff >= -0.5 then goto skip_cont end  -- content fits, nothing to scroll

            cont.scroll.isDragging = true
            cont.scroll.phase      = "coasting"

            -- Rubber-band resistance past limits
            local newOff = cont.scroll.offsetY + dy
            if newOff < minOff then
                newOff = minOff + (newOff - minOff) * CONT_RUBBER_BAND
            elseif newOff > maxOff then
                newOff = maxOff + (newOff - maxOff) * CONT_RUBBER_BAND
            end
            cont.scroll.offsetY = newOff

            -- Exponential moving-average velocity
            local frameDt = love.timer.getDelta()
            if frameDt > 0 then
                local rawVel = dy / frameDt
                cont.scroll.velocityY = cont.scroll.velocityY * 0.5 + rawVel * 0.5
            end

            _applyScroll(cont)

            ::skip_cont::
        end
    end
end

function gdsGui_container_touchReleased(x, y)
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.scroll.isDragging then
            cont.scroll.isDragging         = false
            cont.scroll.touchStartedInside = false
            local minOff, maxOff = _scrollLimits(cont)

            if cont.scroll.offsetY < minOff or cont.scroll.offsetY > maxOff then
                cont.scroll.phase = "bouncing"
            elseif math.abs(cont.scroll.velocityY) > CONT_COAST_STOP_VEL then
                cont.scroll.phase = "coasting"
            else
                cont.scroll.phase     = "idle"
                cont.scroll.velocityY = 0
            end
        end
        cont.scroll.touchStartedInside = false
    end
end

-- Mark which container a new touch/click started inside (called from pressed handlers).
function gdsGui_container_markTouchStart(x, y)
    local activePage = gdsGui_page_currentName()
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == activePage then
            local sr = cont.scrollRect
            if x >= sr.x and x <= sr.x + sr.width and
               y >= sr.y and y <= sr.y + sr.height then
                cont.scroll.touchStartedInside = true
                cont.scroll.velocityY          = 0
            end
        end
    end
end

-- ---------------------------------------------------------------------------
--  RESIZE  (called from gdsGui_general_handleResize)
-- ---------------------------------------------------------------------------

function gdsGui_container_resize(pageName)
    _layoutPage(pageName or gdsGui_page_currentName())
end

-- ---------------------------------------------------------------------------
--  DRAW  (called from gdsGui_general_draw)
-- ---------------------------------------------------------------------------

function gdsGui_container_draw(pageName)
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page ~= pageName then goto next_cont end

        local f  = cont.frame
        local hr = cont.headerRect
        local fr = cont.footerRect
        local sr = cont.scrollRect

        -- ── Container background ──────────────────────────────────────────
        love.graphics.setColor(cont.bgColor[1], cont.bgColor[2], cont.bgColor[3], cont.bgColor[4] or 1)
        love.graphics.rectangle("fill", f.x, f.y, f.width, f.height)

        -- ── Border ───────────────────────────────────────────────────────
        love.graphics.setColor(cont.borderColor[1], cont.borderColor[2], cont.borderColor[3], 1)
        love.graphics.rectangle("line", f.x, f.y, f.width, f.height)

        -- ── Header strip ─────────────────────────────────────────────────
        if hr.height > 0 then
            love.graphics.setColor(cont.headerColor[1], cont.headerColor[2], cont.headerColor[3], 1)
            love.graphics.rectangle("fill", hr.x, hr.y, hr.width, hr.height)
            -- Title text
            if cont.title and cont.title ~= "" then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(cont.title, hr.x + PADDING, hr.y + PADDING,
                                     hr.width - 2 * PADDING, "left")
            end
            -- Header-role objects
            for _, entry in ipairs(cont.objects) do
                if entry.role == "header" then
                    _drawWidget(entry.ref)
                end
            end
        end

        -- ── Scrollable area (scissored) ───────────────────────────────────
        love.graphics.setScissor(sr.x, sr.y, sr.width, sr.height)
        for _, entry in ipairs(cont.objects) do
            if entry.role == "scroll" then
                _drawWidget(entry.ref)
            end
        end
        love.graphics.setScissor()

        -- ── Fade masks at scroll area top/bottom edges ────────────────────
        -- Top mask: covers transition from header into scroll area
        love.graphics.setColor(cont.headerColor[1], cont.headerColor[2], cont.headerColor[3], 0.6)
        love.graphics.rectangle("fill", sr.x, sr.y, sr.width, 4)
        -- Bottom mask: covers transition from scroll area into footer
        love.graphics.setColor(cont.footerColor[1], cont.footerColor[2], cont.footerColor[3], 0.6)
        love.graphics.rectangle("fill", sr.x, sr.y + sr.height - 4, sr.width, 4)

        -- ── Footer strip ─────────────────────────────────────────────────
        if fr.height > 0 then
            love.graphics.setColor(cont.footerColor[1], cont.footerColor[2], cont.footerColor[3], 1)
            love.graphics.rectangle("fill", fr.x, fr.y, fr.width, fr.height)
            for _, entry in ipairs(cont.objects) do
                if entry.role == "footer" then
                    _drawWidget(entry.ref)
                end
            end
        end

        love.graphics.reset()

        ::next_cont::
    end
end
