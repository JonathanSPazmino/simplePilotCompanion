-- container_gdsGuiLib.lua
-- Page-layout system: fixed header/footer zones + single scrollable body containing panels.
--
-- DEVELOPER USAGE (in main.lua):
--
--   -- 1) Create containers FIRST (before any widgets that belong to them):
--   gdsGui_container_create("navBar",    "MainMenu", "PILOT COMPANION", 50, 0, "pageHeader")
--   gdsGui_container_create("footBar",   "MainMenu", "",                40, 0, "pageFooter")
--   gdsGui_container_create("myPanel",   "MainMenu", "MY PANEL",        32, 0)
--
--   -- 2) Pass the container name as the last arg when creating widgets:
--   gdsGui_button_create("myBtn",   "MainMenu", ..., true, "myPanel")
--   gdsGui_outputTxtBox_create("myLabel", "MainMenu", ..., 12, "myPanel")
--   -- gdsGui_container_addObject is called automatically; no manual calls needed.
--
--   -- 3) Finalise once after all containers on a page are declared:
--   gdsGui_container_finalise("MainMenu")
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
--  PRIVATE — resize a widget to explicit pixel dimensions
-- ---------------------------------------------------------------------------

local function _setObjDimensions(obj, pixW, pixH)
    if obj.objectType == "button" then
        obj.mywidth  = pixW
        obj.myheight = pixH
        local baseImg = obj.images[globApp.BUTTON_STATES.RELEASED]
                     or obj.images[globApp.BUTTON_STATES.PRESSED]
        obj.factorWidth  = pixW / baseImg:getWidth()
        obj.factorHeight = pixH / baseImg:getHeight()

    elseif obj.objectType == "outputTextBox" then
        obj.frame.width  = pixW
        obj.frame.height = pixH
        if obj.bgSprite and obj.bgSprite.sprite then
            obj.bgSprite.width  = pixW / obj.bgSprite.sprite:getWidth()
            obj.bgSprite.height = pixH / obj.bgSprite.sprite:getHeight()
        end
        obj.text.width             = pixW * 0.8
        obj.text.maxTextLineCount  = findMaxNumOfLinesNeeded(obj.text.font, obj.text.width, obj.text.text)
        obj.text.height            = gdsGui_general_returnFontInfo(obj.text.font, "height")
        obj.text.combinedTxtHeight = obj.text.height * obj.text.maxTextLineCount
        obj.text.lastText          = nil  -- force line reflow on next update

    elseif obj.objectType == "scrollBar" then
        obj.original.width  = pixW
        obj.original.height = pixH
        obj.frame.width     = pixW
        if obj.upButton then
            local arrowSide = pixW
            obj.upButton.width          = pixW;     obj.upButton.height          = arrowSide
            obj.downButton.width        = pixW;     obj.downButton.height        = arrowSide
            obj.upButton.factorWidth    = pixW / obj.imgButtonUpArrow_active:getWidth()
            obj.upButton.factorHeight   = arrowSide / obj.imgButtonUpArrow_active:getHeight()
            obj.downButton.factorWidth  = pixW / obj.imgButtonDownArrow_active:getWidth()
            obj.downButton.factorHeight = arrowSide / obj.imgButtonDownArrow_active:getHeight()
            obj.frame.height = pixH - 2 * arrowSide
        else
            obj.frame.height = pixH
        end
        if obj.orientation == "vertical" then
            obj.bar.width = pixW;  obj.bar.height = pixW
        else
            obj.bar.width = pixH;  obj.bar.height = pixH
        end

    elseif obj.objectType == "rotaryKnob" then
        local s        = pixW   -- knobs are square; width drives size
        obj.size       = s
        local iw, ih   = obj.imgReleased:getDimensions()
        obj.scaleX     = s / iw
        obj.scaleY     = s / ih
        obj.imgOriginX = iw * 0.5
        obj.imgOriginY = ih * 0.5
        if obj.isDual then
            local ratio        = obj.innerRatio or 0.8
            obj.inner.size     = s * ratio
            local iiw, iih     = obj.inner.imgReleased:getDimensions()
            obj.inner.scaleX   = obj.inner.size / iiw
            obj.inner.scaleY   = obj.inner.size / iih
        end
    end
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
            line.x         = obj.text.x
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
            line.naturalY  = line.naturalY + dy
            line.y         = line.naturalY + obj.scroll.offsetY
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

-- Update only the X coordinate of a widget (mirror of _setObjY, used by hScroll).
local function _setObjX(obj, newX)
    if obj.objectType == "button" then
        obj.myx    = math.floor(newX)
        obj.myMaxx = obj.myx + obj.mywidth

    elseif obj.objectType == "outputTextBox" then
        obj.frame.x    = math.floor(newX)
        if obj.bgSprite then obj.bgSprite.x = obj.frame.x end
        obj.text.x = obj.frame.x + (obj.frame.width - obj.text.width) / 2
        for _, line in ipairs(obj.text.lines) do
            line.x = obj.text.x
        end

    elseif obj.objectType == "rotaryKnob" then
        obj.x       = math.floor(newX)
        obj.centerX = obj.x + obj.size * 0.5
    end
end

-- ---------------------------------------------------------------------------
--  PRIVATE — horizontal scroll helpers (pageHeader / pageFooter containers)
-- ---------------------------------------------------------------------------

-- Returns (minOffsetX, maxOffsetX) for cont.hScroll.offsetX.
-- maxOffset is always 0 (content at natural left).
local function _hScrollLimits(cont)
    if not cont.hScroll then return 0, 0 end
    local minOff = math.min(0, cont.frame.width - (cont.hScroll.contentWidth or 0))
    return minOff, 0
end

-- Shift all widgets in a header/footer container by hScroll.offsetX.
local function _applyHScroll(cont)
    if not cont.hScroll then return end
    local ox = cont.hScroll.offsetX
    for _, entry in ipairs(cont.objects) do
        _setObjX(entry.ref, entry.naturalX + ox)
    end
end

-- Called after _layoutObjects to measure the total content width and clamp offset.
local function _computeHScrollContentWidth(cont)
    if not cont.hScroll then return end
    local maxRight = cont.frame.x
    for _, entry in ipairs(cont.objects) do
        local obj   = entry.ref
        local right = entry.naturalX
        if     obj.objectType == "button"       then right = right + obj.mywidth
        elseif obj.objectType == "outputTextBox" then right = right + obj.frame.width
        elseif obj.objectType == "rotaryKnob"   then right = right + obj.size
        end
        if right > maxRight then maxRight = right end
    end
    cont.hScroll.contentWidth = math.max(0, maxRight - cont.frame.x) + PADDING
    local minOff = math.min(0, cont.frame.width - cont.hScroll.contentWidth)
    cont.hScroll.offsetX = math.max(minOff, math.min(0, cont.hScroll.offsetX))
    _applyHScroll(cont)
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
--  PRIVATE — resolve anchor-point pixel position
-- ---------------------------------------------------------------------------

-- ox, oy: pixel offsets from the base rect's origin (container scroll-rect
-- top-left).  Returns {floor(x), floor(y)} of the widget's top-left corner.
local function _anchorPos(anchor, ox, oy, w, h, bx, by)
    local ax = anchor:sub(1, 1)   -- L / C / R
    local ay = anchor:sub(2, 2)   -- T / C / B
    local px = bx + ox
    local py = by + oy
    if     ax == "C" then px = px - w * 0.5
    elseif ax == "R" then px = px - w
    end
    if     ay == "C" then py = py - h * 0.5
    elseif ay == "B" then py = py - h
    end
    return { math.floor(px), math.floor(py) }
end

-- ---------------------------------------------------------------------------
--  PRIVATE — layout widgets within a single container
-- ---------------------------------------------------------------------------

-- Positions widgets using pixel-based containerFrac values (x, y, w, h in px).
-- x/y are pixel offsets from the container's scroll-rect origin; the anchor
-- point determines which corner/edge of the widget sits at that coordinate.
local function _layoutObjects(cont)
    local sr          = cont.scrollRect
    local maxContentH = 0
    local minTopY     = math.huge

    for _, entry in ipairs(cont.objects) do
        local obj = entry.ref
        local cf  = obj.containerFrac
        if not cf then goto continue end

        local baseX, baseY
        if     entry.role == "header" then baseX, baseY = cont.headerRect.x, cont.headerRect.y
        elseif entry.role == "footer" then baseX, baseY = cont.footerRect.x, cont.footerRect.y
        else                               baseX, baseY = sr.x, sr.y
        end

        local pixW = math.max(1, math.floor(cf.w))
        local pixH = math.max(1, math.floor(cf.h))
        if obj.objectType == "rotaryKnob" then pixH = pixW end

        _setObjDimensions(obj, pixW, pixH)

        local anchorW = pixW
        local anchorH = (obj.objectType == "rotaryKnob") and obj.size or pixH
        local pos     = _anchorPos(cf.anchorPoint, cf.x, cf.y, anchorW, anchorH, baseX, baseY)

        entry.naturalX = pos[1]
        entry.naturalY = pos[2]
        _initObjForContainer(obj, pos[1], pos[2])

        if entry.role == "scroll" then
            local topY   = pos[2] - sr.y
            local bottom = topY + anchorH
            if topY   < minTopY     then minTopY     = topY   end
            if bottom > maxContentH then maxContentH = bottom  end
        end

        ::continue::
    end

    -- Bottom buffer mirrors the top gap, with PADDING as a minimum so containers
    -- whose topmost widget starts at y=0 (e.g. CC-anchored) still get spacing.
    local bottomBuffer = (minTopY < math.huge) and math.max(PADDING, minTopY) or PADDING
    cont.contentHeight = math.max(0, maxContentH + bottomBuffer)
end

-- ---------------------------------------------------------------------------
--  PRIVATE — reposition widgets when a container's scroll-rect dimensions change
-- ---------------------------------------------------------------------------
-- Repositions widgets when a container's scroll-rect dimensions change.
-- Widget sizes (DIP) are never altered; only positions shift so that each
-- widget maintains its relationship to the container edge it was anchored to:
--   L → fixed left offset      C → tracks the midpoint      R → fixed right offset
--   T → fixed top  offset      C → tracks the midpoint      B → fixed bottom offset
-- Y shifts are suppressed for header/footer-role objects (fixed-height title strip).
local function _layoutObjectsScaled(cont)
    local origW = cont.originalScrollWidth
    local origH = cont.originalScrollHeight
    local sr    = cont.scrollRect          -- already updated by _computeSubrects
    local dW    = sr.width  - origW        -- how much wider/narrower the scroll area is
    local dH    = sr.height - origH        -- how much taller/shorter

    local maxContentH = 0
    local minTopY     = math.huge

    for _, entry in ipairs(cont.objects) do
        local obj = entry.ref
        local cf0 = entry.origCF or obj.containerFrac
        if not cf0 then goto continue end

        local baseX, baseY
        if     entry.role == "header" then baseX, baseY = cont.headerRect.x, cont.headerRect.y
        elseif entry.role == "footer" then baseX, baseY = cont.footerRect.x, cont.footerRect.y
        else                               baseX, baseY = sr.x, sr.y
        end

        -- Sizes are density-independent and never rescaled.
        local pixW = math.max(1, cf0.w)
        local pixH = math.max(1, cf0.h)
        if obj.objectType == "rotaryKnob" then pixH = pixW end

        _setObjDimensions(obj, pixW, pixH)

        local anchorW = pixW
        local anchorH = (obj.objectType == "rotaryKnob") and obj.size or pixH

        -- Horizontal: shift position so the anchored edge stays at the same
        -- distance from the container edge it was originally anchored to.
        local ax  = cf0.anchorPoint:sub(1, 1)   -- L / C / R
        local effX = cf0.x
        if     ax == "C" then effX = cf0.x + dW * 0.5
        elseif ax == "R" then effX = cf0.x + dW
        end

        -- Vertical: same logic, but Y shift is suppressed outside the scroll area.
        local ay   = cf0.anchorPoint:sub(2, 2)  -- T / C / B
        local effY = cf0.y
        if entry.role == "scroll" then
            if     ay == "C" then effY = cf0.y + dH * 0.5
            elseif ay == "B" then effY = cf0.y + dH
            end
        end

        local pos = _anchorPos(cf0.anchorPoint,
                               math.floor(effX), math.floor(effY),
                               anchorW, anchorH, baseX, baseY)

        entry.naturalX = pos[1]
        entry.naturalY = pos[2]
        _initObjForContainer(obj, pos[1], pos[2])

        if entry.role == "scroll" then
            local topY   = pos[2] - sr.y
            local bottom = topY + anchorH
            if topY   < minTopY     then minTopY     = topY   end
            if bottom > maxContentH then maxContentH = bottom  end
        end

        ::continue::
    end

    local bottomBuffer = (minTopY < math.huge) and math.max(PADDING, minTopY) or PADDING
    cont.contentHeight = math.max(0, maxContentH + bottomBuffer)
end

-- ---------------------------------------------------------------------------
--  PRIVATE — page-level layout
-- ---------------------------------------------------------------------------

local function _layoutPage(pageName)
    local sa = globApp.safeScreenArea

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
        _computeHScrollContentWidth(cont)
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
        _computeHScrollContentWidth(cont)
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
        -- First-layout detection: originalScrollWidth is nil until first finalize.
        -- At first finalize we always use single-column (portrait reference) to
        -- establish per-container original dimensions and per-object origCF.
        local isFirstLayout = not bodyConts[1].originalScrollWidth

        -- Original container width = portrait single-column body width.
        -- On subsequent layouts this drives the column count decision.
        local origContW = isFirstLayout and bodyArea.width
                                        or  bodyConts[1].originalScrollWidth

        -- Number of columns: how many original-width containers fit side by side.
        local numCols = math.max(1, math.min(#bodyConts,
                                 math.floor(bodyArea.width / origContW)))

        local contentH = 0
        local curY     = bodyArea.y

        if isFirstLayout then
            -- ── First layout: single column, capture reference dimensions ──────
            for _, cont in ipairs(bodyConts) do
                cont.frame = { x=bodyArea.x, y=curY, width=bodyArea.width, height=0 }
                _computeSubrects(cont)
                _layoutObjects(cont)
                cont.frame.height = cont.headerHeight + cont.contentHeight + cont.footerHeight

                -- Store per-container originals (portrait, single-column reference).
                cont.originalScrollWidth  = cont.scrollRect.width
                cont.originalScrollHeight = cont.contentHeight

                -- Store per-object origCF so resize can scale positions proportionally.
                for _, entry in ipairs(cont.objects) do
                    local cf = entry.ref.containerFrac
                    if cf then
                        entry.origCF = { x=cf.x, y=cf.y, w=cf.w, h=cf.h,
                                         anchorPoint=cf.anchorPoint }
                    end
                end

                cont.frameNaturalY = curY
                curY = curY + cont.frame.height
            end
            contentH = curY - bodyArea.y

        else
            -- ── Resize layout: row-based, proportional X/Y scaling ───────────

            -- Build rows of numCols containers each.
            local rows = {}
            local idx  = 1
            while idx <= #bodyConts do
                local row = {}
                for _ = 1, numCols do
                    if bodyConts[idx] then
                        table.insert(row, bodyConts[idx])
                        idx = idx + 1
                    end
                end
                table.insert(rows, row)
            end

            for _, row in ipairs(rows) do
                local numInRow = #row
                local baseW    = math.floor(bodyArea.width / numInRow)

                -- Row frame height = tallest container in the row
                -- (each cont's natural frame height = header + origScrollH + footer).
                local rowFrameH = 0
                for _, cont in ipairs(row) do
                    local fh = cont.headerHeight + cont.originalScrollHeight + cont.footerHeight
                    if fh > rowFrameH then rowFrameH = fh end
                end

                for ci, cont in ipairs(row) do
                    -- Last container fills any remaining pixel-rounding remainder.
                    local x = bodyArea.x + (ci - 1) * baseW
                    local w = (ci == numInRow)
                              and (bodyArea.x + bodyArea.width - x) or baseW

                    cont.frame = { x=x, y=curY, width=w, height=rowFrameH }
                    _computeSubrects(cont)
                    -- _computeSubrects sets scrollRect to reflect the new dimensions,
                    -- so _layoutObjectsScaled can read dW/dH directly from cont.
                    _layoutObjectsScaled(cont)
                    cont.frameNaturalY = curY
                end

                curY    = curY    + rowFrameH
            end

            contentH = curY - bodyArea.y
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

    -- pageHeader/pageFooter clip to their own frame so h-scrolled content
    -- doesn't bleed outside the fixed zones.
    local effectiveClip = clip
    if cont.pageRole == "pageHeader" or cont.pageRole == "pageFooter" then
        effectiveClip = f
    end

    _setClip(effectiveClip)

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
            local tc = globApp.themeTextColor or {1, 1, 1, 1}
            love.graphics.setColor(tc[1], tc[2], tc[3], tc[4] or 1)
            love.graphics.printf(cont.title, hr.x + PADDING, hr.y + PADDING,
                                 hr.width - 2 * PADDING, "left")
        end
        for _, entry in ipairs(cont.objects) do
            if entry.role == "header" then
                _drawWidget(entry.ref, effectiveClip)
            end
        end
    end

    -- Content (scroll-role) widgets.
    for _, entry in ipairs(cont.objects) do
        if entry.role == "scroll" then
            _drawWidget(entry.ref, effectiveClip)
        end
    end

    -- Footer strip.
    if fr.height > 0 then
        _setClip(effectiveClip)
        love.graphics.setColor(cont.footerColor[1], cont.footerColor[2], cont.footerColor[3], 1)
        love.graphics.rectangle("fill", fr.x, fr.y, fr.width, fr.height)
        for _, entry in ipairs(cont.objects) do
            if entry.role == "footer" then
                _drawWidget(entry.ref, effectiveClip)
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
        if not (x >= obj.frame.x and x <= obj.frame.x + obj.frame.width and
                y >= obj.frame.y and y <= obj.frame.y + obj.frame.height) then
            return false
        end
        -- Only suppress page scroll if the text content actually overflows the frame
        local contentH = obj.text and obj.text.combinedTxtHeight or 0
        return obj.frame.height - contentH < -0.5
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

    -- Horizontal scroll state (only for fixed pageHeader / pageFooter zones).
    if pageRole == "pageHeader" or pageRole == "pageFooter" then
        cont.hScroll = {
            offsetX      = 0,
            velocityX    = 0,
            phase        = "idle",
            isDragging   = false,
            touchStarted = false,
            contentWidth = 0,
        }
        cont.gestureDx = 0
        cont.gestureDy = 0
    end

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
    elseif objectType == "table" then
        for _, o in ipairs(globApp.objects.tables) do
            if o.name == objectName then obj = o; break end
        end
    elseif objectType == "inputTxtBox" then
        for _, o in ipairs(textBoxes) do
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

    -- pageHeader/pageFooter containers have no separate scroll area; default
    -- widgets to the "header" role so they are laid out in the full frame.
    local effectiveRole = role or (
        (cont.pageRole == "pageHeader" or cont.pageRole == "pageFooter")
        and "header" or "scroll"
    )

    table.insert(cont.objects, {
        ref      = obj,
        role     = effectiveRole,
        naturalX = 0,
        naturalY = 0,
    })
end

-- Call once after all containers on a page are declared, and again on resize.
function gdsGui_container_finalise(pageName)
    _layoutPage(pageName)
end

-- ---------------------------------------------------------------------------
--  PUBLIC API — convenience header / footer creators
-- ---------------------------------------------------------------------------
-- These wrap gdsGui_container_create so callers don't need to know about
-- pageRole or the internal height/footer-height parameters.
--
-- Widgets are added to a header or footer the same way as any container:
--   pass the header/footer name as the last "containerName" argument of any
--   widget-creation function (gdsGui_button_create, gdsGui_outputTxtBox_create …)
-- ---------------------------------------------------------------------------

-- Creates a fixed-height zone pinned to the top of the page.
--   name    : unique string identifier
--   page    : page this header belongs to
--   height  : pixel height of the zone
--   bgColor : {r,g,b[,a]} fill color; nil uses the library default dark gray
function gdsGui_pageHeader_create(name, page, height, bgColor)
    gdsGui_container_create(name, page, "", height, 0, "pageHeader")
    if bgColor then
        local cont = globApp.objects.containers[#globApp.objects.containers]
        cont.bgColor     = { bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1 }
        cont.headerColor = cont.bgColor
    end
end

-- Creates a fixed-height zone pinned to the bottom of the page.
--   name    : unique string identifier
--   page    : page this footer belongs to
--   height  : pixel height of the zone
--   bgColor : {r,g,b[,a]} fill color; nil uses the library default dark gray
function gdsGui_pageFooter_create(name, page, height, bgColor)
    gdsGui_container_create(name, page, "", height, 0, "pageFooter")
    if bgColor then
        local cont = globApp.objects.containers[#globApp.objects.containers]
        cont.bgColor     = { bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1 }
        cont.headerColor = cont.bgColor
    end
end

-- ---------------------------------------------------------------------------
--  PUBLIC API — physics update (page-level scroll)
-- ---------------------------------------------------------------------------

function gdsGui_container_physicsUpdate(dt)
    if not dt or dt <= 0 then return end

    local activePage = gdsGui_page_currentName()

    -- ── Vertical page scroll ────────────────────────────────────────────────
    local state = globApp.objects.pageScrollStates[activePage]
    if state then
        local s = state.scroll
        if not (s.isDragging or s.phase == "idle") then
            local minOff, maxOff = _pageScrollLimits(state)
            if minOff < -0.5 then
                if s.phase == "coasting" then
                    s.velocityY = s.velocityY * math.exp(-CONT_FRICTION * dt)
                    s.offsetY   = s.offsetY   + s.velocityY * dt
                    if s.offsetY < minOff or s.offsetY > maxOff then
                        s.phase = "bouncing"
                    elseif math.abs(s.velocityY) < CONT_COAST_STOP_VEL then
                        s.phase = "idle";  s.velocityY = 0
                    end
                    _applyPageScroll(activePage)
                elseif s.phase == "bouncing" then
                    local target = math.max(minOff, math.min(maxOff, s.offsetY))
                    local disp   = s.offsetY - target
                    local acc    = (-CONT_SPRING_K * disp) + (-CONT_SPRING_C * s.velocityY)
                    s.velocityY  = s.velocityY + acc * dt
                    s.offsetY    = s.offsetY   + s.velocityY * dt
                    if math.abs(s.offsetY - target) < CONT_BOUNCE_STOP_D and
                       math.abs(s.velocityY) < CONT_BOUNCE_STOP_V then
                        s.offsetY = target;  s.velocityY = 0;  s.phase = "idle"
                    end
                    _applyPageScroll(activePage)
                end
            end
        end
    end

    -- ── Horizontal scroll for pageHeader / pageFooter containers ────────────
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == activePage and cont.hScroll then
            local hs = cont.hScroll
            if not (hs.isDragging or hs.phase == "idle") then
                local minOff, maxOff = _hScrollLimits(cont)
                if minOff < -0.5 then
                    if hs.phase == "coasting" then
                        hs.velocityX = hs.velocityX * math.exp(-CONT_FRICTION * dt)
                        hs.offsetX   = hs.offsetX   + hs.velocityX * dt
                        if hs.offsetX < minOff or hs.offsetX > maxOff then
                            hs.phase = "bouncing"
                        elseif math.abs(hs.velocityX) < CONT_COAST_STOP_VEL then
                            hs.phase = "idle";  hs.velocityX = 0
                        end
                        _applyHScroll(cont)
                    elseif hs.phase == "bouncing" then
                        local target = math.max(minOff, math.min(maxOff, hs.offsetX))
                        local disp   = hs.offsetX - target
                        local acc    = (-CONT_SPRING_K * disp) + (-CONT_SPRING_C * hs.velocityX)
                        hs.velocityX = hs.velocityX + acc * dt
                        hs.offsetX   = hs.offsetX   + hs.velocityX * dt
                        if math.abs(hs.offsetX - target) < CONT_BOUNCE_STOP_D and
                           math.abs(hs.velocityX) < CONT_BOUNCE_STOP_V then
                            hs.offsetX = target;  hs.velocityX = 0;  hs.phase = "idle"
                        end
                        _applyHScroll(cont)
                    end
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
--  PUBLIC API — touch/mouse scroll (page-level)
-- ---------------------------------------------------------------------------

function gdsGui_container_touchScroll(id, x, y, dx, dy)
    local isGestureActive = (globApp.userInput == "slide") or love.mouse.isDown(1)
    if not isGestureActive then return end

    local activePage = gdsGui_page_currentName()
    local frameDt    = love.timer.getDelta()

    -- ── Vertical page scroll ─────────────────────────────────────────────────
    local state = globApp.objects.pageScrollStates[activePage]
    if state and state.scroll.touchStartedInside then
        local s              = state.scroll
        local minOff, maxOff = _pageScrollLimits(state)
        if minOff < -0.5 then
            s.isDragging = true
            s.phase      = "coasting"
            local newOff = s.offsetY + dy
            if newOff < minOff then
                newOff = minOff + (newOff - minOff) * CONT_RUBBER_BAND
            elseif newOff > maxOff then
                newOff = maxOff + (newOff - maxOff) * CONT_RUBBER_BAND
            end
            s.offsetY = newOff
            if frameDt > 0 then
                s.velocityY = s.velocityY * 0.5 + (dy / frameDt) * 0.5
            end
            _applyPageScroll(activePage)
        end
    end

    -- ── Horizontal scroll for pageHeader / pageFooter containers ─────────────
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == activePage and cont.hScroll and cont.hScroll.touchStarted then
            local hs = cont.hScroll
            local minOff, maxOff = _hScrollLimits(cont)
            if minOff < -0.5 then
                hs.isDragging = true
                hs.phase      = "coasting"
                local newOff = hs.offsetX + dx
                if newOff < minOff then
                    newOff = minOff + (newOff - minOff) * CONT_RUBBER_BAND
                elseif newOff > maxOff then
                    newOff = maxOff + (newOff - maxOff) * CONT_RUBBER_BAND
                end
                hs.offsetX = newOff
                if frameDt > 0 then
                    hs.velocityX = hs.velocityX * 0.5 + (dx / frameDt) * 0.5
                end
                _applyHScroll(cont)
            end
        end
    end
end

function gdsGui_container_touchReleased(x, y)
    local activePage = gdsGui_page_currentName()

    -- ── Vertical page scroll release ─────────────────────────────────────────
    local state = globApp.objects.pageScrollStates[activePage]
    if state then
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
                s.phase = "idle";  s.velocityY = 0
            end
        end
        s.touchStartedInside = false
    end

    -- ── Horizontal scroll release for pageHeader / pageFooter ────────────────
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == activePage and cont.hScroll then
            local hs = cont.hScroll
            if hs.isDragging then
                hs.isDragging = false
                local minOff, maxOff = _hScrollLimits(cont)
                if hs.offsetX < minOff or hs.offsetX > maxOff then
                    hs.phase = "bouncing"
                elseif math.abs(hs.velocityX) > CONT_COAST_STOP_VEL then
                    hs.phase = "coasting"
                else
                    hs.phase = "idle";  hs.velocityX = 0
                end
            end
            hs.touchStarted = false
        end
    end
end

-- Mark scroll-start state when a touch/mouse-press lands.
-- • Body area  → marks vertical page scroll touchStartedInside (suppressed if on a widget).
-- • Header/Footer zone → marks horizontal scroll touchStarted for that container.
function gdsGui_container_markTouchStart(x, y)
    local activePage = gdsGui_page_currentName()

    -- ── Header / footer horizontal scroll start ──────────────────────────────
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == activePage and cont.hScroll then
            local f = cont.frame
            if x >= f.x and x <= f.x + f.width and
               y >= f.y and y <= f.y + f.height then
                cont.hScroll.touchStarted = true
                cont.hScroll.velocityX    = 0
            end
        end
    end

    -- ── Body vertical page scroll start ─────────────────────────────────────
    local state = globApp.objects.pageScrollStates[activePage]
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
--  PUBLIC API — programmatic scroll-to-panel
-- ---------------------------------------------------------------------------

-- Instantly scrolls the body so that the named container is at the top of the
-- body area.  Useful for navigation buttons in a fixed footer.
function gdsGui_container_scrollToBody(pageName, containerName)
    local state = globApp.objects.pageScrollStates[pageName]
    if not state then return end
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.page == pageName and cont.pageRole == "body" and cont.name == containerName then
            local minOff = math.min(0, state.bodyArea.height - state.contentHeight)
            local target = math.max(minOff, math.min(0, state.bodyArea.y - cont.frameNaturalY))
            state.scroll.offsetY   = target
            state.scroll.phase     = "idle"
            state.scroll.velocityY = 0
            _applyPageScroll(pageName)
            return
        end
    end
end

-- ---------------------------------------------------------------------------
--  PUBLIC API — container clip hit-test
-- ---------------------------------------------------------------------------

-- Returns true when (x,y) is within the visible clip rect of obj's owner container.
-- • body containers  → clip is the page body area (between fixed header and footer).
-- • header/footer    → clip is the container's own frame.
-- • no ownerContainer → always true (standalone widget).
function gdsGui_container_isTouchInOwnerContainer(obj, x, y)
    if not obj.ownerContainer then return true end
    for _, cont in ipairs(globApp.objects.containers) do
        if cont.name == obj.ownerContainer then
            if cont.pageRole == "body" then
                local state = globApp.objects.pageScrollStates[cont.page]
                if state then
                    local ba = state.bodyArea
                    return x >= ba.x and x <= ba.x + ba.width and
                           y >= ba.y and y <= ba.y + ba.height
                end
                return true
            end
            local f = cont.frame
            return x >= f.x and x <= f.x + f.width and
                   y >= f.y and y <= f.y + f.height
        end
    end
    return true
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
