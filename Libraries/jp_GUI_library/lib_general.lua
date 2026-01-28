--lib_general.lua
--created by /Jonathan Pazmino
--created on 8/2/2021


	--[[GENERAL FUNCTION LOAD/CALLS]]

	math.randomseed(os.time()) --increased randomness of program


function jpGUI_simulateWinUnsafeArea (perX,perY,perW,perH)

	--parameters use percentage of screen ie. 0.5 of total screen widht

	local safeScreenArea = {}
	local totalWindowWidth = love.graphics.getWidth()
	local totalWindowHeight = love.graphics.getHeight()
		
	safeScreenArea.x = perX * totalWindowWidth
	safeScreenArea.y = perY * totalWindowHeight
	safeScreenArea.w = perW * totalWindowWidth
	safeScreenArea.h = perH * totalWindowHeight
	safeScreenArea.xw = safeScreenArea.x + safeScreenArea.w
	safeScreenArea.yh = safeScreenArea.y + safeScreenArea.h

	return safeScreenArea 

end

function jpGUI_convertSafeAreaPercentToDPI (percArea, reqResult, isDevMode)

	--[[
	return a single value that represents the DPI equivalent of the desired percentage of width or height safe area
	
	INPUT:
	percWidth-------------------double----------------0 to 1 desired widht %
	percHeight------------------double----------------0 to 1 desired height %
	reqResult-------------------string---------------"width or height" result type
	isDevMode-------------------boolean---------------"true runs unit test"

	OUTPUT:
	result----------------------doble-----------------DPI widht or height

	]]

	local formatedReqResult = reqResult:upper()

	local windowSafeWidth = globApp.safeScreenArea.w

	local windowSafeHeight = globApp.safeScreenArea.h

	if isDevMode == true then
		windowSafeWidth = 1000
		windowSafeHeight = 1000
	end 

	local result = "error"

	if formatedReqResult == "WIDTH" then

		result = windowSafeWidth * percArea

	elseif formatedReqResult == "HEIGHT" then

		result = windowSafeHeight * percArea

	end

	if isDevMode == true then
		local devOutput = {}
				devOutput[1] = result
		return result
	end

	return result

end

function jpGUI_findTriangAngle (side_oposite, side_adjacent, resultType)

	local hipot = math.sqrt((side_oposite * side_oposite) + (side_adjacent * side_adjacent))

	local result = 0

		result = math.atan(side_oposite / side_adjacent)

	if resultType == "degrees" then

		result = result * (180 / math.pi)

	end

	return result

end


function gui_handle_resize()
    -- This function will call the resize method for all active objects
    -- For now, we iterate through each type separately.
    for _, obj in ipairs(globApp.objects.buttons) do
        if obj.resize then obj:resize() end
    end
    for _, obj in ipairs(globApp.objects.tables) do
        if obj.resize then obj:resize() end
    end
    for _, obj in ipairs(globApp.objects.scrollBars) do
        if obj.resize then obj:resize() end
    end
    -- TODO: Add loops for other object types like text boxes...
end


function jpGUI_update (dt)

	--RESIZE TRIGGER CODE MUST GO BEFORE EVERYTHING THAT USES SAFESCREEN AREA TABLE
	globApp.resizeDetected = resizeDetect ()
	if globApp.resizeDetected == true then

		-- Add these lines to copy the safe area table
		globApp.lastSafeScreenArea = {
			x = globApp.safeScreenArea.x, y = globApp.safeScreenArea.y,
			w = globApp.safeScreenArea.w, h = globApp.safeScreenArea.h,
			xw = globApp.safeScreenArea.xw, yh = globApp.safeScreenArea.yh
		}
		
		globApp.totalWindowWidth = love.graphics.getWidth()
		globApp.totalWindowHeight = love.graphics.getHeight()
		globApp.displayOrientation = findScreenOrientation ()
		
		if globApp.isScreenSimulated == false then
			globApp.safeScreenArea = getScreenSafeArea ()
		end

		gui_handle_resize()

	end

	globApp.txtBoxChangeDetected = txtInput_changeTrigger ()
	if globApp.txtBoxChangeDetected == true then
		globApp.doesAnyTextBoxHaveEndingBlankSpace = doesAnyInputTextBoxHaveEndingBlankSpace ()
					-- print (globApp.doesAnyTextBoxHaveEndingBlankSpace)
		globApp.areCurrentPageRequiredInputTextBoxesEmpty = areRequiredTextBoxesEmpty ()
	end

	--UPDATES DEVELOPER DATA SHOWN ON EDGES OF 
	updateDevDisplaysParameters (dt)

	updatedProjectAvailability ()

	updateTimeTrigger (dt)

	update_loadingPage (dt)

	scrollBarButtonsPressed (dt)

end


function jpGUI_draw ()

	draw_loadingPage ()
	drawAllDevDisplays()
	draw_gui ()
	

end

function draw_gui ()
	
	local activePageName = 0
	for i, pgs in ipairs (pages) do
		if pgs.index == globApp.currentPageIndex then
			activePageName = pgs.name
		end
	end

	gui_buttons_draw (activePageName)
	gui_outputTxtBox_draw (activePageName)
	gui_table_draw (activePageName)
	gui_scrollBar_draw (activePageName)

end


function relativePosition (anchorPoint, x, y, width, height, baseX, baseY, baseWidth, baseHeight)

	--positions sprites and other objects based on indicated anchor Point of the object and fractional position compared to base object
	
	--[[
	INPUT:

		anchorPoint: ------------string--------------LT,LC,LB,CT,CC,CB,RT,RC,RB relative
		x------------------------double--------------x coordinate obj
		y------------------------double--------------y coordinate obj
		width -------------------double--------------obj width
		height ------------------double--------------obj height
		baseX--------------------double--------------x coordinate base object
		baseY--------------------double--------------y coordinate base object
		baseWidth----------------double--------------base object widht
		baseHeight---------------double--------------base object height

	OUTPUT:

		Float number representing pixels of position (NOT PERCENTAGE OF SCREEN)
	]]


	local result = {}

	if string.upper(anchorPoint) == "LT" then

		result[1] = baseX + (x * baseWidth)
		result[2] = baseY + (y * baseHeight)

	elseif string.upper(anchorPoint) == "LC" then

		result[1] = baseX + (x * baseWidth)
		result[2] = baseY + (y * baseHeight) - height/2

	elseif string.upper(anchorPoint) == "LB" then

		result[1] = baseX + (x * baseWidth)
		result[2] = baseY + (y * baseHeight) - height

	elseif string.upper(anchorPoint) == "CT" then

		result[1] = baseX + (x * baseWidth) - width /2
		result[2] = baseY + (y * baseHeight)

	elseif string.upper(anchorPoint) == "CC" then

		result[1] = baseX + ((x * baseWidth) - width /2)
		result[2] = baseY + ((y * baseHeight) - height/2)

	elseif string.upper(anchorPoint) == "CB" then

		result[1] = baseX + (x * baseWidth) - width /2
		result[2] = baseY + (y * baseHeight) - height

	elseif string.upper(anchorPoint) == "RT" then

		result[1] = baseX + (x * baseWidth) - width
		result[2] = baseY + (y * baseHeight) 

	elseif string.upper(anchorPoint) == "RC" then

		result[1] = baseX + (x * baseWidth) - width
		result[2] = baseY + (y * baseHeight) - height / 2

	elseif string.upper(anchorPoint) == "RB" then

		result[1] = baseX + (x * baseWidth) - width
		result[2] = baseY + (y * baseHeight) - height

	end

	return result
	
end


function smartScaling (scalingMode, minPercentWidth, maxPercentWidth, minPercentHeight, maxPercentHeight, heightToWidthRatio,strgReturValue ) 
	--[[use percentage of total window size]]
	--[[PARAMETERS:
		scalingMode:------------string ------- inverse or normal
		minPercentWidth: -------float ---------percentage of window screen
		maxPercentWidth: -------float---------percentage of window screen
		minPercentHeight: ------float---------percentage of window screen
		maxPercentHeight: ------float---------percentage of window screen
		heightToWidthRatio------float---------height divided by width
		strgReturValue----------string--------"width","height" or "font"]]

		--[[declaring app window dimensions]]
	local currentWindowWidth = globApp.safeScreenArea.w
	local currentWindowHeight = globApp.safeScreenArea.h
	local winMinWidth = globApp.minWindowWidth
	local winMinHeight = globApp.minWindowHeight
	local winMaxWidth = globApp.maxWindowWidth
	local winMaxHeight = globApp.maxWindowHeight
	local winWidthSpan = winMaxWidth - winMinWidth --[[window width span]]
	local winHeightSpan = winMaxHeight - winMinHeight --[[window height span]]
	
	local newDimensions = {} --[[initialize result dimensions tables]]

	--[[Assign obj Min and Max pixel values based on percentage times min and max window values from above:]]
	if scalingMode == "inverse" then

			--[[devclaring object dimensions]]
		local objMinWidth = winMinWidth * maxPercentWidth
		local objMaxWidth = winMaxWidth * minPercentWidth
		local objMinHeight =  maxPercentHeight * winMinHeight
		local objMaxHeight =  minPercentHeight * winMaxHeight
		local objWidthSpan = objMaxWidth - objMinWidth
		local objHeightSpan = objMaxHeight - objMinHeight


		--[[determine object size as function of window size and mode (landscape,
		portrait)]]
		if currentWindowWidth < currentWindowHeight then --[[width is controlling if portrait]]
			
			newDimensions.newWidth = (currentWindowWidth - winMinWidth) / winWidthSpan
			
			newDimensions.newWidth = objMinWidth + (newDimensions.newWidth * objWidthSpan)

			newDimensions.newHeight = newDimensions.newWidth * heightToWidthRatio

		elseif currentWindowWidth >= currentWindowHeight then --[[height is controlling if landscape]]
			
			--[[determine the relationship between current window height to the total span of the window, result is percentage of total span]]
			newDimensions.newHeight = (currentWindowHeight - winMinHeight) / winHeightSpan

			--[[find new object heigth by multiplying previews value by object height span and adding the min objt height]]
			newDimensions.newHeight = objMinHeight + (newDimensions.newHeight * objHeightSpan)

			--[[new width = percentage new height from above times 1 divided the heightToWidthRatio parameter. fyi= we convert to widthToHeightRatio by dividing by one]]
			newDimensions.newWidth = newDimensions.newHeight * (1  / heightToWidthRatio )

		end

		if string.lower(strgReturValue) == "width" then

			return newDimensions.newWidth

		elseif string.lower(strgReturValue) == "height" then

			return newDimensions.newHeight

		end

	end

	if scalingMode == "normal" then

		--[[assing minimum and maximum values (PIXELS) to object variables
		based on parameters and window dimensions--see above]]
		
		--[[object width]]
		objMinWidth = winMinWidth * minPercentWidth
		objMaxWidth = winMaxWidth * maxPercentWidth

		--[[object height]]
		objMinHeight =  maxPercentHeight * winMaxHeight
		objMaxHeight =  minPercentHeight * winMinHeight

		--[[object widht and height span]]
		objWidthSpan = objMaxWidth - objMinWidth
		objHeightSpan = objMaxHeight - objMinHeight


		--[[determine object size as function of window size and mode (landscape,
		portrait)]]
		if currentWindowWidth < currentWindowHeight then --[[width is controlling if portrait]]
			
			newDimensions.newWidth = (currentWindowWidth - winMinWidth) / winWidthSpan
			--[[newWidth equals current window size minus minimum windowsize divided by the span]]

			newDimensions.newWidth = objMinWidth + (newDimensions.newWidth * objWidthSpan)

			newDimensions.newHeight = newDimensions.newWidth * heightToWidthRatio

		elseif currentWindowWidth >= currentWindowHeight then --[[height is controlling if landscape]]
			

			newDimensions.newHeight = (currentWindowHeight - winMinHeight) / winHeightSpan

			newDimensions.newHeight = objMinHeight + (newDimensions.newHeight * objHeightSpan)

			newDimensions.newWidth = newDimensions.newHeight * (1  / heightToWidthRatio )

		end

		if string.lower(strgReturValue) == "width" then

			return newDimensions.newWidth

		elseif string.lower(strgReturValue) == "height" then

			return newDimensions.newHeight

		end

	end

end


function resizeDetect ()
	--[[returns boolean true when it detects a change on window dimensions]]

	local resizeDetected = false

	local lastSaveWidth = globApp.totalWindowWidth
	globApp.lastWindowWidth = lastSaveWidth
	local lastSavedHeight = globApp.totalWindowHeight
	globApp.lastWindowHeight = lastSavedHeight

	local currentWidth, currentHeight = love.graphics.getDimensions()

	if lastSaveWidth ~= currentWidth or lastSavedHeight ~= currentHeight then

		resizeDetected = true
		print ("dev= resize detected!")

	end

	return resizeDetected

end



function smartFontScaling (minFontPercentSize, maxFontPercentSize)

	--[[window dimensions]]

	local currentWindowWidth = globApp.safeScreenArea.w
	local currentWindowHeight = globApp.safeScreenArea.h

	local winMinWidth = globApp.minWindowWidth
	local winMinHeight = globApp.minWindowHeight

	local winMaxWidth = globApp.maxWindowWidth
	local winMaxHeight = globApp.maxWindowHeight
	-- love.window.fromPixels(love.window.getDesktopDimensions( 1 ))

	local winWidthSpan = winMaxWidth - winMinWidth --[[window width span]]
	local winHeightSpan = winMaxHeight - winMinHeight --[[window height span]]
	
	--[[font dimensions:]]

	local newFontSize = 0  --[[initialize new font size -- return variable]]

	--[[determine font size as function of window size and mode (landscape,
		portrait)]]
	if currentWindowWidth <= currentWindowHeight then --[[smallest of window widht or height is controlling]]

		local fontMinSize =  maxFontPercentSize * winMinWidth
		local fontMaxSize =  minFontPercentSize * winMaxWidth
		local fontSizeSpan = fontMaxSize - fontMinSize
			
		newFontSize = (currentWindowWidth - winMinWidth) / winWidthSpan
		
		newFontSize = fontMinSize + (newFontSize * fontSizeSpan)

	elseif currentWindowWidth > currentWindowHeight then --[[height is controlling if landscape]]
		
		local fontMinSize =  maxFontPercentSize * winMinHeight
		local fontMaxSize =  minFontPercentSize * winMaxHeight
		local fontSizeSpan = fontMaxSize - fontMinSize

		newFontSize = (currentWindowHeight - winMinHeight) / winHeightSpan

		newFontSize = fontMinSize + (newFontSize * fontSizeSpan)

	end

	return newFontSize --[[returns value as pixels]]

end 


function smartRelocation (position_1, perOfScreen_1, position_2, perOfScreen_2, position_3, perOfScreen_3, position_4, perOfScreen_4, returnValue)
	--[[relocates objects to specified locations based on diferent screens sizes and aspect ratios, use height to width ratio ONLY]]

	--[[PARAMETERS:

		position_1 --------------------double--------------------relative percent of screen
		perOfScreen_1------------------double--------------------percentage of total span
		position_2 --------------------double--------------------relative percent of screen
		perOfScreen_2------------------double--------------------percentage of total span
		position_3 --------------------double--------------------relative percent of screen
		perOfScreen_3------------------double--------------------percentage of total span
		position_4 --------------------double--------------------relative percent of screen
		perOfScreen_4------------------double--------------------percentage of total span
		returnValue -------------------string--------------------x or y
	
	]]

	local countConstraints = 0 --[[determines how many contraints were received as parameter]]

	--[[window dimensions]]

	local winMaxWidth = globApp.maxWindowWidth
	local winMaxHeight = globApp.maxWindowHeight

	-- local winMaxWidth = globApp.safeScreenArea.w
	-- local winMaxHeight = globApp.safeScreenArea.h

	-- winMaxHeight = love.window.getDesktopDimensions( 1 ) --removed on 12/16/2021
	
	if returnValue == "x" then

		winMinWidth = globApp.minWindowWidth
		
		winWidthSpan = winMaxWidth - winMinWidth --[[window width span]]
		
		currentPercWinSize = (globApp.safeScreenArea.w - winMinWidth) / winWidthSpan

	elseif returnValue == "y" then

		winMinHeight = globApp.minWindowHeight

		winHeightSpan = winMaxHeight - winMinHeight --[[window height span]]

		currentPercWinSize = (globApp.safeScreenArea.h - winMinHeight) / winHeightSpan

	end

	--[[Creating a sorted table]]
	local positions = {}

	if position_1 ~= nil then

		local siglePositions = {}
			siglePositions.objPosition = position_1
			siglePositions.windPercSize = perOfScreen_1

		table.insert(positions, siglePositions)

	end

	if position_2 ~= nil then
		
		local siglePositions = {}
			siglePositions.objPosition = position_2
			siglePositions.windPercSize = perOfScreen_2

		table.insert(positions, siglePositions)

	end

	if position_3 ~= nil then
		
		local siglePositions = {}
			siglePositions.objPosition = position_3
			siglePositions.windPercSize = perOfScreen_3

		table.insert(positions, siglePositions)

	end

	if position_4 ~= nil then

		local siglePositions = {}
			siglePositions.objPosition = position_4
			siglePositions.windPercSize = perOfScreen_4

		table.insert(positions, siglePositions)

	end

	local sortedValuesTable = {}
			sortedValuesTable.windowPerSizes = {}
			sortedValuesTable.objPerLocation = {}


	for i,p in ipairs (positions) do

		winPerCValue = p.windPercSize

		sortedValuesTable.windowPerSizes[i]= winPerCValue --[[inserts unsorted windowPerSize values into sorting table]]

	end

	table.sort(sortedValuesTable.windowPerSizes) --[[sorts the values of the positions table]]
		
	for i,tbl1column1val in ipairs (sortedValuesTable.windowPerSizes) do--[[inserts values of corresponding unsorted table into second table created on parallel to sorted first collumn tables]]
		
		for j, tbl2val in ipairs (positions) do

			winPerCValue = tbl2val.windPercSize

			objPositionVal =  tbl2val.objPosition

			if tbl1column1val == winPerCValue then

				sortedValuesTable.objPerLocation[i] = objPositionVal

			end

		end

		countConstraints = countConstraints + 1
	
	end

	local currentHeightToWidthRatio = globApp.safeScreenArea.h / globApp.safeScreenArea.w--define the current width to height ratio of the screen

	local minScreenSizeCons = sortedValuesTable.windowPerSizes[1] --define minimum constraint value

	local maxScreenSizeCons = sortedValuesTable.windowPerSizes[#sortedValuesTable.windowPerSizes] --define the maximum contraint value

	local middlePoints = {}

	for i = 1,(#sortedValuesTable.windowPerSizes - 1), 1 do

		middlePoints[i] = sortedValuesTable.windowPerSizes[i] + ((sortedValuesTable.windowPerSizes[i + 1 ] - sortedValuesTable.windowPerSizes[i]) / 2)
	
	end

	if countConstraints == 2 then

		if currentPercWinSize <= middlePoints[1] then

			return sortedValuesTable.objPerLocation[1]

		elseif currentPercWinSize > middlePoints[1] then

			return sortedValuesTable.objPerLocation[2]

		end

	elseif countConstraints == 3 then

		if currentPercWinSize <= middlePoints[1] then

			return sortedValuesTable.objPerLocation[1]

		elseif currentPercWinSize > middlePoints[1] and currentPercWinSize < middlePoints[2] then

			return sortedValuesTable.objPerLocation[2]

		elseif currentPercWinSize >= middlePoints[2] then

			return sortedValuesTable.objPerLocation[3]

		end

	elseif countConstraints == 4 then

		if currentPercWinSize <= middlePoints[1] then

			return sortedValuesTable.objPerLocation[1]

		elseif currentPercWinSize > middlePoints[1] and currentPercWinSize <= middlePoints[2] then

			return sortedValuesTable.objPerLocation[2]

		elseif currentPercWinSize > middlePoints[2] and currentPercWinSize < middlePoints[3] then

			return sortedValuesTable.objPerLocation[3]


		elseif currentPercWinSize >= middlePoints[3] then

			return sortedValuesTable.objPerLocation[4]

		end

	end

end


function findScreenOrientation (myWidht, myHeight, devMode)

	local currentWidht = globApp.safeScreenArea.w
	local currentHeight = globApp.safeScreenArea.h
	local result = "no orientation"

	if devMode ==  true then	
		currentWidht = myWidht
		currentHeight = myHeight
	end

	local widthToHeightRatio = currentWidht / currentHeight


	if widthToHeightRatio > 1 then
		result = "landscape"
	elseif widthToHeightRatio == 1 then
		result = "square"
	elseif widthToHeightRatio < 1 then
		result = "portrait"
	end

	return result

end


function determineSafeWindowArea (strgOrientation, strgOS, myWidht, myHeight, isDevMode)

	local safeScreenArea = {}

	local totalWidth = globApp.totalWindowWidth
	local totalHeight = globApp.totalWindowHeight
	local OS = globApp.OperatingSystem
	local screenOrientation = globApp.displayOrientation

	if isDevMode == true then
		totalWidth = myWidht
		totalHeight = myHeight
		OS = strgOS
		screenOrientation = strgOrientation

	end


	if OS ==  "Android" or  OS == "iOS" then

		if screenOrientation == "portrait" then

			safeScreenArea[1] = 0
			safeScreenArea[2] = totalHeight * 0.06
			safeScreenArea[3] = totalWidth
			safeScreenArea[4] = totalHeight * .88


		elseif screenOrientation == "landscape"  then

			safeScreenArea[1] = totalWidth * 0.06
			safeScreenArea[2] = 0
			safeScreenArea[3] = totalWidth * .88
			safeScreenArea[4] = totalHeight * .94 

		elseif screenOrientation == "square"  then

			safeScreenArea[1] = totalWidth * 0.8
			safeScreenArea[2] = totalHeight * 0.8 
			safeScreenArea[3] = totalWidth * 0.84
			safeScreenArea[4] = totalHeight * 0.84 

		end

	else 

		safeScreenArea[1] = 0
		safeScreenArea[2] = 0
		safeScreenArea[3] = totalWidth
		safeScreenArea[4] = totalHeight

	end

	safeScreenArea[5] = safeScreenArea[1] + safeScreenArea[3]
	safeScreenArea[6] = safeScreenArea[2] + safeScreenArea[4]

	return safeScreenArea 


end


function getScreenSafeArea ()

	local safeScreenArea = {}
	local x, y, w, h = love.window.getSafeArea( )
		
	safeScreenArea.x = x
	safeScreenArea.y = y
	safeScreenArea.w = w
	safeScreenArea.h = h
	safeScreenArea.xw = safeScreenArea.x + safeScreenArea.w
	safeScreenArea.yh = safeScreenArea.y + safeScreenArea.h

	return safeScreenArea 

end



------------------------------------------------------------------------------
				--TOUCHES AND CLICKS
------------------------------------------------------------------------------

function love.touchpressed( id, x, y, dx, dy, pressure )

	gdsGUI_touchpressed (id, x, y, dx, dy, pressure)

end


function love.touchmoved( id, x, y, dx, dy, pressure )

	gdsGUI_touchmoved (id, x, y, dx, dy, pressure)

end


function love.touchreleased( id, x, y, dx, dy, pressure )

	gdsGUI_touchreleased (id, x, y, dx, dy, pressure)

end


function love.mousepressed (x,y,button,istouch)

	gdsGUI_mousepressed (x, y, button, istouch, presses)

end

function love.mousemoved ( x, y, button, istouch, presses )

	gdsGUI_mousemoved (x, y, button, istouch, presses)

end


function love.mousereleased ( x, y, button, istouch, presses )

	gdsGUI_mousereleased (x, y, button, istouch, presses)

end




function isTouchInSafeArea (touchX, touchY)

	local result = false
	
	if touchX >= globApp.safeScreenArea.x and touchX <= globApp.safeScreenArea.xw and touchY >= globApp.safeScreenArea.y and touchY <= globApp.safeScreenArea.yh then

		result = true
	
	end
	
	return result
	
end

function isolateTouchableArea ()

	relativePosition (anchorPoint, x, y, width, height, baseX, baseY, baseWidth, baseHeight)

	local result = false

end



function gdsGUI_convertButtonNumToString (buttonNum)

	local buttonName = ""

	if buttonNum == 1 then
		buttonName = "left"
	elseif buttonNum == 2 then
		buttonName = "right"
	end

	return buttonName

end


---------------MOUSE-----------------------

function gdsGUI_mousepressed (x, y, button, istouch, presses)

	if istouch == false then

		local buttonName = gdsGUI_convertButtonNumToString (button)

		local calledFunction = (buttonName .. " click pressed")
		globApp.userInput = calledFunction

gui_button_pressed (x,y,button,istouch) --runs when clicked on created buttons
		
		txtInput_pressed (x,y,button,istouch) --runs when clicked or touched on textboxes

		tableButtonsPressed (x,y,button,istouch)

		focus_scrollingBar (x,y,button,istouch)

		if x >= .8 * globApp.safeScreenArea.xw and y >= .9 * globApp.safeScreenArea.yh then

			open_DevPgByEightTapping (x,y,button,istouch) -- opens and closes devPage 

		end

	end

end


function gdsGUI_mousereleased (x, y, button, istouch, presses)
	
	if istouch == false then

		local buttonName = gdsGUI_convertButtonNumToString (button)

		if globApp.userInput == (buttonName .. " click pressed") then

			local calledFunction = (buttonName .. " click")
			globApp.userInput = calledFunction

			gui_button_released (x, y, 1, istouch, presses)
		
			tableRow_Select (x,y,button,istouch)

			tableButtonsReleased (x,y,button,istouch)
			
			unfocus_scrollingBar (x,y,button,istouch)

			globApp.userInput = "none"

		end

	end

end


function gdsGUI_mousemoved (x, y, button, istouch, presses)

	local buttonName = gdsGUI_convertButtonNumToString (button)



	holdAndDragScrollBar (x,y,button,istouch)

end


---------------------------------------------------------------------
					--KEYBOARD AND TEXT GATHERING
---------------------------------------------------------------------

function love.textinput(t)

	txtInput_text_update ("add",t, nil)

end


function love.keypressed(key, unicode)

	if isTextRemoveCommanded (key) == true then
		txtInput_text_update ("remove",nil, key)
	end
	
	txtInput_tabToSwitch (key)

end 

function isTextRemoveCommanded (key)

	local removeKeys = {}
		removeKeys[1] = "backspace"
		removeKeys[2] = "delete"

	local isRemoveKeyValid = false

	for i, rk in ipairs (removeKeys) do

		if key == rk then 

			isRemoveKeyValid = true

		end

	end

	return isRemoveKeyValid

end


--------------------------------------------------
				--TOUCHSCREEN INTERACTION
--------------------------------------------------

function gdsGUI_touchpressed (id, x, y, dx, dy, pressure)

	local calledFunction = "touch pressed"

	globApp.userInput = calledFunction -- insert code below this line to user glob var

	gui_button_pressed (x,y,1,true) --runs when clicked on created buttons

	tableButtonsPressed (x,y,button,istouch)

	focus_scrollingBar (x,y,button,istouch)

	tableRow_Select (x,y,button,istouch)

end

function gdsGUI_touchmoved (id, x, y, dx, dy, pressure)

	touches = love.touch.getTouches()

	local calledFunction = "slide"
	local slideSensitivity=3
	local slideSensitivityPixelsPositive = slideSensitivity
	local slideSensitivityPixelsNegative = -(slideSensitivity)

	for i, tchs in ipairs (touches) do --isolate to first touch only

		if i == 1 then

			if globApp.userInput == "touch pressed" and ((dx > slideSensitivityPixelsPositive or dx < slideSensitivityPixelsNegative) or (dy > slideSensitivityPixelsPositive or dy < slideSensitivityPixelsNegative )) then

				globApp.userInput = "slide"

			end 

			gui_button_released (x, y, 1, istouch, presses)

			holdAndDragScrollBar (x,y,button,istouch)

			touchScrollSpreadShett (id, x, y, dx, dy, pressure, button, istouch)

			gui_touchScrollOutputTxtBox (id, x, y, dx, dy, pressure, button, istouch)

		end

	end

end


function gdsGUI_touchreleased (id, x, y, dx, dy, pressure)

	local calledFunction = "touch released"

	if globApp.userInput == "touch pressed" then

		globApp.userInput = "tap"

	end 

	
	if 	globApp.userInput == "tap" then

		-- buttons_pressed (x,y,button,istouch) --runs when clicked on created buttons

		gui_button_released (x, y, 1, istouch, presses)		txtInput_pressed (x,y,button,istouch) --runs when clicked or touched on textboxes
		tableRow_Select (x,y,button,true)

		if x >= .8 * globApp.safeScreenArea.xw and y >= .9 * globApp.safeScreenArea.yh then
			open_DevPgByEightTapping (x,y,button,istouch) -- opens and closes devPage 
		end

	end

	globApp.userInput = calledFunction

	tableButtonsReleased (x,y,button,istouch)

	unfocus_scrollingBar (x,y,button,istouch)

	globApp.userInput = "none"

end


--------------------------------------------------------------------------------
							--FONT
--------------------------------------------------------------------------------
function returnFontInfo (thisFont, reqInfo)

	local result = {}

	result.lineHeight = thisFont:getLineHeight()
	result.baseline = thisFont:getBaseline()
	result.ascent = thisFont:getAscent()
	result.descent = thisFont:getDescent()
	result.height = thisFont:getHeight()
	result.width = thisFont:getWidth(1)


	if reqInfo == "print" then
		local printString = ""
		for i, info in pairs (result) do
			printString = (printString .. i .. "=" .. info .. " || ")
		end
		print (printString)
	else 
		for i, info in pairs (result) do
			if reqInfo == i then
				local tblResult = {}
				tblResult[1] = info
				return tblResult[1]
			end
		end
	end
	
end


-------------------------------------------------------------------------------------
							--READ ABOUT PAGE
-------------------------------------------------------------------------------------

function doesAboutPageFileExist (path, isUnitTest)
	local exists = false
   	local info = love.filesystem.getInfo(path)
   	if info ~= nil then
   		exists = true
   	else
   		if isUnitTest ~= true then
   			generateConsoleMessage ("error", "no about.txt file was found, add one")
   		end
   	end
   	return exists
end

function isAboutTextFileEmpty (path, isUnitTest)
	local isEmpty = true
	contents, size = love.filesystem.read( path )
	if size > 0 then
		isEmpty = false
	else
		if isUnitTest ~= true or isUnitTest == nil then
			generateConsoleMessage ("error", "your " .. path .. " file is empty")
		end
	end
	return isEmpty
end

function readAboutPageFile ()
	local aboutFileExits = doesAboutPageFileExist ("about.txt")
	if aboutFileExits == true then
		local isAboutFileEmpty = isAboutTextFileEmpty ("about.txt")
		local contents = "NO ABOUT.TXT FILE FOUND"
		if aboutFileExits == true and isAboutFileEmpty == false then
			contents = love.filesystem.read( "about.txt" )
		end
		return contents
	end
end


-------------------------------------------------------------------------------------
							--PROJECT SELECTION 
--------------------------------------------------------------------------------------

function projectSelect (id)
	globApp.selectedProject = id
	print ("globApp.selectedProject is " .. globApp.selectedProject )
end

function projectDeselect (id)
	globApp.selectedProject = "none"
	print ("globApp.selectedProject is " .. globApp.selectedProject )
end



--THE FOLLOWING TABLE VARIABLE CONTAINS ALL GUI OBJECTS
-- gui_objects = {}

--[[GLOBAL VARIABLES TABLE:]]
	globApp = {} --[[global variables table]]
		globApp.BUTTON_STATES = {
			DEACTIVATED = 0,
			RELEASED = 1,
			PRESSED = 2
		}
		globApp.objects = {}
		globApp.developerMode = true
		globApp.OperatingSystem  = love.system.getOS( ) --[["OS X", "Windows", "Linux", "Android" or "iOS"]]
		globApp.fourDevTap = false
		globApp.devTapCounter = 0
		globApp.minWindowWidth = 230 --[[defines minimum app width]]
		globApp.minWindowHeight = 230 --[[defines minimum app height]]
		globApp.maxWindowWidth = 1920
		globApp.maxWindowHeight = 1920
		globApp.appColor = {0.15,0.15,0.15,1} -- RGBT 0-1
		globApp.numObjectsDisplayed = 0 --[[displayed on lower status bar]]
		globApp.totalWindowWidth = love.graphics.getWidth() --[[can be called instd love func]]
		globApp.totalWindowHeight = love.graphics.getHeight() --[[can be called instd love func]]
		globApp.safeScreenArea = getScreenSafeArea () --jpGUI_simulateWinUnsafeArea (0,.1,1,.8) --
		globApp.lastSafeScreenArea = globApp.safeScreenArea -- Add this line
		globApp.isScreenSimulated = false
		globApp.displayOrientation = findScreenOrientation ()
		globApp.appScale = love.graphics.getDPIScale ()
		globApp.currentPageIndex = 1 --[[activates the first page to load when app starts]]
		globApp.pageChanged = false
		globApp.resizeDetected = false --[[Event Initialization]]
		globApp.lastWindowWidth = 0
		globApp.lastWindowHeight = 0
		globApp.txtBoxChangeDetected = false --[[Event initialization]]
		globApp.areCurrentPageRequiredInputTextBoxesEmpty = true
		globApp.doesAnyTextBoxHaveEndingBlankSpace = true
		globApp.projects = {} --[[table that contains all the saved projects data]]
		globApp.projectAvailable = false --[[true activates the main menu "Loal Projct but."]]
		globApp.projectsTblChanged = false
		globApp.selectedProject = "none"
		globApp.userInput = "none"
		globApp.mouseSensitivity = 2
		globApp.touchSensitivity = 2
		globApp.devCompanyAcronym = "GDS"
		globApp.aboutPageContent = readAboutPageFile ()

	devSpritesPath = "Libraries/jp_GUI_library/librarySprites/"