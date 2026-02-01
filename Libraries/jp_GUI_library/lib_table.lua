--[[tables.lua]]

-- spreadSheets = {}
globApp.objects.tables = {}
local recordErased = false

------------------------------------------------------------
			--OBJECT CREATION
------------------------------------------------------------
function gui_table_create (spreadSheetName, strgPage, strgspreadSheetType, dataTable, myX, myY, tableWidth, tableHeight, anchorPoint, strgImgspreadSheetBg, tblCallbackFuncs, fontSize, headerTitles)

	local t = {}

	t.name = spreadSheetName
	t.page = strgPage
	t.objectType = "table"
	t.type = strgspreadSheetType
	t.rowsCount = determineSizeOfArray (dataTable, "rows")
	t.collumnsCount = #headerTitles

	-- Store original properties for resize
	t.original = {
		x = myX,
		y = myY,
		width = tableWidth,
		height = tableHeight,
		aspectRatio = (tableHeight * globApp.safeScreenArea.h) / (tableWidth * globApp.safeScreenArea.w),
		anchorPoint = anchorPoint,
		fontSize = fontSize,
		headerTitles = headerTitles,
		tblCallbackFuncs = tblCallbackFuncs,
		dataTable = dataTable
	}

	t.fonts = {
		title = { size = 12, font = love.graphics.newFont(12) },
		headers = { size = 12, font = love.graphics.newFont(12) },
		cells = { size = 12, font = love.graphics.newFont(12) }
	}

	if strgImgspreadSheetBg ~= nil then
		t.imgSpreadSheetBg = love.graphics.newImage(strgImgspreadSheetBg)
	end

	-- Initialize all sub-tables
	t.frame, t.masks, t.titleBox, t.titleCaption, t.headersBox, t.scrollBox, t.buttons, t.cells, t.verticalScrollBar, t.horizontalScrollBar = {},{},{},{},{},{},{},{},{},{}

	-- This internal function calculates all geometry. It's called on creation and again on resize.
	local function calculate_geometry_and_layout(tbl)
		local original = tbl.original
		
		-- Recalculate frame
		local newDims = gui_getObjectScaledDimensions(original.width, original.height, original.aspectRatio)
		tbl.frame.width = newDims.width
		tbl.frame.height = newDims.height
		local framePositions = relativePosition(original.anchorPoint, original.x, original.y, tbl.frame.width, tbl.frame.height, globApp.safeScreenArea.x, globApp.safeScreenArea.y, globApp.safeScreenArea.w, globApp.safeScreenArea.h)
		tbl.frame.x = framePositions[1]
		tbl.frame.y = framePositions[2]

		-- ADDED: Recalculate masks
		tbl.masks = {}
		tbl.masks.properties = {}
		tbl.masks.properties.color = globApp.appColor
		tbl.masks.top = {
			x = globApp.safeScreenArea.x,
			y = globApp.safeScreenArea.y,
			width = globApp.safeScreenArea.w,
			height = tbl.frame.y - globApp.safeScreenArea.y
		}
		tbl.masks.left = {
			x = globApp.safeScreenArea.x,
			y = globApp.safeScreenArea.y + tbl.masks.top.height,
			width = tbl.frame.x - globApp.safeScreenArea.x,
			height = tbl.frame.height
		}
		tbl.masks.right = {
			x = tbl.frame.x + tbl.frame.width,
			y = globApp.safeScreenArea.y + tbl.masks.top.height,
			width = (globApp.safeScreenArea.x + globApp.safeScreenArea.w) - (tbl.frame.x + tbl.frame.width),
			height = tbl.frame.height
		}
		tbl.masks.bottom = {
			x = globApp.safeScreenArea.x,
			y = tbl.frame.y + tbl.frame.height,
			width = globApp.safeScreenArea.w,
			height = (globApp.safeScreenArea.y + globApp.safeScreenArea.h) - (tbl.frame.y + tbl.frame.height)
		}

		-- Other base properties
		tbl.rowHeight = tbl.fonts.cells.size + (tbl.fonts.cells.size * .4)
		tbl.displayWidth = tbl.frame.width
		tbl.displayHeight = original.height * globApp.safeScreenArea.h

		-- Recalculate Buttons
        tbl.buttons = {}
		local iterator1 = 0
		for i=1, #original.tblCallbackFuncs, 1 do
			local index = ""
			for j, cb in pairs(original.tblCallbackFuncs[i]) do 
				index = j
				iterator1 = iterator1 + 1
				tbl.buttons[index] = {
					text = index,
					x = tbl.frame.x + (iterator1 * (tbl.displayWidth / #original.tblCallbackFuncs)) - (tbl.displayWidth / #original.tblCallbackFuncs),
					y = tbl.frame.y + tbl.displayHeight - tbl.rowHeight,
					width = tbl.displayWidth / #original.tblCallbackFuncs,
					height = tbl.rowHeight,
					isFocused = false
				}
			end
		end

		-- Recalculate Boxes
		tbl.titleBox = { x = tbl.frame.x, y = tbl.frame.y, width = tbl.frame.width, height = tbl.fonts.title.size * 1.3 }
		tbl.titleCaption = { x = tbl.titleBox.x + (tbl.titleBox.width * .1), y = tbl.titleBox.y + (tbl.titleBox.height * .1), wrapWidth = tbl.titleBox.width * 0.8}
		tbl.headersBox = { x = tbl.titleBox.x, y = tbl.titleBox.y + tbl.titleBox.height, w = tbl.titleBox.width, h = 0 }

		-- Recalculate column width
		tbl.minCollumnWidth = tbl.fonts.cells.size * 10
		tbl.maxCollumnWidth = tbl.frame.width - tbl.fonts.cells.size
		if tbl.collumnsCount == 1 then
			tbl.collumWidth = tbl.frame.width - tbl.fonts.cells.size
		else
			tbl.collumWidth = ((tbl.frame.width - tbl.fonts.cells.size) / tbl.collumnsCount)
			if tbl.collumWidth < tbl.minCollumnWidth then tbl.collumWidth = tbl.minCollumnWidth end
		end
		tbl.textWrapCellPercentWidth = tbl.collumWidth * 0.8
		
		-- On resize, we must recalculate cell positions. Recreating them is the safest way to implement this now.
		tbl.cells = {}
		local headerData = original.headerTitles
		local dataTable = original.dataTable
		local allTblHeaders = {}
		for i=1, #dataTable, 1 do allTblHeaders[i] = dataTable[i]["ID"] end
		
		local maxOverallTextLineCount = 1
		local actualCellFontHeight = returnFontInfo(tbl.fonts.cells.font, "height")
		maxOverallTextLineCount = math.max(maxOverallTextLineCount, findMaxNumOfLinesNeeded(tbl.fonts.headers.font, tbl.textWrapCellPercentWidth, headerData))
		for i = 1, tbl.rowsCount, 1 do
			local textTable = {}
			for z=1, #headerData, 1 do textTable[z] = table_lookUp(dataTable, i, headerData[z]) end
			maxOverallTextLineCount = math.max(maxOverallTextLineCount, findMaxNumOfLinesNeeded(tbl.fonts.cells.font, tbl.textWrapCellPercentWidth, textTable))
		end
		tbl.uniformCellHeight = (actualCellFontHeight * maxOverallTextLineCount) * (1 + 0.30)
		tbl.headersBox.h = tbl.uniformCellHeight
		
		local cellPositions = {w = tbl.collumWidth}
		local previewsRowY, previewsRowH = tbl.headersBox.y, tbl.headersBox.h
		tbl.combinedRowsHeight = 0
		for i = 1, tbl.rowsCount + 1, 1 do
			for j = 1, #headerData , 1 do
				cellPositions.x = tbl.frame.x - tbl.collumWidth + (tbl.collumWidth * j)
				if i == 1 then
					cellPositions.y, cellPositions.h = tbl.headersBox.y, tbl.headersBox.h
					TableCell_create((i..","..j), cellPositions.x, cellPositions.y, cellPositions.w, cellPositions.h, i, j, headerData[j], false, tbl.cells, "HEADER")
				else
					if j == 1 then
						cellPositions.y = (previewsRowY + previewsRowH)
						cellPositions.h = tbl.uniformCellHeight
						previewsRowY, previewsRowH = cellPositions.y, cellPositions.h
						tbl.combinedRowsHeight = tbl.combinedRowsHeight + cellPositions.h
					end
					TableCell_create((i..","..j), cellPositions.x, cellPositions.y, cellPositions.w, cellPositions.h, i, j, table_lookUp(dataTable, i-1, headerData[j]), true, tbl.cells, allTblHeaders[i-1])
				end
			end
		end

		-- Recalculate ScrollBox (depends on final header height)
		tbl.scrollBox = {
			x = tbl.frame.x,
			y = tbl.frame.y + tbl.titleBox.height + tbl.headersBox.h,
			width = tbl.frame.width - tbl.fonts.cells.size,
			height = (tbl.displayHeight - ( (tbl.frame.y + tbl.titleBox.height + tbl.headersBox.h) - tbl.frame.y)) - (tbl.rowHeight * 2)
		}

		-- Recalculate scrollbar definitions
		tbl.scrollableYequivPercent = (globApp.safeScreenArea.y + tbl.scrollBox.y) / globApp.safeScreenArea.h
		tbl.y_difBetweenSafeAndTotalArea = globApp.safeScreenArea.y / globApp.safeScreenArea.h
		
		tbl.verticalScrollBar = {
			name = tbl.name .. "_vsb",
			x = ((tbl.frame.x + tbl.frame.width) - (tbl.fonts.cells.size)) / globApp.safeScreenArea.w,
			y = tbl.scrollableYequivPercent - tbl.y_difBetweenSafeAndTotalArea,
			width = tbl.fonts.cells.size / globApp.safeScreenArea.w,
			height = tbl.scrollBox.height / globApp.safeScreenArea.h
		}
		tbl.horizontalScrollBar = {
			name = tbl.name .. "_hsb",
			x = tbl.frame.x / globApp.safeScreenArea.w,
			y = (tbl.scrollBox.y + tbl.scrollBox.height) / globApp.safeScreenArea.h,
			width = tbl.scrollBox.width / globApp.safeScreenArea.w,
			height = tbl.rowHeight / globApp.safeScreenArea.h
		}

		if tbl.rowsCount > 0 then tbl.avrgRowHeight = tbl.combinedRowsHeight / tbl.rowsCount else tbl.avrgRowHeight = 1 end
		tbl.numRowsPerDisplay = tbl.scrollBox.height / tbl.avrgRowHeight
		tbl.combinedCollumnsWidth = tbl.collumnsCount * tbl.collumWidth
		if tbl.collumnsCount > 0 then tbl.avrgCollumnsWidht = tbl.collumWidth else tbl.avrgCollumnsWidht = 1 end
		tbl.numCollumnsPerDisplay = tbl.scrollBox.width / tbl.collumWidth
	end

	-- NEW: The resize method for this object
    function t:resize()
        calculate_geometry_and_layout(self)
        
        -- Find and update child scrollbar objects
        for _, sb in ipairs(globApp.objects.scrollBars) do
            if sb.id == self.verticalScrollBar.name then
				sb.original.x, sb.original.y, sb.original.width, sb.original.height = self.verticalScrollBar.x, self.verticalScrollBar.y, self.verticalScrollBar.width, self.verticalScrollBar.height
				if sb.resize then sb:resize() end
            elseif sb.id == self.horizontalScrollBar.name then
                sb.original.x, sb.original.y, sb.original.width, sb.original.height = self.horizontalScrollBar.x, self.horizontalScrollBar.y, self.horizontalScrollBar.width, self.horizontalScrollBar.height
				if sb.resize then sb:resize() end
            end
        end
    end
    t.resize = t.resize

	-- Run initial calculations
	calculate_geometry_and_layout(t)

	t.dataCurrentVertPosition, t.dataCurrentHorzPosition, t.state = 0.0, 0.0, 1

	table.insert(globApp.objects.tables, t)
	globApp.numObjectsDisplayed = globApp.numObjectsDisplayed + 1

	-- Create the scrollbar objects
	gui_scrollBar_create (t.verticalScrollBar.name, t.page, t.verticalScrollBar.x, t.verticalScrollBar.y, t.verticalScrollBar.width, t.verticalScrollBar.height, "LT", t.numRowsPerDisplay, t.rowsCount, t.dataCurrentVertPosition, "table-linked", "vertical", 30, "spreadSheetScrollbarVertCallback")
	gui_scrollBar_create (t.horizontalScrollBar.name, t.page, t.horizontalScrollBar.x, t.horizontalScrollBar.y, t.horizontalScrollBar.width, t.horizontalScrollBar.height, "LT", t.numCollumnsPerDisplay, t.collumnsCount, t.dataCurrentHorzPosition, "table-linked", "horizontal", 30, "speadSheetScrollbarHorzCallback")
end

------------------------------------------------------------
			--OBJECT UPDATE
------------------------------------------------------------
function gui_table_update (spreadSheetName, strgPage, strgspreadSheetType, dataTable, myX, myY, tableWidth, tableHeight, anchorPoint, strgImgspreadSheetBg, tblCallbackFuncs, fontSize, headerTitles)

	for i, t in ipairs(globApp.objects.tables) do 

		if t.name == spreadSheetName then

			t.rowsCount = determineSizeOfArray (dataTable, "rows")
			t.collumnsCount = #headerTitles

			t.frame.width = (tableWidth * globApp.safeScreenArea.w)
			t.frame.height = (tableHeight * globApp.safeScreenArea.h)
			local framePositions = 
				relativePosition(anchorPoint, 
								myX, 
								myY, 
								t.frame.width, 
								t.frame.height, 
								globApp.safeScreenArea.x,
								globApp.safeScreenArea.y, 
								globApp.safeScreenArea.w, 
								globApp.safeScreenArea.h)
			t.frame.x = framePositions[1]
			t.frame.y = framePositions[2]

			t.masks = {}
				t.masks.properties = {}
					t.masks.properties.color = globApp.appColor --{rgbt}
				t.masks.top = {}
					t.masks.top.x = globApp.safeScreenArea.x
					t.masks.top.y = globApp.safeScreenArea.y
					t.masks.top.width = globApp.safeScreenArea.w
					t.masks.top.height = t.frame.y - t.masks.top.y
				t.masks.left = {}
					t.masks.left.x = globApp.safeScreenArea.x
					t.masks.left.y = globApp.safeScreenArea.y + t.masks.top.height
					t.masks.left.width = t.frame.x - globApp.safeScreenArea.x
					t.masks.left.height = t.frame.height
				t.masks.right = {}
					t.masks.right.x = t.frame.x + t.frame.width
					t.masks.right.y = globApp.safeScreenArea.y + t.masks.top.height
					t.masks.right.width = (globApp.safeScreenArea.x + globApp.safeScreenArea.w) - t.masks.right.x
					t.masks.right.height = t.frame.height
				t.masks.bottom = {}
					t.masks.bottom.x = globApp.safeScreenArea.x
					t.masks.bottom.y = t.frame.y + t.frame.height
					t.masks.bottom.width = globApp.safeScreenArea.w
					t.masks.bottom.height = globApp.safeScreenArea.h - t.masks.bottom.y

			t.minCollumnWidth = t.fonts.cells.size * 10
			t.maxCollumnWidth = t.frame.width - t.fonts.cells.size
			if t.collumnsCount == 1 then
				t.collumWidth = t.frame.width - t.fonts.cells.size
			elseif t.collumnsCount > 1 and ((t.frame.width - t.fonts.cells.size) / t.collumnsCount) < t.minCollumnWidth then
				t.collumWidth = t.minCollumnWidth
			elseif t.collumnsCount > 1 and ((t.frame.width - t.fonts.cells.size )/ t.collumnsCount) > t.minCollumnWidth then
				t.collumWidth = ((t.frame.width -t.fonts.cells.size) / t.collumnsCount)
			end

			t.textWrapCellPercentWidth = t.collumWidth * 0.8 
			t.rowHeight = t.fonts.cells.size + (t.fonts.cells.size * .4)

			t.displayWidth = t.frame.width
			t.displayHeight = tableHeight * globApp.safeScreenArea.h

			------------------------FUNC CALLBACKS/BUTTONS--------------------
			t.callbackFuncNames = {}
			t.fullCallbackFuncs = {}
			t.buttons = {}

			local numOfCallbackButtons = 0

			for i, cb in pairs(tblCallbackFuncs) do
				numOfCallbackButtons = numOfCallbackButtons + 1
			end 

			local iterator1 = 0
			for i=1, #tblCallbackFuncs, 1 do
				local index = ""
				for j, cb in  pairs (tblCallbackFuncs[i]) do 
					index = j

					iterator1 = iterator1 + 1

					t.callbackFuncNames[index] = cb
					t.fullCallbackFuncs[index] = ""
					t.buttons[index] = {}
					t.buttons[index].text = index
					t.buttons[index].x = t.frame.x + (iterator1 * (t.displayWidth / #tblCallbackFuncs)) - (t.displayWidth / #tblCallbackFuncs)
					t.buttons[index].y = t.frame.y + t.displayHeight - t.rowHeight
					t.buttons[index].width = t.displayWidth / #tblCallbackFuncs
					t.buttons[index].height = t.rowHeight
					t.buttons[index].isFocused = false
				end
			end

			t.titleBox = {}
				t.titleBox.x = t.frame.x
				t.titleBox.y = t.frame.y
				t.titleBox.width = t.frame.width
				t.titleBox.height = t.fonts.title.size * 1.3

			t.titleCaption = {}
				t.titleCaption.x = t.titleBox.x + (t.titleBox.width * .1)
				t.titleCaption.y = t.titleBox.y + (t.titleBox.height * .1)
				t.titleCaption.wrapWidth = t.titleBox.width * 0.8

			t.headersBox = {}
				t.headersBox.x = t.titleBox.x
				t.headersBox.y = t.titleBox.y + t.titleBox.height
				t.headersBox.w = t.titleBox.width
				t.headersBox.h = 0


			local headerData = headerTitles
			local allTblHeaders = {}
			for i=1, #dataTable, 1 do
				allTblHeaders[i] = dataTable[i]["ID"]
			end

			-- uniqueHeaderFilter (dataTable, t.collumnsCount)
			t.cells = {}
			
			-- New code to calculate uniformCellHeight
			local maxOverallTextLineCount = 1
			local actualCellFontHeight = returnFontInfo (t.fonts.cells.font, "height")

			-- Check headers
			maxOverallTextLineCount = math.max(maxOverallTextLineCount, findMaxNumOfLinesNeeded(t.fonts.headers.font, t.textWrapCellPercentWidth, headerData))

			-- Check data rows
			for i = 1, t.rowsCount, 1 do
				local textTable = {}
				for z=1, #headerData, 1 do
					textTable[z] = table_lookUp (dataTable, i, headerData[z])
				end
				maxOverallTextLineCount = math.max(maxOverallTextLineCount, findMaxNumOfLinesNeeded(t.fonts.cells.font, t.textWrapCellPercentWidth, textTable))
			end

			-- Calculate uniform cell height with 15% top/bottom padding
			local cellPaddingFactor = 0.30 -- 15% top + 15% bottom
			local uniformCellHeight = (actualCellFontHeight * maxOverallTextLineCount) * (1 + cellPaddingFactor)
			t.uniformCellHeight = uniformCellHeight -- Store it for later use
			-- End new code

			local cellPositions = {}
			cellPositions.w = t.collumWidth
			local previewsRowY = 0
			local previewsRowH = 0
			t.combinedRowsHeight = 0
			
			for i = 1, t.rowsCount + 1, 1 do
				for j = 1, #headerData , 1 do

					local cellName = (i .. "," .. j)
					local cellData = "--empty--"
					local scrollability = false
					local cellRercordID = ""
					
					cellPositions.x = t.frame.x - t.collumWidth + (t.collumWidth * j )

					if i == 1 then --takes care of the header row data

						cellData = headerData[j]	
						cellRercordID = "HEADER"

						if j == 1 then

							local maxTextLineCount = findMaxNumOfLinesNeeded (t.fonts.headers.font, t.textWrapCellPercentWidth, headerData)
							local actualHeaderFontHeight = returnFontInfo (t.fonts.headers.font, "height")

							cellPositions.y = t.headersBox.y
												cellPositions.h = t.uniformCellHeight
												t.headersBox.h = t.uniformCellHeight
						end

					elseif i > 1 then --takes care of the data rows data

						local textTable = {}
						
						for z=1, #headerData, 1 do
							textTable[z] = table_lookUp (dataTable, i-1,headerData[z])
						end

						if j == 1 then

							for k, c in pairs(t.cells) do
								 if c.row == (i - 1) and c.collumn == 1 then
									previewsRowY = c.y
									previewsRowH = c.height
									-- print (c.height)
								end
							end

												cellPositions.y = (previewsRowY + previewsRowH)
												cellPositions.h = t.uniformCellHeight							t.combinedRowsHeight = t.combinedRowsHeight + cellPositions.h
						end
					
						cellRercordID = allTblHeaders[i - 1]
						
						cellData = table_lookUp (dataTable, i-1,headerData[j])
						scrollability = true

					end
					
					TableCell_create (cellName, cellPositions.x, cellPositions.y, cellPositions.w, cellPositions.h, i, j, cellData, scrollability, t.cells,cellRercordID)

				end --[[cell objects creation]]

			end

			t.scrollBox = {}
				t.scrollBox.x = t.frame.x
				t.scrollBox.y = t.frame.y + t.titleBox.height + t.headersBox.h
				t.scrollBox.width = t.frame.width - t.fonts.cells.size
				t.scrollBox.height = (t.displayHeight - (t.scrollBox.y - t.frame.y)) - (t.rowHeight * 2)

			t.scrollableYequivPercent = t.scrollBox.y / globApp.safeScreenArea.h

			t.y_difBetweenSafeAndTotalArea = globApp.safeScreenArea.y /  globApp.safeScreenArea.h
			
			t.verticalScrollBar = {}
				t.verticalScrollBar.name = spreadSheetName .. "_vsb"
				t.verticalScrollBar.x = ((t.frame.x + t.frame.width) -  (t.fonts.cells.size)) / globApp.safeScreenArea.w
				t.verticalScrollBar.y = t.scrollableYequivPercent - t.y_difBetweenSafeAndTotalArea
				t.verticalScrollBar.width = t.fonts.cells.size/ globApp.safeScreenArea.w
				t.verticalScrollBar.height = t.scrollBox.height / globApp.safeScreenArea.h
			--IMPORTANT: DONT REMOVE FOLLOWING LINE


			t.horizontalScrollBar = {}
				t.horizontalScrollBar.name = spreadSheetName .. "_hsb"
				t.horizontalScrollBar.x = t.frame.x / globApp.safeScreenArea.w
				t.horizontalScrollBar.y = (t.scrollBox.y + t.scrollBox.height) / globApp.safeScreenArea.h
				t.horizontalScrollBar.width = t.scrollBox.width / globApp.safeScreenArea.w
				t.horizontalScrollBar.height = t.rowHeight / globApp.safeScreenArea.h

			if t.rowsCount > 0 then
				t.avrgRowHeight = t.combinedRowsHeight / t.rowsCount
			else
				t.avrgRowHeight = 1
			end
			t.numRowsPerDisplay = t.scrollBox.height / t.avrgRowHeight


			t.combinedCollumnsWidth = t.collumnsCount * t.collumWidth
			if t.collumnsCount > 0 then
				t.avrgCollumnsWidht = t.collumWidth
			else
				t.avrgCollumnsWidht = 1
			end
			t.numCollumnsPerDisplay = t.scrollBox.width / t.collumWidth

			t.dataCurrentVertPosition = t.dataCurrentVertPosition
			t.dataCurrentHorzPosition = t.dataCurrentHorzPosition
			t.state = 0 --[[0 deactivated, 1 = released, 2 = pressed.]]

			-- scrollBar_update calls removed as they were redundant and non-functional.
			-- Resizing is now handled by the .resize() method on each object.

			-- scrollBar_update calls removed as they were redundant and non-functional.
			-- Resizing is now handled by the .resize() method on each object.
		end

	end
end

-- function spreadSheet_delete (spreadSheetName,strgPage)

-- 	for i = #spreadSheets,1,-1 do

-- 		local spreadSheet = spreadSheets[i]

-- 		--LOAD PROJECT:

-- 			if spreadSheet.name == spreadSheetName and spreadSheet.page == strgPage then

-- 				table.remove(spreadSheets,i)

-- 				globApp.numObjectsDisplayed = globApp.numObjectsDisplayed - 1

-- 			end

-- 	end
-- end

function uniqueHeaderFilter (array, headerCount)

	local headers = {}
	local counter = {}

	for i = 1, headerCount, 1 do
		headers[i] = "empty"
	end

	counter[1] = 0

	for i, block in pairs (array) do

		counter[1] = counter[1] + 1 
		counter[2] = 0


		if type (block) == "table" then

			for j, rows in pairs (block) do

				counter[2] = counter [2] + 1 
				counter[3] = 0

				for k = 1, headerCount, 1 do

					if k == counter[2] then 

						headers [counter[2]] = j

					end 

				end

			end

		end

	end
					
	return headers
end

function gui_table_draw (pageName)

	-- local activePageName = 0

	-- for i, pgs in ipairs (pages) do
	-- 	if pgs.index == globApp.currentPageIndex then
	-- 		activePageName = pageName
	-- 	end
	-- end

	-- local spreadSheetExists = false


	-- if activePageName == strgPage then --[[compares object pg to current page]]

		-- if spreadSheetExists == false then --[[runs once]]

		-- 	gui_table_create (spreadSheetName, strgPage, strgspreadSheetType, dataTable, myX, myY, tableWidth, tableHeight, anchorPoint, strgImgspreadSheetBg, tblCallbackFuncs, fontSize, headerTitles)

		-- elseif spreadSheetExists == true and (globApp.resizeDetected == true or globApp.projectsTblChanged == true) then --[[updates only if window is resized]]

		-- if globApp.projectAvailable == false then
		-- -- 	spreadSheet_update(spreadSheetName, strgPage, strgspreadSheetType, dataTable, myX, myY, tableWidth, tableHeight, anchorPoint, strgImgspreadSheetBg, tblCallbackFuncs, fontSize, headerTitles)
		-- -- else  
		-- 	page_switch ("LoadingMainMenu", 3, 2, false)
		-- end
		-- 	globApp.projectsTblChanged = false

		-- -- end

		for i,x in pairs(globApp.objects.tables) do --[[draws table]]

			if x.page == pageName then

				if x.state == 0  then
					
				elseif x.state == 1  then

					--TABLE FONT SIZE
					love.graphics.setFont(x.fonts.cells.font)

					--TABLE TOTAL BG AREA 
					love.graphics.setColor(1, 0, 0, 1)
					love.graphics.rectangle("fill", x.titleBox.x, x.titleBox.y, x.displayWidth, x.displayHeight)

					--SCROLLABLE SPACE
					love.graphics.setColor(0, 0, 0, 1)
					love.graphics.rectangle("fill", x.scrollBox.x, x.scrollBox.y, x.scrollBox.width, x.scrollBox.height)

					--CELLS:
					for j,cells in pairs(x.cells) do

						if cells.row ~= 1 then

							if cells.y + cells.height > x.scrollBox.y and cells.y < x.scrollBox.y + x.scrollBox.height then

								if cells.focused == false then
								
									love.graphics.setColor(.5, .5, .5, 1)
									love.graphics.rectangle("line", cells.x, cells.y, cells.width, cells.height)

									love.graphics.setColor(1, 1, 1, 1)
									love.graphics.printf(cells.content, cells.x + (cells.width * 0.05), cells.y + (cells.height * 0.05), (cells.width * 0.95), "center")

								elseif cells.focused == true then

									love.graphics.setColor(0, 1, 0, 1)
									love.graphics.rectangle("fill", cells.x, cells.y, cells.width, cells.height)

									love.graphics.setColor(1, 0, 0, 1)
									love.graphics.printf(cells.content, cells.x + (cells.width * 0.05), cells.y + (cells.height * 0.05), (cells.width * 0.95), "center")

								end

							end

						end

					end

					--TITLE:

					love.graphics.setFont(x.fonts.title.font)
					love.graphics.setColor(.2, .2, .2, 1)
					love.graphics.rectangle("fill", x.titleBox.x, x.titleBox.y, x.titleBox.width , x.titleBox.height)--[[title rectangle]]

					love.graphics.setColor(1, 1, 1, 1)
					
					love.graphics.printf(x.name, x.titleCaption.x, x.titleCaption.y, x.titleCaption.wrapWidth, "center") --[[Title text]]

					--HEADERS
					love.graphics.setFont(x.fonts.headers.font)

					for j,cells in ipairs (x.cells) do

						if cells.row == 1 then
							
							love.graphics.setColor(.3, .3, .3, 1)
							
							love.graphics.rectangle("fill", cells.x, cells.y, cells.width, cells.height)

							love.graphics.setColor(0, 1, 0, 1)
							love.graphics.printf(cells.content, cells.x + (cells.width * 0.05), cells.y + (cells.height * 0.05), (cells.width * 0.95), "center")

						end

					end
					

					--[[TABLE BUTTONS]]
					for j, bt in pairs (x.buttons) do

						local btFontColor = {0,0,0,1}
						local btColor = {0,0,0,1}

						if bt.isFocused == false then
							btFontColor = {1,1,1,1}
							btColor = {.3,.3,.3,1}
						elseif bt.isFocused == true then
							btFontColor = {1,0,0,1}
							btColor = {0,1,1,1}
						end

							love.graphics.setColor(btColor[1], btColor[2], btColor[3], btColor[4])
							love.graphics.rectangle("fill", bt.x, bt.y, bt.width, bt.height)

							love.graphics.setColor(btFontColor[1], btFontColor[2], btFontColor[3], btFontColor[4])
							love.graphics.printf(bt.text, bt.x + (bt.width * .1), bt.y + (bt.height * 0.1), (bt.width * 0.8), "center")
							love.graphics.reset ()


					end




					--MASKS:
						love.graphics.setColor(globApp.appColor[1], globApp.appColor[2], globApp.appColor[3], globApp.appColor[4])
						--TOP
						love.graphics.rectangle("fill", x.masks.top.x, x.masks.top.y, x.masks.top.width, x.masks.top.height, rx, ry, segments)
						--LEFT
						love.graphics.rectangle("fill", x.masks.left.x, x.masks.left.y, x.masks.left.width, x.masks.left.height, rx, ry, segments)
						--RIGHT
						love.graphics.rectangle("fill", x.masks.right.x, x.masks.right.y, x.masks.right.width, x.masks.right.height, rx, ry, segments)
						--BOTTOM
						love.graphics.rectangle("fill", x.masks.bottom.x, x.masks.bottom.y, x.masks.bottom.width, x.masks.bottom.height, rx, ry, segments)
						
						love.graphics.reset ()
						

					--UNSAFE AREA MASKS:
						love.graphics.setColor(0,0,0,1)
						--TOP
						love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), globApp.safeScreenArea.y, rx, ry, segments)
						--LEFT
						love.graphics.rectangle("fill", 0, 0, globApp.safeScreenArea.x, love.graphics.getHeight(), rx, ry, segments)
						-- --RIGHT
						love.graphics.rectangle("fill", globApp.safeScreenArea.xw, 0, (love.graphics.getWidth()-globApp.safeScreenArea.xw), love.graphics.getHeight(), rx, ry, segments)
						-- --BOTTOM
						love.graphics.rectangle("fill", 0, globApp.safeScreenArea.yh, love.graphics.getWidth(), (love.graphics.getHeight()-globApp.safeScreenArea.yh), rx, ry, segments)
						
						love.graphics.reset ()
				
				end

			end
	    end

	-- elseif activePageName ~= strgPage  then--[[compares object pg to current page]]
 
	 	-- if spreadSheetExists == true then
			
		-- 	spreadSheet_delete (spreadSheetName, strgPage)
		-- 	scrollBar_delete ((spreadSheetName.. "_hsb"), strgPage)
		-- 	scrollBar_delete ((spreadSheetName.. "_vsb"), strgPage)

		-- end
	
	-- end	
end

function TableCell_create (name, x, y, width, height, myRow, myCollumn, content, scrollable, addTo, recordID)

	local newCell = {}

		newCell.recordID = recordID
		newCell.name = name
		newCell.x = x
		newCell.y = y
		newCell.row = myRow
		newCell.collumn = myCollumn
		newCell.width = width
		newCell.height = height
		newCell.content = content
		newCell.focused = false
		newCell.scrollable = scrollable

		table.insert(addTo, newCell)
end

function determineSizeOfArray (myArray, resultType)
	--[[returns table with 1) #rows, 2) #collums, 3) #dimensions, 4) #dataPicies]]

	--[[PARAMETERS:

		myArray ----------------Table/Array ----------------any 1d or 2d array
		resultType --------------string --------------------required result, choose from
															rows, collums, dimensions, dataCount or info.

	]]


	local resultArray = {}
	local arrayRows = 0
	local arrayCollums = 0
	local arrayDimensions = 0
	local arrayPicesOfData = 0
	local maxCollumFinder = 0

	if myArray ~= nil then

		if #myArray > 0 then --[[checks if the first dimension exists]]

			arrayDimensions = arrayDimensions + 1 --[[adds one to dimensions counter]]

		end

		for i, rows in pairs (myArray) do

			arrayRows = arrayRows + 1

			arrayCollums = 0

			if type(rows) == "table" then

				for j, collums in pairs (rows) do

						arrayCollums = arrayCollums + 1

						if arrayCollums > maxCollumFinder then --[[finds the max number of collums]]

							maxCollumFinder = arrayCollums

						end

						if arrayCollums >= 1 then --[[checks if the second dimension exists]]

							arrayDimensions = 2

						end

					arrayPicesOfData = arrayPicesOfData + 1

				end

			end

		end

		arrayCollums = maxCollumFinder

	elseif myArray == nil then

		local errorMessage = "Table does not exist"
		arrayRows = errorMessage
		arrayCollums = errorMessage
		arrayDimensions = errorMessage
		arrayPicesOfData = errorMessage

	end

	resultArray[1] = arrayRows
	resultArray[2] = arrayCollums
	resultArray[3] = arrayDimensions
	resultArray[4] = arrayPicesOfData


	if resultType == "rows" then

		return resultArray[1]

	elseif resultType == "collums" then

		return resultArray[2]

	elseif resultType == "dimensions" then

		return resultArray[3]

	elseif resultType == "dataCount" then

		return resultArray[4]

	elseif resultType == "info" and myArray ~= nil then

		print ("Array info: " .. resultArray[1] .. " rows, " .. resultArray[2] .. " collums, " .. resultArray[3] .. " dimensions, and " .. resultArray[4].. " pieces of data")

	end
end

function table_lookUp (array, rcrdIndex, header)
	--[[returns specified value based grid coordinates. returns empty if no value was found at coordinates]]

	local cellContent = "empty"
	local counters = {}

	counters.row = 0 

	for i=1, #array, 1 do

		counters.row = counters.row + 1 
		counters.collum = 0

		if type(array[i]) == "table" then

			for j, data in pairs (array[i])do
				counters.collum = counters.collum + 1 
					
				if rcrdIndex == counters.row and j == header then

					local preFormatCellContent = array[i][header]
					local postFormatCellContent = ""
					if type(preFormatCellContent) == "table" then
						for indx, val in ipairs (preFormatCellContent) do
							if indx == 1 then
								postFormatCellContent = val
							else
								postFormatCellContent = (postFormatCellContent .. ", " .. val)
							end
							
						end
					else
						postFormatCellContent = preFormatCellContent
					end
					cellContent = postFormatCellContent

				end
			
			end

		end

	end
					
	return cellContent
end

function touchScrollSpreadShett (id, x, y, dx, dy, pressure, button, istouch)
	--isolate table
	local myTable = globApp.objects.tables
	local spreadSheetExist = false
	local totalRows = 0
	local totalCollums = 0

	--determine if it is just a tap or click
	local justATapOrClick = true
	if globApp.userInput == "slide" then
		justATapOrClick = false
	end 

	if justATapOrClick == false then 
		--determine if there are spreadsheets available 
		for i, tbls in ipairs (myTable) do 
			if i > 0 then
				spreadSheetExist = true
			end
			totalRows = tbls.rowsCount 
			totalCollums = tbls.collumnsCount
		end

		--skip code if no spreadsheet is present
		if spreadSheetExist == true then
			--identify touch or click within any cell
			for i, tbl in ipairs (myTable) do
				for j, cl in ipairs (tbl.cells) do 
					if cl.row == 2 then
						if cl.y < (tbl.scrollBox.y) and (cl.y + dy) < (tbl.scrollBox.y) then
							isScrollUpAvlbl = true
						else
							isScrollUpAvlbl = false
						end
					end
					if cl.row == totalRows + 1 then
						if (cl.y + cl.height) > (tbl.scrollBox.y + tbl.scrollBox.height) and (cl.y + cl.height + dy) > (tbl.scrollBox.y + tbl.scrollBox.height) then
							isScrollDownAvlbl = true
						else
							isScrollDownAvlbl = false
						end
					end
					if cl.collumn == 1 then
						if cl.x < (tbl.scrollBox.x) and (cl.x + dx) < (tbl.scrollBox.x) then
							isScrollLeftAvlbl = true
						else
							isScrollLeftAvlbl = false
						end
					end
					if cl.collumn == totalCollums then
						if (cl.x + cl.width) > (tbl.scrollBox.x + tbl.scrollBox.width) and (cl.x + cl.width + dx) > (tbl.scrollBox.x + tbl.scrollBox.width) then
							isScrollRightAvlbl = true
						else
							isScrollRightAvlbl = false
						end
					end
				end

				for j, cl in ipairs (tbl.cells) do
					--determine if touch was made within scrollable area
					if x >= tbl.scrollBox.x and x <= (tbl.scrollBox.x + tbl.scrollBox.width) and y >= tbl.scrollBox.y and y <= (tbl.scrollBox.y + tbl.scrollBox.height ) then
						if cl.row ~= 1 then
							--VERTICAL SCROLLING LOGIC
							if (isScrollUpAvlbl == true and dy > 0) or (isScrollDownAvlbl == true and dy < 0) then
								cl.y = cl.y + dy
								local new_v_pos = returnTblRowsToScrollBoxVerticalPosition()
								for _, sb in ipairs(globApp.objects.scrollBars) do
									if sb.id == tbl.verticalScrollBar.name then
										updateScrollingBarPosition(sb, new_v_pos)
										tbl.dataCurrentVertPosition = new_v_pos
										break
									end
								end
	
							end
							--HORIZONTAL SCROLLING LOGIC
							if (isScrollLeftAvlbl == true and dx > 0) or (isScrollRightAvlbl == true and dx < 0) then
							-- print (isScrollRightAvlbl)
								cl.x = cl.x + dx

								local new_h_pos = returnTblCollumnsToScrollHorizontalPosition()
								for _, sb in ipairs(globApp.objects.scrollBars) do
									if sb.id == tbl.horizontalScrollBar.name then
										updateScrollingBarPosition(sb, new_h_pos)
										tbl.dataCurrentHorzPosition = new_h_pos
										break
									end
								end
							end
						elseif cl.row == 1 then
							--HORIZONTAL SCROLLING LOGIC
							if (isScrollLeftAvlbl == true and dx > 0) or (isScrollRightAvlbl == true and dx < 0) then
							-- print (isScrollRightAvlbl)
								cl.x = cl.x + dx

							end

						end
					end
				end

			end
		end 
	end
end

function touchedCell (x, y, button, istouch, mySpreadSheet)

	local cell = {x = 0, y = 0, row = 0, collum = 0}

	for i, sp in ipairs (mySpreadSheet) do

		for j, cl in ipairs (sp.cells) do

			if button == 1 or istouch == true  then

				if x >= cl.x and x <= (cl.x + cl.width) and y >= cl.y and y <= (cl.y + cl.height) and cl.focused == false then

					cl.focused = true

					if cl.focused == true then

						cell.cellName = cl.name
						cell.x = cl.x
						cell.y = cl.y
						cell.row = cl.row
						cell.collum = cl.collum

					end 

					cl.focused = false

				end

			end

		end

	end

	return cell
end

function tableRow_Select (x,y,button,istouch)

	--isolate table
	local myTable = globApp.objects.tables
	local spreadSheetExist = false
	local totalCollums = 0
	local justATapOrClick = false

	--determine if it is just a tap or click
	if globApp.userInput == "left click" or globApp.userInput == "tap"then 
		--determine if there are spreadsheets available 
		for i, tbls in ipairs (myTable) do 

			if i > 0 then
				spreadSheetExist = true
			end

			totalRows = tbls.rowsCount
			totalCollums = tbls.collumnsCount

		end

		--skip code if no spreadsheet is present
		if spreadSheetExist == true then
			
			--identify touch or click within any cell

			for i, tbl in ipairs (myTable) do

				for j, cl in ipairs (tbl.cells) do

					if cl.row ~= 1 then

						--determine if touch was made within scrollable area
						if x >= tbl.scrollBox.x and x <= (tbl.scrollBox.x + tbl.scrollBox.width) and y >= tbl.scrollBox.y and y <= (tbl.scrollBox.y + tbl.scrollBox.height ) then

							if  y >= cl.y and y <= (cl.y + cl.height) and cl.focused == false then
								if cl.focused == false then
									cl.focused = true
								elseif cl.focused == true then
									cl.focused = false
								end

							else

							cl.focused = false

							end

						end

					end

				end

			end

		end 

	end
end

function tableCellAddress_find (myTouchedCell, table, outputMode, devMode)

	--[[-------------------------------------------------------------
	used to determine the row or collum number that the last touched
	cell belongs to

	INPUT
	myTouchedCell ---------------string -----------------name of cell x/y 
	table----------------------table-------------------array data name
	devMode -------------------boolean ----------------unit test boolean
	outputMode-----------------string -----------------row or collum
	
	OUTPUT:
	row or collumn numeber-----integer-----------------number representing
													   a row or collumn
	-----------------------------------------------------------------]]
	--mock table for dev


	--determine if page has a spreadsheet
	local spreadSheetExists = false

	if #table >= 1 then

		spreadSheetExists = true

	end
	
	local myResult = {}

	for i, tbl in ipairs (table) do 

		for j, cell in pairs (tbl) do

			--isolate touched cell and gather associated row or collumn
			if cell.name == myTouchedCell then
				--split result based on selected outputMode
				if outputMode == "row" then

					myResult[1] = cell.row - 1
					myResult[2] = cell.collumn
				
				elseif outputMode == "collumn" then

					myResult[1] = cell.collumn
					myResult[2] = cell.row - 1


				end

			end 

		end

	end

	--standard unit testing return code
	if devMode == true then
		local testResult = {}
			testResult[1] = myResult[1]
			testResult[2] = myResult[2]
			testResult[3] = spreadSheetExists
			-- print (myResult[1])
		return testResult
	end

	return myResult[1]
end

function tablefuncCallbackToString (strgFuncCallBackName, parameters)

	--writes a string that corresponds to an executable function

	--create function strings
	local funcStrings = {}
	local fullStringPath = ""

	funcStrings[1] = (strgFuncCallBackName .. "(")

	fullStringPath = funcStrings[1]


	for i = 1, #parameters, 1 do

		if tonumber (parameters[i]) ~= nil then

			parameters[i] = tonumber (parameters[i])

		end

		if type(parameters[i]) == "string" then

			parameters[i] = ("\"" .. parameters[i] .. "\"")

		end

	end


	for i = 1, #parameters, 1 do

		if i ~= #parameters then
			funcStrings[i + 1] = tostring(parameters[i]) .. ","
		elseif i == #parameters then
			funcStrings[i + 1] = tostring(parameters[i]) .. ")"
		end

		fullStringPath = (fullStringPath .. funcStrings[i + 1])

	end

	return (fullStringPath)
end

function tableButtonsPressed (x,y,button,istouch)
	
	local myTable = globApp.objects.tables

	if button == 1 or globApp.userInput == "touch pressed" then
		for i, tbl in ipairs (myTable) do 
			for j, bt in pairs (tbl.buttons) do
				if x >= bt.x and x <= (bt.x + bt.width) and y >= bt.y and y <= (bt.y + bt.height) then
					if bt.isFocused == false then
						bt.isFocused = true
					end
				end
			end
		end
	end
end

function tableButtonsReleased (x,y,button,istouch)

	local myTable = globApp.objects.tables

	if button == 1 or globApp.userInput == "touch released" then
		for i, tbl in ipairs (myTable) do 
			for j, bt in pairs (tbl.buttons) do
				if x >= bt.x and x <= (bt.x + bt.width) and y >= bt.y and y <= (bt.y + bt.height) then
					if bt.isFocused == true then

						local isDataSelected = false
						local selectedRow = {}
						local selectedRcrdID = ""
						local collumnIterator = 1
						local callBackId = tbl.callbackFuncNames[bt.text]
						local callBackParameters = {}
						local wasFunctionDeclared = false

						for k, cell in ipairs(tbl.cells) do
							if cell.focused == true and collumnIterator == 1 then
								isDataSelected = true
								selectedRcrdID = cell.recordID
								callBackParameters[1] = selectedRcrdID
								collumnIterator = collumnIterator + 1
							end
						end

						local func = callBackId

						if _G[func] then 
						    wasFunctionDeclared = true
						else
							print ("Callback " .. callBackId .. " was NOT declared, for button " .. bt.text .. ", please declare one!")
						end

						if selectedRcrdID ~= "" and wasFunctionDeclared == true then
							local callback = loadstring(tablefuncCallbackToString (callBackId, callBackParameters))
							callback () --executes callback
						end
						bt.isFocused = false
					end
				end
			end
		end
	end
end

function tableSelectButton_released (x,y,button,istouch)

	local buttonState = 0
	local myTable = globApp.objects.tables
	local selectedRow = 0
	local myResult = {}
	local buttonTouched = false
	local isDataSelected = false

	--determine if button has been touched
	for i, tbl in ipairs (myTable) do 

		if (button == 1 or istouch == true) and tbl.selectButtonFocused == true then

			buttonTouched = true

		end

	end

	--run code only if button is pressed
	if buttonTouched == true then

		--determine the row of the focused cell
		for i, tbl in ipairs (myTable) do 

			for j, cell in ipairs(tbl.cells) do

				if cell.focused == true then

					isDataSelected = true

					selectedRow = cell.row

				end

			end

		end

		--run code only if data is selected

		if isDataSelected == true then
			--gather selected row data
			for i, tbl in ipairs (myTable) do

				for j, cell in ipairs(tbl.cells) do

					if cell.row  == selectedRow and cell.focused == true then

						table.insert(myResult, cell.content)

					end

				end

			end

			--pass parameters to table callback function
			for i, tbl in ipairs (myTable) do

				tbl.fullCallbackFuncs = loadstring(tablefuncCallbackToString (tbl.callbackFuncNames, myResult))

				tbl.fullCallbackFuncs ()
				tbl.fullCallbackFuncs = ""

				if tbl.selectButtonFocused == true then

					tbl.selectButtonFocused = false

				end

			end

		elseif isDataSelected == false then

			for i, tbl in ipairs (myTable) do

				if tbl.selectButtonFocused == true then

					tbl.selectButtonFocused = false

				end

			end


		end

		myResult = nil
		
	end
end

function tableDeleteButton_released (x,y,button,istouch)

	local buttonState = 0
	local myTable = globApp.objects.tables
	local selectedRow = 0
	local myResult = {}
	local buttonTouched = false
	local isDataSelected = false

	--determine if button has been touched
	for i, tbl in ipairs (myTable) do 

		if (button == 1 or istouch == true) and tbl.deleteButtonFocused == true then

			buttonTouched = true

		end

	end

	--run code only if button is pressed
	if buttonTouched == true then

		--determine the row of the focused cell
		for i, tbl in ipairs (myTable) do 

			for j, cell in ipairs(tbl.cells) do

				if cell.focused == true then

					isDataSelected = true

					selectedRow = cell.row

				end

			end

		end

		--run code only if data is selected

		if isDataSelected == true then
			--gather selected row data
			for i, tbl in ipairs (myTable) do

				for j, cell in ipairs(tbl.cells) do

					if cell.row  == selectedRow and cell.focused == true then

						table.insert(myResult, cell.content)

					end

				end

			end

			local selectProjIndex = findTableIndexByRecordID (globApp.projects, "NTI",myResult[2], 23)

			--pass parameters to table callback function
			deletedProject (globApp.projects, selectProjIndex)
			saveNewProject ("savedProjectData.lua", globApp.projects, "globApp.projects")
			recordErased = true
			print (recordErased)

			for i, tbl in ipairs (myTable) do --deselect delete button"

				print ("deleteButtonReleased")

				if tbl.deleteButtonFocused == true then

					tbl.deleteButtonFocused = false

				end

			end

		elseif isDataSelected == false then

			for i, tbl in ipairs (myTable) do

				if tbl.deleteButtonFocused == true then

					tbl.deleteButtonFocused = false

				end

			end


		end

		myResult = nil
		
	end
end

function spreadSheetScrollbarVertCallback (position)
	for i, t in ipairs (globApp.objects.tables) do

		local lowerY = t.scrollBox.y
		local upperY = lowerY - t.combinedRowsHeight + t.scrollBox.height
		local spanY = lowerY - upperY
		local collumnCount = 0

		if t.state == 1 then

			local thisY = 0
			local nextY = 0
			local baseY = 0

			if t.combinedRowsHeight < t.scrollBox.height then

				baseY = t.scrollBox.y

			else

				for j, cl in ipairs (t.cells) do 

					if cl.row ~= 1 then

						collumnCount = collumnCount + 1

						if cl.row == 2 then

							if collumnCount == 1 then
								baseY = lowerY - (spanY * position)
								thisY = baseY
								nexty = thisY + cl.height
							end

							cl.y = thisY
							
						elseif cl.row > 2 then

							if collumnCount == 1 then
								thisY = nexty
								nexty = thisY + cl.height
							end

							cl.y = thisY

						end

						if collumnCount == t.collumnsCount then
							collumnCount = 0
						end

						t.dataCurrentVertPosition = position
						
					end -- closes 'if cl.row ~= 1'

				end -- closes 'for j, cl'

			end -- closes 'if t.combinedRowsHeight < t.scrollBox.height' and its 'else' part
		
		end -- closes 'if t.state == 1'

	end -- closes 'for i, t'
end -- closes 'function spreadSheetScrollbarVertCallback (position)'


function speadSheetScrollbarHorzCallback (position)

	for i, t in ipairs (globApp.objects.tables) do

		local lowerX = t.scrollBox.x
		local upperX = lowerX - t.combinedCollumnsWidth + t.scrollBox.width
		local spanX = lowerX - upperX
		local collumnCount = 0

		if t.state == 1 then

			local thisX = 0
			local nextX = 0
			local baseX = 0

			if t.combinedCollumnsWidth < t.scrollBox.width then
				baseX = t.scrollBox.x
			else

				for j, cl in ipairs (t.cells) do 

					collumnCount = collumnCount + 1

					if collumnCount == 1 then

						baseX = lowerX - (spanX * position)
						thisX = baseX
						nextX = thisX + cl.width

						cl.x = thisX
							
					elseif collumnCount > 1 then

						thisX = nextX
						nextX = thisX + cl.width


						cl.x = thisX


						if collumnCount == t.collumnsCount then
							collumnCount = 0
						end

						t.dataCurrentHorzPosition = position
						
					end

				end

			end
		
		end

	end
end

function findMaxNumOfLinesNeeded (thisFont, wrapWidth, txt)
	local maxLineFound = 1

	if type(txt) == "table" then
		for i, txt in ipairs (txt) do
			local thisText = tostring(txt)
			local width, lines = thisFont:getWrap(thisText, wrapWidth)
			if #lines > maxLineFound then
				maxLineFound = #lines
			end
		end
	else
		local width, lines = thisFont:getWrap(tostring(txt), wrapWidth)
		if #lines > maxLineFound then

			maxLineFound = #lines
		end
	end
	return maxLineFound
end

function returnTblRowsToScrollBoxVerticalPosition ()
	--[[ returns values 0 to 1 for 0 to 100 percent vertical displacement of 
	of rows, 0 means lowermost point of first row (2) and 100 means highermost point of
	first row (2)]]
	local result = nil

	for i, t in ipairs (globApp.objects.tables) do

		local lowerY = t.scrollBox.y
		local upperY = lowerY - t.combinedRowsHeight + t.scrollBox.height
		local spanY = -(lowerY - upperY)

		for j, cl in ipairs (t.cells) do

			if cl.row == 2 then

				result = (cl.y - lowerY * 1 ) / spanY

				return result

			end

		end

	end
end

function returnTblCollumnsToScrollHorizontalPosition ()

	--[[ returns values 0 to 1 for 0 to 100 percent horizontal displacement of 
	of collumns, 0 means right-most point of first collumn (1) and 100 means left-most point of
	first collumn (1)]]
	local result = nil

	for i, t in ipairs (globApp.objects.tables) do

		local rightY = t.scrollBox.x
		local leftY = rightY - t.combinedCollumnsWidth + t.scrollBox.width
		local spanX = -(rightY - leftY)

		for j, cl in ipairs (t.cells) do

			if cl.collumn == 1 then

				result = (cl.x - rightY * 1 ) / spanX

				return result

			end

		end

	end

end