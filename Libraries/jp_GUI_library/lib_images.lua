--lib_images.lua 
--created by jonathan Pazmino

------------------------------------------------------------
			--OBJECT CREATION
------------------------------------------------------------
images = {}

function image_create (id, page, drawPosition, x, y, width, height, anchorPoint, opacity, rotation, ox, oy, sprite)

	local newImage = {}

	newImage.id = id
	newImage.page = page
	newImage.isVisible = true
	newImage.sprite = love.graphics.newImage(sprite)
	newImage.drawPosition = drawPosition
	newImage.initPosition = 0.5
	newImage.width = width
	newImage.height = height

	if ox ~= nil then
		newImage.ox = (ox * newImage.sprite:getWidth())
	else 
		newImage.ox = nil
	end

	if oy ~= nil then
		newImage.oy = (oy * newImage.sprite:getHeight())
	else 
		newImage.oy = nil
	end

	newImage.scaleFactorWidth = width/newImage.sprite:getWidth()
	newImage.scaleFactorHeight = height/newImage.sprite:getHeight()

	local myPositions = relativePosition (anchorPoint, x, y, width, height, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --do not move this line to other part.

	newImage.x = myPositions[1]
	newImage.y = myPositions[2]

	newImage.opacity = opacity
	newImage.rotation  = rotation



	table.insert(images, newImage)

	globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1

end

------------------------------------------------------------
			--OBJECT DELETE
------------------------------------------------------------

function image_delete (id, page)

	for i = #images, 1, -1 do

		local img = images[i]

		if img.page == page and img.id == id then

			table.remove(images, i)

			globApp.numObjectsDisplayed = globApp.numObjectsDisplayed - 1

		end

	end

end

------------------------------------------------------------
			--OBJECT UPDATE
------------------------------------------------------------

function image_update (id, page, drawPosition, x, y, width, height, anchorPoint, opacity, rotation, ox, oy, sprite)

	for i, img in ipairs (images) do

		if img.id == id then

			img.width = width
			img.height = height

			if ox ~= nil then
				img.ox = (ox * img.sprite:getWidth())
			else 
				img.ox = nil
			end

			if oy ~= nil then
				img.oy = (oy * img.sprite:getHeight())
			else 
				img.oy = nil
			end

			img.scaleFactorWidth = width/img.sprite:getWidth()
			img.scaleFactorHeight = height/img.sprite:getHeight()

			local myPositions = relativePosition (anchorPoint, x, y, width, height, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h) --do not move this line to other part.

			img.x = myPositions[1]
			img.y = myPositions[2]

			img.opacity = opacity
			img.rotation  = rotation

		end

	end

end


------------------------------------------------------------
			--OBJECT DRAW
------------------------------------------------------------

function image_draw (id, page, drawPosition, x, y, width, height, anchorPoint, opacity, rotation, ox, oy, sprite)

	---------------------OBJ ISOLATION-------------------------------

	local activePageName = ""

	for i, pgs in ipairs (pages) do

		if pgs.index == globApp.currentPageIndex then

			activePageName = pgs.name

		end

	end

	local imageExists = false

	for i,x in ipairs(images) do

		if x.id == id then
			
			imageExists = true
		
		end

	end

	------------------------------------------------------------------

	if activePageName == page then

		if imageExists == false then

			image_create (id, page, drawPosition, x, y, width, height, anchorPoint, opacity, rotation, ox, oy, sprite)

		elseif imageExists == true and globApp.resizeDetected == true then

			image_update (id, page, drawPosition, x, y, width, height, anchorPoint, opacity, rotation, ox, oy, sprite)

		end

		----------------------------drawing----------------------------------
			

		for i, img in ipairs (images) do 

			if img.id == id then

				love.graphics.draw(img.sprite, img.x, img.y, math.rad(img.rotation), img.scaleFactorWidth, img.scaleFactorHeight, img.ox, img.oy, kx, ky)

			end

		end
			
		--------------------------------------------------------------------

	elseif activePageName ~= page then

		if imageExists == true then

			image_delete (id, page)

		end

	end


end

------------------------------------------------------------
			--OBJECT FUNCTIONS
------------------------------------------------------------


function image_rotate (id, page)



end


function image_move ()


end



function image_hide ()



end



function image_show ()



end