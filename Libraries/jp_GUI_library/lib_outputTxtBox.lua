--[[API = Menu labels Lybrary ]]

-----------------------------------------------------------------
globApp.objects.outputTextBox = {}

function gui_outputTextBox_create (id, page, bgSprite,  x, y, anchorPoint, width, height, txtColor, text, fontSize)

	local tb = {}

		tb.name = id --[[name of the object]]
		tb.objectType = "outputTextBox"
		tb.page = page --[[page location for creation and deleting purposes]]
		tb.type = labelType --toggle, pushOnOff, Selector

		tb.x = x
		tb.y = y
		tb.anchorPoint = anchorPoint
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
				tb.text.lastText = text
			elseif tb.state == 2 then
				tb.text.color = {1,0,0,1}
				tb.text.text = "txtOutputBox Error"
				tb.text.lastText = "txtOutputBox Error"
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

		table.insert(globApp.objects.outputTextBox,tb)

		globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1

end



local function _recalculate_textBox(updtLbl)

	if globApp.lastSafeScreenArea and globApp.lastSafeScreenArea.w > 0 then


		updtLbl.rltvWidth = updtLbl.frame.width --[[percentage of screen size]]
		updtLbl.rltvHeight = updtLbl.frame.height --[[percentage of screen size]]
		local myPositions = relativePosition (updtLbl.anchorPoint, updtLbl.x, updtLbl.y, updtLbl.rltvWidth, updtLbl.rltvHeight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --[[do not move this line to other part]]

		updtLbl.frame.width = updtLbl.frame.width
		updtLbl.frame.height = updtLbl.frame.height
		updtLbl.frame.x = math.floor(myPositions[1])
		updtLbl.frame.y = math.floor(myPositions[2])

		if updtLbl.bgSprite.sprite ~= nil then
			-- updtLbl.bgSprite.sprite = love.graphics.newImage(bgSprite) --nil is ok
			updtLbl.bgSprite.width = updtLbl.frame.width / updtLbl.bgSprite.sprite:getWidth ()
			updtLbl.bgSprite.height = updtLbl.frame.height / updtLbl.bgSprite.sprite:getHeight ()
			updtLbl.bgSprite.x = updtLbl.frame.x
			updtLbl.bgSprite.y = updtLbl.frame.y
		end
		
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

function gui_outputTextBoxes_update()

	for i, updtLbl in ipairs(globApp.objects.outputTextBox) do

		if globApp.resizeDetected or (updtLbl.text.text ~= updtLbl.text.lastText) then
			_recalculate_textBox(updtLbl)
			updtLbl.text.lastText = updtLbl.text.text
		end

	end

end


function gui_outputTextBox_delete (id,page)

	for i = #globApp.objects.outputTextBox,1,-1 do

		local l = globApp.objects.outputTextBox[i]

		--LOAD PROJECT:

			if l.name == id and l.page == page then

				table.remove(globApp.objects.outputTextBox,i)

				globApp.numObjectsDisplayed = globApp.numObjectsDisplayed - 1

			end

	end

end


function gui_outputTxtBox_draw (pg)
	for i,t in ipairs(globApp.objects.outputTextBox) do
		if t.page == pg then
			if t.bgSprite.sprite ~= nil then --[[draw the background before the text]]
				love.graphics.draw(t.bgSprite.sprite, t.bgSprite.x, t.bgSprite.y, 0, t.bgSprite.width, t.bgSprite.height, ox, oy, kx, ky)
			end

			if t.state == 1  then
				--FRAME
				love.graphics.rectangle("line", t.frame.x, t.frame.y, t.frame.width, t.frame.height, rx, ry, segments)
				love.graphics.setFont(t.text.font)
				for y , z in ipairs (t.text.lines) do
					if z.isVisible == true then
						love.graphics.setColor(t.text.color[1], t.text.color[2], t.text.color[3], t.text.color[4])
						love.graphics.printf(z.text, z.x, z.y, z.width, "center", 0, nil, nil, nil, nil, nil, nil)
					end
				end
				love.graphics.reset()
			elseif t.state == 2  then
				if t.labelText2 ~= nil then
					love.graphics.setColor(t.text.color[1], t.text.color[2], t.text.color[3], t.text.color[4])
					--FRAME
					love.graphics.rectangle("line", t.frame.x, t.frame.y, t.frame.width, t.frame.height, rx, ry, segments)
					--TEXT
					love.graphics.setFont(t.text.font)
					love.graphics.printf(t.text.text, t.text.x, t.text.y, t.text.width, "center", 0, nil, nil, nil, nil, nil, nil)
					love.graphics.reset()
				end
			end
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


function gui_touchScrollOutputTxtBox (id, x, y, dx, dy, pressure, button, istouch)

	--isolate table
	local myTxtBox = globApp.objects.outputTextBox
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

function gui_updateOutputTextBoxText(name, text)
    for _, box in ipairs(globApp.objects.outputTextBox) do
        if box.name == name then
            box.text.text = text
            break
        end
    end
end