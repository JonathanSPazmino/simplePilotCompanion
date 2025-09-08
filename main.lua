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
  mode = "COUNT UP",   -- "COUNT UP" or "COUNT DOWN"
  duration = 90,      -- only used in COUNT DOWN mode (seconds)
  t = 0,              -- current time (seconds)
  running = true
}

local font

local function format_time(s)
  if s < 0 then s = 0 end
  local minutes = math.floor(s / 60)
  local seconds = math.floor(s % 60)
  return string.format("%02d:%02d", minutes, seconds)
end


local visRhTimerInputBox = false




function love.load ()

	page_switch ("IntialBooting", 3, 2, false)

	font = love.graphics.newFont(20)
	love.graphics.setFont(font)

	-- initialize starting time based on mode
	if timer.mode == "COUNT DOWN" then
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

	if timer.mode == "COUNT UP" then
	  timer.t = timer.t + dt
	else -- COUNT DOWN
	  timer.t = timer.t - dt
	  if timer.t <= 0 then
	    timer.t = 0
	    timer.running = false
	    -- do something when COUNT DOWN finishes:
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

	local fontSize = 12

	local thisPageName = "MainMenu"

	--BUTONS:
	local thisPageButtons = {}
		thisPageButtons[1] = "resetRHTopTimer"
		thisPageButtons[2] = "pauseRHTopTimer"
		thisPageButtons[3] = "modeSelectRHTopTimer"
		thisPageButtons[4] = "incrsMinRHTopTimer"
		thisPageButtons[5] = "dcrsMinRHTopTimer"

	drawButtons(thisPageButtons[1]--[[ButtonLable]], 
		"MainMenu"--[[page]], 
		"pushonoff"--[[buttonType]],
		"Sprites/newTripButton_pushed.png"--[[sprite: released]],
		"Sprites/newTripButton_Released.png"--[[sprite: pressed]],
		"Sprites/newTripButton_deactivated.png"--[[sprite:deactivated]],
		.95, --[[x position]]
		.3, --[[y position]]
		"RT"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"width" )--[[width]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"height" )--[[height]],
		"resetRHTopTimer"--[[callback function]],
		1--[[button initial status]])


	drawButtons(thisPageButtons[2]--[[ButtonLable]], 
		"MainMenu"--[[page]], 
		"pushonoff"--[[buttonType]],
		"Sprites/newTripButton_pushed.png"--[[sprite: released]],
		"Sprites/newTripButton_Released.png"--[[sprite: pressed]],
		"Sprites/newTripButton_deactivated.png"--[[sprite:deactivated]],
		.725, --[[x position]]
		.3, --[[y position]]
		"LT"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"width" )--[[width]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"height" )--[[height]],
		"pauseRHTopTimer"--[[callback function]],
		1--[[button initial status]])

	drawButtons(thisPageButtons[3]--[[ButtonLable]], 
		"MainMenu"--[[page]], 
		"pushonoff"--[[buttonType]],
		"Sprites/newTripButton_pushed.png"--[[sprite: released]],
		"Sprites/newTripButton_Released.png"--[[sprite: pressed]],
		"Sprites/newTripButton_deactivated.png"--[[sprite:deactivated]],
		.55, --[[x position]]
		.3, --[[y position]]
		"LT"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"width" )--[[width]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"height" )--[[height]],
		"modeSelectRHTopTimer"--[[callback function]],
		1--[[button initial status]])


	drawButtons(thisPageButtons[4]--[[ButtonLable]], 
		"MainMenu"--[[page]], 
		"pushonoff"--[[buttonType]],
		"Sprites/newTripButton_pushed.png"--[[sprite: released]],
		"Sprites/newTripButton_Released.png"--[[sprite: pressed]],
		"Sprites/newTripButton_deactivated.png"--[[sprite:deactivated]],
		.5, --[[x position]]
		.05, --[[y position]]
		"LT"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"width" )--[[width]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"height" )--[[height]],
		"incrsMinRHTopTimer"--[[callback function]],
		0--[[button initial status]])

	drawButtons(thisPageButtons[5]--[[ButtonLable]], 
		"MainMenu"--[[page]], 
		"pushonoff"--[[buttonType]],
		"Sprites/newTripButton_pushed.png"--[[sprite: released]],
		"Sprites/newTripButton_Released.png"--[[sprite: pressed]],
		"Sprites/newTripButton_deactivated.png"--[[sprite:deactivated]],
		.5, --[[x position]]
		.15, --[[y position]]
		"LT"--[[anchorPoint -- string= LT,LC,LB,CT,CC,CB,RT,RC,RB]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"width" )--[[width]],
		smartScaling ("inverse", 0.08, .08, .08, 0.08, 1,"height" )--[[height]],
		"dcrsMinRHTopTimer"--[[callback function]],
		0--[[button initial status]])



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
		globApp.safeScreenArea.w * .4,--[[width]]
		globApp.safeScreenArea.h * .2, --[[height]]
		{1,1,1,1},--[[rgba]]
		UTCString, --[[string of label display 1]]
		fontSize--[[font size]])


	--TIMER TOP RIGHT CORNER
	  -- timer text
	  local text = timer.mode .. "\n" .. " TIMER:" .. "\n" .. "M  " .. format_time(timer.t) .. "  S"

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
		globApp.safeScreenArea.w * .4,--[[width]]
		globApp.safeScreenArea.h * .2, --[[height]]
	  	{1,1,1,1},--[[rgba]]
	  	text, --[[string of label display 1]]
	  	fontSize--[[font size]])


end



function resetRHTopTimer ()
	if timer.mode == "COUNT UP" then
		timer.t = 0
	else
	timer.t = timer.duration
	end
		timer.running = true
end


function pauseRHTopTimer ()
	timer.running = not timer.running
end


function modeSelectRHTopTimer ()
	-- toggle modes and re-init time
	timer.mode = (timer.mode == "COUNT UP") and "COUNT DOWN" or "COUNT UP"
	if timer.mode == "COUNT DOWN" then
		activateButton ("incrsMinRHTopTimer")
		activateButton ("dcrsMinRHTopTimer")
	  timer.t = timer.duration
	else
		deactiveButton ("incrsMinRHTopTimer")
		deactiveButton ("dcrsMinRHTopTimer")
	  timer.t = 0
	end
	timer.running = true
end

