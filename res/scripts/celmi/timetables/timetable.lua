local timetableHelper = require "celmi/timetables/timetable_helper"
local guard = require "celmi/timetables/guard"

--[[
timetable = {
	line = {
		stations = { stationinfo }
		hasTimetable = true
		frequency = 1 :: int
	}
}

stationInfo = {
	conditions = {condition :: Condition},
	vehiclesWaiting = {
		vehicleNumber = {
			slot = {}
			departureTime = 1 :: int
		}
	}
}

conditions = {
	type = "None"| "ArrDep" | "debounce" | "moreFancey"
	ArrDep = {}
	debounce  = {}
	moreFancey = {}
}

ArrDep = {
	[1] = 12 -- arrival minute
	[2] = 30 -- arrival second
	[3] = 15 -- departure minute
	[4] = 00 -- departure second
}
--]]

local timetable = { }
local timetableObject = { }

function timetable.getTimetableObject()
	return timetableObject
end

function timetable.setTimetableObject(t)
	if t then
		-- make sure the line is a number
		local keysToPatch = { }
		for lineID, lineInfo in pairs(t) do
			if type(lineID) == "string" then
				table.insert(keysToPatch, lineID)
			end
		end
		
		for _, lineID in pairs(keysToPatch) do
			print("timetable: patching lineID: " .. lineID .. " to be a number")
			local lineInfo = t[lineID]
			t[lineID] = nil
			t[tonumber(lineID)] = lineInfo
		end
		
		timetableObject = nil
		timetableObject = t
		-- print("timetable after loading and processing:")
		-- print(timetableHelper.dump(timetableObject))
	end
end

function timetable.setConditionType(line, stationNumber, type)
	local stationID = timetableHelper.getStationID(line, stationNumber)
	if not(line and stationNumber) then return -1 end

	if not timetableObject[line] then
		timetableObject[line] = { hasTimetable = false, stations = {} }
	end
	if not timetableObject[line].stations[stationNumber] then
		timetableObject[line].stations[stationNumber] = { stationID = stationID, conditions = {} }
	end

	local stopInfo = timetableObject[line].stations[stationNumber]
	stopInfo.conditions.type = type

	if not stopInfo.conditions[type] then 
		stopInfo.conditions[type] = {}
	end
	
	if type == "ArrDep" then
		if not stopInfo.vehiclesWaiting then
			stopInfo.vehiclesWaiting = {}
		end
	else
		stopInfo.vehiclesWaiting = nil
	end
end

function timetable.getConditionType(line, stationNumber)
	if not(line and stationNumber) then return "ERROR" end
	if timetableObject[line] and timetableObject[line].stations[stationNumber] then
		if timetableObject[line].stations[stationNumber].conditions.type then
			return timetableObject[line].stations[stationNumber].conditions.type
		else
			timetableObject[line].stations[stationNumber].conditions.type = "None"
			return "None"
		end
	else
		return "None"
	end
end

-- reorders the constraints into the structure res[stationID][lineID][stopNr] = 
-- only returns stations that have constraints
function timetable.getConstraintsByStation()
	local res = { }
	for lineID, lineInfo in pairs(timetableObject) do
		for stopNr, stopInfo in pairs(lineInfo.stations) do
			if stopInfo.stationID and stopInfo.conditions and  stopInfo.conditions.type and not (stopInfo.conditions.type == "None")  then
				if not res[stopInfo.stationID] then res[stopInfo.stationID] = {} end
				if not res[stopInfo.stationID][lineID] then res[stopInfo.stationID][lineID] = {} end
				res[stopInfo.stationID][lineID][stopNr] = stopInfo
			end
		end
	end
	
	return res
end

function timetable.getAllConditionsOfAllStations()
	local res = { }
	for k,v in pairs(timetableObject) do
		for _,v2 in pairs(v.stations) do
			if v2.stationID and v2.conditions and  v2.conditions.type and not (v2.conditions.type == "None")  then
				if not res[v2.stationID] then res[v2.stationID] = {} end
				res[v2.stationID][k] = {
					conditions = v2.conditions
				}
			end
		end
	end
	return res
end

function timetable.getConditions(line, stationNumber, type)
	if not(line and stationNumber) then return -1 end
	if timetableObject[line]
	   and timetableObject[line].stations[stationNumber]
	   and timetableObject[line].stations[stationNumber].conditions[type] then
		return timetableObject[line].stations[stationNumber].conditions[type]
	else
		return -1
	end
end

function timetable.addFrequency(line, frequency)
	if not timetableObject[line] then return end
	timetableObject[line].frequency = frequency
end

-- TEST: timetable.addCondition(1,1,{type = "ArrDep", ArrDep = {{12,14,14,14}}})
function timetable.addCondition(line, stationNumber, condition)
	local stationID = timetableHelper.getStationID(line, stationNumber)
	if not(line and stationNumber and condition) then return -1 end

	if timetableObject[line] and timetableObject[line].stations[stationNumber] then
		if condition.type == "ArrDep" then
			timetable.setConditionType(line, stationNumber, condition.type)
			local arrDepCond = timetableObject[line].stations[stationNumber].conditions.ArrDep
			local mergedArrays = timetableHelper.mergeArray(arrDepCond, condition.ArrDep)
			timetableObject[line].stations[stationNumber].conditions.ArrDep = mergedArrays
		elseif condition.type == "debounce" then
			timetableObject[line].stations[stationNumber].conditions.type = "debounce"
			timetableObject[line].stations[stationNumber].conditions.debounce = condition.debounce
		elseif condition.type == "auto_debounce" then
			timetableObject[line].stations[stationNumber].conditions.type = "auto_debounce"
			timetableObject[line].stations[stationNumber].conditions.auto_debounce = condition.auto_debounce
		elseif condition.type == "moreFancey" then
			timetableObject[line].stations[stationNumber].conditions.type = "moreFancey"
			timetableObject[line].stations[stationNumber].conditions.moreFancey = condition.moreFancey
		end
		timetableObject[line].stations[stationNumber].stationID = stationID

	else
		if not timetableObject[line] then
			timetableObject[line] = {hasTimetable = false, stations = {}}
		end
		timetableObject[line].stations[stationNumber] = {
			stationID = stationID,
			conditions = condition
		}
	end
end

function timetable.insertArrDepCondition(line, station, indexKey, condition)
	if not(line and station and indexKey and condition) then return -1 end
	if timetableObject[line] and
	   timetableObject[line].stations[station] and
	   timetableObject[line].stations[station].conditions and
	   timetableObject[line].stations[station].conditions.ArrDep and
	   timetableObject[line].stations[station].conditions.ArrDep[indexKey] then
		table.insert(timetableObject[line].stations[station].conditions.ArrDep, indexKey, condition)
		return 0
	else
		return -2
	end
end

function timetable.updateArrDep(line, station, indexKey, indexValue, value)
	if not (line and station and indexKey and indexValue and value) then return -1 end
	if timetableObject[line] and
	   timetableObject[line].stations[station] and
	   timetableObject[line].stations[station].conditions and
	   timetableObject[line].stations[station].conditions.ArrDep and
	   timetableObject[line].stations[station].conditions.ArrDep[indexKey] and
	   timetableObject[line].stations[station].conditions.ArrDep[indexKey][indexValue] then
	   timetableObject[line].stations[station].conditions.ArrDep[indexKey][indexValue] = value
		return 0
	else
		return -2
	end
end

function timetable.updateDebounce(line, station, indexKey, value, debounceType)
	if not (line and station and indexKey and value) then return -1 end
	if timetableObject[line] and
	   timetableObject[line].stations[station] and
	   timetableObject[line].stations[station].conditions and
	   timetableObject[line].stations[station].conditions[debounceType] then
	   timetableObject[line].stations[station].conditions[debounceType][indexKey] = value
		return 0
	else
		return -2
	end
end

function timetable.removeAllConditions(line, station, type)
	if not(line and station) or (not (timetableObject[line]
	   and timetableObject[line].stations[station])) then
		return -1
	end

	timetableObject[line].stations[station].conditions[type] = {}
end

function timetable.removeCondition(line, station, type, index)
	if not(line and station and index) or (not (timetableObject[line]
	   and timetableObject[line].stations[station])) then
		return -1
	end

	if type == "ArrDep" then
		local tmpTable = timetableObject[line].stations[station].conditions.ArrDep
		if tmpTable and tmpTable[index] then return table.remove(tmpTable, index) end
	else
		-- just remove the whole condition
		local tmpTable = timetableObject[line].stations[station].conditions[type]
		if tmpTable and tmpTable[index] then timetableObject[line].stations[station].conditions[type] = {} end
		return 0
	end
	return -1
end

function timetable.hasTimetable(line)
	if timetableObject[line] then
		return timetableObject[line].hasTimetable
	else
		return false
	end
end

function timetable.updateFor(line, vehicles)
	for _, vehicle in pairs(vehicles) do
		local vehicleInfo = timetableHelper.getVehicleInfo(vehicle)
		if vehicleInfo then
			if timetable.hasTimetable(line) then
				timetable.updateForVehicle(vehicle, vehicleInfo, line, vehicles)
			elseif not vehicleInfo.autoDeparture then
				timetableHelper.restartAutoVehicleDeparture(vehicle)
			end
		end
	end
end

function timetable.updateForVehicle(vehicle, vehicleInfo, line, vehicles)
	if timetableHelper.isVehicleAtTerminal(vehicleInfo) then
		local stop = vehicleInfo.stopIndex + 1

		if timetable.LineAndStationHasTimetable(line, stop) then
			timetable.departIfReady(vehicle, vehicleInfo, vehicles, line, stop)
		elseif not vehicleInfo.autoDeparture then
			timetableHelper.restartAutoVehicleDeparture(vehicle)
		end

	elseif not vehicleInfo.autoDeparture then
		timetableHelper.restartAutoVehicleDeparture(vehicle)
	end
end

function timetable.LineAndStationHasTimetable(line, stop)
	if not timetableObject[line].stations[stop] then return false end
	if not timetableObject[line].stations[stop].conditions then return false end
	if not timetableObject[line].stations[stop].conditions.type then return false end
	return not (timetableObject[line].stations[stop].conditions.type == "None")
end

function timetable.departIfReady(vehicle, vehicleInfo, vehicles, line, stop)
	if vehicleInfo.autoDeparture then
		timetableHelper.stopAutoVehicleDeparture(vehicle)
	elseif vehicleInfo.doorsOpen then
		local arrivalTime = math.floor(vehicleInfo.doorsTime / 1000000)
		if timetable.readyToDepart(vehicle, arrivalTime, vehicles, line, stop) then
			if timetable.getForceDepartureEnabled(line) then
				timetableHelper.departVehicle(vehicle)
			else
				timetableHelper.restartAutoVehicleDeparture(vehicle)
			end
		end
	end
end

function timetable.readyToDepart(vehicle, arrivalTime, vehicles, line, stop)
	if not timetableObject[line] then return end
	if not timetableObject[line].stations then return end
	if not timetableObject[line].stations[stop] then return end
	if not timetableObject[line].stations[stop].conditions then return end
	if not timetableObject[line].stations[stop].conditions.type then return end
	local conditionType = timetableObject[line].stations[stop].conditions.type

	if not timetableObject[line].stations[stop].vehiclesWaiting then
		timetableObject[line].stations[stop].vehiclesWaiting = {}
	end
	local vehiclesWaiting = timetableObject[line].stations[stop].vehiclesWaiting

	local time = timetableHelper.getTime()

	if conditionType == "ArrDep" then
		return timetable.readyToDepartArrDep(vehicle, arrivalTime, vehicles, time, line, stop, vehiclesWaiting)
	elseif conditionType == "debounce" or conditionType == "auto_debounce" then
		local debounceIsManual = conditionType == "debounce"
		return timetable.readyToDepartDebounce(vehicle, arrivalTime, vehicles, time, line, stop, vehiclesWaiting, debounceIsManual)
	end
end

---Gets the time a vehicle needs to wait for
---@param slot table in format like: {28, 45, 30, 00}
---@param arrivalTime integer for the time of arrival: 1740
---@return integer wait time: 60
function timetable.getWaitTime(slot, arrivalTime)
	local arrivalSlot = timetable.slotToArrivalSlot(slot)
	local departureSlot = timetable.slotToDepartureSlot(slot)
	if not timetable.afterArrivalSlot(arrivalSlot, arrivalTime) then
		local waitTime = (departureSlot - arrivalSlot) % 3600
		return waitTime + (arrivalSlot - arrivalTime) % 3600
	end
	if not timetable.afterDepartureSlot(arrivalSlot, departureSlot, arrivalTime) then
		return (departureSlot - arrivalTime) % 3600
	end
	return 0
end

---Gets the departure time for a vehicle
---Takes into account min and max wait times when enabled
---@param line integer the line the vehicle is only
---@param stop integer the stop on the line the vehicle is in
---@param arrivalTime integer the time the vehicle anotherVehicleArrivedEarlier
---@param waitTime integer the time the vehicle should wait for given its timetable slot
---@return integer time the vehicle should depart
function timetable.getDepartureTime(line, stop, arrivalTime, waitTime)
	local lineInfo = timetableHelper.getLineInfo(line)
	local stopInfo = lineInfo.stops[stop]
	if waitTime < 0 then waitTime = 0 end

	if timetable.getMinWaitEnabled(line) then
		if waitTime < stopInfo.minWaitingTime then
			waitTime = stopInfo.minWaitingTime
		end
	end
	if timetable.getMaxWaitEnabled(line) then
		if waitTime > stopInfo.maxWaitingTime then
			waitTime = stopInfo.maxWaitingTime
		end
	end

	return arrivalTime + waitTime
end

---Find the next valid timetable slot for given slots and arrival time
---@param vehicle integer The vehicle ID
---@param doorsTime integer The arrival time in seconds, calculated by the time the door opened.
---@param vehicles table Of vehicle IDs on this line. Currently unused.
---@param currentTime integer in seconds.
---@param line integer The line ID.
---@param stop integer The stop index (of the line).
---@param vehiclesWaiting table in format like: {[1]={arrivalTime=1800, slot={30,0,59,0}, departureTime=3540}, [2]={arrivalTime=540, slot={9,0,59,0}, departureTime=3540}}
---@return boolean readyToDepart True if ready. False if waiting.
function timetable.readyToDepartArrDep(vehicle, doorsTime, vehicles, currentTime, line, stop, vehiclesWaiting)
	local slots = timetableObject[line].stations[stop].conditions.ArrDep
	if not slots or slots == {} then
		timetableObject[line].stations[stop].conditions.type = "None"
		-- If there aren't any timetable slots, then the vehicle should depart now.
		return true
	end

	local slot = nil
	local departureTime = nil
	local validSlot = nil
	if  vehiclesWaiting[vehicle] then
		local arrivalTime = vehiclesWaiting[vehicle].arrivalTime
		slot = vehiclesWaiting[vehicle].slot
		departureTime = vehiclesWaiting[vehicle].departureTime

		-- Make sure the timetable slot for this vehicle isn't old. If it is old, remove it.
		if not arrivalTime or arrivalTime < doorsTime then
			vehiclesWaiting[vehicle] = nil
		elseif slot and departureTime then
			validSlot = timetable.arrayContainsSlot(slot, slots)
		end
	end
	
	if not validSlot then
		slot = timetable.getNextSlot(slots, doorsTime, vehiclesWaiting)
		-- getNextSlot returns nil when there are no slots. We should depart ASAP.
		if (slot == nil) then
			return true
		end
		local waitTime = timetable.getWaitTime(slot, doorsTime)
		departureTime = timetable.getDepartureTime(line, stop, doorsTime, waitTime)
		vehiclesWaiting[vehicle] = {
			arrivalTime = doorsTime,
			slot = slot,
			departureTime = departureTime
		}
	end

	return timetable.afterDepartureTime(departureTime, currentTime)
end

function timetable.setForceDepartureEnabled(line, value)
	if timetableObject[line] then
		timetableObject[line].forceDeparture = value
	end
end

function timetable.getForceDepartureEnabled(line)
	if timetableObject[line] then
		-- if true or nil
		if timetableObject[line].forceDeparture ~= true then
			return false
		end
	end

	return false
end

function timetable.setMinWaitEnabled(line, value)
	if timetableObject[line] then
		timetableObject[line].minWaitEnabled = value
	end
end

function timetable.getMinWaitEnabled(line)
	if timetableObject[line] then
		-- if true or nil
		if timetableObject[line].minWaitEnabled ~= false then
			return true
		end
	end

	return false
end

function timetable.setMaxWaitEnabled(line, value)
	if timetableObject[line] then
		timetableObject[line].maxWaitEnabled = value
	end
end

function timetable.getMaxWaitEnabled(line)
	if timetableObject[line] then
		-- if true
		if timetableObject[line].maxWaitEnabled then
			return true
		end
	end
	return false
end

function timetable.readyToDepartDebounce(vehicle, arrivalTime, vehicles, time, line, stop, vehiclesWaiting, debounceIsManual)
	local departureTime = nil

	if vehiclesWaiting[vehicle] then
		departureTime = vehiclesWaiting[vehicle].departureTime
	end

	if departureTime == nil then
		if #vehicles == 1 then
			departureTime = time -- depart now if the vehicle is the only one on the line
		elseif timetable.anotherVehicleArrivedEarlier(vehicle, arrivalTime, line, stop) then
			return false -- Unknown depart time
		elseif debounceIsManual then
			departureTime = timetable.manualDebounceDepartureTime(arrivalTime, vehicles, time, line, stop, vehiclesWaiting)
		else
			departureTime = timetable.autoDebounceDepartureTime(arrivalTime, vehicles, time, line, stop, vehiclesWaiting)
		end
		vehiclesWaiting[vehicle] = { departureTime = departureTime }
	end

	if timetable.afterDepartureTime(departureTime, time) then
		vehiclesWaiting[vehicle] = nil
		return true
	end

	return false
end

function timetable.manualDebounceDepartureTime(arrivalTime, vehicles, time, line, stop, vehiclesWaiting)
	local previousDepartureTime = timetableHelper.getPreviousDepartureTime(stop, vehicles, vehiclesWaiting)
	local condition = timetable.getConditions(line, stop, "debounce")
	if condition == -1 then condition = {0, 0} end
	if not condition[1] then condition[1] = 0 end
	if not condition[2] then condition[2] = 0 end

	local unbunchTime = timetable.minToSec(condition[1], condition[2])
	local nextDepartureTime = previousDepartureTime + unbunchTime
	local waitTime = nextDepartureTime - arrivalTime
	return timetable.getDepartureTime(line, stop, arrivalTime, waitTime)
end

function timetable.autoDebounceDepartureTime(arrivalTime, vehicles, time, line, stop, vehiclesWaiting)
	local previousDepartureTime = timetableHelper.getPreviousDepartureTime(stop, vehicles, vehiclesWaiting)
	local frequency = timetableObject[line].frequency
	if not frequency then return end

	local condition = timetable.getConditions(line, stop, "auto_debounce")
	if condition == -1 then condition = {1, 0} end
	if not condition[1] then condition[1] = 1 end
	if not condition[2] then condition[2] = 0 end

	local marginTime = timetable.minToSec(condition[1], condition[2])
	local nextDepartureTime = previousDepartureTime + frequency - marginTime
	local waitTime = nextDepartureTime - arrivalTime
	return timetable.getDepartureTime(line, stop, arrivalTime, waitTime)
end

-- Account for vehicles currently waiting or departing
function timetable.anotherVehicleArrivedEarlier(vehicle, arrivalTime, line, stop)
	local vehiclesAtStop = timetableHelper.getVehiclesAtStop(line, stop)
	if #vehiclesAtStop <= 1 then return false end
	for _, otherVehicle in pairs(vehiclesAtStop) do
		if otherVehicle ~= vehicle then
			local otherVehicleInfo = timetableHelper.getVehicleInfo(otherVehicle)
			if otherVehicleInfo.doorsOpen then
				local otherArrivalTime = math.floor(otherVehicleInfo.doorsTime / 1000000)
				return otherArrivalTime < arrivalTime
			else
				return true
			end
		end
	end
	return false
end

function timetable.setHasTimetable(line, bool)
	if timetableObject[line] then
		timetableObject[line].hasTimetable = bool
		if bool == false and timetableObject[line].stations then
			for station, _ in pairs(timetableObject[line].stations) do
				timetableObject[line].stations[station].vehiclesWaiting = {}
			end
		end
	else
		timetableObject[line] = {stations = {} , hasTimetable = bool}
	end
	return bool
end

--- Start all vehicles of given line.
---@param line number line id
function timetable.restartAutoDepartureForAllLineVehicles(line)
	for _, vehicle in pairs(timetableHelper.getVehiclesOnLine(line)) do
		timetableHelper.restartAutoVehicleDeparture(vehicle)
	end
end

-------------- UTILS FUNCTIONS ----------
function timetable.afterDepartureTime(departureTime, currentTime)
	return departureTime <= currentTime
end

function timetable.afterArrivalSlot(arrivalSlot, arrivalTime)
	local furthestFromArrivalSlot = (arrivalSlot + (30 * 60)) % 3600
	arrivalTime = arrivalTime % 3600
	if arrivalSlot < furthestFromArrivalSlot then
		return arrivalSlot <= arrivalTime and arrivalTime < furthestFromArrivalSlot
	else
		return not(furthestFromArrivalSlot <= arrivalTime and arrivalTime < arrivalSlot)
	end
end

function timetable.afterDepartureSlot(arrivalSlot, departureSlot, arrivalTime)
	arrivalTime = arrivalTime % 3600
	if arrivalSlot <= departureSlot then
		-- Eg. the arrival time is 10:00 and the departure is 12:00
		return arrivalTime < arrivalSlot or departureSlot <= arrivalTime
	else
		-- Eg. the arrival time is 59:00 and the departure is 01:00
		return arrivalTime < arrivalSlot and departureSlot <= arrivalTime
	end
end

---Find the next valid timetable slot for given slots and arrival time
---@param slots table in format like: {{30,0,59,0},{9,0,59,0}}
---@param arrivalTime number in seconds
---@param vehiclesWaiting table in format like: {[1]={slot={30,0,59,0}, departureTime=3540}, [2]={slot={9,0,59,0}, departureTime=3540}}
---@return table | nil closestSlot example: {30,0,59,0}
function timetable.getNextSlot(slots, arrivalTime, vehiclesWaiting)
	-- Put the slots in chronological order by arrival time
	table.sort(slots, function(slot1, slot2)
		local arrivalSlot1 = timetable.slotToArrivalSlot(slot1)
		local arrivalSlot2 = timetable.slotToArrivalSlot(slot2)
		return arrivalSlot1 < arrivalSlot2
	end)

	-- Find the distance from the arrival time
	local res = {diff = 3601, value = nil}
	for index, slot in pairs(slots) do
		local arrivalSlot = timetable.slotToArrivalSlot(slot)
		local diff = timetable.getTimeDifference(arrivalSlot, arrivalTime % 3600)

		if (diff < res.diff) then
			res = {diff = diff, index = index}
		end
	end

	-- Return nil when there are no contraints
	if not res.index then return nil end

	-- Split vehiclesWaiting by whether they have departed
	local waitingSlots = {}
	local departedSlots = {}
	if #slots == 1 then
		for vehicle, _ in pairs(vehiclesWaiting) do
			vehiclesWaiting[vehicle] = nil
		end
	else
		for vehicle, waitingVehicle in pairs(vehiclesWaiting) do
			local departureTime = waitingVehicle.departureTime
			local slot = waitingVehicle.slot
			-- Remove waitingVehicle if it is in invalid format
			if not (departureTime and slot) then
				vehiclesWaiting[vehicle] = nil
			elseif arrivalTime <= departureTime then
				waitingSlots[vehicle] = slot
			else
				departedSlots[vehicle] = slot
			end
		end
	end

	-- Find if the slot with the closest arrival time is currently being used
	-- If true, find the next consecutive available slot
	for i = res.index, #slots + res.index - 1 do
		-- Need to make sure that 2 mod 2 returns 2 rather than 0
		local normalisedIndex = ((i - 1) % #slots) + 1

		local slot = slots[normalisedIndex]
		local slotAvailable = true
		if timetable.arrayContainsSlot(slot, waitingSlots) then
			slotAvailable = false
			-- if the nearest slot is still waiting, then all departedSlots can be removed
			for vehicle, _ in pairs(departedSlots) do
				vehiclesWaiting[vehicle] = nil
				departedSlots[vehicle] = nil
			end
		else
			-- if the nearest slot is a departed, all other departedSlots can be removed
			for vehicle, departedSlot in pairs(departedSlots) do
				if timetable.slotsEqual(slot, departedSlot) then
					slotAvailable = false
				else
					vehiclesWaiting[vehicle] = nil
					departedSlots[vehicle] = nil
				end
			end
		end

		if slotAvailable then
			return slot
		end
	end

	-- If all slots are being used, still return the closest slot anyway.
	return slots[res.index]
end

function timetable.arrayContainsSlot(slot, slotArray)
	for key, slotItem in pairs(slotArray) do
		if timetable.slotsEqual(slotItem, slot) then
			return true
		end
	end
	return false
end

function timetable.slotsEqual(slot1, slot2)
	if slot1 == slot2 then
		return true
	elseif (
		slot1[1] == slot2[1] and 
		slot1[2] == slot2[2] and
		slot1[3] == slot2[3] and
		slot1[4] == slot2[4]
	) then
		return true
	end
	return false
end

function timetable.slotToArrivalSlot(slot)
	guard.againstNil(slot)
	return timetable.minToSec(slot[1], slot[2])
end

function timetable.slotToDepartureSlot(slot)
	guard.againstNil(slot)
	return timetable.minToSec(slot[3], slot[4])
end

function timetable.minToSec(min, sec)
	return min * 60 + sec
end

function timetable.secToMin(sec)
	local min = math.floor(sec / 60) % 60
	local sec = math.floor(sec % 60)
	return min, sec
end

function timetable.minToStr(min, sec)
	return string.format("%02d:%02d", min, sec)
end

function timetable.secToStr(sec)
	local min, sec = timetable.secToMin(sec)
	return timetable.minToStr(min, sec)
end

function timetable.deltaSecToStr(deltaSec)
	return math.floor(deltaSec / 6) / 10
end

---Calculates the time difference between two timestamps in seconds.
---Considers that 59 mins is close to 0 mins.
---@param a number in seconds between in range of 0-3599 (inclusive)
---@param b number in seconds between in range of 0-3599 (inclusive)
---@return number
function timetable.getTimeDifference(a, b)
	local absDiff = math.abs(a - b)
	if absDiff > 1800 then
		return 3600 - absDiff
	else
		return absDiff
	end
end

---Shifts a time in minutes and seconds by some offset
---Helper function for shiftSlot() 
---@param time table in format like: {28,45}
---@param offset number in seconds 
---@return table shifted time, example: {30,0}
function timetable.shiftTime(time, offset)
	local timeSeconds = (time + offset) % 3600
	return {math.floor(timeSeconds / 60), timeSeconds % 60}
end


---Shifts a slot by some offset
---@param slot table in format like: {30,0,59,0}
---@param offset number in seconds 
---@return table slot shifted time, example: {31,0,0,0}
function timetable.shiftSlot(slot, offset)
	local arrivalSlot = timetable.slotToArrivalSlot(slot)
	local shiftArr = timetable.shiftTime(arrivalSlot, offset)
	local departureSlot = timetable.slotToDepartureSlot(slot)
	local shiftDep = timetable.shiftTime(departureSlot, offset)
	return {shiftArr[1], shiftArr[2], shiftDep[1], shiftDep[2]}
end

-- removes old lines from timetable
function timetable.cleanTimetable()
	for lineID, _ in pairs(timetableObject) do
		if not timetableHelper.lineExists(lineID) then
			timetableObject[lineID] = nil
			print("removed line " .. lineID)
		else
			local stations = timetableHelper.getAllStations(lineID)
			for stationID = #stations + 1, #timetableObject[lineID].stations, 1 do
				timetableObject[lineID].stations[stationID] = nil
				print("removed station " .. stationID)
			end
		end
	end
end

return timetable
