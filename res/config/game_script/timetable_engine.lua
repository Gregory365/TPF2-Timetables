local timetable = require "celmi/timetables/timetable"
local timetableHelper = require "celmi/timetables/timetable_helper"

local time = 0
local clockstate = nil

local timetableEngine = {}

local co = nil
local state = nil

local timetableChanged = false

-------------------------------------------------------------
--------------------- OTHER ---------------------------------
-------------------------------------------------------------
function timetableEngine.timetableCoroutine()
	local lastUpdate = -1

	while true do
		-- only run once a second to avoid unnecessary cpu usage
		while timetableHelper.getTime() - lastUpdate < 1 do
			coroutine.yield()
		end
		lastUpdate = timetableHelper.getTime()
		local vehicleLineMap = api.engine.system.transportVehicleSystem.getLine2VehicleMap()
		
		for line, vehicles in pairs(vehicleLineMap) do
			timetable.updateFor(line, vehicles)
			coroutine.yield()
		end
		--- timetable.cleanTimetable()
		coroutine.yield()
	end
end

function data()
	return {
		--engine Thread
		handleEvent = function (_, id, _, param)
			if id == "timetableUpdate" then
				if state == nil then state = {timetable = {}} end
				state.timetable = param
				timetable.setTimetableObject(state.timetable)
				timetableChanged = true
			end
		end,
		
		save = function()
			-- save happens once for both threads to verify loading and saving works
			-- then the engine thread repeatedly saves its state for the gui thread to load
			state = {}
			state.timetable = timetable.getTimetableObject()
			
			return state
		end,
		
		load = function(loadedState)
			-- load happens once for engine thread and repeatedly for gui thread
			state = loadedState or {timetable = {}}
			
			timetable.setTimetableObject(state.timetable)
		end,
		
		update = function()
			if state == nil then state = {timetable = {}} end
			if co == nil or coroutine.status(co) == "dead" then
				co = coroutine.create(timetableEngine.timetableCoroutine)
			end
			for _ = 0, 20 do
				local coroutineStatus = coroutine.status(co)
				if coroutineStatus == "suspended" then
					local err, msg = coroutine.resume(co)
					if not err then print("Timetables coroutine error: " .. tostring(msg)) end
				else
					print("Timetables failed to resume " .. coroutineStatus .. " coroutine.")
				end
			end
			
			-- TODO: check if needed
			state.timetable = timetable.getTimetableObject()
			
			local lines = game.interface.getLines()
			for _, line in pairs(lines) do
				timetable.addFrequency(line, timetableHelper.getFrequency(line))
			end
		end,
	}
end

