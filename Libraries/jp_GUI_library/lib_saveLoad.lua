--[[saveLoad.lua
	contains all code necessary to manage project data. save and load
	it uses open source software show.lua referenced below]]


function createNewProjectData ( arrDataLabels, arrData, dataTable, recordIDLocator, numIDRandomDigit)

   --[[takes a specially formated data table, checks if data labels and pieces
      count matched, checks if serial number exits, processes the data, organizes 
      data, creates timeStamps and a unique ID, and returns the same table for 
      further use]]
   local labelsCount = 0
   local dataPiecesCount = 0
   local recordIDLength = (string.len(globApp.devCompanyAcronym) + string.len(recordIDLocator) +  numIDRandomDigit + 10 --[[not changeable]])


   local isThereNilLabels = areThereNILvalues (arrDataLabels)
   local isThereNilDataPieces = areThereNILvalues (arrData)
   local isSameNumOfLabelsAndData = areTwoTablesSameSize (arrDataLabels, arrData)
   local isTableEmpty = isTableEmpty (dataTable)


   local doesTableContainInvalidRecords = doesTableHaveInvalidRecordsIDs (dataTable, recordIDLocator, recordIDLength)

   if isTableEmpty == true or  (isSameNumOfLabelsAndData == true and doesTableContainInvalidRecords == false and isThereNilLabels == false and isThereNilDataPieces == false) then
      
      local newProjectData = {}
      local timestamp = string.sub(os.time(), 8, 11)

   	newProjectData["dateCreated"] = os.date("%Y/%m/%d")
      newProjectData["data"] = {}
      newProjectData["ID"] = createNewIdNumber_gdsLove2dGUI (dataTable, recordIDLocator, numIDRandomDigit)

      for i=1, #arrDataLabels, 1 do
         newProjectData[arrDataLabels[i]] = arrData [i]
      end 

      return newProjectData
   else

      local errorMessage = "The data labels and data pieces count do NOT match, ref createNew ProjectData funciton and callbacks"

      return errorMessage
   end
end

function findTableIndexByRecordID (searchT, recordIDLocator,recordId, idLength)
   --[[returns numerical index representing a table record index number]]
   local isTableEmpty = isTableEmpty (searchT)
   local doesTableContainInvalidRecords = doesTableHaveInvalidRecordsIDs (searchT, recordIDLocator, idLength)
   local isThereNilIndex = areThereNILvalues (searchT)

   local indexMatch = false

   if isTableEmpty == false and doesTableContainInvalidRecords == false and isThereNilIndex == false then
      local foundRecord = {}
      for i=1, #searchT, 1 do
         if searchT[i]["ID"] == recordId then
            indexMatch = true
            return i
         end
      end
      if indexMatch==false then
         local notFoundMsg = "Could Not Find the provided record ID"
         return notFoundMsg
      end
   else 
      local prvdedTableIssue = "there is an issue with the provided table"
      return prvdedTableIssue
   end
end 

function rtrnProjectDataFromIndexNum (t, indexNum, rtrnType)
   -- rtrnType Table or info 
   local tblResult = {}

   for i, prjt in ipairs (t) do
      if i == indexNum then

         tblResult = prjt
         if rtrnType == "info" then
            local strgResult = ""
            for j, data in pairs (tblResult) do

               if type (data) == "table" or type (data) == "boolean" then
                  strgResult = (strgResult .. j .. "=" .. type(data) .. "|")
               else
                  strgResult = (strgResult .. j .. "=" .. data  .. "|")
               end
               
            end
            return strgResult
         elseif rtrnType == "table" then
            return tblResult
         end
         
      end
   end
end

function areThereNILvalues (tableOrVariable)
   --[[ returns true if NIL values are found in table or variable]]
   local result = true 

   --checks if parameter if nil
   if tableOrVariable == nil then 
      return result
   else
      local parmtrType = type(tableOrVariable)
      if parmtrType == "table" then
         for i=1, #tableOrVariable, 1 do
            if tableOrVariable[i] == nil then
               return result
            end
         end
      end 
      result = false
      return   result
   end
end

function areTwoTablesSameSize (table1, table2)
   --[[ INFO: compares the number of variables in a single dimension array

      INPUT:
      table1: ------------Table--------------single dimensionErray
      table2: ------------Table--------------single dimensionErray

      OUTPUT:
      result--------------Boolean-------------representing equality btw 2 tables
   ]]

   local result = false

   if #table1 == #table2 then
      result = true
   end

   return result
end

function doesTableHaveInvalidRecordsIDs (table, recordIDLocator, idLength)

   --[[ INFO: compares the number of variables in a single dimension array

      INPUT:
      table: ------------Table--------------table to be examined for valid records
      recordIDLocator ---STRING-------------THREE LETTER CODE, AVOID NIL, TST, NOR

      OUTPUT:
      result--------------Boolean-------------representing whether valid recs found
   ]]

   local result = false
   local invalidID = false

   for i, thisProject in ipairs (table) do

      for j, thisID in pairs (thisProject) do

         if j == "ID" then
            local s = thisID
            
            if string.len(s) ~= idLength then
               invalidID = true
               -- print "ID length doesn't match the values in the provided table"
            end

            local from, to = string.find(s, recordIDLocator)
            
            if from ~= nil and to ~= nil then

            else 
                invalidID = true
               -- print "The provided record ID does not match the record IDs found in the provided table"
            end
         end

      end

   end

   if invalidID == true then

      result = true

   end

   return result
end

function createNewIdNumber_gdsLove2dGUI (recordsTable, recordIDLocator, numRandomDigits)

   --[[ INFO: creates a serial number based on GDS code, timestamp last 4, 7 
         random nums from 0 to 9, and character E for end, checks if 
         table contains this serialnumber and re-runs code to create a 
         unique code that is not yet created

         INPUT:
         recordTable: ------------Table--------------special formated table
         table={[1]={["ID" = ID ]}}

         OUTPUT:
         SN-----------------------String-------------representing SN
      ]]

   local result
   local iterate = true
   local numIteration = 0

   while iterate == true do

      iterate = false

      local ID = {}
         ID["SIGNATURE"] = globApp.devCompanyAcronym
         ID["IDLOCATOR"] = recordIDLocator
         ID["TIMESTAMP"] = string.sub(os.time(), 8, 11) --[[ 3 digit timestamp]]
         ID["RANDOMSTRING"] = ""
         ID["RANDOMDIGITS"] = {}
         for j=1,numRandomDigits,1 do
            ID["RANDOMDIGITS"][j] = math.random(0,9)
            ID["RANDOMSTRING"]=(ID["RANDOMSTRING"] .. ID["RANDOMDIGITS"][j])
         end
         ID["END_ID"] = "E"

      local newSerialNumber = (ID["SIGNATURE"] .. ID["IDLOCATOR"].. string.sub(os.date("%Y%m%d"), 3, 8) .. ID["TIMESTAMP"] .. ID["RANDOMSTRING"] ..ID["END_ID"])
      local doesRecordExits = doesSerialNumExistsInTable (recordsTable, newSerialNumber)

      if doesRecordExits == true then

         numIteration = numIteration + 1

         iterate = true 
         print ("New Project ID was remade " .. numIteration .. "x because it was duplicated")

      elseif doesRecordExits == false then
         
         result = newSerialNumber

      end

   end

   return result
end

function isTableEmpty (table)

   local result = false

   if #table == 0 then

      result = true

   end

   return result
end

function doesSerialNumExistsInTable (table, projectID)

   --[[ INFO: returns true or false depending if project id exits in
         provided table

      INPUT:
      recordTable: ------------Table--------------special formated table
      table={[1]={["ID" = ID ]}}

      OUTPUT:
      result--------------------boolean-----------if SN is found false else true

   ]]

   local result = false
   local savedProjects = table

   for i, project in ipairs (savedProjects) do

         
      for j, data in pairs (project)do
          -- print (project)
          --   print (projectID)
         if data == projectID then
            result = true

         end
      end
   end

   return result
end

function pairsByKeys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function sortProjectsTable()

  local sortedTable = {}

  for i, tbls in pairs (globApp.projects) do

    table.insert (sortedTable, i)

  end

  table.sort (sortedTable)

  for i = 1, #sortedTable, 1 do

    for j, tbls in pairs (globApp.projects) do

      if j == i then

        sortedTable[i] = tbls

      end

    end 

  end

  globApp.projects = sortedTable
end

function sortDataTable (parTable)
   local preSortingData = parTable
   local sortedIndexes = {}
   --creates a table with indexes based on preSortingData table count
   for i=1, #parTable,1 do
      table.insert (sortedIndexes, i)
   end
   -- table.sort (sortedIndexes)

   local sortedTable = {}
   for i = 1, #sortedIndexes, 1 do
      for j, tbls in ipairs (preSortingData) do
         if j == i then
            sortedTable[i] = tbls
         end
      end 
   end

   return sortedTable
end

function saveNewProject (fileName, Data, SavingTag)
  --[[called from main.lua create new project button]]
	--[[fileName --------------string --------------------name of dataSavingFile
		Data-------------------Multiple-------------------any data type, preferebly table
		SavingTag--------------String---------------------name of variable or table for 												  lua code retrieval execution]]
	
  love.filesystem.write(fileName, table.show(Data, SavingTag))
end

function loadLuaFileContents (strFileName)
   --[[checks if file exists]]
	if love.filesystem.getInfo (strFileName) then 
      --[[assigns function that loads data contained in file to variable]]
		local loadData = love.filesystem.load(strFileName) 
      --[[calls the function which loads it data back to the globApp.projects table]]
		loadData() 
	end
end

function updatedProjectAvailability ()

  local availability = false

   if #globApp.projects >= 1 then

      availability = true

  end 

	globApp.projectAvailable = availability
end

function deletedProject (t, projectID)
   -- convert id to index number
   local deletingIndex = ""
   for i, prjt in ipairs (globApp.projects) do
      if projectID == prjt.ID then 
         -- print ("index= " .. i .. " / " .. prjt.ID .. " found ")
         deletingIndex = i
      end
   end
   -- delete converted index number
   for j = #t,1,-1 do
      if j == deletingIndex then
         -- print ("deleting index = " .. j)
         table.remove(t,j)
         globApp.projectsTblChanged = true
      end
   end
   saveNewProject ("savedProjectData.lua", globApp.projects, "globApp.projects")
end

function overWriteProjectData (id, dataLabel, newValue)

   for i, prjt in ipairs (globApp.projects) do
      if id == prjt.ID then 
         -- print ("before " .. prjt[dataLabel])
         prjt[dataLabel] = newValue

         -- print ("index= " .. i .. " / " .. prjt.ID .. " found /" .. prjt[dataLabel]) 

         sortProjectsTable()

         saveNewProject ("savedProjectData.lua", globApp.projects, "globApp.projects")

         globApp.projectsTblChanged = true

      end
   end

end

--[[
   Author: Julio Manuel Fernandez-Diaz
   Date:   January 12, 2007
   (For Lua 5.1)
   Modified slightly by RiciLake to avoid the unnecessary table traversal in tablecount()
   Formats tables with cycles recursively to any depth.
   The output is returned as a string.
   References to other tables are shown as values.
   Self references are indicated.
   The string returned is "Lua code", which can be procesed
   				(in the case in which indent is composed by spaces or "--").
   Userdata and function keys and values are shown as strings,
   which logically are exactly not equivalent to the original code.
   This routine can serve for pretty formating tables with
   proper indentations, apart from printing them:
      print(table.show(t, "t"))   -- a typical use
   Heavily based on "Saving tables with cycles", PIL2, p. 113.
   Arguments:
      t is the table.
      name is the name of the table (optional)
      indent is a first indentation (optional).
--]]
function table.show(t, name, indent)
    local cart     -- a container
    local autoref  -- for self references
 
    			--counts the number of elements in a table
	-- local function tablecount(t)
	--    local n = 0
	--    for _, _ in pairs(t) do n = n+1 end
	--    return n
	-- end

    -- (RiciLake) returns true if the table is empty
    local function isemptytable(t) return next(t) == nil end
 
    local function basicSerialize (o)
       local so = tostring(o)
       if type(o) == "function" then
          local info = debug.getinfo(o, "S")
          -- info.name is nil because o is not a calling level
          if info.what == "C" then
             return string.format("%q", so .. ", C function")
          else
             -- the information is defined through lines
             return string.format("%q", so .. ", defined in (" ..
                 info.linedefined .. "-" .. info.lastlinedefined ..
                 ")" .. info.source)
          end
       elseif type(o) == "number" or type(o) == "boolean" then
          return so
       else
          return string.format("%q", so)
       end
    end
 
    local function addtocart (value, name, indent, saved, field)
       indent = indent or ""
       saved = saved or {}
       field = field or name
 
       cart = cart .. indent .. field
 
       if type(value) ~= "table" then
          cart = cart .. " = " .. basicSerialize(value) .. ";\n"
       else
          if saved[value] then
             cart = cart .. " = {}; -- " .. saved[value]
                         .. " (self reference)\n"
             autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
          else
             saved[value] = name
             --if tablecount(value) == 0 then
             if isemptytable(value) then
                cart = cart .. " = {};\n"
             else
                cart = cart .. " = {\n"
                for k, v in pairs(value) do
                   k = basicSerialize(k)
                   local fname = string.format("%s[%s]", name, k)
                   field = string.format("[%s]", k)
                   -- three spaces between levels
                   addtocart(v, fname, indent .. "   ", saved, field)
                end
                cart = cart .. indent .. "};\n"
             end
          end
       end
    end
 
    name = name or "__unnamed__"
    if type(t) ~= "table" then
       return name .. " = " .. basicSerialize(t)
    end
    cart, autoref = "", ""
    addtocart(t, name, indent)
    return cart .. autoref
 end

--loads all available project data from file system files see lib
 loadLuaFileContents ("savedProjectData.lua") 