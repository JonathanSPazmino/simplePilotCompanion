--[[API = Menu labels Lybrary ]]

-----------------------------------------------------------------
lib_labels = {}

function outputTxtBox_create (id, page, bgSprite,  x, y, anchorPoint, width, height, txtColor, text, fontSize)

	--[[ PARAMETERS:

		1) 	id ----------------string--------------unique id/name
		2) 	page---------------string--------------page name
		3) 	bgSprite-----------string--------------png file
		4) 	x------------------double--------------0 to 1 relative to window size
		5) 	y------------------double--------------0 to 1 relative to window size
		6) 	anchorPoint--------string--------------LT,LC,LB,CT,CC,CB,RT,RC,RB
		7) 	width--------------double--------------pixels
		8) 	max height --------double--------------pixels
		9) 	txtColor ----------table---------------rgb data values (0-1 scale)
		10) text --------------string -------------txt string
		11) fontSize ----------string -------------pixels

	]]

	local tb = {}

		tb.name = id --[[name of the object]]
		tb.page = page --[[page location for creation and deleting purposes]]
		tb.type = labelType --toggle, pushOnOff, Selector

		tb.rltvWidth = width --[[percentage of screen size]]
		tb.rltvHeight = height --[[percentage of screen size]]
			local myPositions = relativePosition (anchorPoint, x, y, tb.rltvWidth, tb.rltvHeight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --[[do not move this line to other part]]
		tb.state = 1 --[[0 deactivated, 1 = released, 2 = pressed.]]

		tb.frame = {}
			tb.frame.width = width
			tb.frame.height = height
			tb.frame.x = math.floor(myPositions[1])
			tb.frame.y = math.floor(myPositions[2])

		tb.bgSprite = {}
			if bgSprite ~= nil then
				tb.bgSprite.sprite = love.graphics.newImage(bgSprite) --nil is ok
				tb.bgSprite.width = width / tb.bgSprite.sprite:getWidth ()
				tb.bgSprite.height = height / tb.bgSprite.sprite:getHeight ()
				tb.bgSprite.x = tb.frame.x
				tb.bgSprite.y = tb.frame.y
			end
			
		tb.text = {}
			tb.text.font = love.graphics.newFont(fontSize)
			if tb.state == 1 then 
				tb.text.color = txtColor
				tb.text.text = text
			elseif tb.state == 2 then
				tb.text.color = {1,0,0,1}
				tb.text.text = "txtOutputBox Error"
			end

			tb.text.width = tb.frame.width * 0.8
			tb.text.maxTextLineCount = findMaxNumOfLinesNeeded (tb.text.font, tb.text.width, tb.text.text)
			tb.text.height = returnFontInfo (tb.text.font, "height")
			tb.text.combinedTxtHeight = tb.text.height * tb.text.maxTextLineCount
			tb.text.x = tb.frame.x + ((tb.frame.width - tb.text.width)/2)
			tb.text.baseY = tb.frame.y

			-- gathers text string information, puts the string into a table for iteration
			local width, wrappedtext = tb.text.font:getWrap( tb.text.text, tb.text.width )

			tb.text.lines = {}
			for t, l in ipairs (wrappedtext) do
				local newLine = {}
				newLine.text = l
				newLine.x = tb.text.x
				newLine.width = tb.text.width
				newLine.y = tb.text.baseY + ((tb.text.height * t) - tb.text.height)
				newLine.height = tb.text.height
				newLine.color = tb.text.color
				newLine.alignement = "center"
				newLine.isVisible = isTextInsideTheFrame (tb.frame, newLine)

				table.insert(tb.text.lines, newLine)
			end

		table.insert(lib_labels,tb)

		globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1

end


function outputTxtBox_update(id, anchorPoint, x, y, width, height, fontSize)

	for i, updtLbl in ipairs(lib_labels) do 

		if updtLbl.name == id then

			updtLbl.rltvWidth = width --[[percentage of screen size]]
			updtLbl.rltvHeight = height --[[percentage of screen size]]
				local myPositions = relativePosition (anchorPoint, x, y, updtLbl.rltvWidth, updtLbl.rltvHeight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --[[do not move this line to other part]]

				updtLbl.frame.width = width
				updtLbl.frame.height = height
				updtLbl.frame.x = math.floor(myPositions[1])
				updtLbl.frame.y = math.floor(myPositions[2])

				if bgSprite ~= nil then
					updtLbl.bgSprite.sprite = love.graphics.newImage(bgSprite) --nil is ok
					updtLbl.bgSprite.width = width / updtLbl.bgSprite.sprite:getWidth ()
					updtLbl.bgSprite.height = height / updtLbl.bgSprite.sprite:getHeight ()
					updtLbl.bgSprite.x = updtLbl.frame.x
					updtLbl.bgSprite.y = updtLbl.frame.y
				end
				
				updtLbl.text.font = love.graphics.newFont(fontSize)

				updtLbl.text.width= updtLbl.frame.width * 0.8
				updtLbl.text.maxTextLineCount = findMaxNumOfLinesNeeded (updtLbl.text.font, updtLbl.text.width, updtLbl.text.text)
				updtLbl.text.height = returnFontInfo (updtLbl.text.font, "height")
				updtLbl.text.combinedTxtHeight = updtLbl.text.height * updtLbl.text.maxTextLineCount
				updtLbl.text.x = updtLbl.frame.x + ((updtLbl.frame.width - updtLbl.text.width)/2)
				updtLbl.text.baseY = updtLbl.frame.y

				-- gathers text string information, puts the string into a table for iteration
				local width, wrappedtext = updtLbl.text.font:getWrap( updtLbl.text.text, updtLbl.text.width )
				updtLbl.text.lines = {}
				for t, l in ipairs (wrappedtext) do
					local newLine = {}
					newLine.text = l
					newLine.x = updtLbl.text.x
					newLine.width = updtLbl.text.width
					newLine.y = updtLbl.text.baseY + ((updtLbl.text.height * t) - updtLbl.text.height)
					newLine.height = updtLbl.text.height
					newLine.color = updtLbl.text.color
					newLine.alignement = "center"
					newLine.isVisible = isTextInsideTheFrame (updtLbl.frame, newLine)
					table.insert(updtLbl.text.lines, newLine)
				end

		end

	end

end


function outputTxtBox_delete (id,page)

	for i = #lib_labels,1,-1 do

		local l = lib_labels[i]

		--LOAD PROJECT:

			if l.name == id and l.page == page then

				table.remove(lib_labels,i)

				globApp.numObjectsDisplayed = globApp.numObjectsDisplayed - 1

			end

	end

end


function outputTxtBox_draw (id, page, bgSprite,  x,y,anchorPoint,width,height, txtColor, text, fontSize)

	
	--[[ PARAMETERS:

	1) id ----------------string--------------name of label
	2) page------------------string--------------select page from pageNameList table
	3) labelType----------------string---------------static, dynamic
	4) bgSprite------------string--------------nameofpngfile
	5) x-----------------------double--------------0 to 1 relative to window size
	6) y-----------------------double--------------0 to 1 relative to window size
	7) anchorPoint---------------string--------------LT,LC,LB,CT,CC,CB,RT,RC,RB
	8) width-------------------double--------------pixels
	9) height------------------double--------------pixels
	10) FontColor1 --------------table---------------rgb data values
	11) labelText1 --------------string -------------label text 1
	12) FontColor2 --------------string -------------rgb data values
	13) labelText2 --------------string -------------label text 2

	]]


	local activePageName = 0

	for i, pgs in ipairs (pages) do
		if pgs.index == globApp.currentPageIndex then
			activePageName = pgs.name
		end
	end

	local labelExists = false

	for i,x in ipairs(lib_labels) do
		if x.name == id then
			labelExists = true
		end
	end

	if activePageName == page then

		if labelExists == false then

			outputTxtBox_create (id, page, bgSprite, x, y,anchorPoint, width, height, txtColor, text, fontSize)

		elseif labelExists == true and globApp.resizeDetected == true then --[[updates only if window is resized]]

			outputTxtBox_update(id, anchorPoint, x, y, width, height, fontSize)

		end

		for i,x in ipairs(lib_labels) do
			
			if x.bgSprite.sprite ~= nil then --[[draw the background before the text]]

				love.graphics.draw(x.bgSprite.sprite, x.bgSprite.x, x.bgSprite.y, 0, x.bgSprite.width, x.bgSprite.height, ox, oy, kx, ky)

			end


			if x.name == id and x.state == 0  then
				



			elseif x.name == id and x.state == 1  then


				--FRAME
				love.graphics.rectangle("line", x.frame.x, x.frame.y, x.frame.width, x.frame.height, rx, ry, segments)
				love.graphics.setFont(x.text.font)
				for y , z in ipairs (x.text.lines) do
					if z.isVisible == true then
						love.graphics.setColor(x.text.color[1], x.text.color[2], x.text.color[3], x.text.color[4])
						love.graphics.printf(z.text, z.x, z.y, z.width, "center", 0, nil, nil, nil, nil, nil, nil)
					end

				end

				love.graphics.reset()



			elseif x.name == id and x.state == 2  then

				if x.labelText2 ~= nil then 

					love.graphics.setColor(x.text.color[1], x.text.color[2], x.text.color[3], x.text.color[4])
					--FRAME
					love.graphics.rectangle("line", x.frame.x, x.frame.y, x.frame.width, x.frame.height, rx, ry, segments)

					--TEXT
					love.graphics.setFont(x.text.font)
					love.graphics.printf(x.text.text, x.text.x, x.text.y, x.text.width, "center", 0, nil, nil, nil, nil, nil, nil)
					love.graphics.reset()

				end

			end

	    end

	elseif activePageName ~= page  then
 
	 	if labelExists == true then
			
			outputTxtBox_delete (id, page)

		end
	
	end
	
end


function isTextInsideTheFrame (txtBoxTable, lineTable)
	local result = false

	if lineTable.y >= txtBoxTable.y and (lineTable.y  + lineTable.height) <= (txtBoxTable.y + txtBoxTable.height) then
		result = true
	end

	return result
end


function touchScrollOutputTxtBox (id, x, y, dx, dy, pressure, button, istouch)

	--isolate table
	local myTxtBox = lib_labels
	local outputTxtBoxExists = false

	
	--determine if it is just a tap or click
	local justATapOrClick = true
	if globApp.userInput == "slide" then
		justATapOrClick = false
	end 

	if justATapOrClick == false then 
		--determine if there are spreadsheets available 
		for i, tb in ipairs (myTxtBox) do 
			if i > 0 then
				outputTxtBoxExists = true
			end
		end

		--skip code if no spreadsheet is present
		if outputTxtBoxExists == true then
			--identify touch or click within any cell
			for i, tb in ipairs (myTxtBox) do

				local isScrollDownAvlbl = false --page goes up
				local isScrollUpAvlbl = false --page goes down

				for j, line in ipairs (tb.text.lines) do 
					if j == 1 and line.y < tb.frame.y then
						isScrollUpAvlbl = true
					end
					if j == #tb.text.lines and (line.y + line.height) > (tb.frame.y + tb.frame.height )then
						isScrollDownAvlbl = true
					end
				end

				for j, line in ipairs (tb.text.lines) do
					--determine if touch was made within scrollable area
					if x >= tb.frame.x and x <= (tb.frame.x + tb.frame.width) and y >= tb.frame.y and y <= (tb.frame.y + tb.frame.height ) then

						if isScrollUpAvlbl == true and dy > 0 then
						
							line.y = line.y + dy

						elseif isScrollDownAvlbl == true and dy < 0 then

							line.y = line.y + dy

						end

					end

					line.isVisible = isTextInsideTheFrame (tb.frame, line)

				end


			end

		end 
 

	end
end