--scrollBar.lua

gui_scrollBar_assets = {}

function gui_scrollBar_init_assets()
    gui_scrollBar_assets.up_active = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_UpArrowButton_pushed.png")
    gui_scrollBar_assets.up_inactive = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_UpArrowButton_released.png")
    gui_scrollBar_assets.down_active = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_downArrowButton_pushed.png")
    gui_scrollBar_assets.down_inactive = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_downArrowButton_released.png")
    gui_scrollBar_assets.left_active = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_leftArrowButton_pushed.png")
    gui_scrollBar_assets.left_inactive = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_leftArrowButton_released.png")
    gui_scrollBar_assets.right_active = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_rightArrowButton_pushed.png")
    gui_scrollBar_assets.right_inactive = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_rightArrowButton_released.png")
end
gui_scrollBar_init_assets() -- Call the function immediately after its definition

-- scrollbars = {}
globApp.objects.scrollBars = {}

function gui_scrollBar_create (id, strgPage, x, y, width, height, anchorPoint, visibleValues, totalValues, dataRelativePosition, sbType, sbOrientation, scrollSpeed, callback)

	local t = {}

		t.id = id
		t.type = sbType --[[independent or table-linked]]
		t.objectType = "scrollbar"
		t.orientation = sbOrientation
		t.state = 1
		t.scrollSpeedFactor = scrollSpeed
		t.page = strgPage
		t.isFocused = false
		t.numVisValues = visibleValues
		t.numTotalValues = totalValues
		t.callbackString = callback

		t.original = {
			x = x,
			y = y,
			width = width,
			height = height,
			anchorPoint = anchorPoint
		}

		
		t.frame = {}
			if globApp.safeScreenArea.w < globApp.safeScreenArea.h then
				t.frame.width = width * globApp.safeScreenArea.w
				t.frame.height = t.frame.width / (width / height)
			else
				t.frame.height = height * globApp.safeScreenArea.h
				t.frame.width = t.frame.height * (width / height)
			end
			 
			t.frame.positions = 
					relativePosition (anchorPoint, 
										x,
										y, 
										t.frame.width, 
										t.frame.height, 
										globApp.safeScreenArea.x,
										globApp.safeScreenArea.y, 
										globApp.safeScreenArea.w, 
										globApp.safeScreenArea.h)
			t.frame.x = t.frame.positions[1] - globApp.safeScreenArea.x
			t.frame.y = t.frame.positions[2] - globApp.safeScreenArea.y
	
		if globApp.OperatingSystem == "iOS" or globApp.OperatingSystem == "Android" then
			t.frame.y = t.frame.y + globApp.safeScreenArea.y
		end
	
		if globApp.OperatingSystem == "iOS" or globApp.OperatingSystem == "Android" then
			t.frame.y = t.frame.y + globApp.safeScreenArea.y
		end
	
		if t.orientation == "vertical" then

			t.imgButtonUpArrow_active = gui_scrollBar_assets.up_active
			t.imgButtonUpArrow_inactive = gui_scrollBar_assets.up_inactive
			t.imgButtonDownArrow_active = gui_scrollBar_assets.down_active
			t.imgButtonDownArrow_inactive = gui_scrollBar_assets.down_inactive

			t.upButton = {}
				t.upButton.width = t.frame.width
				t.upButton.height = t.frame.width
				t.upButton.x = t.frame.x
				t.upButton.y = t.frame.y
				t.upButton.factorWidth = t.upButton.width / t.imgButtonUpArrow_active:getWidth ()
				t.upButton.factorHeight = t.upButton.height / t.imgButtonUpArrow_active:getHeight ()
				t.upButton.isActive = false

			t.downButton = {}
				t.downButton.width = t.frame.width
				t.downButton.height = t.frame.width
				t.downButton.x = t.frame.x
				t.downButton.y = t.frame.y + t.frame.height - t.downButton.height
				t.downButton.factorWidth = t.downButton.width / t.imgButtonDownArrow_active:getWidth ()
				t.downButton.factorHeight = t.downButton.height / t.imgButtonDownArrow_active:getHeight ()
				t.downButton.isActive = false

			t.frame.y = t.upButton.y + t.upButton.height
				t.frame.height = t.downButton.y - t.frame.y
		
		elseif t.orientation == "horizontal" then

			t.imgButtonLeftArrow_active = gui_scrollBar_assets.left_active
				t.imgButtonLeftArrow_inactive = gui_scrollBar_assets.left_inactive
				t.imgButtonRightArrow_active = gui_scrollBar_assets.right_active
				t.imgButtonRightArrow_inactive = gui_scrollBar_assets.right_inactive
			
			t.leftButton = {}
				t.leftButton.width = t.frame.height
				t.leftButton.height = t.frame.height
				t.leftButton.x = t.frame.x
				t.leftButton.y = t.frame.y
				t.leftButton.factorWidth = t.leftButton.width / t.imgButtonLeftArrow_active:getWidth ()
				t.leftButton.factorHeight = t.leftButton.height / t.imgButtonLeftArrow_active:getHeight ()
				t.leftButton.isActive = false

			t.rightButton = {}
				t.rightButton.width = t.frame.height
				t.rightButton.height = t.frame.height
				t.rightButton.x = t.frame.x + t.frame.width - t.rightButton.width
				t.rightButton.y = t.frame.y
				t.rightButton.factorWidth = t.rightButton.width / t.imgButtonRightArrow_active:getWidth ()
				t.rightButton.factorHeight = t.rightButton.height / t.imgButtonRightArrow_active:getHeight ()
				t.rightButton.isActive = false

				t.frame.x = t.leftButton.x + t.leftButton.width
			t.frame.width = t.rightButton.x - t.frame.x

		end
				
		t.bar = {}
			t.bar.position = dataRelativePosition
		if t.orientation == "vertical" then
			t.bar.width = t.frame.width
			t.bar.height = determine_scrollingBarSize (t.numVisValues, t.numTotalValues) * t.frame.height
			t.bar.x = t.frame.x
			t.bar.y = t.frame.y + (t.bar.position * (t.frame.height - t.bar.height))
		elseif t.orientation == "horizontal" then
			t.bar.width = determine_scrollingBarSize (t.numVisValues, t.numTotalValues) * t.frame.width
			t.bar.height = t.frame.height
			t.bar.x = t.frame.x + (t.bar.position * (t.frame.width - t.bar.width))
			t.bar.y = t.frame.y 
		end

	-- table.insert(scrollBars,t)
	table.insert(globApp.objects.scrollBars, t)
	globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1
	
end


-- function scrollBar_delete (id, strgPage)
-- 	for i = #globApp.objects.scrollBars,1,-1 do
-- 		local scrollbar = globApp.objects.scrollBars[i]
-- 		if scrollbar.id == id and scrollbar.page == strgPage then
-- 			table.remove(globApp.objects.scrollBars,i)
-- 			globApp.numObjectsDisplayed = globApp.numObjectsDisplayed - 1
-- 		end
-- 	end
-- end


function gui_scrollBar_update ()

	if globApp.resizeDetected then

		for i, sb in ipairs (globApp.objects.scrollBars) do

			-- Use the original, relative values for recalculation
			local original = sb.original
			
			if globApp.safeScreenArea.w < globApp.safeScreenArea.h then
				sb.frame.width = original.width * globApp.safeScreenArea.w
				sb.frame.height = sb.frame.width / (original.width / original.height)
			else
				sb.frame.height = original.height * globApp.safeScreenArea.h
				sb.frame.width = sb.frame.height * (original.width / original.height)
			end
			
			sb.frame.positions = 
					relativePosition (original.anchorPoint, 
										original.x,
										original.y, 
										sb.frame.width, 
										sb.frame.height, 
										globApp.safeScreenArea.x,
										globApp.safeScreenArea.y, 
										globApp.safeScreenArea.w, 
										globApp.safeScreenArea.h)
			sb.frame.x = sb.frame.positions[1] - globApp.safeScreenArea.x
			sb.frame.y = sb.frame.positions[2] - globApp.safeScreenArea.y

			if globApp.OperatingSystem == "iOS" or globApp.OperatingSystem == "Android" then
				sb.frame.y = sb.frame.y + globApp.safeScreenArea.y
			end
			
			if sb.orientation == "vertical" then

				sb.upButton.width = sb.frame.width
				sb.upButton.height = sb.frame.width
				sb.upButton.x = sb.frame.x
				sb.upButton.y = sb.frame.y
				sb.upButton.factorWidth = sb.upButton.width / sb.imgButtonUpArrow_active:getWidth ()
				sb.upButton.factorHeight = sb.upButton.height / sb.imgButtonUpArrow_active:getHeight ()
				sb.upButton.isActive = false


				sb.downButton.width = sb.frame.width
				sb.downButton.height = sb.frame.width
				sb.downButton.x = sb.frame.x
				sb.downButton.y = sb.frame.y + sb.frame.height - sb.downButton.height
				sb.downButton.factorWidth = sb.downButton.width / sb.imgButtonDownArrow_active:getWidth ()
				sb.downButton.factorHeight = sb.downButton.height / sb.imgButtonDownArrow_active:getHeight ()
				sb.downButton.isActive = false

				sb.frame.y = sb.upButton.y + sb.upButton.height
				sb.frame.height = sb.downButton.y - sb.frame.y
			
			elseif sb.orientation == "horizontal" then

				sb.leftButton.width = sb.frame.height
				sb.leftButton.height = sb.frame.height
				sb.leftButton.x = sb.frame.x
				sb.leftButton.y = sb.frame.y
				sb.leftButton.factorWidth = sb.leftButton.width / sb.imgButtonLeftArrow_active:getWidth ()
				sb.leftButton.factorHeight = sb.leftButton.height / sb.imgButtonLeftArrow_active:getHeight ()
				sb.leftButton.isActive = false

				sb.rightButton.width = sb.frame.height
				sb.rightButton.height = sb.frame.height
				sb.rightButton.x = sb.frame.x + sb.frame.width - sb.rightButton.width
				sb.rightButton.y = sb.frame.y
				sb.rightButton.factorWidth = sb.rightButton.width / sb.imgButtonRightArrow_active:getWidth ()
				sb.rightButton.factorHeight = sb.rightButton.height / sb.imgButtonRightArrow_active:getHeight ()
				sb.rightButton.isActive = false

				sb.frame.x = sb.leftButton.x + sb.leftButton.width
				sb.frame.width = sb.rightButton.x - sb.frame.x

			end

			-- sb.bar.position is updated externally, so we only recalculate its physical position
			if sb.orientation == "vertical" then
				sb.bar.width = sb.frame.width
				sb.bar.height = determine_scrollingBarSize (sb.numVisValues, sb.numTotalValues) * sb.frame.height
				sb.bar.x = sb.frame.x
				sb.bar.y = sb.frame.y + (sb.bar.position * (sb.frame.height - sb.bar.height))
			elseif sb.orientation == "horizontal" then
				sb.bar.width = determine_scrollingBarSize (sb.numVisValues, sb.numTotalValues) * sb.frame.width
				sb.bar.height = sb.frame.height
				sb.bar.x = sb.frame.x + (sb.bar.position * (sb.frame.width - sb.bar.width))
				sb.bar.y = sb.frame.y 
			end

		end

	end

end


function gui_scrollBar_draw (pageName)

	for i,x in pairs(globApp.objects.scrollBars) do --[[runs continuously]]

			if x.page == pageName then

				if x.bar.position ~= dataRelativePosition and dataRelativePosition ~= nil then

					if x.type == "independent" then

						updateScrollingBarPosition (x, x.bar.position)

					elseif x.type == "table-linked" then
					
						updateScrollingBarPosition (x, dataRelativePosition)

					end

				end
				
					--------------------------------------------------------------------------
											--SCROLLBAR FRAME
					--------------------------------------------------------------------------

										love.graphics.setColor(1, 1, 1, 1)

										

										love.graphics.rectangle("fill", x.frame.x, x.frame.y, x.frame.width, x.frame.height)

										

										

										---------------------------------------------------------------------------

																--BAR

										---------------------------------------------------------------------------

					

										if x.isFocused == true then

											love.graphics.setColor(0, 0, 1, 1)

										elseif x.isFocused == false then

											love.graphics.setColor(0, 1, 0, 1)

										end

					

										love.graphics.rectangle("fill", x.bar.x, x.bar.y, x.bar.width, x.bar.height)

					

					

										---------------------------------------------------------------------------

																--BUTTONS

										---------------------------------------------------------------------------

										

										love.graphics.setColor(1, 0, 0, 1)

					

										if x.orientation == "vertical" then

					

											love.graphics.rectangle("fill", x.upButton.x, x.upButton.y, x.upButton.width, x.upButton.height)

											if x.upButton.isActive == false then

												local imgW, imgH = x.imgButtonUpArrow_inactive:getDimensions()

												local centeredX = x.upButton.x + (x.upButton.width - (imgW * x.upButton.factorWidth)) / 2

												local centeredY = x.upButton.y + (x.upButton.height - (imgH * x.upButton.factorHeight)) / 2

												love.graphics.draw(x.imgButtonUpArrow_inactive, centeredX, centeredY, 0, x.upButton.factorWidth, x.upButton.factorHeight, 0, 0)

											else

												local imgW, imgH = x.imgButtonUpArrow_active:getDimensions()

												local centeredX = x.upButton.x + (x.upButton.width - (imgW * x.upButton.factorWidth)) / 2

												local centeredY = x.upButton.y + (x.upButton.height - (imgH * x.upButton.factorHeight)) / 2

												love.graphics.draw(x.imgButtonUpArrow_active, centeredX, centeredY, 0, x.upButton.factorWidth, x.upButton.factorHeight, 0, 0)

											end

					

											love.graphics.rectangle("fill", x.downButton.x, x.downButton.y, x.downButton.width, x.downButton.height)

											if x.downButton.isActive == false then

												local imgW, imgH = x.imgButtonDownArrow_inactive:getDimensions()

												local centeredX = x.downButton.x + (x.downButton.width - (imgW * x.downButton.factorWidth)) / 2

												local centeredY = x.downButton.y + (x.downButton.height - (imgH * x.downButton.factorHeight)) / 2

												love.graphics.draw(x.imgButtonDownArrow_inactive, centeredX, centeredY, 0, x.downButton.factorWidth, x.downButton.factorHeight, 0, 0)

											else

												local imgW, imgH = x.imgButtonDownArrow_active:getDimensions()

												local centeredX = x.downButton.x + (x.downButton.width - (imgW * x.downButton.factorWidth)) / 2

												local centeredY = x.downButton.y + (x.downButton.height - (imgH * x.downButton.factorHeight)) / 2

												love.graphics.draw(x.imgButtonDownArrow_active, centeredX, centeredY, 0, x.downButton.factorWidth, x.downButton.factorHeight, 0, 0)

											end

					

										elseif x.orientation == "horizontal" then

					

											love.graphics.rectangle("fill", x.leftButton.x, x.leftButton.y, x.leftButton.width, x.leftButton.height)

											if x.leftButton.isActive == false then

												local imgW, imgH = x.imgButtonLeftArrow_inactive:getDimensions()

												local centeredX = x.leftButton.x + (x.leftButton.width - (imgW * x.leftButton.factorWidth)) / 2

												local centeredY = x.leftButton.y + (x.leftButton.height - (imgH * x.leftButton.factorHeight)) / 2

												love.graphics.draw(x.imgButtonLeftArrow_inactive, centeredX, centeredY, 0, x.leftButton.factorWidth, x.leftButton.factorHeight, 0, 0)

											else

												local imgW, imgH = x.imgButtonLeftArrow_active:getDimensions()

												local centeredX = x.leftButton.x + (x.leftButton.width - (imgW * x.leftButton.factorWidth)) / 2

												local centeredY = x.leftButton.y + (x.leftButton.height - (imgH * x.leftButton.factorHeight)) / 2

												love.graphics.draw(x.imgButtonLeftArrow_active, centeredX, centeredY, 0, x.leftButton.factorWidth, x.leftButton.factorHeight, 0, 0)

											end

					

											love.graphics.rectangle("fill", x.rightButton.x, x.rightButton.y, x.rightButton.width, x.rightButton.height)

											if x.rightButton.isActive == false then

												local imgW, imgH = x.imgButtonRightArrow_inactive:getDimensions()

												local centeredX = x.rightButton.x + (x.rightButton.width - (imgW * x.rightButton.factorWidth)) / 2

												local centeredY = x.rightButton.y + (x.rightButton.height - (imgH * x.rightButton.factorHeight)) / 2

												love.graphics.draw(x.imgButtonRightArrow_inactive, centeredX, centeredY, 0, x.rightButton.factorWidth, x.rightButton.factorHeight, 0, 0)

											else

												local imgW, imgH = x.imgButtonRightArrow_active:getDimensions()

												local centeredX = x.rightButton.x + (x.rightButton.width - (imgW * x.rightButton.factorWidth)) / 2

												local centeredY = x.rightButton.y + (x.rightButton.height - (imgH * x.rightButton.factorHeight)) / 2

												love.graphics.draw(x.imgButtonRightArrow_active, centeredX, centeredY, 0, x.rightButton.factorWidth, x.rightButton.factorHeight, 0, 0)

											end

										end

					love.graphics.print(x.bar.position, (x.frame.x + x.frame.width + 10), (x.frame.y + x.frame.height))

					love.graphics.reset()
				

			end


	    end

	end


function determine_scrollingBarSize (numOfVisibleValues, numOfScrollableValues) 
	--returns size of scrolling size based on number of values to be scrolled
	--result is expressed on decimal value, percentage of scroll bar total size

	local minBarSize = 0.1
	local maxBarSize = 1.0

	local result = "no result"
	local vis2scrollableNumValRatio = (numOfScrollableValues / numOfVisibleValues)

	if numOfVisibleValues >= numOfScrollableValues then --runs if num of values are less than the total amount of visible

		result = maxBarSize

	elseif numOfVisibleValues < numOfScrollableValues then -- runs if num of values are more than the total amount of visible values

		if (1 / vis2scrollableNumValRatio <= minBarSize) then --runs if result 

			result = minBarSize

		elseif (1 / vis2scrollableNumValRatio > minBarSize) then
		
			result = 1 / vis2scrollableNumValRatio

		end

	end

	return result
end


function updateScrollingBarPosition (sb, dataPercPosition)
	if sb.state == 1 then
		if sb.orientation == "vertical" then
			sb.bar.y = sb.frame.y + (dataPercPosition * (sb.frame.height - sb.bar.height))
		elseif sb.orientation == "horizontal" then
			sb.bar.x = sb.frame.x + (dataPercPosition * (sb.frame.width - sb.bar.width))
		end
	end
end


function focus_scrollingBar (x,y,button,istouch)

	if button == 1 or globApp.userInput == "touch pressed" then 

		for i, sb in ipairs (globApp.objects.scrollBars) do

			if x >= sb.bar.x and x <= (sb.bar.x + sb.bar.width) and y >= sb.bar.y and y <= sb.bar.y + sb.bar.height then
				sb.isFocused = true
			end

			local stepSize = 0
			if sb.numTotalValues and sb.numTotalValues > 0 then
				stepSize = 1 / sb.numTotalValues
			end

			if sb.orientation == "vertical" then
				
				if x >= sb.upButton.x and x <= (sb.upButton.x + sb.upButton.width) and y >= sb.upButton.y and y <= sb.upButton.y + sb.upButton.height then
					if not sb.upButton.isActive then -- Only step if not already active (first press)
						sb.upButton.isActive = true
						-- Discrete step for up arrow
						sb.bar.position = math.max(0, sb.bar.position - stepSize)
						updateScrollingBarPosition(sb, sb.bar.position)
						if sb.callbackString ~= nil then
							getfenv()[sb.callbackString](sb.bar.position)
						end
					end
				end

				if x >= sb.downButton.x and x <= (sb.downButton.x + sb.downButton.width) and y >= sb.downButton.y and y <= sb.downButton.y + sb.downButton.height then
					if not sb.downButton.isActive then -- Only step if not already active (first press)
						sb.downButton.isActive = true
						-- Discrete step for down arrow
						sb.bar.position = math.min(1, sb.bar.position + stepSize)
						updateScrollingBarPosition(sb, sb.bar.position)
						if sb.callbackString ~= nil then
							getfenv()[sb.callbackString](sb.bar.position)
						end
					end
				end

			elseif sb.orientation == "horizontal" then
				
				if x >= sb.leftButton.x and x <= (sb.leftButton.x + sb.leftButton.width) and y >= sb.leftButton.y and y <= sb.leftButton.y + sb.leftButton.height then
					if not sb.leftButton.isActive then -- Only step if not already active (first press)
						sb.leftButton.isActive = true
						-- Discrete step for left arrow
						sb.bar.position = math.max(0, sb.bar.position - stepSize)
						updateScrollingBarPosition(sb, sb.bar.position)
						if sb.callbackString ~= nil then
							getfenv()[sb.callbackString](sb.bar.position)
						end
					end
				end

				if x >= sb.rightButton.x and x <= (sb.rightButton.x + sb.rightButton.width) and y >= sb.rightButton.y and y <= sb.rightButton.y + sb.rightButton.height then
					if not sb.rightButton.isActive then -- Only step if not already active (first press)
						sb.rightButton.isActive = true
						-- Discrete step for right arrow
						sb.bar.position = math.min(1, sb.bar.position + stepSize)
						updateScrollingBarPosition(sb, sb.bar.position)
						if sb.callbackString ~= nil then
							getfenv()[sb.callbackString](sb.bar.position)
						end
					end
				end -- Added missing 'end'

			end

		end

	end
end


function unfocus_scrollingBar (x,y,button,istouch)
	if button == 1 or globApp.userInput == "touch released" then --isolate to mouse use
		for i, sb in ipairs (globApp.objects.scrollBars) do
			sb.isFocused = false
			if sb.orientation == "vertical" then
				sb.upButton.isActive = false
				sb.downButton.isActive = false
			elseif sb.orientation == "horizontal" then
				sb.leftButton.isActive = false
				sb.rightButton.isActive = false
			end
		end
	end
end


function holdAndDragScrollBar (x,y,button,istouch, devMode)
	--moves scrolling bar up or down when the bar is cocused and dragged
	--runs using the love.mouseMoved callback function

	for i, sb in ipairs (globApp.objects.scrollBars) do--scroll through avialable scrollbars
		if sb.orientation == "vertical" then
			totalPositionSpan = sb.frame.height - sb.bar.height
		elseif sb.orientation == "horizontal" then
			totalPositionSpan = sb.frame.width - sb.bar.width
		end

		if totalPositionSpan > 0 then -- code only runs if bar is smaller than frame
			if sb.isFocused == true then --isolates focused bars only
				if sb.orientation == "vertical" then
					if y - (sb.bar.height / 2) >= sb.frame.y and ((y - (sb.bar.height / 2)) + sb.bar.height) <= (sb.frame.y + sb.frame.height) then
						sb.bar.y = y - (sb.bar.height / 2)
					elseif y - (sb.bar.height / 2) < sb.frame.y then
						sb.bar.y = sb.frame.y
					elseif (y + sb.bar.height) > (sb.frame.y + sb.frame.height)then
						sb.bar.y = (sb.frame.y + sb.frame.height) - sb.bar.height
					end
					sb.bar.position = (sb.bar.y - sb.frame.y) / totalPositionSpan
					-- Snap to nearest increment
					if sb.numTotalValues and sb.numTotalValues > 0 then
						sb.bar.position = math.floor(sb.bar.position * sb.numTotalValues + 0.5) / sb.numTotalValues
					end
					updateScrollingBarPosition(sb, sb.bar.position) -- Update physical position after snapping
				elseif sb.orientation == "horizontal" then
					if x - (sb.bar.width / 2) >= sb.frame.x and ((x - (sb.bar.width / 2)) + sb.bar.width) <= (sb.frame.x + sb.frame.width) then
						sb.bar.x = x - (sb.bar.width / 2)
					elseif x - (sb.bar.width / 2) < sb.frame.x then
						sb.bar.x = sb.frame.x
					elseif (x + sb.bar.width) > (sb.frame.x + sb.frame.width)then
						sb.bar.x = (sb.frame.x + sb.frame.width) - sb.bar.width
					end
					sb.bar.position = (sb.bar.x - sb.frame.x) / totalPositionSpan
					-- Snap to nearest increment
					if sb.numTotalValues and sb.numTotalValues > 0 then
						sb.bar.position = math.floor(sb.bar.position * sb.numTotalValues + 0.5) / sb.numTotalValues
					end
					updateScrollingBarPosition(sb, sb.bar.position) -- Update physical position after snapping
				end
				
				if sb.callbackString ~= nil then
					getfenv()[sb.callbackString](sb.bar.position)
				elseif sb.callbackString == nil then
					print ("no callback assigned to " .. sb.id .. " scrollbar")
				end
			end
		end

		if devMode == true then
			local result = {}
				result.sBarPosition = sb.bar.position
			return result
		end
	end
end


function scrollBarButtonsPressed (dt)
	-- Continuous scrolling for scrollbar buttons is now handled by discrete steps in focus_scrollingBar.
	-- This function will no longer actively move scrollbars based on button presses.
end


function convert_scrollBarPosToDPI (SBposition, lBound, uBound)
	--[[converts relative bar position to pixels based on lbound and u bound pixel values
		INPUT:
		SBposition--------------FLOAT-------------------0-1 sb position
		lBound------------------FLOAT-------------------pix representing lbound
		uBound------------------FLOAT-------------------pix representing ubound

		OUTPUT:
		dpiEquivalent-----------INT--------------int representing corresponding pixel value relative to SBposition]]

	local dpiEquivalent = lBound + (SBposition * (uBound - lBound))

	return dpiEquivalent
end