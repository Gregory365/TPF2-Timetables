local timetable = require "celmi/timetables/timetable"
local timetableHelper = require "celmi/timetables/timetable_helper"

local gui = require "gui"

local time = 0
local clockstate = nil

local menu = {window = nil, lineTableItems = {}, popUp = nil}
local timetableGUI = {}

local UIState = {
	currentlySelectedLineTableIndex = nil ,
	currentlySelectedStationIndex = nil,
	currentlySelectedConstraintType = nil,
	currentlySelectedStationTabStation = nil
}
local co = nil
local state = nil

local timetableChanged = false

local stationTableScrollOffset
local lineTableScrollOffset
local constraintTableScrollOffset

local UIStrings = {
		arr	= _("arr_i18n"),
		arrival	= _("arrival_i18n"),
		dep	= _("dep_i18n"),
		departure = _("departure_i18n"),
		unbunch_time = _("unbunch_time_i18n"),
		unbunch	= _("unbunch_i18n"),
		auto_unbunch = _("auto_unbunch_i18n"),
		timetable = _("timetable_i18n"),
		timetables = _("timetables_i18n"),
		line = _("line_i18n"),
		lines = _("lines_i18n"),
		min	= _("time_min_i18n"),
		sec	= _("time_sec_i18n"),
		stations = _("stations_i18n"),
		frequency = _("frequency_i18n"),
		journey_time = _("journey_time_i18n"),
		arr_dep	= _("arr_dep_i18n"),
		no_timetable = _("no_timetable_i18n"),
		all	= _("all_i18n"),
		add	= _("add_i18n"),
		none = _("none_i18n"),
		tooltip	= _("tooltip_i18n")
}

local local_styles = {
	zh_CN = "timetable-mono-sc",
	zh_TW = "timetable-mono-tc",
	ja = "timetable-mono-ja",
	kr = "timetable-mono-kr"
}

-------------------------------------------------------------
---------------------- stationTab ---------------------------
-------------------------------------------------------------
-- abbreviated prefix: st
function timetableGUI.initStationTab()
	if menu.stationTabScrollArea then UIState.floatingLayoutStationTab:removeItem(menu.scrollArea) end

	--left table
	local stationOverview = api.gui.comp.TextView.new('StationOverview')
	menu.stationTabScrollArea = api.gui.comp.ScrollArea.new(stationOverview, "timetable.stationTabStationOverviewScrollArea")
	menu.stStations = api.gui.comp.Table.new(1, 'SINGLE')
	menu.stationTabScrollArea:setMinimumSize(api.gui.util.Size.new(320, 720))
	menu.stationTabScrollArea:setMaximumSize(api.gui.util.Size.new(320, 720))
	menu.stationTabScrollArea:setContent(menu.stStations)
	timetableGUI.stFillStations()
	UIState.floatingLayoutStationTab:addItem(menu.stationTabScrollArea,0,0)

	local lineOverview = api.gui.comp.TextView.new('LineOverview')
	menu.stationTabLinesScrollArea = api.gui.comp.ScrollArea.new(lineOverview, "timetable.stationTabLinesScrollArea")
	menu.stationTabLinesTable = api.gui.comp.Table.new(1, 'NONE')
	menu.stationTabLinesScrollArea:setMinimumSize(api.gui.util.Size.new(880, 720))
	menu.stationTabLinesScrollArea:setMaximumSize(api.gui.util.Size.new(880, 720))
	-- menu.stationTabLinesTable:setColWidth(0,23)
	-- menu.stationTabLinesTable:setColWidth(1,150)

	menu.stationTabLinesScrollArea:setContent(menu.stationTabLinesTable)
	UIState.floatingLayoutStationTab:addItem(menu.stationTabLinesScrollArea,1,0)
end

-- fills the station table on the left side with all stations that have constraints
function timetableGUI.stFillStations()
	-- list all stations that are part of a timetable 
	timetable.cleanTimetable() -- remove old lines no longer in the game
	--timetableChanged = true
	--timetableChanged = false

	menu.stStations:deleteAll()
	local stationNameOrder = {} -- used to sort the lines by name

	-- add stations from timetable data
	for stationID, stationInfo in pairs(timetable.getConstraintsByStation()) do
		local stationName = timetableHelper.getStationName(stationID)
		if not (stationName == -1) then
			local stationNameTextView = api.gui.comp.TextView.new(tostring(stationName))
			menu.stStations:addRow({stationNameTextView})
			stationNameOrder[#stationNameOrder + 1] = stationName
		end
	end

	local order = timetableHelper.getOrderOfArray(stationNameOrder)
	menu.stStations:setOrder(order)
	menu.stStations:onSelect(timetableGUI.stFillLines)
  
	-- select last station again
	if UIState.currentlySelectedStationTabStation
	   and menu.stStations:getNumRows() > UIState.currentlySelectedStationTabStation  then
		menu.stStations:select(UIState.currentlySelectedStationTabStation, true)
	end
end

-- fills the line table on the right side with all lines that stop at the selected station
function timetableGUI.stFillLines(tabIndex)
	-- setting up internationalization
	local lang = api.util.getLanguage()
	local local_style = {local_styles[lang.code]}

	-- resetting line info
	if tabIndex == - 1 then return end
	UIState.currentlySelectedStationTabStation = tabIndex
	menu.stationTabLinesTable:deleteAll()

	-- get station data for tab
	-- since the order is the same, we can use the index to get the data
	local stationData
	local stationIndex = 0
	for stationID, data in pairs(timetable.getConstraintsByStation()) do
		if stationIndex == tabIndex then
			stationData = data
			break
		end
		stationIndex = stationIndex + 1
	end

	-- add stops and lines to table
	local lineNameOrder = {}
	for lineID, lineData in pairs(stationData) do
		for stopNr, stopData in pairs(lineData) do

			-- create container to hold line info
			-- local lineInfoBox =  api.gui.comp.List.new(false, api.gui.util.Orientation.VERTICAL, false)
			local lineInfoBox = api.gui.comp.Table.new(1, 'NONE')

			-- add line name
			local lineColourTV = api.gui.comp.TextView.new("●")
			---@diagnostic disable-next-line: param-type-mismatch
			lineColourTV:setName("timetable-linecolour-" .. timetableHelper.getLineColour(tonumber(lineID)))
			lineColourTV:setStyleClassList({"timetable-linecolour"})

			local lineName = timetableHelper.getLineName(lineID) .. " - Stop " .. stopNr
			local lineNameTV = api.gui.comp.TextView.new(lineName)

			local lineNameBox = api.gui.comp.Table.new(2, 'NONE')
			lineNameBox:setColWidth(0, 25)
			lineNameBox:addRow({lineColourTV, lineNameTV})

			lineInfoBox:addRow({lineNameBox})

			-- add constraint info
			local type = timetableHelper.conditionToString(stopData.conditions[stopData.conditions.type], lineID, stopData.conditions.type)
			local stConditionString = api.gui.comp.TextView.new(type)
			stConditionString:setName("conditionString")
			stConditionString:setStyleClassList(local_style)

			lineInfoBox:addRow({stConditionString})

			 -- add line table
			menu.stationTabLinesTable:addRow({lineInfoBox})
			lineNameOrder[#lineNameOrder + 1] = lineName
		end
	end
	local order = timetableHelper.getOrderOfArray(lineNameOrder)
	menu.stationTabLinesTable:setOrder(order)
end

-------------------------------------------------------------
---------------------- SETUP --------------------------------
-------------------------------------------------------------
function timetableGUI.initLineTable()
	if menu.scrollArea then
		local tmp = menu.scrollArea:getScrollOffset()
		lineTableScrollOffset = api.type.Vec2i.new(tmp.x, tmp.y)
		UIState.boxlayout2:removeItem(menu.scrollArea)
	else
		lineTableScrollOffset = api.type.Vec2i.new()
	end
	if menu.lineHeader then UIState.boxlayout2:removeItem(menu.lineHeader) end


	local lineOverwiew = api.gui.comp.TextView.new('LineOverview')
	menu.scrollArea = api.gui.comp.ScrollArea.new(lineOverwiew, "timetable.LineOverview")
	menu.lineTable = api.gui.comp.Table.new(3, 'SINGLE')
	menu.lineTable:setColWidth(0,28)

	menu.lineTable:onSelect(function(index)
		if not index == -1 then UIState.currentlySelectedLineTableIndex = index end
		UIState.currentlySelectedStationIndex = 0
		timetableGUI.fillStationTable(index, true)
	end)

	menu.lineTable:setColWidth(1,240)

	menu.scrollArea:setMinimumSize(api.gui.util.Size.new(320, 690))
	menu.scrollArea:setMaximumSize(api.gui.util.Size.new(320, 690))
	menu.scrollArea:setContent(menu.lineTable)

	timetableGUI.fillLineTable()

	UIState.boxlayout2:addItem(menu.scrollArea,0,1)
end

function timetableGUI.initStationTable()
	if menu.stationScrollArea then
		local tmp = menu.stationScrollArea:getScrollOffset()
		stationTableScrollOffset = api.type.Vec2i.new(tmp.x, tmp.y)
	else
		local stationScrollArea = api.gui.comp.TextView.new('stationScrollArea')
		stationTableScrollOffset = api.type.Vec2i.new()
		menu.stationScrollArea = api.gui.comp.ScrollArea.new(stationScrollArea, "timetable.stationScrollArea")
		menu.stationScrollArea:setMinimumSize(api.gui.util.Size.new(560, 730))
		menu.stationScrollArea:setMaximumSize(api.gui.util.Size.new(560, 730))
		UIState.boxlayout2:addItem(menu.stationScrollArea,0.5,0)
	end

	menu.stationTableHeader = api.gui.comp.Table.new(1, 'NONE')
	menu.stationTable = api.gui.comp.Table.new(4, 'SINGLE')
	menu.stationTable:setColWidth(0,40)
	menu.stationTable:setColWidth(1,120)
	menu.stationTableHeader:addRow({menu.stationTable})
	menu.stationScrollArea:setContent(menu.stationTableHeader)
end

function timetableGUI.initConstraintTable()
	if menu.scrollAreaConstraint then
		local tmp = menu.scrollAreaConstraint:getScrollOffset()
		constraintTableScrollOffset = api.type.Vec2i.new(tmp.x, tmp.y)
	else
		constraintTableScrollOffset = api.type.Vec2i.new()
		local scrollAreaConstraint = api.gui.comp.TextView.new('scrollAreaConstraint')
		menu.scrollAreaConstraint = api.gui.comp.ScrollArea.new(scrollAreaConstraint, "timetable.scrollAreaConstraint")
		menu.scrollAreaConstraint:setMinimumSize(api.gui.util.Size.new(320, 730))
		menu.scrollAreaConstraint:setMaximumSize(api.gui.util.Size.new(320, 730))
		UIState.boxlayout2:addItem(menu.scrollAreaConstraint,1,0)
	end

	menu.constraintTable = api.gui.comp.Table.new(1, 'NONE')
	menu.constraintHeaderTable = api.gui.comp.Table.new(1, 'NONE')
	menu.constraintContentTable = api.gui.comp.Table.new(1, 'NONE')
	menu.constraintTable:addRow({menu.constraintHeaderTable})
	menu.constraintTable:addRow({menu.constraintContentTable})
	menu.scrollAreaConstraint:setContent(menu.constraintTable)
end

function timetableGUI.showLineMenu()
	if menu.window ~= nil then
		timetableGUI.initLineTable()
		return menu.window:setVisible(true, true)
	end
	if not api.gui.util.getById('timetable.floatingLayout') then
		local floatingLayout = api.gui.layout.FloatingLayout.new(0,1)
		floatingLayout:setId("timetable.floatingLayout")
	end
	-- new folting layout to arrange all members

	UIState.boxlayout2 = api.gui.util.getById('timetable.floatingLayout')
	UIState.boxlayout2:setGravity(-1,-1)

	timetableGUI.initLineTable()
	timetableGUI.initStationTable()
	timetableGUI.initConstraintTable()

	-- Setting up Line Tab
	menu.tabWidget = api.gui.comp.TabWidget.new("NORTH")
	local wrapper = api.gui.comp.Component.new("wrapper")
	wrapper:setLayout(UIState.boxlayout2 )
	menu.tabWidget:addTab(api.gui.comp.TextView.new(UIStrings.lines), wrapper)

	if not api.gui.util.getById('timetable.floatingLayoutStationTab') then
		local floatingLayout = api.gui.layout.FloatingLayout.new(0,1)
		floatingLayout:setId("timetable.floatingLayoutStationTab")
	end

	UIState.floatingLayoutStationTab = api.gui.util.getById('timetable.floatingLayoutStationTab')
	UIState.floatingLayoutStationTab:setGravity(-1,-1)

	timetableGUI.initStationTab()
	local wrapper2 = api.gui.comp.Component.new("wrapper2")
	local stationsString = api.gui.comp.TextView.new(UIStrings.stations) 
	wrapper2:setLayout(UIState.floatingLayoutStationTab)
	menu.tabWidget:addTab(stationsString, wrapper2)

	menu.tabWidget:onCurrentChanged(function(i)
		if i == 1 then
			timetableGUI.stFillStations()
		end
	end)

	-- create final window
	menu.window = api.gui.comp.Window.new(UIStrings.timetables, menu.tabWidget)
	menu.window:addHideOnCloseHandler()
	menu.window:setMovable(true)
	menu.window:setPinButtonVisible(true)
	menu.window:setResizable(false)
	menu.window:setSize(api.gui.util.Size.new(1202, 802))
	menu.window:setPosition(200,200)
	menu.window:onClose(function()
		menu.lineTableItems = {}
	end)
end

-------------------------------------------------------------
---------------------- LEFT TABLE ---------------------------
-------------------------------------------------------------
function timetableGUI.fillLineTable()
	menu.lineTable:deleteRows(0,menu.lineTable:getNumRows())
	if not (menu.lineHeader == nil) then menu.lineHeader:deleteRows(0,menu.lineHeader:getNumRows()) end

	menu.lineHeader = api.gui.comp.Table.new(6, 'None')
	local sortAll   = api.gui.comp.ToggleButton.new(api.gui.comp.TextView.new(UIStrings.all))
	local sortBus   = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_road_vehicles.tga"))
	local sortTram  = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/tram/TimetableTramIcon.tga"))
	local sortRail  = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_trains.tga"))
	local sortWater = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_ships.tga"))
	local sortAir   = api.gui.comp.ToggleButton.new(api.gui.comp.ImageView.new("ui/icons/game-menu/hud_filter_planes.tga"))

	menu.lineHeader:addRow({sortAll,sortBus,sortTram,sortRail,sortWater,sortAir})

	local lineNames = {}
	for k,v in pairs(timetableHelper.getAllLines()) do
		local lineColour = api.gui.comp.TextView.new("●")
		lineColour:setName("timetable-linecolour-" .. timetableHelper.getLineColour(v.id))
		lineColour:setStyleClassList({"timetable-linecolour"})
		local lineName = api.gui.comp.TextView.new(v.name)
		lineNames[k] = v.name
		lineName:setName("timetable-linename")
		local buttonImage = api.gui.comp.ImageView.new("ui/checkbox0.tga")
		if timetable.hasTimetable(v.id) then buttonImage:setImage("ui/checkbox1.tga", false) end
		local button = api.gui.comp.Button.new(buttonImage, true)
		button:setStyleClassList({"timetable-activateTimetableButton"})
		button:setGravity(1,0.5)
		button:onClick(function()
			local imageView = buttonImage
			local hasTimetable = timetable.hasTimetable(v.id)
			if  hasTimetable then
				timetable.setHasTimetable(v.id,false)
				timetableChanged = true
				imageView:setImage("ui/checkbox0.tga", false)
				-- start all stopped vehicles again if the timetable is disabled for this line
				timetable.restartAutoDepartureForAllLineVehicles(v.id)
			else
				timetable.setHasTimetable(v.id,true)
				timetableChanged = true
				imageView:setImage("ui/checkbox1.tga", false)
			end
		end)
		menu.lineTableItems[#menu.lineTableItems + 1] = {lineColour, lineName, button}
		menu.lineTable:addRow({lineColour,lineName, button})
	end

	local order = timetableHelper.getOrderOfArray(lineNames)
	menu.lineTable:setOrder(order)

	sortAll:onToggle(function()
		for _,v in pairs(menu.lineTableItems) do
				v[1]:setVisible(true,false)
				v[2]:setVisible(true,false)
				v[3]:setVisible(true,false)
		end
		sortBus:setSelected(false,false)
		sortTram:setSelected(false,false)
		sortRail:setSelected(false,false)
		sortWater:setSelected(false,false)
		sortAir:setSelected(false,false)
		sortAll:setSelected(true,false)
	end)

	sortBus:onToggle(function()
		local linesOfType = timetableHelper.isLineOfType("ROAD")
		for k,v in pairs(menu.lineTableItems) do
			if not(linesOfType[k] == nil) then
				v[1]:setVisible(linesOfType[k],false)
				v[2]:setVisible(linesOfType[k],false)
				v[3]:setVisible(linesOfType[k],false)
			end
		end
		sortBus:setSelected(true,false)
		sortTram:setSelected(false,false)
		sortRail:setSelected(false,false)
		sortWater:setSelected(false,false)
		sortAir:setSelected(false,false)
		sortAll:setSelected(false,false)
	end)

	sortTram:onToggle(function()
		local linesOfType = timetableHelper.isLineOfType("TRAM")
		for k,v in pairs(menu.lineTableItems) do
			if not(linesOfType[k] == nil) then
				v[1]:setVisible(linesOfType[k],false)
				v[2]:setVisible(linesOfType[k],false)
				v[3]:setVisible(linesOfType[k],false)
			end
		end
		sortBus:setSelected(false,false)
		sortTram:setSelected(true,false)
		sortRail:setSelected(false,false)
		sortWater:setSelected(false,false)
		sortAir:setSelected(false,false)
		sortAll:setSelected(false,false)
	end)

	sortRail:onToggle(function()
		local linesOfType = timetableHelper.isLineOfType("RAIL")
		for k,v in pairs(menu.lineTableItems) do
			if not(linesOfType[k] == nil) then
				v[1]:setVisible(linesOfType[k],false)
				v[2]:setVisible(linesOfType[k],false)
				v[3]:setVisible(linesOfType[k],false)
			end
		end
		sortBus:setSelected(false,false)
		sortTram:setSelected(false,false)
		sortRail:setSelected(true,false)
		sortWater:setSelected(false,false)
		sortAir:setSelected(false,false)
		sortAll:setSelected(false,false)
	end)

	sortWater:onToggle(function()
		local linesOfType = timetableHelper.isLineOfType("WATER")
		for k,v in pairs(menu.lineTableItems) do
			if not(linesOfType[k] == nil) then
				v[1]:setVisible(linesOfType[k],false)
				v[2]:setVisible(linesOfType[k],false)
				v[3]:setVisible(linesOfType[k],false)
			end
		end
		sortBus:setSelected(false,false)
		sortTram:setSelected(false,false)
		sortRail:setSelected(false,false)
		sortWater:setSelected(true,false)
		sortAir:setSelected(false,false)
		sortAll:setSelected(false,false)
	end)

	sortAir:onToggle(function()
		local linesOfType = timetableHelper.isLineOfType("AIR")
		for k,v in pairs(menu.lineTableItems) do
			if not(linesOfType[k] == nil) then
				v[1]:setVisible(linesOfType[k],false)
				v[2]:setVisible(linesOfType[k],false)
				v[3]:setVisible(linesOfType[k],false)
			end
		end
		sortBus:setSelected(false,false)
		sortTram:setSelected(false,false)
		sortRail:setSelected(false,false)
		sortWater:setSelected(false,false)
		sortAir:setSelected(true,false)
		sortAll:setSelected(false,false)
	end)

	UIState.boxlayout2:addItem(menu.lineHeader,0,0)
	menu.scrollArea:invokeLater( function () 
		menu.scrollArea:invokeLater(function () 
			menu.scrollArea:setScrollOffset(lineTableScrollOffset) 
		end) 
	end)
end

-------------------------------------------------------------
---------------------- Middle TABLE -------------------------
-------------------------------------------------------------
-- params
-- index: index of currently selected line
-- bool: emit select signal when building table
function timetableGUI.fillStationTable(index, bool)
	local lang = api.util.getLanguage()
	local local_style = {local_styles[lang.code]}

	--initial checks
	if not index then return end
	if not(timetableHelper.getAllLines()[index+1]) or (not menu.stationTable)then return end

	-- initial cleanup
	menu.stationTable:deleteAll()

	UIState.currentlySelectedLineTableIndex = index
	local lineID = timetableHelper.getAllLines()[index+1].id
	local headerTable = timetableGUI.stationTableHeader(lineID)
	local vehicleType = timetableHelper.getLineType(lineID)
	menu.stationTableHeader:setHeader({headerTable})

	local stationLegTime = timetableHelper.getLegTimes(lineID)
	--iterate over all stations to display them
	for k, v in pairs(timetableHelper.getAllStations(lineID)) do
		menu.lineImage = {}
		local vehiclePositions = timetableHelper.getTrainLocations(lineID)
		if vehiclePositions[k-1] then
			if vehiclePositions[k-1].atTerminal then
				if vehiclePositions[k-1].countStr == "MANY" then
					menu.lineImage[k] = api.gui.comp.ImageView.new("ui/"..vehicleType.."/timetable_line_"..vehicleType.."_in_station_many.tga")
				else
					menu.lineImage[k] = api.gui.comp.ImageView.new("ui/"..vehicleType.."/timetable_line_"..vehicleType.."_in_station.tga")
				end
			else
				if vehiclePositions[k-1].countStr == "MANY" then
					menu.lineImage[k] = api.gui.comp.ImageView.new("ui/"..vehicleType.."/timetable_line_"..vehicleType.."_en_route_many.tga")
				else
					menu.lineImage[k] = api.gui.comp.ImageView.new("ui/"..vehicleType.."/timetable_line_"..vehicleType.."_en_route.tga")
				end
			end
		else
			menu.lineImage[k] = api.gui.comp.ImageView.new("ui/timetable_line.tga")
		end
		local x = menu.lineImage[k]
		menu.lineImage[k]:onStep(function()
			if not x then print("ERRROR") return end
			local vehiclePositions2 = timetableHelper.getTrainLocations(lineID)
			if vehiclePositions2[k-1] then
				if vehiclePositions2[k-1].atTerminal then
					if vehiclePositions2[k-1].countStr == "MANY" then
						x:setImage("ui/"..vehicleType.."/timetable_line_"..vehicleType.."_in_station_many.tga", false)
					else
						x:setImage("ui/"..vehicleType.."/timetable_line_"..vehicleType.."_in_station.tga", false)
					end
				else
					if vehiclePositions2[k-1].countStr == "MANY" then
						x:setImage("ui/"..vehicleType.."/timetable_line_"..vehicleType.."_en_route_many.tga", false)
					else
						x:setImage("ui/"..vehicleType.."/timetable_line_"..vehicleType.."_en_route.tga", false)
					end
				end
			else
				x:setImage("ui/timetable_line.tga", false)
			end
		end)

		local station = timetableHelper.getStation(v)
		local stationNumber = api.gui.comp.TextView.new(tostring(k))

		stationNumber:setStyleClassList({"timetable-stationcolour"})
		stationNumber:setName("timetable-stationcolour-" .. timetableHelper.getLineColour(lineID))
		stationNumber:setMinimumSize(api.gui.util.Size.new(30, 30))

		local stationName = api.gui.comp.TextView.new(station.name)
		stationName:setName("stationName")

		local jurneyTime
		if (stationLegTime and stationLegTime[k]) then
			jurneyTime = api.gui.comp.TextView.new(UIStrings.journey_time .. ": " .. os.date('%M:%S', stationLegTime[k]))
		else
			jurneyTime = api.gui.comp.TextView.new("")
		end
		jurneyTime:setName("conditionString")
		jurneyTime:setStyleClassList(local_style)

		local stationNameTable = api.gui.comp.Table.new(1, 'NONE')
		stationNameTable:addRow({stationName})
		stationNameTable:addRow({jurneyTime})
		stationNameTable:setColWidth(0,120)

		local conditionType = timetable.getConditionType(lineID, k)
		local condStr = timetableHelper.conditionToString(timetable.getConditions(lineID, k, conditionType), lineID, conditionType)
		local conditionString = api.gui.comp.TextView.new(condStr)
		conditionString:setName("conditionString")
		conditionString:setStyleClassList(local_style)

		conditionString:setMinimumSize(api.gui.util.Size.new(360,50))
		conditionString:setMaximumSize(api.gui.util.Size.new(360,50))

		menu.stationTable:addRow({stationNumber,stationNameTable, menu.lineImage[k], conditionString})
	end

	menu.stationTable:onSelect(function (tableIndex)
		if not (tableIndex == -1) then
			UIState.currentlySelectedStationIndex = tableIndex
			timetableGUI.initConstraintTable()
			timetableGUI.fillConstraintTable(tableIndex,lineID)
		end
	end)

	-- keep track of currently selected station and resets if nessesarry
	if UIState.currentlySelectedStationIndex then
		if menu.stationTable:getNumRows() > UIState.currentlySelectedStationIndex and not(menu.stationTable:getNumRows() == 0) then
			menu.stationTable:select(UIState.currentlySelectedStationIndex, bool)
		else
			timetableGUI.initConstraintTable()
		end
	end
	menu.stationScrollArea:invokeLater(function () 
		menu.stationScrollArea:invokeLater(function () 
			menu.stationScrollArea:setScrollOffset(stationTableScrollOffset) 
		end) 
	end)
end

function timetableGUI.stationTableHeader(lineID)
	-- force departure setting
	local forceDepLabel = api.gui.comp.TextView.new("Force departure")
	forceDepLabel:setGravity(1,0.5)
	local forceDepImage = api.gui.comp.ImageView.new("ui/checkbox0.tga")
	if timetable.getForceDepartureEnabled(lineID) then forceDepImage:setImage("ui/checkbox1.tga", false) end
	local forceDepButton = api.gui.comp.Button.new(forceDepImage, true)
	forceDepButton:setStyleClassList({"timetable-activateTimetableButton"})
	forceDepButton:setGravity(0,0.5)
	forceDepButton:onClick(function()
		local forceDepEnabled = timetable.getForceDepartureEnabled(lineID)
		if forceDepEnabled then
			timetable.setForceDepartureEnabled(lineID, false)
			forceDepImage:setImage("ui/checkbox0.tga", false)
		else
			timetable.setForceDepartureEnabled(lineID, true)
			forceDepImage:setImage("ui/checkbox1.tga", false)
		end
		timetableChanged = true
	end)

	-- minimum wait setting
	local minButtonLabel = api.gui.comp.TextView.new("Min. wait enabled")
	minButtonLabel:setGravity(1,0.5)
	local minButtonImage = api.gui.comp.ImageView.new("ui/checkbox0.tga")
	if timetable.getMinWaitEnabled(lineID) then minButtonImage:setImage("ui/checkbox1.tga", false) end
	local minButton = api.gui.comp.Button.new(minButtonImage, true)
	minButton:setStyleClassList({"timetable-activateTimetableButton"})
	minButton:setGravity(0,0.5)
	minButton:onClick(function()
		local minEnabled = timetable.getMinWaitEnabled(lineID)
		if minEnabled then
			timetable.setMinWaitEnabled(lineID, false)
			minButtonImage:setImage("ui/checkbox0.tga", false)
		else
			timetable.setMinWaitEnabled(lineID, true)
			minButtonImage:setImage("ui/checkbox1.tga", false)
		end
		timetableChanged = true
	end)

	-- maximum wait setting
	local maxButtonLabel = api.gui.comp.TextView.new("Max. wait enabled")
	maxButtonLabel:setGravity(1,0.5)
	local maxButtonImage = api.gui.comp.ImageView.new("ui/checkbox0.tga")
	if timetable.getMaxWaitEnabled(lineID) then maxButtonImage:setImage("ui/checkbox1.tga", false) end
	local maxButton = api.gui.comp.Button.new(maxButtonImage, true)
	maxButton:setStyleClassList({"timetable-activateTimetableButton"})
	maxButton:setGravity(0,0.5)
	maxButton:onClick(function()
		local maxEnabled = timetable.getMaxWaitEnabled(lineID)
		if maxEnabled then
			timetable.setMaxWaitEnabled(lineID, false)
			maxButtonImage:setImage("ui/checkbox0.tga", false)
		else
			timetable.setMaxWaitEnabled(lineID, true)
			maxButtonImage:setImage("ui/checkbox1.tga", false)
		end
		timetableChanged = true
	end)

	local headerTable = api.gui.comp.Table.new(7, 'None')
	headerTable:addRow({
		api.gui.comp.TextView.new(UIStrings.frequency .. " " .. timetableHelper.getFrequencyString(lineID)),
		forceDepLabel, forceDepButton, minButtonLabel, minButton, maxButtonLabel, maxButton
	})
	--headerTable:addRow({})

	return headerTable
end

-------------------------------------------------------------
---------------------- Right TABLE --------------------------
-------------------------------------------------------------
function timetableGUI.clearConstraintWindow()
	-- initial cleanup
	menu.constraintHeaderTable:deleteRows(1, menu.constraintHeaderTable:getNumRows())
end

function timetableGUI.fillConstraintTable(index,lineID)
	--initial cleanup
	if index == -1 then
		menu.constraintHeaderTable:deleteAll()
		return
	end
	index = index + 1
	menu.constraintHeaderTable:deleteAll()


	-- combobox setup
	local comboBox = api.gui.comp.ComboBox.new()
	comboBox:addItem(UIStrings.no_timetable)
	comboBox:addItem(UIStrings.arr_dep)
	--comboBox:addItem("Minimum Wait")
	comboBox:addItem(UIStrings.unbunch)
	comboBox:addItem(UIStrings.auto_unbunch)
	--comboBox:addItem("Every X minutes")
	comboBox:setGravity(1,0)

	UIState.currentlySelectedConstraintType = timetableHelper.constraintStringToInt(timetable.getConditionType(lineID, index))


	comboBox:onIndexChanged(function (i)
		if not api.engine.entityExists(lineID) then 
			return
		end
		if i == -1 then return end
		local constraintType = timetableHelper.constraintIntToString(i)
		timetable.setConditionType(lineID, index, constraintType)
		conditions = timetable.getConditions(lineID, index, constraintType)
		if conditions == -1 then return end
		if constraintType == "debounce" then
			if not conditions[1] then conditions[1] = 0 end
			if not conditions[2] then conditions[2] = 0 end
		elseif constraintType == "auto_debounce" then
			if not conditions[1] then conditions[1] = 1 end
			if not conditions[2] then conditions[2] = 0 end
		end

		if i ~= UIState.currentlySelectedConstraintType then
			timetableChanged = true
			timetableGUI.initStationTable()
			timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
			UIState.currentlySelectedConstraintType = i
		end

		timetableGUI.clearConstraintWindow()
		menu.constraintContentTable:deleteAll()
		if i == 1 then
			timetableGUI.makeArrDepWindow(lineID, index)
		elseif i == 2 then
			timetableGUI.makeDebounceWindow(lineID, index, "debounce")
		elseif i == 3 then
			timetableGUI.makeDebounceWindow(lineID, index, "auto_debounce")
		end
	end)


	local infoImage = api.gui.comp.ImageView.new("ui/info_small.tga")
	infoImage:setTooltip(UIStrings.tooltip)
	infoImage:setName("timetable-info-icon")

	local table = api.gui.comp.Table.new(2, 'NONE')
	table:addRow({infoImage,comboBox})
	menu.constraintHeaderTable:addRow({table})
	comboBox:setSelected(UIState.currentlySelectedConstraintType, true)
	menu.scrollAreaConstraint:invokeLater(function ()
		menu.scrollAreaConstraint:invokeLater(function () 
			menu.scrollAreaConstraint:setScrollOffset(constraintTableScrollOffset) 
		end) 
	end)
end

function timetableGUI.makeArrDepWindow(lineID, stationID)
	if not menu.constraintTable then return end
	if not menu.constraintHeaderTable then return end

	-- setup separation selector
	local separationList = {30, 20, 15, 12, 10, 7.5, 6, 5, 4, 3, 2.5, 2, 1.5, 1.2, 1}
	local separationCombo = api.gui.comp.ComboBox.new()
	for k,v in ipairs(separationList) do 
		separationCombo:addItem(v .. " min (" .. 60 / v .. "/h)")
	end
	separationCombo:setGravity(1,0)
	
	-- setup generate button
	local generate = function(separationIndex, templateArrDep)
		if separationIndex  == -1 then return end
		if templateArrDep  == -1 then return end

		-- generate recurring conditions
		local separation = separationList[separationIndex + 1]
		for i = 1, 60 / separation - 1 do
			timetable.addCondition(lineID,stationID, {type = "ArrDep", ArrDep = {timetable.shiftSlot(templateArrDep, i * separation * 60)}})
		end

		-- cleanup
		timetableChanged = true
		timetableGUI.initStationTable()
		timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
		timetableGUI.makeArrDepConstraintsTable(lineID, stationID)
	end
	local generateButton = api.gui.comp.Button.new(api.gui.comp.TextView.new("Generate"), true)
	generateButton:setGravity(1, 0)
	generateButton:onClick(function()
		-- preparation
		local conditions = timetable.getConditions(lineID,stationID, "ArrDep")
		if conditions == -1 or #conditions < 1 then
			timetableGUI.popUpMessage("You must have one initial arrival / departure time", function() end)
			return
		end

		local separationIndex = separationCombo:getCurrentIndex()
		if separationIndex == -1 then -- no separation selected
			timetableGUI.popUpMessage("You must select a separation", function() end)
			return
		end

		if #conditions > 1 then
			generateButton:setEnabled(false)
			-- "Regenerate will replace current timetable"
			timetableGUI.popUpYesNo("Override?", function()
				local condition1 = conditions[1]
				timetable.removeAllConditions(lineID, stationID, "ArrDep")
				timetable.addCondition(lineID, stationID, {type = "ArrDep", ArrDep = {condition1}})
				generate(separationIndex, condition1)
				generateButton:setEnabled(true)
			end, function()
				generateButton:setEnabled(true)
			end)
		else
			generate(separationIndex, conditions[1])
		end
	end)

	-- setup recurring departure generator
	local recurringTable = api.gui.comp.Table.new(3, 'NONE')
	recurringTable:addRow({api.gui.comp.TextView.new("Separation"),separationCombo,generateButton})
	menu.constraintHeaderTable:addRow({recurringTable})


	-- setup add button
	local addButton = api.gui.comp.Button.new(api.gui.comp.TextView.new(UIStrings.add), true)
	addButton:setGravity(-1,0)
	addButton:onClick(function()
		timetable.addCondition(lineID,stationID, {type = "ArrDep", ArrDep = {{0,0,0,0}}})
		timetableChanged = true

			timetableGUI.initStationTable()
			timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
			timetableGUI.makeArrDepConstraintsTable(lineID, stationID)
	end)

	-- setup deleteButton button
	local deleteButton = api.gui.comp.Button.new(api.gui.comp.TextView.new("X All"), true)
	deleteButton:setGravity(-1,0)
	deleteButton:onClick(function()
		deleteButton:setEnabled(false)

		timetableGUI.popUpYesNo("Delete All?", function()
			timetable.removeAllConditions(lineID, stationID, "ArrDep")
			timetableChanged = true
			timetableGUI.initStationTable()
			timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
			timetableGUI.makeArrDepConstraintsTable(lineID, stationID)
			
			deleteButton:setEnabled(true)
		end, function()
			deleteButton:setEnabled(true)
		end)
	end)

	--setup header
	local headerTable = api.gui.comp.Table.new(4, 'NONE')
	local buttonStringMin = api.gui.comp.TextView.new(UIStrings.min)
	local buttonStringSec = api.gui.comp.TextView.new(UIStrings.sec)
	headerTable:setColWidth(1,85)
	headerTable:setColWidth(2,60)
	headerTable:setColWidth(3,60)
	headerTable:addRow({addButton,buttonStringMin,buttonStringSec,deleteButton})
	menu.constraintHeaderTable:addRow({headerTable})

	timetableGUI.makeArrDepConstraintsTable(lineID, stationID)
end

function timetableGUI.makeArrDepConstraintsTable(lineID, stationID)
	local conditions = timetable.getConditions(lineID,stationID, "ArrDep")
	if conditions == -1 then return end

	menu.constraintContentTable:deleteAll()

	-- setup arrival and departure content
	for k,v in pairs(conditions) do
		local horizontalLine = api.gui.comp.Component.new("HorizontalLine")
		menu.constraintContentTable:addRow({horizontalLine})

		local arivalLabel =  api.gui.comp.TextView.new(UIStrings.arrival .. ":  ")
		arivalLabel:setMinimumSize(api.gui.util.Size.new(75, 30))

		local arrivalMin = api.gui.comp.DoubleSpinBox.new()
		arrivalMin:setMinimum(0,false)
		arrivalMin:setMaximum(59,false)
		arrivalMin:setValue(v[1],false)
		arrivalMin:onChange(function(value)
			timetable.updateArrDep(lineID, stationID, k, 1, value)
			timetableChanged = true
			timetableGUI.initStationTable()
			timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
		end)

		local minSecSeparator = api.gui.comp.TextView.new(":")

		local arrivalSec = api.gui.comp.DoubleSpinBox.new()
		arrivalSec:setMinimum(0,false)
		arrivalSec:setMaximum(59,false)
		arrivalSec:setValue(v[2],false)
		arrivalSec:onChange(function(value)
			timetable.updateArrDep(lineID, stationID, k, 2, value)
			timetableChanged = true
			timetableGUI.initStationTable()
			timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
		end)

		local deleteLabel = api.gui.comp.TextView.new("     X")
		deleteLabel:setMinimumSize(api.gui.util.Size.new(60, 10))
		local deleteButton = api.gui.comp.Button.new(deleteLabel, true)
		deleteButton:onClick(function()
			deleteButton:setEnabled(false)
			timetableGUI.popUpYesNo("Delete?", function()
				timetable.removeCondition(lineID, stationID, "ArrDep", k)
				timetableChanged = true
				timetableGUI.initStationTable()
				timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
				menu.constraintTable:invokeLater( function ()
					timetableGUI.makeArrDepConstraintsTable(lineID, stationID)
				end)

				deleteButton:setEnabled(true)
			end, function()
				deleteButton:setEnabled(true)
			end)
		end)

		local linetable = api.gui.comp.Table.new(5, 'NONE')
		linetable:addRow({
			arivalLabel,
			arrivalMin,
			minSecSeparator,
			arrivalSec,
			deleteButton
		})
		linetable:setColWidth(1, 60)
		linetable:setColWidth(2, 25)
		linetable:setColWidth(3, 60)
		linetable:setColWidth(4, 60)
		menu.constraintContentTable:addRow({linetable})

		local departureLabel =  api.gui.comp.TextView.new(UIStrings.departure .. ":  ")
		departureLabel:setMinimumSize(api.gui.util.Size.new(75, 30))

		local departureMin = api.gui.comp.DoubleSpinBox.new()
		departureMin:setMinimum(0,false)
		departureMin:setMaximum(59,false)
		departureMin:setValue(v[3],false)
		departureMin:onChange(function(value)
			timetable.updateArrDep(lineID, stationID, k, 3, value)
			timetableChanged = true
			timetableGUI.initStationTable()
			timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
		end)

		local minSecSeparator = api.gui.comp.TextView.new(":")

		local departureSec = api.gui.comp.DoubleSpinBox.new()
		departureSec:setMinimum(0,false)
		departureSec:setMaximum(59,false)
		departureSec:setValue(v[4],false)
		departureSec:onChange(function(value)
			timetable.updateArrDep(lineID, stationID, k, 4, value)
			timetableChanged = true
			timetableGUI.initStationTable()
			timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
		end)

		local insertLabel = api.gui.comp.TextView.new("     +")
		insertLabel:setMinimumSize(api.gui.util.Size.new(60, 10))
		local insertButton = api.gui.comp.Button.new(insertLabel, true)
		insertButton:onClick(function()
			timetable.insertArrDepCondition(lineID, stationID, k, {0,0,0,0})
			timetableChanged = true
			timetableGUI.initStationTable()
			timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
			menu.constraintTable:invokeLater( function ()
				timetableGUI.makeArrDepConstraintsTable(lineID, stationID)
			end)
		end)

		local linetable2 = api.gui.comp.Table.new(5, 'NONE')
		linetable2:addRow({
			departureLabel,
			departureMin,
			minSecSeparator,
			departureSec,
			insertButton
		})
		linetable2:setColWidth(1, 60)
		linetable2:setColWidth(2, 25)
		linetable2:setColWidth(3, 60)
		linetable2:setColWidth(4, 60)
		menu.constraintContentTable:addRow({linetable2})

		local horizontalLine = api.gui.comp.Component.new("HorizontalLine")
		menu.constraintContentTable:addRow({horizontalLine})
	end
end

function timetableGUI.makeDebounceWindow(lineID, stationID, debounceType)
	if not menu.constraintHeaderTable then return end
	local frequency = timetableHelper.getFrequencyMinSec(lineID)
	local condition = timetable.getConditions(lineID,stationID, debounceType)
	if condition == -1 then return end
	local autoDebounceMin = nil
	local autoDebounceSec = nil

	local updateAutoDebounce = function()
		if debounceType == "auto_debounce" then
			condition = timetable.getConditions(lineID, stationID, debounceType)
			if condition == -1 then return end
			if type(frequency) == "table" and autoDebounceMin and autoDebounceSec and condition and condition[1] and condition[2] then
				local unbunchTime = (frequency.min - condition[1]) * 60 + frequency.sec - condition[2]
				if unbunchTime >= 0 then
					autoDebounceMin:setText(tostring(math.floor(unbunchTime / 60)))
					autoDebounceSec:setText(tostring(math.floor(unbunchTime % 60)))
				else
					autoDebounceMin:setText("--")
					autoDebounceSec:setText("--")
				end
			end
		end
	end

	--setup header
	local headerTable = api.gui.comp.Table.new(3, 'NONE')
	headerTable:setColWidth(0,175)
	headerTable:setColWidth(1,85)
	headerTable:setColWidth(2,60)
	headerTable:addRow({
		api.gui.comp.TextView.new(""),
		api.gui.comp.TextView.new(UIStrings.min),
		api.gui.comp.TextView.new(UIStrings.sec)})
	menu.constraintHeaderTable:addRow({headerTable})

	local debounceTable = api.gui.comp.Table.new(4, 'NONE')
	debounceTable:setColWidth(0,175)
	debounceTable:setColWidth(1,60)
	debounceTable:setColWidth(2,25)
	debounceTable:setColWidth(3,60)

	local debounceMin = api.gui.comp.DoubleSpinBox.new()
	debounceMin:setMinimum(0,false)
	debounceMin:setMaximum(59,false)
	if debounceType == "auto_debounce" and type(frequency) == "table" then
		debounceMin:setMaximum(frequency.min,false)
	end

	debounceMin:onChange(function(value)
		timetable.updateDebounce(lineID, stationID,  1, value, debounceType)
		timetableChanged = true
		timetableGUI.initStationTable()
		timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
		updateAutoDebounce()
	end)

	if condition and condition[1] then
		debounceMin:setValue(condition[1],false)
	end

	local debounceSec = api.gui.comp.DoubleSpinBox.new()
	debounceSec:setMinimum(0,false)
	debounceSec:setMaximum(59,false)

	debounceSec:onChange(function(value)
		timetable.updateDebounce(lineID, stationID, 2, value, debounceType)
		timetableChanged = true
		timetableGUI.initStationTable()
		timetableGUI.fillStationTable(UIState.currentlySelectedLineTableIndex, false)
		updateAutoDebounce()
	end)

	if condition and condition[2] then
		debounceSec:setValue(condition[2],false)
	end

	local unbunchTimeHeader = api.gui.comp.TextView.new(UIStrings.unbunch_time .. ":")
	local textColon = api.gui.comp.TextView.new(":")
	debounceHeader = unbunchTimeHeader
	if debounceType == "auto_debounce" then debounceHeader = api.gui.comp.TextView.new("Margin Time:") end
	debounceTable:addRow({debounceHeader, debounceMin, textColon, debounceSec})

	if debounceType == "auto_debounce" then
		textColon = api.gui.comp.TextView.new(":")
		autoDebounceMin = api.gui.comp.TextView.new("--")
		autoDebounceSec = api.gui.comp.TextView.new("--")
		updateAutoDebounce()
		debounceTable:addRow({unbunchTimeHeader, autoDebounceMin, textColon, autoDebounceSec})
	end

	menu.constraintHeaderTable:addRow({debounceTable})
end

-------------------------------------------------------------
--------------------- OTHER ---------------------------------
-------------------------------------------------------------
function timetableGUI.popUpMessage(message, onOK)
	debugPrint("popUpMessage")
	if menu.popUp then
		menu.popUp:close()
	end

	local textOK = api.gui.comp.TextView.new("OK")
	local okButton = api.gui.comp.Button.new(textOK, true)
	menu.popUp = api.gui.comp.Window.new(message, okButton)
	local position = api.gui.util.getMouseScreenPos()
	menu.popUp:setPosition(position.x, position.y)
	menu.popUp:addHideOnCloseHandler()

	menu.popUp:onClose(function()
		onOK()
	end)

	okButton:onClick(function()
		menu.popUp:close()
	end)
end

function timetableGUI.popUpYesNo(title, onYes, onNo)
	if menu.popUp then
		menu.popUp:close()
	end
	
	local popUpTable = api.gui.comp.Table.new(2, 'NONE')
	local textYes = api.gui.comp.TextView.new("Yes")
	local yesButton = api.gui.comp.Button.new(textYes, true)
	local textNo = api.gui.comp.TextView.new("No")
	local noButton = api.gui.comp.Button.new(textNo, true)
	popUpTable:addRow({yesButton, noButton})

	menu.popUp = api.gui.comp.Window.new(title, popUpTable)
	local position = api.gui.util.getMouseScreenPos()
	menu.popUp:setPosition(position.x, position.y)
	menu.popUp:addHideOnCloseHandler()

	local yesPressed = false
	menu.popUp:onClose(function()
		if yesPressed then
			onYes()
		else
			onNo()
		end
		menu.popUp = nil
	end)

	yesButton:onClick(function()
		yesPressed = true
		menu.popUp:close()
	end)
	noButton:onClick(function()
		menu.popUp:close()
	end)
end

function data()
	return {
		guiUpdate = function()
			if timetableChanged then
				game.interface.sendScriptEvent("timetableUpdate", "", timetable.getTimetableObject())
				timetableChanged = false
			end

			if not clockstate then
				-- element for the divider
				local line = api.gui.comp.Component.new("VerticalLine")
				-- element for the icon
				local icon = api.gui.comp.ImageView.new("ui/clock_small.tga")
				-- element for the time
				clockstate = api.gui.comp.TextView.new("gameInfo.time.label")

				local buttonLabel = gui.textView_create("gameInfo.timetables.label", UIStrings.timetable)

				local button = gui.button_create("gameInfo.timetables.button", buttonLabel)
				button:onClick(function ()
					local err, msg = pcall(timetableGUI.showLineMenu)
					if not err then
						menu.window = nil
						print(msg)
					end
				end)
				game.gui.boxLayout_addItem("gameInfo.layout", button.id)
				-- add elements to ui
				local gameInfoLayout = api.gui.util.getById("gameInfo"):getLayout()
				gameInfoLayout:addItem(line)
				gameInfoLayout:addItem(icon)
				gameInfoLayout:addItem(clockstate)
			end

			time = timetableHelper.getTime()

			if clockstate and time then
				clockstate:setText(os.date('%M:%S', time))
			end
		end
	}
end

