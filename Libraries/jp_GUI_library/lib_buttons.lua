--[[API = Menu Buttons Lybrary ]]


---------------------------------------------------------------------------------------
										--SINGLE BUTTON
---------------------------------------------------------------------------------------

lib_buttons = {}

function gui_button_create (strgLabel, strgPage, buttonType, strgImgButtonPressed, strgImgButtonReleased, strgImgButtonDeactivated, myx, myy, anchorPoint, myWidth, myHeight, strgCallbackFunc, initialState)

	local newButton = {}

		newButton.name = strgLabel
		newButton.page = strgPage
		newButton.objectType = "button"
		newButton.type = buttonType --toggle, pushOnOff, Selector
		newButton.imgButtonPressed = love.graphics.newImage(strgImgButtonPressed)
		newButton.imgButtonReleased = love.graphics.newImage(strgImgButtonReleased)
		newButton.imgButtonDeactivated = love.graphics.newImage(strgImgButtonDeactivated)
		newButton.mywidth = myWidth
		newButton.myheight = myHeight
		newButton.anchorPoint = anchorPoint
		local myPositions = relativePosition (newButton.anchorPoint, myx, myy, newButton.mywidth, newButton.myheight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --do not move this line to other part.
		newButton.myx = myPositions[1]
		newButton.myy = myPositions[2]
		newButton.factorWidth = newButton.mywidth / newButton.imgButtonPressed:getWidth ()
		newButton.factorHeight = newButton.myheight / newButton.imgButtonPressed:getHeight ()
		newButton.myMaxx = newButton.myx + newButton.mywidth
		newButton.myMaxy = newButton.myy + newButton.myheight
		newButton.deactivated = false
		newButton.state = initialState --[[0 deactivated, 1 = released, 2 = pressed.]]
		newButton.callbackFunc = strgCallbackFunc

		table.insert(lib_buttons,newButton)

		table.insert(gui_objects,newButton)

		globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1

end

function gui_buttons_draw (pg)

	for i,x in ipairs(gui_objects) do
		if x.page == pg then 
			if x.state == 0  then
			love.graphics.draw(x.imgButtonDeactivated, x.myx, x.myy, 0, x.factorWidth, x.factorHeight, ox, oy, kx, ky)
			elseif x.state == 1  then
			love.graphics.draw(x.imgButtonReleased, x.myx, x.myy, 0, x.factorWidth, x.factorHeight, ox, oy, kx, ky)
			elseif x.state == 2  then
			love.graphics.draw(x.imgButtonPressed, x.myx, x.myy, 0, x.factorWidth, x.factorHeight, ox, oy, kx, ky)
			end
		end
    end
end

function gui_buttons_update ()
	if globApp.resizeDetected == true then --[[updates only if window is resized]]
		for i, btns in ipairs (gui_objects) do
			if btns.objectType == "button" then --[[updates only if objt is a buttonqsq]]
				oldXRatio = btns.myx / globApp.lastWindowWidth
				oldYRatio = btns.myy / globApp.lastWindowHeight
				oldWidth = (btns.mywidth / globApp.lastWindowWidth) 
				oldHeight = (btns.myheight / globApp.lastWindowHeight) 

				btns.mywidth = oldWidth * globApp.safeScreenArea.w
				btns.myheight= oldHeight * globApp.safeScreenArea.h

				local myPositions = relativePosition (btns.anchorPoint, oldXRatio, oldYRatio, oldWidth, oldHeight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --do not move this line to other part.

				btns.myx = myPositions[1]
				btns.myy = myPositions[2]
				btns.factorWidth = btns.mywidth / btns.imgButtonPressed:getWidth ()
				btns.factorHeight = btns.myheight / btns.imgButtonPressed:getHeight ()
				btns.myMaxx = btns.myx + btns.mywidth
				btns.myMaxy = btns.myy + btns.myheight
			end
		end
	end
end



function gui_button_pressed (x,y,button,istouch)

	local activePageName = ""
	for i, pgs in ipairs(pages) do
		if pgs.index == globApp.currentPageIndex then
			activePageName = pgs.name
		end
	end

	local currentButtonsTable = lib_buttons

	--TOGGLE BUTTON CODE
	for i,p in ipairs(currentButtonsTable) do
		if p.page == activePageName then
			if p.type == "toggle" then

				if button == 1 and x >= p.myx and x <= p.myMaxx and y >= p.myy and y <= p.myMaxy then

					if p.state == 1 then
						p.state = 2
						
						if p.callbackFunc ~= nil then
							getfenv()[p.callbackFunc](p.state)
						else
							print ("no callback has been assigned to this button")
						end


					elseif p.state == 2 then
						p.state = 1
						
						if p.callbackFunc ~= nil then
							getfenv()[p.callbackFunc](p.state)
						else
							print ("no callback has been assigned to this button")
						end
			
					end
				
				end

				if touch == true and x >= p.myx and x <= p.myMaxx and y >= p.myy and y <= p.myMaxy then

					if p.state == 1 then
						p.state = 2
						
						if p.callbackFunc ~= nil then
							getfenv()[p.callbackFunc](p.state)
						else
							print ("no callback has been assigned to this button")
						end

					elseif p.state == 2 then
						p.state = 1
						
						if p.callbackFunc ~= nil then
							getfenv()[p.callbackFunc](p.state)
						else
							print ("no callback has been assigned to this button")
						end

					end

				end

			end

			--PUSH BUTTON ON / PUSH OFF:
			if p.type == "pushonoff" then

				if button == 1 and x >= p.myx and x <= p.myMaxx and y >= p.myy and y <= p.myMaxy then

					if p.state == 1 then
							p.state = 2
					end
				
				end

				if touch == true and x >= p.myx and x <= p.myMaxx and y >= p.myy and y <= p.myMaxy then

					if p.state == 1 then
							p.state = 2
					end

				end

			end
		end
	end

end



function gui_button_released (x, y, button, istouch, presses)

	local activePageName = ""
	for i, pgs in ipairs(pages) do
		if pgs.index == globApp.currentPageIndex then
			activePageName = pgs.name
		end
	end

	local currentButtonsTable = lib_buttons

	for i,p in ipairs(currentButtonsTable) do
		if p.page == activePageName then
			--PUSH ON / PUSH OFF BUTTON:
			if p.type == "pushonoff" then

				if button == 1  then

					if p.state == 2 then
						
						p.state = 1

						if p.callbackFunc ~= nil then
							getfenv()[p.callbackFunc](p.state)
						else
							print ("no callback has been assigned to this button")
						end

					end

				end

				-- if touch == true then
					
				-- 	if p.state == 2 then

				-- 		p.state = 1
						
				-- 		if p.callbackFunc ~= nil then
				-- 			getfenv()[p.callbackFunc](p.state)
				-- 		else
				-- 			print ("no callback has been assigned to this button")
				-- 		end

				-- 	end

				-- end

			end
		end
	end

end



function gui_button_returnPosition (position)

	resultPosition = value

	return resultPosition

end


function setButtonState( buttonName, state )
	--"deactivated 0, released 1, pushed 2"
	for i, b in ipairs(lib_buttons) do
		if b.name == buttonName then
			if state == "deactivated" then
				b.deactivated = true
				b.state = 0
			elseif state == "released" then
				b.deactivated = false
				b.state = 1
			elseif state == "pushed" then
				b.deactivated = false
				b.state = 2
			end
		end
	end 
end