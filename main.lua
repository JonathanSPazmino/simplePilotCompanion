--[[Main.lua
	Author: Jonathan Pazmino
	]]
	

io.stdout:setvbuf("no")

----------------------------------------------------------------------------
		  	 			--LIBRARIES LOAD
----------------------------------------------------------------------------
	require ("Libraries.jp_GUI_library.jpGUIlib")

	page_create (3, "MainMenu", false, false, globApp.appColor, 12, 0, {.5,1,.6,.6,"LT"}, "max")



----------------------------------------------------------------------------
		  	 --CORE FUNCTIONS BELOW THIS LINE (CALLBACKS)
----------------------------------------------------------------------------

local utc = {}
local TopRightTimer = 0
	-- returns a table with UTC date & time
   -- print(string.format("UTC: %04d-%02d-%02d %02d:%02d:%02d",
   --     utc.year, utc.month, utc.day, utc.hour, utc.min, utc.sec))
local utcPrintString = ""

function love.load ()

	page_switch ("IntialBooting", 3, 2, false)

end


function love.update (dt)
	utc = os.date("!*t")
	utcPrintString = string.format(
    "UTC:" .. "\n" .. "%04d-%02d-%02d" .. "\n" .. "%02d:%02d:%02d",
    utc.year, utc.month, utc.day, utc.hour, utc.min, utc.sec
)
	jpGUI_update (dt)

end


function love.draw ()
	drawPages ()

	jpGUI_draw ()
end

---------------------------------------------------------------------
				--GENERAL FUNCTIONS BELOW THIS LINE
---------------------------------------------------------------------

function drawPages ()
	--pageBackGround_draw must be added on top in order to change bg color
	pageBackground_draw ()
	--------------------------------------------------------------------
	mainMenuDisplay ()


end

function OpenMainMenuPage (position)

	page_switch ("LoadingMainMenu", 3, 1, false)

end



function mainMenuDisplay()

	local thisPageName = "MainMenu"

	--BUTONS:
	-- local thisPageButtons = {}
	-- 	thisPageButtons[1] = "newTrip"
	-- 	thisPageButtons[2] = "loadTrip"
	-- 	thisPageButtons[3] = "Learn"
	-- 	thisPageButtons[4] = "Settings"
	-- 	thisPageButtons[5] = "About"

	-- drawButtons(thisPageButtons[1]--[[ButtonLable]], 
	-- 	"MainMenu"--[[page]], 
	-- 	"pushonoff"--[[buttonType]],
	-- 	"Sprites/newTripButton_pushed.png"--[[sprite: released]],
	-- 	"Sprites/newTripButton_Released.png"--[[sprite: pressed]],
	-- 	"Sprites/newTripButton_deactivated.png"--[[sprite:deactivated]],
	-- 	.5--[[x coordinate]],
	-- 	.18--[[y coordinate]],
	-- 	"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
	-- 	"OpenNewProjectPage"--[[callback function]],
	-- 	1--[[button initial status]])

	-- if globApp.projectAvailable == false then
	-- 	deactiveButton (thisPageButtons[2])
	-- end
	-- drawButtons(thisPageButtons[2]--[[ButtonLable]], 
	-- 	"MainMenu"--[[page]], 
	-- 	"pushonoff"--[[buttonType]],
	-- 	"Sprites/loadTripButton_pushed.png"--[[sprite: pressed]],
	-- 	"Sprites/loadTripButton_released.png"--[[sprite: released]],
	-- 	"Sprites/loadTripButton_deactivated.png"--[[sprite:deactivated]],
	-- 	.5--[[x coordinate]],
	-- 	.34--[[y coordinate]],
	-- 	"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
	-- 	"OpenLoadProjectPage"--[[callback function]],
	-- 	1--[[button initial status]])


	-- drawButtons(thisPageButtons[3]--[[ButtonLable]], 
	-- 	"MainMenu"--[[page]], 
	-- 	"pushonoff"--[[buttonType]],
	-- 	"Sprites/learnButton_selected.png"--[[sprite: pressed]],
	-- 	"Sprites/learnButton_deselected.png"--[[sprite: released]],
	-- 	"Sprites/learnButton_deactivated.png"--[[sprite:deactivated]],
	-- 	.5--[[x coordinate]],
	-- 	.50--[[y coordinate]],
	-- 	"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
	-- 	"OpenLearnPage"--[[callback function]],
	-- 	1--[[button initial status]])


	-- drawButtons(thisPageButtons[4]--[[ButtonLable]], 
	-- 	"MainMenu"--[[page]], 
	-- 	"pushonoff"--[[buttonType]],
	-- 	"Sprites/SettingsButtonPushed.png"--[[sprite: pressed]],
	-- 	"Sprites/SettingsButtonReleased.png"--[[sprite: released]],
	-- 	"Sprites/SettingsButton_deactivated.png"--[[sprite:deactivated]],
	-- 	.5--[[x coordinate]],
	-- 	.66--[[y coordinate]],
	-- 	"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
	-- 	"OpenSettingsPage"--[[callback function]],
	-- 	1--[[button initial status]])


	-- drawButtons(thisPageButtons[5]--[[ButtonLable]], 
	-- 	"MainMenu"--[[page]], 
	-- 	"pushonoff"--[[buttonType]],
	-- 	"Sprites/aboutButton_selected.png"--[[sprite: pressed]],
	-- 	"Sprites/aboutButton_deselected.png"--[[sprite: released]],
	-- 	"Sprites/aboutButton_deactivated.png"--[[sprite:deactivated]],
	-- 	.5--[[x coordinate]],
	-- 	.82--[[y coordinate]],
	-- 	"CC"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"width" )--[[width]],
	-- 	smartScaling ("inverse", 0.36, .54, .080, 0.12, 0.22,"height" )--[[height]],
	-- 	"OpenAboutPage"--[[callback function]],
	-- 	1--[[button initial status]])


	------------------------------------------------------------------------
								--TEXT BOXES
	------------------------------------------------------------------------

	local UTCString = utcPrintString
	outputTxtBox_draw ("title",--[[Label name]]
		thisPageName, --[[strg page]]
		"Sprites/invisibleBox.png", --[[image to be used as bg]]
		.05, --[[x percentage of screen]]
		.05, --[[y percentage of screen]]
		"LT", --[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]]
		smartScaling ("inverse", 0.2, 0.4, .12, .24, 0.6,"width"),--[[width]]
		smartScaling ("inverse", 0.2, 0.4, .12, .24, 0.6,"height"), --[[height]]
		{1,1,1,1},--[[rgba]]
		UTCString, --[[string of label display 1]]
		math.floor(smartFontScaling (0.03, 0.05))--[[font size]])

end


