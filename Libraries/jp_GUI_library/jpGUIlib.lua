-- jpGUIlib.lua
-- Created on 7/20/2021
-- Created by Jonathan Pazmino
-- Last Modified 7/20/2021

MAIN_GDSGUI_VERSION = "0.7.1"

local function requireGUILibraries ()

	--when calling files, no need for .lua externsions
	local pathToLibrary = "Libraries.jp_GUI_library."

	require (pathToLibrary .. "lib_general") --[[general functions]]
	require (pathToLibrary .. "lib_pages") --[[handles all app pages]]
	require (pathToLibrary .. "lib_buttons") --[[contains buttons related code]]
	require (pathToLibrary .. "lib_drawGrid") --[[handles draw grids for scrollable sprites]]
	require (pathToLibrary .. "lib_inputTxtBox") --[[contains text box related code]]
	require (pathToLibrary .. "lib_outputTxtBox") --[[contains labels related code]]
	require (pathToLibrary .. "lib_saveLoad") --[[save and load data code]]
	require (pathToLibrary .. "lib_scrollBar")--[[scrollbars]]
	require (pathToLibrary .. "lib_table") --[[data display tables]]
	require (pathToLibrary .. "lib_timeControl") --[[time triggers callbacks]]
	require (pathToLibrary .. "lib_appFrame")--[[app frame]]
	require (pathToLibrary .. "lib_images")--[[images]]
	require (pathToLibrary .. "lib_devSettings")--[[developement and settings]]
	require (pathToLibrary .. "lib_unitTests")--[[developement and settings]]

end

function generateConsoleMessage (mode, text)
	if (mode == "info" or mode == "error") and (text ~= "" and text ~= nil) then
		local msg1 = "GDS_GUI_v" .. MAIN_GDSGUI_VERSION .. " | "
		local msg2 = ""
		if mode == "info" then
			msg2 = "Info |  "
		elseif mode == "error" then
			msg2 = "Error | "
		end
		local msg3 = text
		print (msg1 .. msg2 .. msg3)
	else 
		print ("gdsGUI| CALLBACK ERROR| generateOutputMessage callback is missing parameters")
	end
end

generateConsoleMessage ("info", "GDS_LOVE2D_GUI initilized")

requireGUILibraries ()

gdsGUI_executeAllUnitTests ("Blank")