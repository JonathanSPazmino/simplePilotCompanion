--Hardware Interface

local appFrames = {}

function appframe_create (id, spriteName, opacity)
	--creates object than needs to be deleted to save memory

	local newFrm = {}

		newFrm.id = id
		newFrm.x = globApp.safeScreenArea.x
		newFrm.y = globApp.safeScreenArea.y
		newFrm.spriteName = love.graphics.newImage(spriteName)
		newFrm.width = globApp.safeScreenArea.w/ newFrm.spriteName:getWidth()
		newFrm.height = globApp.safeScreenArea.h/ newFrm.spriteName:getHeight()
		newFrm.opacity = opacity

	table.insert(appFrames, newFrm)

	globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1

end


function appframe_update (id, opacity)

	for i, updFrm in ipairs (appFrames) do

		if updFrm.id == id then 

			updFrm.x = globApp.safeScreenArea.x
			updFrm.y = globApp.safeScreenArea.y
			updFrm.width = globApp.safeScreenArea.w / updFrm.spriteName:getWidth()
			updFrm.height = globApp.safeScreenArea.h / updFrm.spriteName:getHeight()
			updFrm.opacity = opacity

		end

	end

end


function appframe_remove (id)

	for i = #appFrames,1,-1 do

		local frm = appFrames[i]

		if frm.id == id then 

			table.remove(appFrames, i)

		end

	end

end



function appframe_draw (id, spriteName, opacity)

	--check if one and only one appFrame exists:
	local isOnlyOneFrame = false
	local doesframeExists = false

	if #appFrames == 1 then

		isOnlyOneFrame = true

		for i,frame in ipairs(appFrames) do

			if frame.id == id then
				
				doesframeExists = true
			
			end

		end

	end

	if isOnlyOneFrame == false then

		appframe_create (id, spriteName, opacity)

	elseif isOnlyOneFrame == true and globApp.resizeDetected == true then

		appframe_update (id, opacity)

	end

	if doesframeExists == true then 

		for i, af in ipairs(appFrames) do

			love.graphics.draw(af.spriteName, af.x, af.y, 0, af.width, af.height, ox, oy, kx, ky)

		end

	end

end