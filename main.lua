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

local timer = {
  mode = "countup",   -- "countup" or "countdown"
  duration = 90,      -- only used in countdown mode (seconds)
  t = 0,              -- current time (seconds)
  running = true
}

local font

local function format_time(s)
  if s < 0 then s = 0 end
  local minutes = math.floor(s / 60)
  local seconds = math.floor(s % 60)
  local ms = math.floor((s - math.floor(s)) * 100)
  return string.format("%02d:%02d.%02d", minutes, seconds, ms)
end

function love.load ()

	page_switch ("IntialBooting", 3, 2, false)

	font = love.graphics.newFont(20)
	love.graphics.setFont(font)

	-- initialize starting time based on mode
	if timer.mode == "countdown" then
	  timer.t = timer.duration
	else
	  timer.t = 0
	end

end


function love.update (dt)
	utc = os.date("!*t")
	utcPrintString = string.format(
    "UTC:" .. "\n" .. "%04d-%02d-%02d" .. "\n" .. "%02d:%02d:%02d",
    utc.year, utc.month, utc.day, utc.hour, utc.min, utc.sec
)
	jpGUI_update (dt)

	--topright timer
	if not timer.running then return end

	if timer.mode == "countup" then
	  timer.t = timer.t + dt
	else -- countdown
	  timer.t = timer.t - dt
	  if timer.t <= 0 then
	    timer.t = 0
	    timer.running = false
	    -- do something when countdown finishes:
	    -- e.g., play a sound, change state, etc.
	  end
	end

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


	---UTC TOP LEFT
	local UTCString = utcPrintString
	outputTxtBox_draw ("utcData",--[[Label name]]
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


	--TIMER TOP RIGHT CORNER
	  -- timer text
	  local text = format_time(timer.t)

	  -- small help text
	  -- love.graphics.setNewFont(14)
	  -- love.graphics.print(
	  --   string.format("Mode: %s  |  Space: Pause/Resume  R: Reset  C: Toggle Mode", timer.mode),
	  --   10, h - 28
	  -- )
	  -- love.graphics.setFont(font)

	  outputTxtBox_draw ("timerTopRight",--[[Label name]]
	  	thisPageName, --[[strg page]]
	  	"Sprites/invisibleBox.png", --[[image to be used as bg]]
	  	.95, --[[x percentage of screen]]
	  	.05, --[[y percentage of screen]]
	  	"RT", --[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]]
	  	smartScaling ("inverse", 0.2, 0.4, .12, .24, 0.6,"width"),--[[width]]
	  	smartScaling ("inverse", 0.2, 0.4, .12, .24, 0.6,"height"), --[[height]]
	  	{1,1,1,1},--[[rgba]]
	  	text, --[[string of label display 1]]
	  	math.floor(smartFontScaling (0.03, 0.05))--[[font size]])


end


function love.keypressed(key)
  if key == "space" then
    timer.running = not timer.running
  elseif key == "r" then
    if timer.mode == "countup" then
      timer.t = 0
    else
      timer.t = timer.duration
    end
    timer.running = true
  elseif key == "c" then
    -- toggle modes and re-init time
    timer.mode = (timer.mode == "countup") and "countdown" or "countup"
    if timer.mode == "countdown" then
      timer.t = timer.duration
    else
      timer.t = 0
    end
    timer.running = true
  end
end