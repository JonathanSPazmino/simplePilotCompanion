generateConsoleMessage ("info", "Unit testing initialized")
function gdsGUI_executeAllUnitTests (strPageName)

	--------------------------------------------------------------------------
								--LIB_GENERAL.LUA
	--------------------------------------------------------------------------
		devTest_execute {["id"]="determineSafeWindowArea(android,landscape)_test",
						["funcName"]={"determineSafeWindowArea"},
						["funcParameters"]={"landscape", "iOS", 1000, 500 ,true},
						["funcExpctOutput"]={60, 0, 880, 470}}

		devTest_execute {["id"]="determineSafeWindowArea(ios,portrait)_test",
						["funcName"]={"determineSafeWindowArea"},
						["funcParameters"]={"portrait", "Android", 1000, 500 ,true},
						["funcExpctOutput"]={0, 30, 1000, 440}}

		devTest_execute {["id"]="determineSafeWindowArea(windows,landscape)_test",
						["funcName"]={"determineSafeWindowArea"},
						["funcParameters"]={"landscape", "Windows", 1000, 500 ,true},
						["funcExpctOutput"]={0, 0, 1000, 500}}

		devTest_execute {["id"]="isTouchInSafeArea(wrongYtouch)_test",
						["funcName"]={"isTouchInSafeArea"},
						["funcParameters"]={1,-1},
						["funcExpctOutput"]={false}}

		devTest_execute {["id"]="isTouchInSafeArea(correct)_test",
						["funcName"]={"isTouchInSafeArea"},
						["funcParameters"]={globApp.safeScreenArea.x+ 1 ,globApp.safeScreenArea.y + 1},
						["funcExpctOutput"]={true}}

		devTest_execute {["id"]="relativePosition_test",
						["funcName"]={"relativePosition"},
						["funcParameters"]={"CC", .5, .85, 100, 100, 0, 0, 200, 200},
						["funcExpctOutput"]={50,120}}

		devTest_execute {["id"]="convert_scrollBarPosToDPI_test",
						["funcName"]={"convert_scrollBarPosToDPI"},
						["funcParameters"]={.5, -100, 100},
						["funcExpctOutput"]={0}}

		devTest_execute {["id"]="jpGUI_convertSafeAreaPercentToDPI_test_pass500",
						["funcName"]={"jpGUI_convertSafeAreaPercentToDPI"},
						["funcParameters"]={.5,"width",true},
						["funcExpctOutput"]={500}}

		devTest_execute {["id"]="jpGUI_convertSafeAreaPercentToDPI_test_pass400",
						["funcName"]={"jpGUI_convertSafeAreaPercentToDPI"},
						["funcParameters"]={.4,"height",true},
						["funcExpctOutput"]={400}}

		devTest_execute {["id"]="jpGUI_convertSafeAreaPercentToDPI_test_passError",
						["funcName"]={"jpGUI_convertSafeAreaPercentToDPI"},
						["funcParameters"]={.4,"height6",nil},
						["funcExpctOutput"]={"error"}}

		devTest_execute {["id"]="jpGUI_findTriangAngle_testPassWrightTriangle",
						["funcName"]={"jpGUI_findTriangAngle"},
						["funcParameters"]={1, 1, "degrees"},
						["funcExpctOutput"]={45}}

		devTest_execute {["id"]="isTextRemoveCommanded_false",
						["funcName"]={"isTextRemoveCommanded"},
						["funcParameters"]={"c"},
						["funcExpctOutput"]={false}}

		devTest_execute {["id"]="isTextRemoveCommanded_trueBackspace",
						["funcName"]={"isTextRemoveCommanded"},
						["funcParameters"]={"backspace"},
						["funcExpctOutput"]={true}}

		devTest_execute {["id"]="isTextRemoveCommanded_trueDelete",
						["funcName"]={"isTextRemoveCommanded"},
						["funcParameters"]={"delete"},
						["funcExpctOutput"]={true}}

	---------------------------------------------------------------------------
								--TABLES
	----------------------------------------------------------------------------
		local devTable = {}

		devTable[1] = {x= {name="1,2", row = 2, collumn=2}, y={name="2,3", row = 3, collumn=3},z={name="2,2", row = 2, collumn=2}}

		devTest_execute {["id"]="tableCellAddress_find(row)_test",
						["funcName"]={"tableCellAddress_find"},
						["funcParameters"]={"2,3", devTable , "row", true},
						["funcExpctOutput"]={2, 3, true}}		

		devTest_execute {["id"]="tableCellAddress_find(collumn)_test",
						["funcName"]={"tableCellAddress_find"},
						["funcParameters"]={"2,3", devTable , "collumn", true},
						["funcExpctOutput"]={3, 2, true}}


		devTest_execute {["id"]="findScreenOrientation_test",
						["funcName"]={"findScreenOrientation"},
						["funcParameters"]={800, 1000, true},
						["funcExpctOutput"]={"portrait"}}


	----------------------------------------------------------------------------
								--PAGES
	----------------------------------------------------------------------------

		devTest_execute {["id"]="isPgActive_(xp:false)test",
						["funcName"]={"isPgActive"},
						["funcParameters"]={999},
						["funcExpctOutput"]={false}}

		devTest_execute {["id"]="isPgActive_(xp:true)test",
						["funcName"]={"isPgActive"},
						["funcParameters"]={globApp.currentPageIndex},
						["funcExpctOutput"]={true}}

		devTest_execute {["id"]="returnCurrentPageName_test",
						["funcName"]={"returnCurrentPageName"},
						["funcParameters"]={globApp.currentPageIndex},
						["funcExpctOutput"]={strPageName}}

		devTest_execute {["id"]="doesPageExist_test_true",
						["funcName"]={"doesPageExist"},
						["funcParameters"]={1},
						["funcExpctOutput"]={true}}

		devTest_execute {["id"]="doesPageExist_test_false",
						["funcName"]={"doesPageExist"},
						["funcParameters"]={1000987},
						["funcExpctOutput"]={false}}


		

		local testSavedProjectTable = {[1]= {["ID"] = "P21121E74743E"}}
		local testRecIDlocator = "TST"
		for i=2, 1000, 1 do
			testSavedProjectTable [i]= {["ID"] = createNewIdNumber_gdsLove2dGUI (testSavedProjectTable, testRecIDlocator,7)}
		end

		devTest_execute {["id"]="createNewProjectData_noMatchCount",
						["funcName"]={"createNewProjectData"},
						["funcParameters"]={{15,true,"hello"},{"asldkf", 5},testSavedProjectTable, "TST", 7},
						["funcExpctOutput"]={"The data labels and data pieces count do NOT match, ref createNew ProjectData funciton and callbacks"}}

		devTest_execute {["id"]="doesSerialNumExistsInTable_true",
						["funcName"]={"doesSerialNumExistsInTable"} ,
						["funcParameters"]={testSavedProjectTable,"P21121E74743E"},
						["funcExpctOutput"]={true}}

		devTest_execute {["id"]="doesSerialNumExistsInTable_false",
						["funcName"]={"doesSerialNumExistsInTable"},
						["funcParameters"]={testSavedProjectTable,"P21121E74743F"},
						["funcExpctOutput"]={false}}

		devTest_execute {["id"]="doesTableHaveInvalidRecordsIDs_trueRecIDNotFound",
						["funcName"]={"doesTableHaveInvalidRecordsIDs"},
						["funcParameters"]={testSavedProjectTable,"NIL", 23},
						["funcExpctOutput"]={true}}


		devTest_execute {["id"]="doesTableHaveInvalidRecordsIDs_trueDueToOneInvalRecID",
						["funcName"]={"doesTableHaveInvalidRecordsIDs"},
						["funcParameters"]={testSavedProjectTable,testRecIDlocator,23},
						["funcExpctOutput"]={true}}

		table.remove(testSavedProjectTable, 1)

		devTest_execute {["id"]="doesTableHaveInvalidRecordsIDs_false",
						["funcName"]={"doesTableHaveInvalidRecordsIDs"},
						["funcParameters"]={testSavedProjectTable,testRecIDlocator, 23},
						["funcExpctOutput"]={false}}


		devTest_execute {["id"]="isTableEmpty_false",
						["funcName"]={"isTableEmpty"},
						["funcParameters"]={testSavedProjectTable},
						["funcExpctOutput"]={false}}


		local testTable = {}
			testTable[2] = {1, 2, 3}
			testTable[3] = {"yes", 1, true, 0.56}
			testTable[4] = {"no", 1, true, 0.56}

		devTest_execute {["id"]="areTwoTablesSameSize_false",
						["funcName"]={"areTwoTablesSameSize"},
						["funcParameters"]={testTable[2],testTable[3]},
						["funcExpctOutput"]={false}}

		devTest_execute {["id"]="areTwoTablesSameSize_true",
						["funcName"]={"areTwoTablesSameSize"},
						["funcParameters"]={testTable[3],testTable[4]},
						["funcExpctOutput"]={true}}

		testTable = nil
		testSavedProjectTable [50]= nil
		devTest_execute {["id"]="areThereNILvalues_trueOneValueNil",
						["funcName"]={"areThereNILvalues"},
						["funcParameters"]={testSavedProjectTable},
						["funcExpctOutput"]={true}}
		
		testSavedProjectTable [50]= "new"
		devTest_execute {["id"]="areThereNILvalues_false", 
						["funcName"]={"areThereNILvalues"}, 
						["funcParameters"]={testSavedProjectTable}, 
						["funcExpctOutput"]={false}}

		testSavedProjectTable = {}
		devTest_execute {["id"]="isTableEmpty_true", 
						["funcName"]={"isTableEmpty"}, 
						["funcParameters"]={testSavedProjectTable}, 
						["funcExpctOutput"]={true}}
		testSavedProjectTable = nil

		local testSavedProjectTable2 = {[1]= {	["ID"] = "GDSDEV2201167367319300E", 
												["data"] = {}, 
												["boolean"]= true, 
												["number"] = 6, 
												["string"] = "_trg_"} }

		local testRecIDlocator2 = "DEV"

		for i=2, 10, 1 do
			testSavedProjectTable2 [i]= {["ID"] = createNewIdNumber_gdsLove2dGUI (testSavedProjectTable2, testRecIDlocator2,7)}
		end

		devTest_execute {["id"]="findTableIndexByRecordID_rtrn1", 
						["funcName"]={"findTableIndexByRecordID"}, 
						["funcParameters"]={testSavedProjectTable2, testRecIDlocator2, "GDSDEV2201167367319300E", 23},
						["funcExpctOutput"]={1}}

		devTest_execute {["id"]="findTableIndexByRecordID_IDNot found", 
						["funcName"]={"findTableIndexByRecordID"}, 
						["funcParameters"]={testSavedProjectTable2, testRecIDlocator2, "GDSDEV0101167367319300E", 23},
						["funcExpctOutput"]={"Could Not Find the provided record ID"}}

		testSavedProjectTable2 [11]= {["ID"] = "GDSNIL2201167367319300E"}
		devTest_execute {["id"]="findTableIndexByRecordID_tableIssue", 
						["funcName"]={"findTableIndexByRecordID"}, 
						["funcParameters"]={testSavedProjectTable2, testRecIDlocator2, "GDSDEV0101167367319300E", 23},
						["funcExpctOutput"]={"there is an issue with the provided table"}}


		local testFont = love.graphics.newFont(1)
		
		local testTextTable = {}
				testTextTable[1] = "sometext"
				testTextTable[2] = "1234567810123456782012345678301234567840123456785012345678601234567870"
				testTextTable[3] = "some textsome text, more text"

		devTest_execute {["id"]="findMaxNumOfLinesNeeded_rtr5", 
						["funcName"]={"findMaxNumOfLinesNeeded"}, 
						["funcParameters"]={testFont, 10, testTextTable},
						["funcExpctOutput"]={7}}
		
		devTest_execute {["id"]="returnFontInfo",
						["funcName"]={"returnFontInfo"}, 
						["funcParameters"]={testFont, "lineHeight"}, 
						["funcExpctOutput"]={1}}

		-- ABOUT FILE CONTENTS AND EXISTENCE

		local tempTestFile001_content = "testy2 test" 
		
		local tempTestFile001 = love.filesystem.newFile("tempTestFile001.txt")
		
		tempTestFile001:open("w")
		
		devTest_execute {["id"]="doesAboutPageFileExistFalse", 
						["funcName"]={"doesAboutPageFileExist"}, 
						["funcParameters"]={"tempTestFile002.txt", true}, 
						["funcExpctOutput"]={false}}

		devTest_execute {["id"]="doesAboutPageFileExistTrue", 
						["funcName"]={"doesAboutPageFileExist"}, 
						["funcParameters"]={"tempTestFile001.txt", true}, 
						["funcExpctOutput"]={true}}

		devTest_execute {["id"]="isAboutTextFileEmptyTrue", 
						["funcName"]={"isAboutTextFileEmpty"}, 
						["funcParameters"]={"tempTestFile001.txt", true}, 
						["funcExpctOutput"]={true}}

		tempTestFile001:write(tempTestFile001_content)
		
		devTest_execute {["id"]="isAboutTextFileEmptyFalse",
						["funcName"]={"isAboutTextFileEmpty"}, 
						["funcParameters"]={"tempTestFile001.txt", true}, 
						["funcExpctOutput"]={false}}

		tempTestFile001:close()

		love.filesystem.remove( "tempTestFile001.txt" )
	

		-----------------------------------------------------------------------------------
										--INPUT TEXT BOX FUNCTION
		-----------------------------------------------------------------------------------

		devTest_execute {["id"]="inputTextBox_isNewCharInvalid_true",
						["funcName"]={"inputTextBox_isNewCharInvalid"},
						["funcParameters"]={1, {["pattern"]="%l", ["maxCharCount"]=1,["invalCharacters"]={"/"}}, 0, ""},
						["funcExpctOutput"]={true}}
-- newCharacter, tblTextSpecs, currentChrCount, currentText


		devTest_execute {["id"]="isTouchInSafeArea(correct)_test",
						["funcName"]={"isTouchInSafeArea"},
						["funcParameters"]={globApp.safeScreenArea.x + 1 ,globApp.safeScreenArea.y + 1},
						["funcExpctOutput"]={true}}

		-- devTest_execute {["id"]="createInputTextPattern_4x4alphaNumChars",
		-- 				["funcName"]={"createInputTextPattern"},
		-- 				["funcParameters"]={4, "%w*%w*%w*%w*"},
		-- 				["funcExpctOutput"]={"%w*%w*%w*%w*"}}


	--------------------------------------------------------------------------
	--writes test results to console, second argument filters result type
	write_unit_test_results ("console", "fail") 
end