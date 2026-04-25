--[[API = Menu labels Lybrary ]]

-----------------------------------------------------------------
globApp.objects.outputTextBox = {}

-- ---------------------------------------------------------------------------
--  MOMENTUM SCROLL PHYSICS CONSTANTS
-- ---------------------------------------------------------------------------
local SCROLL_FRICTION  = 3.5    -- exponential velocity decay rate (per second)
local SPRING_OMEGA     = 18.0   -- natural frequency of bounce spring (rad/s)
local SPRING_K         = SPRING_OMEGA * SPRING_OMEGA   -- stiffness  = 324
local SPRING_C         = 2.0   * SPRING_OMEGA          -- critical damping = 36
local RUBBER_BAND      = 0.35   -- drag resistance factor when beyond limits (0–1)
local COAST_STOP_VEL   = 8.0    -- pixels/sec below which coasting is considered stopped
local BOUNCE_STOP_DISP = 0.5    -- pixels of displacement below which spring snaps to limit
local BOUNCE_STOP_VEL  = 5.0    -- pixels/sec below which spring is considered settled


-- ---------------------------------------------------------------------------
--  PRIVATE HELPERS
-- ---------------------------------------------------------------------------

-- Returns (minOffsetY, maxOffsetY) for tb.scroll.offsetY.
-- maxOffset is always 0 (content at natural top position).
-- minOffset is negative when content is taller than the frame.
local function _getScrollLimits(tb)
	local minOffset = math.min(0, tb.frame.height - tb.text.combinedTxtHeight)
	return minOffset, 0
end

-- Applies elastic rubber-band resistance when offset exceeds limits.
local function _applyRubberBand(offset, minOffset, maxOffset)
	if offset < minOffset then
		return minOffset + (offset - minOffset) * RUBBER_BAND
	elseif offset > maxOffset then
		return maxOffset + (offset - maxOffset) * RUBBER_BAND
	end
	return offset
end

-- Recomputes each line's screen Y from its natural (unscrolled) Y plus the
-- current scroll offset, then refreshes isVisible.
local function _apply_scroll_offset(tb)
	for _, line in ipairs(tb.text.lines) do
		line.y = line.naturalY + tb.scroll.offsetY
		line.isVisible = gdsGui_outputTxtBox_isTextInFrame(tb.frame, line)
	end
end


-- ---------------------------------------------------------------------------
--  CREATION
-- ---------------------------------------------------------------------------

function gdsGui_outputTxtBox_create (id, page, bgSprite, x, y, anchorPoint, width, height, txtColor, text, fontSize, containerName)

	local tb = {}

		tb.name       = id
		tb.objectType = "outputTextBox"
		tb.page       = page
		tb.type       = labelType

		tb.x           = x
		tb.y           = y
		tb.anchorPoint = anchorPoint
		tb.rltvWidth   = width
		tb.rltvHeight  = height
			local myPositions = gdsGui_general_relativePosition(anchorPoint, x, y, tb.rltvWidth, tb.rltvHeight,
			                                     globApp.safeScreenArea.x, globApp.safeScreenArea.y,
			                                     globApp.safeScreenArea.w, globApp.safeScreenArea.h)
		tb.state = 1

		tb.frame = {}
			tb.frame.width  = width
			tb.frame.height = height
			tb.frame.x = math.floor(myPositions[1])
			tb.frame.y = math.floor(myPositions[2])

		tb.bgSprite = {}
			if bgSprite ~= nil then
				tb.bgSprite.sprite = love.graphics.newImage(bgSprite)
				tb.bgSprite.width  = width / tb.bgSprite.sprite:getWidth()
				tb.bgSprite.height = height / tb.bgSprite.sprite:getHeight()
				tb.bgSprite.x = tb.frame.x
				tb.bgSprite.y = tb.frame.y
			end

		tb.text = {}
			tb.text.font = love.graphics.newFont(fontSize)
			if tb.state == 1 then
				tb.text.color    = txtColor
				tb.text.text     = text
				tb.text.lastText = text
			elseif tb.state == 2 then
				tb.text.color    = {1, 0, 0, 1}
				tb.text.text     = "txtOutputBox Error"
				tb.text.lastText = "txtOutputBox Error"
			end

			tb.text.width            = tb.frame.width * 0.8
			tb.text.maxTextLineCount = findMaxNumOfLinesNeeded(tb.text.font, tb.text.width, tb.text.text)
			tb.text.height           = gdsGui_general_returnFontInfo(tb.text.font, "height")
			tb.text.combinedTxtHeight= tb.text.height * tb.text.maxTextLineCount
			tb.text.x                = tb.frame.x + ((tb.frame.width - tb.text.width) / 2)
			tb.text.baseY            = tb.frame.y

			local _w, wrappedtext = tb.text.font:getWrap(tb.text.text, tb.text.width)

			tb.text.lines = {}
			for t, l in ipairs(wrappedtext) do
				local newLine = {}
				newLine.text      = l
				newLine.x         = tb.text.x
				newLine.width     = tb.text.width
				newLine.naturalY  = tb.text.baseY + ((tb.text.height * t) - tb.text.height)
				newLine.y         = newLine.naturalY
				newLine.height    = tb.text.height
				newLine.color     = tb.text.color
				newLine.alignement= "center"
				newLine.isVisible = gdsGui_outputTxtBox_isTextInFrame(tb.frame, newLine)
				table.insert(tb.text.lines, newLine)
			end

		-- Momentum scroll physics state
		tb.scroll = {
			offsetY    = 0,      -- cumulative scroll offset in pixels (≤ 0 scrolled down)
			velocityY  = 0,      -- current velocity in pixels/second
			phase      = "idle", -- "idle" | "coasting" | "bouncing"
			isDragging = false,  -- true while a finger/mouse is actively dragging
		}

		table.insert(globApp.objects.outputTextBox, tb)
		globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1
		if containerName then
			gdsGui_container_addObject(containerName, "outputTextBox", id)
		end

end


-- ---------------------------------------------------------------------------
--  PRIVATE RECALCULATE (resize / text change)
-- ---------------------------------------------------------------------------

local function _recalculate_textBox(updtLbl)

	if globApp.lastSafeScreenArea and globApp.lastSafeScreenArea.w > 0 then

		updtLbl.rltvWidth  = updtLbl.frame.width
		updtLbl.rltvHeight = updtLbl.frame.height

		-- Container-owned textboxes: the container system owns frame.x/y.
		-- Recalculating from relative coords would snap the box back to its
		-- original pre-scroll position on every text change.
		if not updtLbl.ownerContainer then
			local myPositions = gdsGui_general_relativePosition(updtLbl.anchorPoint, updtLbl.x, updtLbl.y,
			                                     updtLbl.rltvWidth, updtLbl.rltvHeight,
			                                     globApp.safeScreenArea.x, globApp.safeScreenArea.y,
			                                     globApp.safeScreenArea.w, globApp.safeScreenArea.h)
			updtLbl.frame.x = math.floor(myPositions[1])
			updtLbl.frame.y = math.floor(myPositions[2])
			if updtLbl.bgSprite.sprite ~= nil then
				updtLbl.bgSprite.x = updtLbl.frame.x
				updtLbl.bgSprite.y = updtLbl.frame.y
			end
		end

		if updtLbl.bgSprite.sprite ~= nil then
			updtLbl.bgSprite.width  = updtLbl.frame.width  / updtLbl.bgSprite.sprite:getWidth()
			updtLbl.bgSprite.height = updtLbl.frame.height / updtLbl.bgSprite.sprite:getHeight()
		end

		updtLbl.text.width             = updtLbl.frame.width * 0.8
		updtLbl.text.maxTextLineCount  = findMaxNumOfLinesNeeded(updtLbl.text.font, updtLbl.text.width, updtLbl.text.text)
		updtLbl.text.height            = gdsGui_general_returnFontInfo(updtLbl.text.font, "height")
		updtLbl.text.combinedTxtHeight = updtLbl.text.height * updtLbl.text.maxTextLineCount
		updtLbl.text.x                 = updtLbl.frame.x + ((updtLbl.frame.width - updtLbl.text.width) / 2)
		updtLbl.text.baseY             = updtLbl.frame.y

		local _w, wrappedtext = updtLbl.text.font:getWrap(updtLbl.text.text, updtLbl.text.width)
		updtLbl.text.lines = {}
		for t, l in ipairs(wrappedtext) do
			local newLine = {}
			newLine.text      = l
			newLine.x         = updtLbl.text.x
			newLine.width     = updtLbl.text.width
			newLine.naturalY  = updtLbl.text.baseY + ((updtLbl.text.height * t) - updtLbl.text.height)
			newLine.y         = newLine.naturalY
			newLine.height    = updtLbl.text.height
			newLine.color     = updtLbl.text.color
			newLine.alignement= "center"
			newLine.isVisible = gdsGui_outputTxtBox_isTextInFrame(updtLbl.frame, newLine)
			table.insert(updtLbl.text.lines, newLine)
		end

		-- Clamp scroll to new limits and re-apply offset
		if updtLbl.scroll then
			local minOff, maxOff = _getScrollLimits(updtLbl)
			updtLbl.scroll.offsetY = math.max(minOff, math.min(maxOff, updtLbl.scroll.offsetY))
			_apply_scroll_offset(updtLbl)
		end

	end
end


-- ---------------------------------------------------------------------------
--  UPDATE (called every frame with dt from gdsGui_update)
-- ---------------------------------------------------------------------------

function gdsGui_outputTxtBox_update(dt)

	for i, updtLbl in ipairs(globApp.objects.outputTextBox) do

		-- Rebuild lines on resize or text change
		if globApp.resizeDetected or (updtLbl.text.text ~= updtLbl.text.lastText) then
			_recalculate_textBox(updtLbl)
			updtLbl.text.lastText = updtLbl.text.text
		end

		-- Physics: skip when dragging, idle, or no real dt
		if updtLbl.scroll and not updtLbl.scroll.isDragging
		   and updtLbl.scroll.phase ~= "idle"
		   and dt and dt > 0 then

			local minOff, maxOff = _getScrollLimits(updtLbl)
			local canScroll = (minOff < -0.5)  -- content must overflow frame to scroll

			if canScroll then

				if updtLbl.scroll.phase == "coasting" then
					-- ── Exponential friction ──────────────────────────────────────
					updtLbl.scroll.velocityY = updtLbl.scroll.velocityY * math.exp(-SCROLL_FRICTION * dt)
					updtLbl.scroll.offsetY   = updtLbl.scroll.offsetY   + updtLbl.scroll.velocityY * dt

					if updtLbl.scroll.offsetY < minOff or updtLbl.scroll.offsetY > maxOff then
						-- Flew past a boundary → hand off to spring
						updtLbl.scroll.phase = "bouncing"
					elseif math.abs(updtLbl.scroll.velocityY) < COAST_STOP_VEL then
						updtLbl.scroll.phase     = "idle"
						updtLbl.scroll.velocityY = 0
					end
					_apply_scroll_offset(updtLbl)

				elseif updtLbl.scroll.phase == "bouncing" then
					-- ── Critically-damped spring back to nearest limit ────────────
					local target     = math.max(minOff, math.min(maxOff, updtLbl.scroll.offsetY))
					local disp       = updtLbl.scroll.offsetY - target
					local springAcc  = (-SPRING_K * disp) + (-SPRING_C * updtLbl.scroll.velocityY)
					updtLbl.scroll.velocityY = updtLbl.scroll.velocityY + springAcc * dt
					updtLbl.scroll.offsetY   = updtLbl.scroll.offsetY   + updtLbl.scroll.velocityY * dt

					-- Settle check
					local newDisp = math.abs(updtLbl.scroll.offsetY - target)
					if newDisp < BOUNCE_STOP_DISP and math.abs(updtLbl.scroll.velocityY) < BOUNCE_STOP_VEL then
						updtLbl.scroll.offsetY   = target
						updtLbl.scroll.velocityY = 0
						updtLbl.scroll.phase     = "idle"
					end
					_apply_scroll_offset(updtLbl)

				end
			end
		end

	end

end


-- ---------------------------------------------------------------------------
--  DELETE
-- ---------------------------------------------------------------------------

function gdsGui_outputTxtBox_delete (id, page)

	for i = #globApp.objects.outputTextBox, 1, -1 do

		local l = globApp.objects.outputTextBox[i]

		if l.name == id and l.page == page then
			table.remove(globApp.objects.outputTextBox, i)
			globApp.numObjectsDisplayed = globApp.numObjectsDisplayed - 1
		end

	end

end


-- ---------------------------------------------------------------------------
--  DRAW
-- ---------------------------------------------------------------------------

function gdsGui_outputTxtBox_draw (pg)
	for i, t in ipairs(globApp.objects.outputTextBox) do
		if t.page == pg and not t.ownerContainer then

			if t.bgSprite.sprite ~= nil then
				love.graphics.draw(t.bgSprite.sprite, t.bgSprite.x, t.bgSprite.y,
				                   0, t.bgSprite.width, t.bgSprite.height, ox, oy, kx, ky)
			end

			if t.state == 1 then
				love.graphics.rectangle("line", t.frame.x, t.frame.y, t.frame.width, t.frame.height, rx, ry, segments)
				love.graphics.setFont(t.text.font)

				-- Clip to frame using a scissor so scrolled-out text is hidden
				local prevScissor = {love.graphics.getScissor()}
				love.graphics.setScissor(t.frame.x, t.frame.y, t.frame.width, t.frame.height)

				for y, z in ipairs(t.text.lines) do
					if z.isVisible == true then
						love.graphics.setColor(t.text.color[1], t.text.color[2], t.text.color[3], t.text.color[4])
						love.graphics.printf(z.text, z.x, z.y, z.width, "center", 0, nil, nil, nil, nil, nil, nil)
					end
				end

				love.graphics.setScissor()
				love.graphics.reset()

			elseif t.state == 2 then
				if t.labelText2 ~= nil then
					love.graphics.setColor(t.text.color[1], t.text.color[2], t.text.color[3], t.text.color[4])
					love.graphics.rectangle("line", t.frame.x, t.frame.y, t.frame.width, t.frame.height, rx, ry, segments)
					love.graphics.setFont(t.text.font)
					love.graphics.printf(t.text.text, t.text.x, t.text.y, t.text.width, "center", 0, nil, nil, nil, nil, nil, nil)
					love.graphics.reset()
				end
			end

		end
	end
end


-- ---------------------------------------------------------------------------
--  VISIBILITY HELPER
-- ---------------------------------------------------------------------------

function gdsGui_outputTxtBox_isTextInFrame (txtBoxTable, lineTable)
	local result = false
	if lineTable.y >= txtBoxTable.y and (lineTable.y + lineTable.height) <= (txtBoxTable.y + txtBoxTable.height) then
		result = true
	end
	return result
end


-- ---------------------------------------------------------------------------
--  TOUCH / MOUSE DRAG SCROLL
-- ---------------------------------------------------------------------------

-- Called from gdsGui_general_touchmoved and gdsGui_general_mousemoved.
-- dx, dy are pixel deltas for this frame.
function gdsGui_outputTxtBox_touchScroll (id, x, y, dx, dy, pressure, button, istouch)

	-- Accept both touch-slide and mouse-button-held drags
	local isGestureActive = (globApp.userInput == "slide") or love.mouse.isDown(1)
	if not isGestureActive then return end

	for i, tb in ipairs(globApp.objects.outputTextBox) do

		-- Skip textboxes owned by a container (the container handles their scroll)
		if tb.ownerContainer then goto continue_tb end

		-- Only act when the pointer is inside this textbox
		if x >= tb.frame.x and x <= (tb.frame.x + tb.frame.width) and
		   y >= tb.frame.y and y <= (tb.frame.y + tb.frame.height) then

			local minOff, maxOff = _getScrollLimits(tb)
			if minOff >= -0.5 then break end  -- content fits; nothing to scroll

			tb.scroll.isDragging = true
			tb.scroll.phase      = "coasting"  -- keeps physics ready for release

			-- Apply delta with rubber-band resistance at boundaries
			tb.scroll.offsetY = _applyRubberBand(tb.scroll.offsetY + dy, minOff, maxOff)

			-- Track velocity as exponential moving average (pixels/second)
			local frameDt = love.timer.getDelta()
			if frameDt > 0 then
				local rawVel = dy / frameDt
				tb.scroll.velocityY = tb.scroll.velocityY * 0.5 + rawVel * 0.5
			end

			_apply_scroll_offset(tb)
		end

		::continue_tb::
	end

end


-- Called from gdsGui_general_touchreleased and gdsGui_general_mousereleased.
-- Seeds the correct physics phase from the accumulated drag velocity.
function gdsGui_outputTxtBox_touchReleased (x, y)

	for i, tb in ipairs(globApp.objects.outputTextBox) do

		if tb.scroll.isDragging then
			tb.scroll.isDragging = false
			local minOff, maxOff = _getScrollLimits(tb)

			if tb.scroll.offsetY < minOff or tb.scroll.offsetY > maxOff then
				-- Released while past a boundary → spring directly
				tb.scroll.phase = "bouncing"
			elseif math.abs(tb.scroll.velocityY) > COAST_STOP_VEL then
				tb.scroll.phase = "coasting"
			else
				tb.scroll.phase     = "idle"
				tb.scroll.velocityY = 0
			end
		end

	end

end


-- ---------------------------------------------------------------------------
--  TEXT UPDATE
-- ---------------------------------------------------------------------------

function gdsGui_outputTxtBox_setText(name, text)
	for _, box in ipairs(globApp.objects.outputTextBox) do
		if box.name == name then
			box.text.text = text
			break
		end
	end
end
