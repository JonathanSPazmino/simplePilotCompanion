--scrollBar.lua

scrollBars = {}


function scrollBar_create (id, strgPage, x, y, width, height, anchorPoint, visibleValues, totalValues, dataRelativePosition, sbType, sbOrientation, scrollSpeed, callback)

	local newScrollBar = {}

		newScrollBar.id = id
		newScrollBar.type = sbType --[[independent or table-linked]]
		newScrollBar.orientation = sbOrientation
		newScrollBar.state = 1
		newScrollBar.scrollSpeedFactor = scrollSpeed
		newScrollBar.page = strgPage
		newScrollBar.isFocused = false
		newScrollBar.numVisValues = visibleValues
		newScrollBar.numTotalValues = totalValues
		newScrollBar.callbackString = callback

		
		newScrollBar.frame = {}
			newScrollBar.frame.width = width * globApp.safeScreenArea.w 
			newScrollBar.frame.height = height * globApp.safeScreenArea.h 
			newScrollBar.frame.positions = 
					relativePosition (anchorPoint, 
										x,
										y, 
										newScrollBar.frame.width, 
										newScrollBar.frame.height, 
										globApp.safeScreenArea.x,
										globApp.safeScreenArea.y, 
										globApp.safeScreenArea.w, 
										globApp.safeScreenArea.h)
			newScrollBar.frame.x = newScrollBar.frame.positions[1] - globApp.safeScreenArea.x
			newScrollBar.frame.y = newScrollBar.frame.positions[2] - globApp.safeScreenArea.y
	
		if newScrollBar.orientation == "vertical" then

			newScrollBar.imgButtonUpArrow_active = love.graphics.newImage(devSpritesPath .."jpLoveGUI_UpArrowButton_pushed.png")
			newScrollBar.imgButtonUpArrow_inactive = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_UpArrowButton_released.png")
			newScrollBar.imgButtonDownArrow_active = love.graphics.newImage(devSpritesPath .."jpLoveGUI_downArrowButton_pushed.png")
			newScrollBar.imgButtonDownArrow_inactive = love.graphics.newImage(devSpritesPath .."jpLoveGUI_downArrowButton_released.png")

			newScrollBar.upButton = {}
				newScrollBar.upButton.width = width * globApp.safeScreenArea.w
				newScrollBar.upButton.height = width * globApp.safeScreenArea.w
				newScrollBar.upButton.x = newScrollBar.frame.x
				newScrollBar.upButton.y = newScrollBar.frame.y
				newScrollBar.upButton.factorWidth = newScrollBar.frame.width / newScrollBar.imgButtonUpArrow_active:getWidth ()
				newScrollBar.upButton.factorHeight = newScrollBar.frame.width / newScrollBar.imgButtonUpArrow_active:getWidth ()
				newScrollBar.upButton.isActive = false

			newScrollBar.downButton = {}
				newScrollBar.downButton.width = width * globApp.safeScreenArea.w
				newScrollBar.downButton.height = width * globApp.safeScreenArea.w
				newScrollBar.downButton.x = newScrollBar.frame.x
				newScrollBar.downButton.y = newScrollBar.frame.y + newScrollBar.frame.height - newScrollBar.downButton.height
				newScrollBar.downButton.factorWidth = newScrollBar.frame.width / newScrollBar.imgButtonDownArrow_active:getWidth ()
				newScrollBar.downButton.factorHeight = newScrollBar.frame.width / newScrollBar.imgButtonDownArrow_active:getWidth ()
				newScrollBar.downButton.isActive = false

			newScrollBar.frame.y = newScrollBar.upButton.y + newScrollBar.upButton.height
			newScrollBar.frame.height = newScrollBar.downButton.y - newScrollBar.frame.y
		
		elseif newScrollBar.orientation == "horizontal" then

			newScrollBar.imgButtonLeftArrow_active = love.graphics.newImage(devSpritesPath .."jpLoveGUI_leftArrowButton_pushed.png")
			newScrollBar.imgButtonLeftArrow_inactive = love.graphics.newImage(devSpritesPath .. "jpLoveGUI_leftArrowButton_released.png")
			newScrollBar.imgButtonRightArrow_active = love.graphics.newImage(devSpritesPath .."jpLoveGUI_rightArrowButton_pushed.png")
			newScrollBar.imgButtonRightArrow_inactive = love.graphics.newImage(devSpritesPath .."jpLoveGUI_rightArrowButton_released.png")
			
			newScrollBar.leftButton = {}
				newScrollBar.leftButton.width = height * globApp.safeScreenArea.h
				newScrollBar.leftButton.height = height * globApp.safeScreenArea.h
				newScrollBar.leftButton.x = newScrollBar.frame.x
				newScrollBar.leftButton.y = newScrollBar.frame.y
				newScrollBar.leftButton.factorWidth = newScrollBar.leftButton.height / newScrollBar.imgButtonLeftArrow_active:getHeight ()
				newScrollBar.leftButton.factorHeight = newScrollBar.leftButton.height / newScrollBar.imgButtonLeftArrow_active:getHeight ()
				newScrollBar.leftButton.isActive = false

			newScrollBar.rightButton = {}
				newScrollBar.rightButton.width = height * globApp.safeScreenArea.h
				newScrollBar.rightButton.height = height * globApp.safeScreenArea.h
				newScrollBar.rightButton.x = newScrollBar.frame.x + newScrollBar.frame.width - newScrollBar.rightButton.width
				newScrollBar.rightButton.y = newScrollBar.frame.y
				newScrollBar.rightButton.factorWidth = newScrollBar.rightButton.height / newScrollBar.imgButtonRightArrow_active:getHeight ()
				newScrollBar.rightButton.factorHeight = newScrollBar.rightButton.height / newScrollBar.imgButtonRightArrow_active:getHeight ()
				newScrollBar.rightButton.isActive = false

			newScrollBar.frame.x = newScrollBar.leftButton.x + newScrollBar.leftButton.width
			newScrollBar.frame.width = newScrollBar.rightButton.x - newScrollBar.frame.x

		end
				
		newScrollBar.bar = {}
			newScrollBar.bar.position = dataRelativePosition
		if newScrollBar.orientation == "vertical" then
			newScrollBar.bar.width = newScrollBar.frame.width
			newScrollBar.bar.height = determine_scrollingBarSize (newScrollBar.numVisValues, newScrollBar.numTotalValues) * newScrollBar.frame.height
			newScrollBar.bar.x = newScrollBar.frame.x
			newScrollBar.bar.y = newScrollBar.frame.y + (newScrollBar.bar.position * (newScrollBar.frame.height - newScrollBar.bar.height))
		elseif newScrollBar.orientation == "horizontal" then
			newScrollBar.bar.width = determine_scrollingBarSize (newScrollBar.numVisValues, newScrollBar.numTotalValues) * newScrollBar.frame.width
			newScrollBar.bar.height = newScrollBar.frame.height
			newScrollBar.bar.x = newScrollBar.frame.x + (newScrollBar.bar.position * (newScrollBar.frame.width - newScrollBar.bar.width))
			newScrollBar.bar.y = newScrollBar.frame.y 
		end

	table.insert(scrollBars,newScrollBar)
	globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1
	
end


function scrollBar_delete (id, strgPage)
	for i = #scrollBars,1,-1 do
		local scrollbar = scrollBars[i]
		if scrollbar.id == id and scrollbar.page == strgPage then
			table.remove(scrollBars,i)
			globApp.numObjectsDisplayed = globApp.numObjectsDisplayed - 1
		end
	end
end


function scrollBar_update (id, strgPage, x, y, width, height, anchorPoint, visibleValues, totalValues, dataRelativePosition, sbType, sbOrientation, scrollSpeed, callback)

	for i, sb in ipairs (scrollBars) do

		if sb.id == id and sb.page == strgPage then

			sb.numVisValues = visibleValues
			sb.numTotalValues = totalValues

			sb.frame.width = width * globApp.safeScreenArea.w
			sb.frame.height = height * globApp.safeScreenArea.h
			sb.frame.positions = 
					relativePosition (anchorPoint, 
										x,
										y, 
										sb.frame.width, 
										sb.frame.height, 
										globApp.safeScreenArea.x,
										globApp.safeScreenArea.y, 
										globApp.safeScreenArea.w, 
										globApp.safeScreenArea.h)
			sb.frame.x = sb.frame.positions[1]
			sb.frame.y = sb.frame.positions[2]
			
			if sb.orientation == "vertical" then

				sb.upButton.width = width * globApp.safeScreenArea.w
				sb.upButton.height = width * globApp.safeScreenArea.w
				sb.upButton.x = sb.frame.x
				sb.upButton.y = sb.frame.y
				sb.upButton.factorWidth = sb.frame.width / sb.imgButtonUpArrow_active:getWidth ()
				sb.upButton.factorHeight = sb.frame.width / sb.imgButtonUpArrow_active:getWidth ()
				sb.upButton.isActive = false


				sb.downButton.width = width * globApp.safeScreenArea.w
				sb.downButton.height = width * globApp.safeScreenArea.w
				sb.downButton.x = sb.frame.x
				sb.downButton.y = sb.frame.y + sb.frame.height - sb.downButton.height
				sb.downButton.factorWidth = sb.frame.width / sb.imgButtonDownArrow_active:getWidth ()
				sb.downButton.factorHeight = sb.frame.width / sb.imgButtonDownArrow_active:getWidth ()
				sb.downButton.isActive = false

				sb.frame.y = sb.upButton.y + sb.upButton.height
				sb.frame.height = sb.downButton.y - sb.frame.y
			
			elseif sb.orientation == "horizontal" then

				sb.leftButton.width = height * globApp.safeScreenArea.h
				sb.leftButton.height = height * globApp.safeScreenArea.h
				sb.leftButton.x = sb.frame.x
				sb.leftButton.y = sb.frame.y
				sb.leftButton.factorWidth = sb.leftButton.height / sb.imgButtonLeftArrow_active:getHeight ()
				sb.leftButton.factorHeight = sb.leftButton.height / sb.imgButtonLeftArrow_active:getHeight ()
				sb.leftButton.isActive = false

				sb.rightButton.width = height * globApp.safeScreenArea.h
				sb.rightButton.height = height * globApp.safeScreenArea.h
				sb.rightButton.x = sb.frame.x + sb.frame.width - sb.rightButton.width
				sb.rightButton.y = sb.frame.y
				sb.rightButton.factorWidth = sb.rightButton.height / sb.imgButtonRightArrow_active:getHeight ()
				sb.rightButton.factorHeight = sb.rightButton.height / sb.imgButtonRightArrow_active:getHeight ()
				sb.rightButton.isActive = false

				sb.frame.x = sb.leftButton.x + sb.leftButton.width
				sb.frame.width = sb.rightButton.x - sb.frame.x

			end

			sb.bar.position = dataRelativePosition

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


function scrollBar_draw (id, strgPage, x, y, width, height, anchorPoint, visibleValues, totalValues, dataRelativePosition, sbType, sbOrientation, scrollSpeed, callback)

	local activePageName = "no page"

	for i, pgs in ipairs (pages) do
		if pgs.index == globApp.currentPageIndex then
			activePageName = pgs.name
		end
	end

	local objExists = false

	for i,x in ipairs(scrollBars) do--[[checks if obj exists to avoid multiple creations of the same object]]
		if x.id == id then
			objExists = true
		end
	end


	if activePageName == strgPage then --[[compares object's pg to current strgPage]]

		if objExists == false then --[[runs once]]
			scrollBar_create (id, strgPage, x, y, width, height, anchorPoint, visibleValues, totalValues, dataRelativePosition, sbType, sbOrientation, scrollSpeed, callback)
		elseif objExists == true and globApp.resizeDetected == true then --[[updates only if window is resized]]
			scrollBar_update (id, strgPage, x, y, width, height, anchorPoint, visibleValues, totalValues, dataRelativePosition, sbType, sbOrientation, scrollSpeed, callback)
		end

		for i,x in pairs(scrollBars) do --[[runs continuously]]

			if x.id == id then --[[isolates code to single sb]]

				if x.bar.position ~= dataRelativePosition and dataRelativePosition ~= nil then
					
					if x.type == "independent" then

						updateScrollingBarPosition (x.bar.position, id)

					elseif x.type == "table-linked" then
					
						updateScrollingBarPosition (dataRelativePosition, id)

					end

				end
				
				if x.id == id and x.state == 0  then

				elseif x.id == id and x.state == 1  then

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
							love.graphics.draw(x.imgButtonUpArrow_inactive, x.upButton.x, x.upButton.y, r, x.upButton.factorWidth, x.upButton.factorHeight, ox, oy, kx, ky)
						else
							love.graphics.draw(x.imgButtonUpArrow_active, x.upButton.x, x.upButton.y, r, x.upButton.factorWidth, x.upButton.factorHeight, ox, oy, kx, ky)
						end

						love.graphics.rectangle("fill", x.downButton.x, x.downButton.y, x.downButton.width, x.downButton.height)
						if x.downButton.isActive == false then
							love.graphics.draw(x.imgButtonDownArrow_inactive, x.downButton.x, x.downButton.y, r, x.downButton.factorWidth, x.downButton.factorHeight, ox, oy, kx, ky)
						else
							love.graphics.draw(x.imgButtonDownArrow_active, x.downButton.x, x.downButton.y, r, x.downButton.factorWidth, x.downButton.factorHeight, ox, oy, kx, ky)
						end

					elseif x.orientation == "horizontal" then

						love.graphics.rectangle("fill", x.leftButton.x, x.leftButton.y, x.leftButton.width, x.leftButton.height)
						if x.leftButton.isActive == false then
							love.graphics.draw(x.imgButtonLeftArrow_inactive, x.leftButton.x, x.leftButton.y, r, x.leftButton.factorWidth, x.leftButton.factorHeight, ox, oy, kx, ky)
						else
							love.graphics.draw(x.imgButtonLeftArrow_active, x.leftButton.x, x.leftButton.y, r, x.leftButton.factorWidth, x.leftButton.factorHeight, ox, oy, kx, ky)
						end

						love.graphics.rectangle("fill", x.rightButton.x, x.rightButton.y, x.rightButton.width, x.rightButton.height)
						if x.rightButton.isActive == false then
							love.graphics.draw(x.imgButtonRightArrow_inactive, x.rightButton.x, x.rightButton.y, r, x.rightButton.factorWidth, x.rightButton.factorHeight, ox, oy, kx, ky)
						else
							love.graphics.draw(x.imgButtonRightArrow_active, x.rightButton.x, x.rightButton.y, r, x.rightButton.factorWidth, x.rightButton.factorHeight, ox, oy, kx, ky)
						end
					end

					love.graphics.print(x.bar.position, (x.frame.x + x.frame.width + 10), (x.frame.y + x.frame.height), r, sx, sy, ox, oy, kx, ky)

					love.graphics.reset()
				end

			end


	    end

	elseif activePageName ~= strgPage  then--[[compares object's pg to current strgPage]]

		if objExists == true then --[[runs once]]
				
			scrollBar_delete (id, strgPage)

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


function updateScrollingBarPosition (dataPercPosition, id)
	for i, sb in ipairs (scrollBars) do
		if sb.state == 1 and sb.id == id then
			if sb.orientation == "vertical" then
				sb.bar.y = sb.frame.y + (dataPercPosition * (sb.frame.height - sb.bar.height))
			elseif sb.orientation == "horizontal" then
				sb.bar.x = sb.frame.x + (dataPercPosition * (sb.frame.width - sb.bar.width))
			end
		end

	end
end


function focus_scrollingBar (x,y,button,istouch)

	if button == 1 or globApp.userInput == "touch pressed" then 

		for i, sb in ipairs (scrollBars) do

			if x >= sb.bar.x and x <= (sb.bar.x + sb.bar.width) and y >= sb.bar.y and y <= sb.bar.y + sb.bar.height then
				sb.isFocused = true
			end

			if sb.orientation == "vertical" then
				
				if x >= sb.upButton.x and x <= (sb.upButton.x + sb.upButton.width) and y >= sb.upButton.y and y <= sb.upButton.y + sb.upButton.height then
					sb.upButton.isActive = true
				end

				if x >= sb.downButton.x and x <= (sb.downButton.x + sb.downButton.width) and y >= sb.downButton.y and y <= sb.downButton.y + sb.downButton.height then
					sb.downButton.isActive = true
				end

			elseif sb.orientation == "horizontal" then
				
				if x >= sb.leftButton.x and x <= (sb.leftButton.x + sb.leftButton.width) and y >= sb.leftButton.y and y <= sb.leftButton.y + sb.leftButton.height then
					sb.leftButton.isActive = true
				end

				if x >= sb.rightButton.x and x <= (sb.rightButton.x + sb.rightButton.width) and y >= sb.rightButton.y and y <= sb.rightButton.y + sb.rightButton.height then
					sb.rightButton.isActive = true
				end

			end

		end

	end
end


function unfocus_scrollingBar (x,y,button,istouch)
	if button == 1 or globApp.userInput == "touch released" then --isolate to mouse use
		for i, sb in ipairs (scrollBars) do
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

	for i, sb in ipairs (scrollBars) do--scroll through avialable scrollbars
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
				elseif sb.orientation == "horizontal" then
					if x - (sb.bar.width / 2) >= sb.frame.x and ((x - (sb.bar.width / 2)) + sb.bar.width) <= (sb.frame.x + sb.frame.width) then
						sb.bar.x = x - (sb.bar.width / 2)
					elseif x - (sb.bar.width / 2) < sb.frame.x then
						sb.bar.x = sb.frame.x
					elseif (x + sb.bar.width) > (sb.frame.x + sb.frame.width)then
						sb.bar.x = (sb.frame.x + sb.frame.width) - sb.bar.width
					end
					sb.bar.position = (sb.bar.x - sb.frame.x) / totalPositionSpan
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
	for i, sb in ipairs (scrollBars) do 
		local speed = (dt + (1 / sb.numTotalValues ) * sb.scrollSpeedFactor)

		if sb.orientation == "vertical" then 
			local totalPositionSpan = sb.frame.height - sb.bar.height

			if totalPositionSpan > 0 then

				if sb.downButton.isActive == true then

					if sb.bar.y + speed <= (sb.frame.y + sb.frame.height) - sb.bar.height then

						sb.bar.y = sb.bar.y + speed

					elseif sb.bar.y + speed > (sb.frame.y + sb.frame.height) - sb.bar.height then

						sb.bar.y = (sb.frame.y + sb.frame.height) - sb.bar.height

					end

					sb.bar.position = (sb.bar.y - sb.frame.y) / totalPositionSpan

					if sb.callbackString ~= nil then

						getfenv()[sb.callbackString](sb.bar.position)

					elseif sb.callbackString == nil then

						print ("no callback assigned to " .. sb.id .. " scrollbar")

					end

				elseif sb.upButton.isActive == true then

					if sb.bar.y - speed >= sb.frame.y  then

						sb.bar.y = sb.bar.y - speed

					elseif sb.bar.y - speed < sb.frame.y then

						sb.bar.y = sb.frame.y

					end

					sb.bar.position = (sb.bar.y - sb.frame.y) / totalPositionSpan

					if sb.callbackString ~= nil then

						getfenv()[sb.callbackString](sb.bar.position)

					elseif sb.callbackString == nil then

						print ("no callback assigned to " .. sb.id .. " scrollbar")

					end

				end

			end
		elseif sb.orientation == "horizontal" then

			local totalPositionSpan = sb.frame.width - sb.bar.width

			if totalPositionSpan > 0 then

				if sb.rightButton.isActive == true then

					if sb.bar.x + speed <= (sb.frame.x + sb.frame.width) - sb.bar.width then

						sb.bar.x = sb.bar.x + speed

					elseif sb.bar.x + speed > (sb.frame.x + sb.frame.width) - sb.bar.width then

						sb.bar.x = (sb.frame.x + sb.frame.width) - sb.bar.width

					end

					sb.bar.position = (sb.bar.x - sb.frame.x) / totalPositionSpan

					if sb.callbackString ~= nil then

						getfenv()[sb.callbackString](sb.bar.position)

					elseif sb.callbackString == nil then

						print ("no callback assigned to " .. sb.id .. " scrollbar")

					end

				elseif sb.leftButton.isActive == true then

					if sb.bar.x - speed >= sb.frame.x  then

						sb.bar.x = sb.bar.x - speed

					elseif sb.bar.x - speed < sb.frame.x then

						sb.bar.x = sb.frame.x

					end

					sb.bar.position = (sb.bar.x - sb.frame.x) / totalPositionSpan

					if sb.callbackString ~= nil then

						getfenv()[sb.callbackString](sb.bar.position)

					elseif sb.callbackString == nil then

						print ("no callback assigned to " .. sb.id .. " scrollbar")

					end

				end

			end
		end
	end
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