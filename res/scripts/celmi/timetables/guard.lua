local guard = { }

function guard.againstNil(parameter)
	if (parameter == nil) then
		local calling_func = debug.getinfo(2)
		print("Timetables 1.3 ERROR - " .. calling_func.name .. "() - nil parameter")
		print(debug.traceback())
	end
end

return guard
