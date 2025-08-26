--[[API = Menu Buttons Lybrary ]]


---------------------------------------------------------------------------------------
										--SINGLE BUTTON
---------------------------------------------------------------------------------------

lib_buttons = {}

function button_creation (strgLabel, strgPage, buttonType, strgImgButtonPressed, strgImgButtonReleased, strgImgButtonDeactivated, myx, myy, anchorPoint, myWidth, myHeight, strgCallbackFunc, initialState)

	local newButton = {}

		newButton.name = strgLabel
		newButton.page = strgPage
		newButton.type = buttonType --toggle, pushOnOff, Selector
		newButton.imgButtonPressed = love.graphics.newImage(strgImgButtonPressed)
		newButton.imgButtonReleased = love.graphics.newImage(strgImgButtonReleased)
		newButton.imgButtonDeactivated = love.graphics.newImage(strgImgButtonDeactivated)
		newButton.mywidth = myWidth
		newButton.myheight = myHeight
		local myPositions = relativePosition (anchorPoint, myx, myy, newButton.mywidth, newButton.myheight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --do not move this line to other part.
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

		globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1

end


function buttonUpdate(buttonName, anchorPoint, myx, myy, myWidth, myHeight)

	for i, updButton in ipairs(lib_buttons) do 

		if updButton.name == buttonName then
			
			updButton.mywidth = myWidth
			updButton.myheight = myHeight

			local myPositions = relativePosition (anchorPoint, myx, myy, updButton.mywidth, updButton.myheight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --do not move this line to other part.

			updButton.myx = myPositions[1]
			updButton.myy = myPositions[2]
			updButton.factorWidth = updButton.mywidth / updButton.imgButtonPressed:getWidth ()
			updButton.factorHeight = updButton.myheight / updButton.imgButtonPressed:getHeight ()
			updButton.myMaxx = updButton.myx + updButton.mywidth
			updButton.myMaxy = updButton.myy + updButton.myheight

		end

	end

end


function button_deletion (buttonName,strgPage)

	for i = #lib_buttons,1,-1 do

		local b = lib_buttons[i]

		--LOAD PROJECT:

			if b.name == buttonName and b.page == strgPage then

				table.remove(lib_buttons,i)

				globApp.numObjectsDisplayed = globApp.numObjectsDisplayed - 1

			end

	end

end


function drawButtons (buttonName, strgPage, strgButtonType, strgImgButtonPressed, strgImgButtonReleased, strgImgButtonDeactivated,myx,myy, anchorPoint, mywidth,myheight,callback,initialState)

	--[[ PARAMETERS:

	buttonName -----------------string--------------name of button
	strgPage--------------------string--------------select page from pageNameList table
	strgButtonType--------------string--------------toggle, pushonoff or selector
	strgImgButtonPressed--------string---------------nameofpngfile
	strgImgButtonReleased-------string--------------nameofpngfile
	strgImgButtonDeactivated----double--------------0 to 1 relative to window size
	myx-------------------------double--------------0 to 1 relative to window size
	myy-------------------------double--------------0 to 1 relative to window size
	anchorPoint-----------------string--------------LT,LC,LB,CT,CC,CB,RT,RC,RB
	mywidth---------------------double--------------0 to 1 relative to window size
	myheight--------------------string--------------Name of callback funciton
	callback--------------------string--------------Name of callback funciton

	]]

	local activePageName = 0

	for i, pgs in ipairs (pages) do

		if pgs.index == globApp.currentPageIndex then

			activePageName = pgs.name

		end

	end

	local buttonExists = false

	for i,x in ipairs(lib_buttons) do

		if x.name == buttonName then
			
			buttonExists = true
		
		end

	end

	if activePageName == strgPage then

		if buttonExists == false then --[[ runs once]]

			button_creation (buttonName, strgPage,  strgButtonType, strgImgButtonPressed, strgImgButtonReleased, strgImgButtonDeactivated, myx,myy,anchorPoint,mywidth,myheight,callback, initialState)

		elseif buttonExists == true and globApp.resizeDetected == true then --[[updates only if window is resized]]

			buttonUpdate(buttonName, anchorPoint, myx, myy, mywidth, myheight)

		end

		for i,x in ipairs(lib_buttons) do
			
			if x.name == buttonName and x.state == 0  then
				love.graphics.draw(x.imgButtonDeactivated, x.myx, x.myy, 0, x.factorWidth, x.factorHeight, ox, oy, kx, ky)
			elseif x.name == buttonName and x.state == 1  then
				love.graphics.draw(x.imgButtonReleased, x.myx, x.myy, 0, x.factorWidth, x.factorHeight, ox, oy, kx, ky)
			elseif x.name == buttonName and x.state == 2  then
				love.graphics.draw(x.imgButtonPressed, x.myx, x.myy, 0, x.factorWidth, x.factorHeight, ox, oy, kx, ky)
			end

	    end

	elseif activePageName ~= strgPage  then
 
	 	if buttonExists == true then
			
			button_deletion (buttonName, strgPage)

		end
	
	end
	
end


function buttons_pressed (x,y,button,istouch)

	local currentButtonsTable = lib_buttons

	--TOGGLE BUTTON CODE
	for i,p in ipairs(currentButtonsTable) do

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



function button_released (x, y, button, istouch, presses)

	local currentButtonsTable = lib_buttons

	for i,p in ipairs(currentButtonsTable) do

		--PUSH BUTTON ON / PUSH OFF:
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



function returnButtonPosition (position)

	resultPosition = value

	return resultPosition

end

function deactiveButton (buttonName)
	for i, b in ipairs(lib_buttons) do
		if b.name == buttonName then
			b.deactivated = true
			b.state = 0
		end
	end 
end

function activateButton (buttonName)
	for i, b in ipairs(lib_buttons) do
		if b.name == buttonName then
			b.deactivated = false
			b.state = 1
		end
	end 
end