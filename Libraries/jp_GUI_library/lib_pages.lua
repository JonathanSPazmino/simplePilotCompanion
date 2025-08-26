--[[PAGE HANGLING CODE: 
Contains code to load, switch and handle pages.
This code is called by main.lua
]]

pages = {}

function page_create (myIndex, myName, myLockStatus, myDisplayStatus, myBgColor, myFontSize, myInitPosition, my_width_height_x_y_anchorPoint, myInitMode, testMode)

	local winWidth = globApp.safeScreenArea.w
	local winHeight = globApp.safeScreenArea.h

	local NewPage = {}
		NewPage.index = myIndex
		NewPage.name = myName
		NewPage.locked = myLockStatus
		NewPage.display = myDisplayStatus
		NewPage.bgColor = myBgColor
		NewPage.fontSize = myFontSize
		NewPage.position = myInitPosition
		NewPage.mode = myInitMode
	----------------------------------------------

	local myPagePositions = relativePosition (my_width_height_x_y_anchorPoint[5], my_width_height_x_y_anchorPoint[3], my_width_height_x_y_anchorPoint[4], my_width_height_x_y_anchorPoint[1], my_width_height_x_y_anchorPoint[2], globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --do not move this line to other part.

	if myInitMode == "min" then
	
		NewPage.width = my_width_height_x_y_anchorPoint[1] * winWidth
		NewPage.height = my_width_height_x_y_anchorPoint[2] * winHeight
		NewPage.x = myPagePositions[1]
		NewPage.y = myPagePositions[2]
	
	elseif myInitMode == "max" then

		NewPage.width = winWidth
		NewPage.height = winHeight
		NewPage.x = 0
		NewPage.y = 0

	end

	table.insert(pages, NewPage)

end



local loadingObjects = {}

function loadingPage_create (myName, myToPg, myMinTime_secs, testMode)

	if testMode == true then
		pgWidht = 1000
		pgHeight = 500
	end

	local NewLoadingObject = {}

	NewLoadingObject.name = myName
	NewLoadingObject.fromPg = myFromPg
	NewLoadingObject.toPg = myToPg
	NewLoadingObject.progress = 0
	NewLoadingObject.minEndingProgress = myMinTime_secs
	NewLoadingObject.minTime = myMinTime
	NewLoadingObject.coreFontSize = love.graphics.newFont(math.floor(smartFontScaling (0.025, 0.044)))
	NewLoadingObject.devMsgFontSize = love.graphics.newFont(math.floor(smartFontScaling (0.022, 0.041)))

	for i, pg in ipairs (pages) do
		if pg.index == NewLoadingObject.fromPg then
			NewLoadingObject.fromPg = pg.name
		elseif pg.index == NewLoadingObject.toPg then
			NewLoadingObject.toPg = pg.name
		end
	end

	----------------------------
	--TITLE TEXT
	NewLoadingObject.title = ("Loading " .. NewLoadingObject.toPg .. "...")
	NewLoadingObject.titleWidth = smartScaling ("inverse", .3, .8, .0375, 0.1, 0.125,"width" )
	NewLoadingObject.titleHeight = smartScaling ("inverse", .3, .8, .0375, 0.1, 0.125,"height" )
	local titleAnchorPoint = "CC"
	local titleToScreenRelation_X = 0.5 --change as needed
	local titleToScreenRelation_Y = smartRelocation (.45,.0,.50,1,nil,nil,nil,nil,"y") --change as needed
	local myTitlePositions = relativePosition (titleAnchorPoint, titleToScreenRelation_X, titleToScreenRelation_Y,  NewLoadingObject.titleWidth, NewLoadingObject.titleHeight,  globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h)

	NewLoadingObject.titleX = myTitlePositions[1]
	NewLoadingObject.titleY = myTitlePositions[2]


	---------------------------------------------------------------------------
	--DEV MESSAGE
	NewLoadingObject.msgTxt = ("Follow us on facebook and tweeter for more information on how you can help inprove this app!")
	NewLoadingObject.msgTxtWidth = smartScaling ("inverse", 0.9,.95, .063, 0.0665, 0.07,"width" )
	NewLoadingObject.msgTxtHeight = smartScaling ("inverse", 0.9,.95, .063, 0.0665, 0.07,"height")
	local devMsgAnchorPoint = "CC"
	local devMsgToScreenRelation_X = 0.5 --change as needed
	local devMsgToScreenRelation_Y = smartRelocation (.65,.0,.70,1,nil,nil,nil,nil,"y") --change as needed

	local myDevMsgPositions = relativePosition (devMsgAnchorPoint, devMsgToScreenRelation_X, devMsgToScreenRelation_Y, NewLoadingObject.msgTxtWidth, NewLoadingObject.msgTxtHeight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h)

	NewLoadingObject.msgTxtX = myDevMsgPositions[1]
	NewLoadingObject.msgTxtY = myDevMsgPositions[2]


	-----------------------------------------
	--PROGRESS BAR FRAME
	NewLoadingObject.progressBarFrameWidth = smartScaling ("inverse", 0.85,.90, .034, .036, 0.04,"width" )
	NewLoadingObject.progressBarFrameHeight = smartScaling ("inverse", 0.85,.90, .034, .036, 0.04,"height")
	local progressBarFrameAnchorPoint = "CC"
	local progressBarFrameToScreenRelation_X = 0.5 --change as needed
	local progressBarFrameToScreenRelation_Y = smartRelocation (.85,.0,.90,1,nil,nil,nil,nil,"y") --change as needed

	local myProgressBarFramePositions = relativePosition (progressBarFrameAnchorPoint, progressBarFrameToScreenRelation_X, progressBarFrameToScreenRelation_Y, NewLoadingObject.progressBarFrameWidth, NewLoadingObject.progressBarFrameHeight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h)

	NewLoadingObject.progressBarFrameX = myProgressBarFramePositions [1]
	NewLoadingObject.progressBarFrameY = myProgressBarFramePositions [2]


	----------------------------------------
	--PROGRESS BAR

	NewLoadingObject.progressBarWidth = 400
	NewLoadingObject.progressBarHeight = smartScaling ("inverse", 0.9,.95, .036, .038, 0.04,"height")
	local progressBarAnchorPoint = "LT" --change as needed
	local progressBarToFrameRelation_X = 0 --change as needed
	local progressBarToFrameRelation_Y = 0 --change as needed

	local myProgressBarPositions = relativePosition (progressBarAnchorPoint, progressBarToFrameRelation_X, progressBarToFrameRelation_Y, NewLoadingObject.progressBarWidth, NewLoadingObject.progressBarHeight, NewLoadingObject.progressBarFrameX, NewLoadingObject.progressBarFrameY, NewLoadingObject.progressBarFrameWidth, NewLoadingObject.progressBarFrameHeight)

	NewLoadingObject.progressBarX = myProgressBarPositions [1]
	NewLoadingObject.progressBarY = myProgressBarPositions [2]

	table.insert(loadingObjects, NewLoadingObject)

	if testMode == true then 
		local result = {}
		result[1] = NewLoadingObject.name
		result[2] = NewLoadingObject.titleX
		result[3] = NewLoadingObject.titleY
		result[4] = NewLoadingObject.title
		result[5] = NewLoadingObject.progress
		result[6] = NewLoadingObject.progressBarX
		result[7] = NewLoadingObject.fromPg
		result[8] = NewLoadingObject.toPg
		result[9] = NewLoadingObject.progressBarHeight
		result[10] = NewLoadingObject.progressBarX
		return result --[[unitest only]]
	end

end




function update_loadingPage (dt)

	local activeLoadingPg = false
	local onlyOneLoadingPage = false

	if globApp.currentPageIndex == 2 then
		activeLoadingPg = true
	end

	for i=1, #loadingObjects, 1 do
		if i == 1 then
			onlyOneLoadingPage = true
		elseif i ~= 1 then
			onlyOneLoadingPage = false
		end
	end

	if activeLoadingPg == true and onlyOneLoadingPage == true then

		for i, lp in ipairs (loadingObjects) do

			if lp.progress < lp.minEndingProgress then 

				lp.progress = lp.progress + dt

			elseif lp.progress >= lp.minEndingProgress then

				lp.progress = lp.minEndingProgress

			end

			if globApp.resizeDetected == true then

				lp.coreFontSize = love.graphics.newFont(math.floor(smartFontScaling (0.025, 0.044)))
				lp.devMsgFontSize = love.graphics.newFont(math.floor(smartFontScaling (0.022, 0.041)))

				----------------------------
				--TITLE TEXT
				lp.titleWidth = smartScaling ("inverse", .3, .8, .036, 0.096, 0.12,"width" )
				lp.titleHeight = smartScaling ("inverse", .3, .8, .036, 0.096, 0.12,"height" )
				local titleAnchorPoint = "CC"
				local titleToScreenRelation_X = 0.5 --change as needed
				local titleToScreenRelation_Y = smartRelocation (.45,.0,.50,1,nil,nil,nil,nil,"y") --change as needed
				local myTitlePositions = relativePosition (titleAnchorPoint, titleToScreenRelation_X, titleToScreenRelation_Y,  lp.titleWidth, lp.titleHeight,  globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h)

				lp.titleX = myTitlePositions[1]
				lp.titleY = myTitlePositions[2]

				---------------------------------------------------------------------------
				--DEV MESSAGE
				lp.msgTxtWidth = 0.8 * globApp.safeScreenArea.w
				lp.msgTxtHeight = .2 * globApp.safeScreenArea.h
				local devMsgAnchorPoint = "CC"
				local devMsgToScreenRelation_X = 0.5 --change as needed
				local devMsgToScreenRelation_Y = smartRelocation (.65,.0,.70,1,nil,nil,nil,nil,"y") --change as needed

				local myDevMsgPositions = relativePosition (devMsgAnchorPoint, devMsgToScreenRelation_X, devMsgToScreenRelation_Y, lp.msgTxtWidth, lp.msgTxtHeight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h)

				lp.msgTxtX = myDevMsgPositions[1]
				lp.msgTxtY = myDevMsgPositions[2]

				-----------------------------------------
				--PROGRESS BAR FRAME
				lp.progressBarFrameWidth = smartScaling ("inverse", 0.85,.90, .034, .036, 0.04,"width" )
				lp.progressBarFrameHeight = smartScaling ("inverse", 0.85,.90, .034, .036, 0.04,"height")
				local progressBarFrameAnchorPoint = "CC"
				local progressBarFrameToScreenRelation_X = 0.5 --change as needed
				local progressBarFrameToScreenRelation_Y = smartRelocation (.85,.0,.90,1,nil,nil,nil,nil,"y") --change as needed

				local myProgressBarFramePositions = relativePosition (progressBarFrameAnchorPoint, progressBarFrameToScreenRelation_X, progressBarFrameToScreenRelation_Y, lp.progressBarFrameWidth, lp.progressBarFrameHeight, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h)

				lp.progressBarFrameX = myProgressBarFramePositions [1]
				lp.progressBarFrameY = myProgressBarFramePositions [2]

				----------------------------------------
				--PROGRESS BAR
				lp.progressBarWidth = (lp.progress / lp.minEndingProgress) * lp.progressBarFrameWidth
				lp.progressBarHeight = smartScaling ("inverse", 0.9,.95, .036, .038, 0.04,"height")
				local progressBarAnchorPoint = "LT" --change as needed
				local progressBarToFrameRelation_X = 0 --change as needed
				local progressBarToFrameRelation_Y = 0 --change as needed

				local myProgressBarPositions = relativePosition (progressBarAnchorPoint, progressBarToFrameRelation_X, progressBarToFrameRelation_Y, lp.progressBarWidth, lp.progressBarHeight, lp.progressBarFrameX, lp.progressBarFrameY, lp.progressBarFrameWidth, lp.progressBarFrameHeight)

				lp.progressBarX = myProgressBarPositions [1]
				lp.progressBarY = myProgressBarPositions [2]

			elseif globApp.resizeDetected == false then

				lp.progressBarWidth = (lp.progress / lp.minEndingProgress) * lp.progressBarFrameWidth

			end

		end

	end
	
end


function delete_loadingPage ()

	for i = #loadingObjects,1,-1 do

		table.remove(loadingObjects,i)

	end

end


function draw_loadingPage ()

	local activeLoadingPg = false

	local onlyOneLoadingPage = false

	if globApp.currentPageIndex == 2 then
		activeLoadingPg = true
	end

	for i=1, #loadingObjects, 1 do

		if i == 1 then

			onlyOneLoadingPage = true

		elseif i ~= 1 then

			onlyOneLoadingPage = false

		end

	end

	if onlyOneLoadingPage == true and activeLoadingPg == true then

		for i, lp in ipairs (loadingObjects) do 

			--TITLE:--------------------------------------------------
			love.graphics.setFont(lp.coreFontSize)
			love.graphics.printf(lp.title, lp.titleX, lp.titleY, lp.titleWidth, "center", r, sx, sy, ox, oy, kx, ky)
				--testing only:
				-- love.graphics.rectangle("line", lp.titleX, lp.titleY, lp.titleWidth, lp.titleHeight)

			--DEVELOPER MSG:------------------------------------------
			love.graphics.setFont(lp.devMsgFontSize)
			love.graphics.printf(lp.msgTxt, lp.msgTxtX, lp.msgTxtY, lp.msgTxtWidth, "center", r, sx, sy, ox, oy, kx, ky)
				--testing only:
				-- love.graphics.rectangle("line", lp.msgTxtX, lp.msgTxtY, lp.msgTxtWidth, lp.msgTxtHeight)

			--PROGRESS BAR:--------------------------------------------
			love.graphics.setColor(0, 1, 0, alpha)
			love.graphics.rectangle("fill", lp.progressBarX, lp.progressBarY, lp.progressBarWidth, lp.progressBarHeight)

			--PROGRESS BAR FRAME:

			love.graphics.setColor(1, 1, 1, alpha)
			love.graphics.rectangle("line", lp.progressBarFrameX, lp.progressBarFrameY, lp.progressBarFrameWidth, lp.progressBarFrameHeight)

		end

	end

end


function page_switch (myName, myToPg, myMinTime_secs, testMode)

	local toPageExists = doesPageExist (myToPg)

	if toPageExists == true then

		local initialPage = globApp.currentPageIndex

		local timerName =  ("load:".. globApp.currentPageIndex .. "/".. myToPg)

		globApp.currentPageIndex = 2 --opens loading page index

		loadingPage_create (myName, myToPg, myMinTime_secs, testMode)

		create_newTimeTrigger (timerName,  { myMinTime_secs, myMinTime_secs+.001}, {"delete_loadingPage","changePgto"})

		function changePgto ()
			if globApp.fourDevTap == false then
				globApp.currentPageIndex = myToPg
			elseif globApp.fourDevTap == true then
				globApp.currentPageIndex = 20050
				globApp.fourDevTap = false

			end

			globApp.pageChanged = false
		end
		if initialPage ~= myToPg then
			globApp.pageChanged = true
			-- print ("pageChangeVar= " .. tostring(globApp.pageChanged))
			globApp.pageChanged = false
			-- print ("pageChangeVar= " .. tostring(globApp.pageChanged))
		end

	elseif toPageExists == false then

		print ("The requested page index ".. myToPg .. " does not yet exits")

	end

end


function doesPageExist (pageIndex)

	local result = false
	local pagesVarExist = false 

	--check is glob var exists yet

	if pages ~= nil then

		pagesVarExist = true 

	end 

	if pagesVarExist == true then

		for i, pgs in ipairs (pages) do

			local index = pgs.index

			if index == pageIndex then
				result = true
			end

		end

	end

	return result

end


function returnCurrentPageName ()

	--[[takes page index number and converts it to page name]]

	for i, pg in ipairs(pages) do

		if globApp.currentPageIndex == pg.index then

			pageName = pg.name

			return pageName

		end

	end

end


function isPgActive (pageIndex)

	--[[Takes page index and returns true if page index matches current page index]]

	myResult = false

	if pageIndex == globApp.currentPageIndex then

		myResult = true

	end

	return myResult

end



function pageBackground_draw ()

	for i, pg in ipairs (pages) do

		if pg.index == globApp.currentPageIndex then

			love.graphics.setColor(globApp.appColor[1], globApp.appColor[2], globApp.appColor[3], globApp.appColor[4])

			love.graphics.rectangle("fill", globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h)

			love.graphics.reset ()

		end

	end

end


------------------------------------------------------------------------------
							--DEFAULT GUI PAGES
------------------------------------------------------------------------------
--this pages can not be created by GUI users as they are preDefined

page_create (1, "Blank", false, false, globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")
page_create (2, "Loading", false, false, globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")
page_create (20050, "DeveloperMenu", false, false, globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")
page_create (20051, "UnitTesting", false , false , globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")
page_create (20052, "screenTestsMenu", false , false , globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")
page_create (20053, "switchScreenSize", false , false , globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")
page_create (20054, "unitTestInfo", false , false , globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")
page_create (20055, "devEraseDataConfirmationPage", false , false , globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")
page_create (20056, "devAboutPage", false , false , globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")
