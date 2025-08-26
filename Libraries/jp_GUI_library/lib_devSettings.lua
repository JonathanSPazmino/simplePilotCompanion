
--Settings:
-- require ("pageHandling")

--------------------------------------------------------------------------
						--GENERAL
--------------------------------------------------------------------------

local guiVersion = MAIN_GDSGUI_VERSION

local devSettings = {}
		devSettings.amIdeveloping = true
		devSettings.developerPrint = 1
		devSettings.displayFPS = 1


function developerPrint (printingValue, OnOffSwitch)
	if devSettings.amIdeveloping == true and (OnOffSwitch == "on" or OnOffSwitch == "ON" or OnOffSwitch == "On") and devSettings.developerPrint == 1 then
		print (printingValue)
	end
end

--------------------------------------------------------------------------
					--DEVELOPER DISPLAYS
-------------------------------------------------------------------------
local devDataDisplay = {}
		--FONT
		devDataDisplay.font = {}
			devDataDisplay.font.transparency = .40
			devDataDisplay.font.color = {1, 1, 1}
			devDataDisplay.font.size = math.floor(smartFontScaling (0.02, 0.037))
			devDataDisplay.font.font = love.graphics.newFont(devDataDisplay.font.size)
		--TOP ROW
		devDataDisplay.topRow = {}
			-- TOP ROW GENERAL
			devDataDisplay.topRow.isVisible = true
			devDataDisplay.topRow.y = globApp.safeScreenArea.y + (devDataDisplay.font.size)
			-- TOP ROW WINDOW DIMENSIONS
			devDataDisplay.topRow.winDimensions = {}
				devDataDisplay.topRow.winDimensions.textWidht = math.floor(globApp.safeScreenArea.w)
				devDataDisplay.topRow.winDimensions.textHeight = math.floor(globApp.safeScreenArea.h)
				devDataDisplay.topRow.winDimensions.density = math.floor(globApp.appScale)
				devDataDisplay.topRow.winDimensions.x = globApp.safeScreenArea.x + (globApp.safeScreenArea.w * .3)
				devDataDisplay.topRow.winDimensions.text = (devDataDisplay.topRow.winDimensions.textWidht .. "x" .. devDataDisplay.topRow.winDimensions.textHeight .. "/d:".. devDataDisplay.topRow.winDimensions.density)
			-- TOP ROW FPS DISPLAY
			devDataDisplay.topRow.fpsData = {}
				devDataDisplay.topRow.fpsData.x = globApp.safeScreenArea.x + (globApp.safeScreenArea.w * 0.92) - 45
				devDataDisplay.topRow.fpsData.fps = love.timer.getFPS()
				devDataDisplay.topRow.fpsData.display = "FPS: ".. devDataDisplay.topRow.fpsData.fps
				devDataDisplay.topRow.fpsData.period = 0.01715
				devDataDisplay.topRow.fpsData.timer = devDataDisplay.topRow.fpsData.period
		--BOTTOM ROW
		devDataDisplay.bottomRow = {} 
			--BOTTOM ROW GENERAL
			devDataDisplay.bottomRow.isVisible = true
			devDataDisplay.bottomRow.y = (globApp.safeScreenArea.y + globApp.safeScreenArea.h ) - (devDataDisplay.font.size * 2)
			--BOTTOM ROW PAGE ID
			devDataDisplay.bottomRow.pageID = {}
				devDataDisplay.bottomRow.pageID.text = returnCurrentPageName ()
				devDataDisplay.bottomRow.pageID.x = globApp.safeScreenArea.x + devDataDisplay.font.size 
			--BOTTOM ROW OBJECT COUNT DISPLAY
			devDataDisplay.bottomRow.dsplydOjCount = {}
				devDataDisplay.bottomRow.dsplydOjCount.x = globApp.safeScreenArea.x + globApp.safeScreenArea.w * 0.45 +3
				devDataDisplay.bottomRow.dsplydOjCount.text = globApp.numObjectsDisplayed
			--BOTTOM ROW GUI VERSION
			devDataDisplay.bottomRow.GUIversion = {}
				devDataDisplay.bottomRow.GUIversion.x = globApp.safeScreenArea.x + (globApp.safeScreenArea.w * 0.90) - 45
				devDataDisplay.bottomRow.GUIversion.text = guiVersion

function updateDevDisplaysParameters (dt)
	--WILL RUN ONLY WHEN RESIZE FUNCTION RETURNS TRUE
	if globApp.resizeDetected == true then
		--FONT
			devDataDisplay.font.size = math.floor(smartFontScaling (0.02, 0.037))
			devDataDisplay.font.font = love.graphics.newFont(devDataDisplay.font.size)

		--TOP_ROW 
			--TOPROW GENERAL
			devDataDisplay.topRow.y = globApp.safeScreenArea.y + (devDataDisplay.font.size)
			--WINDIMENSIONS
			devDataDisplay.topRow.winDimensions.textWidht = math.floor(globApp.safeScreenArea.w)
			devDataDisplay.topRow.winDimensions.textHeight = math.floor(globApp.safeScreenArea.h)
			devDataDisplay.topRow.winDimensions.density = math.floor(globApp.appScale)
			devDataDisplay.topRow.winDimensions.x = globApp.safeScreenArea.x + (globApp.safeScreenArea.w * .3)
			devDataDisplay.topRow.winDimensions.text = (devDataDisplay.topRow.winDimensions.textWidht .. "x" .. devDataDisplay.topRow.winDimensions.textHeight .. "/d:".. devDataDisplay.topRow.winDimensions.density)
			--FPS DATA
			devDataDisplay.topRow.fpsData.x = globApp.safeScreenArea.x + (globApp.safeScreenArea.w * 0.92) - 45
		
		--BOTTOM_ROW
			--BOTTOM ROW GENERAL
			devDataDisplay.bottomRow.y = (globApp.safeScreenArea.y + globApp.safeScreenArea.h ) - (devDataDisplay.font.size * 2)
			--PAGE ID
			devDataDisplay.bottomRow.pageID.x = globApp.safeScreenArea.x + devDataDisplay.font.size 
			--DISPLAY OBJECTS COUNT
			devDataDisplay.bottomRow.dsplydOjCount.x = globApp.safeScreenArea.x + globApp.safeScreenArea.w * 0.45 +3
			--GUI VERSION
			devDataDisplay.bottomRow.GUIversion.x = globApp.safeScreenArea.x + (globApp.safeScreenArea.w * 0.90) - 45
	end

	--RUNS CONTINUOUSLY
	devDataDisplay.topRow.fpsData.timer = devDataDisplay.topRow.fpsData.period
	devDataDisplay.topRow.fpsData.timer = devDataDisplay.topRow.fpsData.timer - dt
	if devDataDisplay.topRow.fpsData.timer <= 0 then
		devDataDisplay.topRow.fpsData.fps = math.ceil(1.0 / dt)
		devDataDisplay.topRow.fpsData.timer = devDataDisplay.topRow.fpsData.period
		devDataDisplay.topRow.fpsData.display = "FPS: ".. devDataDisplay.topRow.fpsData.fps
	end
	devDataDisplay.bottomRow.pageID.text = returnCurrentPageName ()
	devDataDisplay.bottomRow.dsplydOjCount.text = globApp.numObjectsDisplayed
end

function drawTopRowDevDisplays ()
	--RUNS ONLY IF DEV DISPLAYS ARE SELECTED VISIBLE FROM VAR DECLARATION
	if devSettings.amIdeveloping == true and devDataDisplay.topRow.isVisible == true then
		--GENERAL
		love.graphics.setFont(devDataDisplay.font.font)
		love.graphics.setColor(devDataDisplay.font.color[1], devDataDisplay.font.color[2], devDataDisplay.font.color[3], devDataDisplay.font.transparency)
		--WINDOW DIMENSIONS:
		love.graphics.print (devDataDisplay.topRow.winDimensions.text, devDataDisplay.topRow.winDimensions.x, devDataDisplay.topRow.y)
		love.graphics.reset ()
		--FPS DISPLAY:
		if devDataDisplay.topRow.fpsData.fps >= 50 then
			love.graphics.setColor(0, 1, 0, devDataDisplay.font.transparency)
		elseif devDataDisplay.topRow.fpsData.fps < 50 and devDataDisplay.topRow.fpsData.fps >= 30 then
			love.graphics.setColor(0.6, 0, 0, devDataDisplay.font.transparency)
		elseif devDataDisplay.topRow.fpsData.fps < 30 then
			love.graphics.setColor(1, 0, 1, devDataDisplay.font.transparency)
		end
		
		love.graphics.print (devDataDisplay.topRow.fpsData.display, devDataDisplay.topRow.fpsData.x, devDataDisplay.topRow.y)
		love.graphics.reset ()
	end
end

function drawBottomRowDevDisplays ()

	if devSettings.amIdeveloping == true and devDataDisplay.bottomRow.isVisible == true then

		love.graphics.setFont(devDataDisplay.font.font)

		love.graphics.setColor(devDataDisplay.font.color[1], devDataDisplay.font.color[2], devDataDisplay.font.color[3], devDataDisplay.font.transparency)

		love.graphics.print("pg: " .. devDataDisplay.bottomRow.pageID.text, devDataDisplay.bottomRow.pageID.x, devDataDisplay.bottomRow.y)

		love.graphics.print("#Objs: " .. devDataDisplay.bottomRow.dsplydOjCount.text, devDataDisplay.bottomRow.dsplydOjCount.x, devDataDisplay.bottomRow.y)

		love.graphics.print("GUI: " .. devDataDisplay.bottomRow.GUIversion.text, devDataDisplay.bottomRow.GUIversion.x, devDataDisplay.bottomRow.y)

	end
end

function drawAllDevDisplays ()

	--DEVELOPER PAGES
	developerMenuPage()

	developerUnitTestPage ()

	screenTestMenuPage ()

	unitTestInfoPage ()

	switchScreenSizePage ()

	devEraseDataConfirmationPage ()

	devAboutPage ()

	--DEVELOPER DISPLAYS:
	drawTopRowDevDisplays ()

	drawBottomRowDevDisplays ()

	testTimeTrigger ()

	love.graphics.reset ()
end

local function returnNumberOfDisplays ()
	local DisplayCount = love.window.getDisplayCount( )
	return DisplayCount
end

local function returnVsyncStatus ()
	local config_vsync = love.window.getVSync()
	return config_vsync
end

local function returnDesktopDimensions (strgMode)
	local stdFormatMode = string.lower(strgMode)
	local desktopWidth, desktopHeight = love.window.getDesktopDimensions( 1 )

	if stdFormatMode == "height" then
		return desktopWidth
	elseif stdFormatMode == "width" then
		return desktopHeight
	end
end

function DrawScanCode (mykey) --I check status of this function posible trash it.
	local printingString = "nothing pressed yet"
	local testkey = mykey

	if testkey ~= nil then
		local testscanCode = love.keyboard.getScancodeFromKey (testkey)
		local testdown = love.keyboard.isScancodeDown(testscanCode)

		if testdown == true then
			printingString = testscanCode .. " is down"
		else 
			printingString = testscanCode .. " is NOT down"
		end
	end
end


------------------------------------------------------------------------------
							--TDD
--TEST DRIVEN DEVELOPMENT SECTION:
--The following code is related to testing development written in a OOP fashion.
--The Objects are stored in the devTests table and can referenced globaly
--------------------------------------------------------------------------------
devTests = {}

function devTest_create (myLable, myTestingUnit, myInput, myExpectedOutPut)

	--[[GUIDE:
		NOTES: unlimited input and output table paramters

		INPUT:
			myLable--------------------string-------------anyUniqueName
			myTestingUnit--------------stringTABLE--------full path values from outter2inner
			myInput--------------------table--------------any data type table format only
			myExpectedOutPut-----------table--------------any data type table format only

		OUTPUT:
			resultString-----------string----------------name,result,elspsedtime
		]]

	processedInput  = myInput

	local path_level_counter = 0
	local parameter_counter = 0
	local expected_output_counter = 0
	local start = 0

	for i=1 , #myTestingUnit, 1 do
		path_level_counter = path_level_counter + 1
	end

	for i=1 , #myInput, 1 do
		parameter_counter = parameter_counter + 1
	end

	NewTest = {}
	NewTest.name = myLable
	NewTest.result = "*fail*"
	NewTest.path = {}


	local msg_positive_test = "passed"

	for i= 1, path_level_counter, 1 do
		if i~= path_level_counter then
			NewTest.path[i] = myTestingUnit[i]
			getfenv()[NewTest.path[i]]()
		elseif i == path_level_counter then
			NewTest.test = myTestingUnit[#myTestingUnit]
		end
	end

	--[[THIS PART RUNNS THE TEST PASSING PARAMETERS]]

	local fullParameterString1 = "NewTest.output = getfenv()[NewTest.test]("
	local fullParameterString2 = ""
	local fullParameterString3 = ""

	for i=1, parameter_counter, 1 do

		if i~= parameter_counter then
		local unitParameterString = ("processedInput[" .. i .. "], ")
		fullParameterString2 = fullParameterString2 .. unitParameterString
		elseif i== parameter_counter then
		local unitParameterString = ("processedInput[" .. i .. "]")
		fullParameterString2 = fullParameterString2 .. unitParameterString
		end
		
	end

	fullParameterString3 = fullParameterString1 .. fullParameterString2 .. ",true)"

	
	local executeStringTestFunction = loadstring(fullParameterString3)
	local startTime = love.timer.getTime()
	executeStringTestFunction()
	local endTime = love.timer.getTime() - startTime

	for i=1, #myExpectedOutPut, 1 do
		expected_output_counter = expected_output_counter + 1
	end

	local testFailTrigger = false
	NewTest.failingParameter = ""

	if type (NewTest.output) ~= "table" and NewTest.output ~= nil then --converts single values to table format

		local tamporaryOutputHolder = NewTest.output
		NewTest.output = {}
		NewTest.output[1] = tamporaryOutputHolder

	end

	for i=1, #myExpectedOutPut, 1 do

		if NewTest.output[i] ~= myExpectedOutPut[i] then

			local outputExists = true
			local expectedOutputExists = true

			if NewTest.output[i] == nil then
				outputExists = false
			end 
			if myExpectedOutPut[i] == nil then
				expectedOutputExists = false
			end 

			testFailTrigger = true

			if outputExists == true and expectedOutputExists == true then
				NewTest.failingParameter = NewTest.failingParameter .. i .. ")_xpctd:" .. tostring(myExpectedOutPut[i]) .. "_butGot:" .. tostring(NewTest.output[i]) ..  ", "
			elseif outputExists == false and expectedOutputExists == true then
				NewTest.failingParameter = NewTest.failingParameter .. i .. ")_noXpctdVal: " .. "_butGot: " .. tostring(NewTest.output[i]) ..  ","
			elseif outputExists == true and expectedOutputExists == false then
				NewTest.failingParameter = NewTest.failingParameter .. i .. ")_xpct:" .. tostring (myExpectedOutPut[i]) .. "butGotNoOutput,"
			end

		end
	end

	if testFailTrigger == false then
		NewTest.result = msg_positive_test
	end

	NewTest.elapsedTime = tonumber(string.format("%.5f", endTime * 1000))

	local serializedUnitTestData = createNewProjectData ({"name","result","path","test","failingParameter","elapsedTime","output"}, {NewTest.name, NewTest.result, NewTest.path, NewTest.test, NewTest.failingParameter, NewTest.elapsedTime, NewTest.output}, devTests, "UTL", 7)
	
	table.insert(devTests, serializedUnitTestData)

	-- table.insert (devTests, NewTest)

end

function devTest_execute (testSpecs)

	--[[ 
		PARAMETERS:

		mylabel---------------string-----------------unique name
		myTestingUnit-------string table-------------outer to inner functions to be called 5 max
		myInput --------------table------------------all required parameters MAX 10
		myExpectedOutPut------table------------------all expected outputs max 4

		RETURN:
		
			result----------------string-----------------concatenated unit test result, 1) test name, 2)result, 3)elapsed time
	]]

	local testId = testSpecs["id"]
	local functionID = testSpecs["funcName"]
	local parameters = testSpecs ["funcParameters"]
	local results = testSpecs["funcExpctOutput"]



	if globApp.developerMode == true then
		local testCount = 0
		local testExists = false

		for i, test in ipairs (devTests) do
			testCount = testCount + 1
			if test.name == testId then
				testExists = true
			end
		end

		if testCount == 0 or testExists == false then
			devTest_create (testId, functionID, parameters, results)
		end
	end
end



function write_unit_test_results (alertMode, alertType)

	if alertMode == "console" then

		for i, test in pairs (devTests) do

			if test.result ~= "passed" and alertType == "fail" then

				local stringResult = (test.result.. " __ in ".. test.elapsedTime .. " secs." .. " __ " .. test.name .. " failures: " .. test.failingParameter)
				-- print (stringResult)
				generateConsoleMessage ("error", stringResult)

			elseif test.result == "passed" and alertType == "passed" then

				local stringResult = (test.result.. " __ in ".. test.elapsedTime .. " secs." .. " __ " .. test.name )
				generateConsoleMessage ("info", stringResult)

			elseif alertType == "all" then

				if test.result ~= "passed" then

					local stringResult = (test.result.. " __ in ".. test.elapsedTime .. " secs." .. " __ " .. test.name .. " failures: " .. test.failingParameter)
					generateConsoleMessage ("error", stringResult)

				elseif test.result == "passed" then

					local stringResult = (test.result.. " __ in ".. test.elapsedTime .. " secs." .. " __ " .. test.name )
					generateConsoleMessage ("info", stringResult)

				end

			end

		end

	end

end


function open_DevPgByEightTapping (x,y,button,istouch)

	if globApp.developerMode == true then

		if (button == 1 or globApp.userInput == "tap") and globApp.currentPageIndex == 2 and globApp.devTapCounter < 8 and globApp.fourDevTap == false then
			
			globApp.devTapCounter = globApp.devTapCounter + 1

			generateConsoleMessage ("info", "devTap #"..globApp.devTapCounter)

			if globApp.devTapCounter == 8 then

				globApp.fourDevTap = true 

				globApp.devTapCounter = 0
				generateConsoleMessage ("info", "Developer access granted")
			end
			
		end



	end

end 






----------------------------------------------------------------------------------
							--SWITCH PAGES FUNCTIONS
----------------------------------------------------------------------------------

function openDevMainMenu ()

	page_switch ("LodingDeveloperMenu", 20050, 2, false)

end

local safeLoadTimer = 0.1

function leaveDeveloperGUI ()

	globApp.fourDevTap = false

	globApp.devTapCounter = 0

	page_switch ("leavingDevPage", 3, safeLoadTimer, false)

end


function openUnitTestPage ()
	gdsGUI_executeAllUnitTests ("DeveloperMenu")

	if globApp.currentPageIndex == 20054 then
		focusedUnitTest = "none"
	end
	page_switch ("LoadingUnitTestsPage", 20051, 2, false)

end


function openScreenTestsMenuPage ()

	page_switch ("LoadingScreenTestsMenuPage", 20052, 2, false)

end

function openDevEraseDataConfirmationPage ()

	page_switch ("LoadingScreenTestsMenuPage", 20055, .3, false)

end


function openSwitchScreenSizePage ()

	ScreenSimulatorsInit ()

	page_switch ("LoadingSwitchScreenSizePage", 20053, 2, false)

end

function openDevAboutPage ()
	page_switch ("LoadingDevAboutPage", 20056, 2, false)

end




----------------------------------------------------------------------------------
							--DEV PAGES
----------------------------------------------------------------------------------

local screenTestButtonInitialState = 1

if globApp.OperatingSystem == "iOS" or globApp.OperatingSystem == "Android" then

	screenTestButtonInitialState = 0

end


function developerMenuPage()

	local thisPageName = "DeveloperMenu"

	drawButtons("unitTest"--[[ButtonLable]], 
		thisPageName--[[page]], 
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_devUnitTest_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_devUnitTest_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_devUnitTest_deactivated.png")--[[sprite:deactivated]],
		.5--[[x coordinate]],
		.20--[[y coordinate]],
		"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
		"openUnitTestPage"--[[callback function]], 
		1--[[button initial status]])

	drawButtons("screenDevTests"--[[ButtonLable]], 
		thisPageName--[[page]], 
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_screenTestMenuButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_screenTestMenuButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_screenTestMenuButton_deactivated.png")--[[sprite:deactivated]],
		.5--[[x coordinate]],
		.35--[[y coordinate]],
		"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
		"openScreenTestsMenuPage"--[[callback function]], 
		screenTestButtonInitialState --[[button initial status]])

	drawButtons("resetData"--[[ButtonLable]], 
		thisPageName--[[page]], 
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_devEraseDataButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_devEraseDataButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_devEraseDataButton_deactivated.png")--[[sprite:deactivated]],
		.5--[[x coordinate]],
		.50--[[y coordinate]],
		"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
		"openDevEraseDataConfirmationPage"--[[callback function]], 
		screenTestButtonInitialState --[[button initial status]])

	drawButtons("aboutAppPage"--[[ButtonLable]], 
		thisPageName--[[page]], 
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_devaAboutButton_pressed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_devaAboutButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_devaAboutButton_deactivated.png")--[[sprite:deactivated]],
		.5--[[x coordinate]],
		.65--[[y coordinate]],
		"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
		"openDevAboutPage"--[[callback function]], 
		1--[[button initial status]])


	drawButtons("exitDevMenu"--[[ButtonLable]], 
		thisPageName--[[page]], 
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_exitDevMenuButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_exitDevMenuButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_exitDevMenuButton_deactivated.png")--[[sprite:deactivated]],
		.5--[[x coordinate]],
		.80--[[y coordinate]],
		"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
		"leaveDeveloperGUI"--[[callback function]], 
		1--[[button initial status]])
end 

function screenTestMenuPage ()

	local thisPageName = "screenTestsMenu"

	drawButtons("returnDevMenu"--[[ButtonLable]], 
		thisPageName--[[page]],
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_deactivated.png")--[[sprite:deactivated]],
		.035--[[x coordinate]],
		.043--[[y coordinate]],
		"LT"--[[anchorPoint string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"width" )--[[width]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"height" )--[[height]],
		"openDevMainMenu"--[[callback function]],
		1--[[button initial status]])

	drawButtons("switchScreenSize"--[[ButtonLable]],
		thisPageName--[[page]],
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_switchScreenSizeButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_switchScreenSizeButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_switchScreenSizeButton_deactivated.png")--[[sprite:deactivated]],
		.5--[[x coordinate]],
		.25--[[y coordinate]],
		"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
		smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
		"openSwitchScreenSizePage"--[[callback function]],
		1--[[button initial status]])
end

function devEraseDataConfirmationPage ()

	local thisPageName = "devEraseDataConfirmationPage"

	drawButtons("returnDevMenu"--[[ButtonLable]], 
		thisPageName--[[page]],
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_deactivated.png")--[[sprite:deactivated]],
		.035--[[x coordinate]],
		.043--[[y coordinate]],
		"LT"--[[anchorPoint string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"width" )--[[width]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"height" )--[[height]],
		"openDevMainMenu"--[[callback function]],
		1--[[button initial status]])

	drawButtons("yesConfirmation"--[[ButtonLable]], 
		thisPageName--[[page]],
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_yesConfirmButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_yesConfirmButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_yesConfirmButton_deactivated.png")--[[sprite:deactivated]],
		.15--[[x coordinate]],
		.70--[[y coordinate]],
		"LT"--[[anchorPoint string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.20, .30, .044, 0.066, 0.22,"width" )--[[width]],
		smartScaling ("inverse", 0.20, .30, .044, 0.066, 0.22,"height" )--[[height]],
		"deleteAllProjectData"--[[callback function]],
		1--[[button initial status]])

	drawButtons("noConfirmation"--[[ButtonLable]], 
		thisPageName--[[page]],
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_noConfirmButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_noConfirmButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_noConfirmButton_deactivated.png")--[[sprite:deactivated]],
		.60--[[x coordinate]],
		.70--[[y coordinate]],
		"LT"--[[anchorPoint string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.20, .30, .044, 0.066, 0.22,"width" )--[[width]],
		smartScaling ("inverse", 0.20, .30, .044, 0.066, 0.22,"height" )--[[height]],
		"openDevMainMenu"--[[callback function]],
		1--[[button initial status]])
end

function deleteAllProjectData ()
	--delete data from love2d memory
	for i = #globApp.projects,1,-1 do
        table.remove(globApp.projects,i)
   end
   --ovewrite data file with empty table:
   saveNewProject ("savedProjectData.lua", globApp.projects, "globApp.projects")

   --returns to devMainMenu after deleting all project data:
   openDevMainMenu ()
end

function developerUnitTestPage ()

	local thisPageName = "UnitTesting"

	spreadSheet_draw (
		"devUnitTest", --[spreadsheet name]
		thisPageName, --[[page]]
		"static", --[[type]]
		devTests,--[[dataTable]]
		.5, --[[x position]]
		smartRelocation (.30,0,.27,.25,.24,.5,.21,1,"y"), --[[y position]]
		.8, --[[table width]]
		.6,--[[table height]]
		"CT", --[[anchor point]]
		nil, --[[bg sprite]]
		{ 	[1]={["INFO"]="openSelectedUTInfoCallback"},},--[[callback function]]
		smartFontScaling (0.025, 0.032),--[[font size]]
		{	[1] = "name", 
			[2]= "result", 
			[3] = "failingParameter"})



	drawButtons("returnDevMenu"--[[ButtonLable]], 
		thisPageName--[[page]], 
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_deactivated.png")--[[sprite:deactivated]],
		.035--[[x coordinate]],
		.043--[[y coordinate]],
		"LT"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"width" )--[[width]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"height" )--[[height]],
		"openDevMainMenu"--[[callback function]], 
		1--[[button initial status]])
end

local focusedUnitTest = "none"
function openSelectedUTInfoCallback (utID)

	focusedUnitTest = utID

	openUnitTestInfoPage ()
end

function openUnitTestInfoPage ()

	page_switch ("LodingUnitTestInfoPage", 20054, .5, false)
end

function unitTestInfoPage ()

	local thisPageName = "unitTestInfo"
	
	local selectedUnitTest = focusedUnitTest
	local utData = {}
	local resultString = ""

	if selectedUnitTest ~= "none" then
		for i, rcrd in ipairs (devTests) do
			if rcrd.ID == selectedUnitTest then
				utData = rcrd
				
				resultString = "[TEST NAME]: " .. rcrd.name
				resultString = resultString .. "\n[TEST ELAPSED TIME]: " .. rcrd.elapsedTime
				resultString = resultString .. "\n[TEST RESULT]: " .. rcrd.result

			end
		end
	end

	drawButtons("returnToUnitTestPage"--[[ButtonLable]], 
		thisPageName--[[page]], 
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_deactivated.png")--[[sprite:deactivated]],
		.035--[[x coordinate]],
		.043--[[y coordinate]],
		"LT"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"width" )--[[width]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"height" )--[[height]],
		"openUnitTestPage"--[[callback function]], 
		1--[[button initial status]])

	outputTxtBox_draw ("UnitTestInfo",--[[Label name]]
		thisPageName, --[[strg page]]
		"Sprites/invisibleBox.png", --[[image to be used as bg]]
		.5, --[[x percentage of screen]]
		.2, --[[y percentage of screen]]
		"CC", --[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]]
		smartScaling ("inverse", 0.80, 0.65, .144, 0.117, 0.18,"width"),--[[width]]
		smartScaling ("inverse", 0.80, 0.65, .144, 0.117, 0.18,"height"), --[[height]]
		{0,1,0,1},--[[rgba]]
		selectedUnitTest, --[[string of label display 1]]
		math.floor(smartFontScaling (0.03, 0.04))--[[font size]])


	outputTxtBox_draw ("testInfo",--[[Label name]]
		thisPageName, --[[strg page]]
		"Sprites/invisibleBox.png", --[[image to be used as bg]]
		.5, --[[x percentage of screen]]
		.6, --[[y percentage of screen]]
		"CC", --[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]]
		smartScaling ("inverse", .9, .8, .63, .56, 0.7,"width"),--[[width]]
		smartScaling ("inverse", .9, .8, .63, .56, 0.7,"height"), --[[height]]
		{1,1,1,1},--[[rgba]]
		resultString, --[[string of label display 1]]
		math.floor(smartFontScaling (0.02, 0.05))--[[font size]])


end

--------------------------------------------------------------------------------
					--CHANGE SCREEN SIZE FUNCTION
--------------------------------------------------------------------------------

local screenSimulators = {}

function createScreenSimulator (screenName, dpiWidht, dpiHeight, tblUnsafeScreen)
	screenSimultorData = createNewProjectData ({"name","dpiWidht","dpiHeight", "tblUnsafeScreen"}, {screenName, dpiWidht, dpiHeight, tblUnsafeScreen}, screenSimulators, "SML", 7)
	
	table.insert(screenSimulators, screenSimultorData)
end

--------------------------------------------------------------------------------
						--SCREEN OBJECTS CREATION
--------------------------------------------------------------------------------

function ScreenSimulatorsInit ()
	--VERTICAL
	createScreenSimulator ("iphone12_vertical", 320, 626, {0,0.07,1,0.86}) --xywh
	createScreenSimulator ("smsngS7Edge_vertical", 336, 640, {0,0,1,1})
	createScreenSimulator ("ipadAir2_vertical", 768, 1004, {0,0,1,1})

	--HORIZONTAL
	createScreenSimulator ("iphone12_Horizontal", 626, 320, {0.07, 0.0, .86,.90})
	createScreenSimulator ("smsngS7Edge_horizontal", 640, 336, {0,0,1,1})
	createScreenSimulator ("ipadAir2_horizontal", 1024, 748, {0,0,1,1})
end

function switchScreenSizePage ()

	local thisPageName = "switchScreenSize"

	spreadSheet_draw (
		"screenSizesTable", --[spreadsheet name]
		thisPageName, --[[page]]
		"static", --[[type]]
		screenSimulators,--[[dataTable]]
		.5, --[[x position]]
		smartRelocation (.30,0,.27,.25,.24,.5,.21,1,"y"), --[[y position]]
		.8, --[[table width]]
		.6,--[[table height]]
		"CT", --[[anchor point]]
		nil, --[[bg sprite]]
		{ 	[1]={["SELECT"]="changeScreenSize"},},--[[callback function]]
		smartFontScaling (0.025, 0.032),--[[font size]]
		{	[1]= "name", 
			[2]= "dpiWidht", 
			[3]= "dpiHeight"})


	drawButtons("returnScreenTestsMenu"--[[ButtonLable]], 
		thisPageName--[[page]],
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_deactivated.png")--[[sprite:deactivated]],
		.035--[[x coordinate]],
		.043--[[y coordinate]],
		"LT"--[[anchorPoint string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"width" )--[[width]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"height" )--[[height]],
		"openScreenTestsMenuPage"--[[callback function]],
		1--[[button initial status]])

end


function changeScreenSize (par1, par2, par3)
	local allowScreenResizeTimer = 0.4 --secs

	for i, screenSim in ipairs (screenSimulators) do
		if screenSim.ID == par1 then

			love.window.setMode(screenSim.dpiWidht, screenSim.dpiHeight)
			love.window.setPosition(0, 40)
			
			if screenSim.tblUnsafeScreen ~= nil then
				globApp.safeScreenArea = jpGUI_simulateWinUnsafeArea (screenSim.tblUnsafeScreen[1], screenSim.tblUnsafeScreen[2], screenSim.tblUnsafeScreen[3], screenSim.tblUnsafeScreen[4])
				globApp.isScreenSimulated = true
			end
		end
	end

	create_newTimeTrigger ("waitToLeaveChangeScreenSizePage", {safeLoadTimer + allowScreenResizeTimer}, {"leaveDeveloperGUI"})
end


function devAboutPage ()
	local thisPageName = "devAboutPage"

	drawButtons("returnScreenTestsMenu"--[[ButtonLable]], 
		thisPageName--[[page]],
		"pushonoff"--[[buttonType]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_pushed.png")--[[sprite: pushed]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_released.png")--[[sprite: released]],
		(devSpritesPath .. "jpLoveGUI_returnPrevPageButton_deactivated.png")--[[sprite:deactivated]],
		.035--[[x coordinate]],
		.043--[[y coordinate]],
		"LT"--[[anchorPoint string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"width" )--[[width]],
		smartScaling ("inverse", .07, .13, .07, .13, 1,"height" )--[[height]],
		"openDevMainMenu"--[[callback function]],
		1--[[button initial status]])

	--TXT OUTPUT BOX:
	outputTxtBox_draw ("AboutContents",--[[Label name]]
		thisPageName, --[[strg page]]
		"Sprites/invisibleBox.png", --[[image to be used as bg]]
		.5, --[[x percentage of screen]]
		.5, --[[y percentage of screen]]
		"CC", --[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]]
		smartScaling ("inverse", 1, 1, .8, .8, .8,"width"),--[[width]]
		smartScaling ("inverse", 1, 1, .8, .8, .8,"height"), --[[height]]
		{1,1,1,1},--[[rgba]]
		globApp.aboutPageContent, --text
		math.floor(smartFontScaling (0.04, 0.055))--[[font size]])

	

end 