--lib_drawGrid.lua
--Created by Jonathan Pazmino
--on 6/26/2022

drawGrid = {}

function drawGrid:new ( id, xPerc, yPerc, widthPerc, heightPerc, initZoom, mode )
	local newGrid = {}
			newGrid.zoom = initZoom
			newGrid.outterRectangle = {}
				newGrid.outterRectangle.x = xPerc * globApp.safeScreenArea.w
				newGrid.outterRectangle.y = yPerc * globApp.safeScreenArea.h
				newGrid.outterRectangle.width = widthPerc * globApp.safeScreenArea.w
				newGrid.outterRectangle.height = heightPerc * globApp.safeScreenArea.h
			newGrid.innerRectangle = {}
				newGrid.innerRectangle.x = newGrid.outterRectangle.x
				newGrid.innerRectangle.y = newGrid.outterRectangle.y
				newGrid.innerRectangle.width = newGrid.outterRectangle.width * newGrid.zoom
				newGrid.innerRectangle.height = newGrid.outterRectangle.height * initZoom
			newGrid.gridSections = 20
			newGrid.horizontalLines = {}
				for i=1, newGrid.gridSections - 1, 1 do
					newGrid.horizontalLines[i] = {}
					newGrid.horizontalLines[i].x1 = newGrid.innerRectangle.x
					newGrid.horizontalLines[i].y1 = newGrid.innerRectangle.y + (i * (newGrid.innerRectangle.height / newGrid.gridSections))
					newGrid.horizontalLines[i].x2 = newGrid.horizontalLines[i].x1 + newGrid.innerRectangle.width
					newGrid.horizontalLines[i].y2 = newGrid.horizontalLines[i].y1
				end
			newGrid.verticalLines = {}
				for i=1, newGrid.gridSections - 1, 1 do
					newGrid.verticalLines[i] = {}
					newGrid.verticalLines[i].x1 =    newGrid.innerRectangle.x + (i * (newGrid.innerRectangle.width / newGrid.gridSections))
					newGrid.verticalLines[i].y1 = newGrid.innerRectangle.y 
					newGrid.verticalLines[i].x2 = newGrid.verticalLines[i].x1
					newGrid.verticalLines[i].y2 = newGrid.verticalLines[i].y1 + newGrid.innerRectangle.height
				end

		newGrid.initZoom = initZoom
		newGrid.color = color
		newGrid.mode = mode

	setmetatable(newGrid, self)
    self.__index = self
    return newGrid
end

function drawGrid:draw ( id )
	if self.mode == "edit" then
		love.graphics.setColor(0,1,0) -- Red color
	elseif self.mode == "display" then
		love.graphics.setColor(1,1,1)
	end
    love.graphics.rectangle("line", self.outterRectangle.x, self.outterRectangle.y, self.outterRectangle.width, self.outterRectangle.height)
    love.graphics.rectangle("line", self.innerRectangle.x, self.innerRectangle.y, self.innerRectangle.width, self.innerRectangle.height)

    for i, n in ipairs (self.horizontalLines) do
    	love.graphics.line( n.x1, n.y1, n.x2, n.y2)
    end
    for i, n in ipairs (self.verticalLines) do
    	love.graphics.line( n.x1, n.y1, n.x2, n.y2)
    end
end