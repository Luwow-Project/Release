-- This is the type system for the Task API as it exists in C++ code.

local task = {}

--[=[
	Resumes a function or thread through the scheduler immediately.

	@param functionOrThread The function or thread to resume.
	@param ... Arguments passed to it.
	@return The thread that was resumed.
]=]
function task.spawn<A...>(functionOrThread: ((A...) -> ...any) | thread, ...: A...): thread
	return nil :: any
end

--[=[
	Resumes a function or thread in the next resumption cycle.

	@param functionOrThread The function or thread to resume.
	@param ... Arguments passed to it.
	@return The scheduled thread.
]=]
function task.defer<A...>(functionOrThread: ((A...) -> ...any) | thread, ...: A...): thread
	return nil :: any
end

--[=[
	Resumes a function or thread after `seconds` have elapsed.

	@param seconds Delay in seconds, negative values are treated as 0.
	@param functionOrThread The function or thread to resume.
	@param ... Arguments passed to it.
	@return The scheduled thread.
]=]
function task.delay<A...>(seconds: number, functionOrThread: ((A...) -> ...any) | thread, ...: A...): thread
	return nil :: any
end

--[=[
	Yields the current thread for `seconds`, or until the next resumption cycle when omitted.

	@param seconds Time to wait in seconds.
	@return The actual time elapsed in seconds.
]=]
function task.wait(seconds: number?): number
	return nil :: any
end

--[=[
	Cancels a pending thread so it is never resumed.

	@param thread The thread to cancel.
]=]
function task.cancel(thread: thread): ()
	return nil :: any
end

return table.freeze(task)
