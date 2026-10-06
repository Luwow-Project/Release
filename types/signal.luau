-- This is the type system for the Signal API as it exists in C++ code.

--[=[
	A handler's link to its signal, returned by `connect` and `once`.
]=]
export type Connection = {
	-- Whether the handler is still connected.
	read connected: boolean,

	--[=[
		Disconnects the handler. Disconnecting twice does nothing.
	]=]
	disconnect: (self: Connection) -> (),
}

--[=[
	An event that handlers connect to. T... are the values it's fired with.
]=]
export type Signal<T...> = {
	--[=[
		Connects a handler. Each fire runs it in its own coroutine, so it may yield, for example with `task.wait`.

		@param handler The function to run on each fire.
		@return The connection, to disconnect the handler later.
	]=]
	connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,

	--[=[
		Connects a handler that's disconnected after the next fire.

		@param handler The function to run on the next fire.
		@return The connection, to disconnect the handler before it runs.
	]=]
	once: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,

	--[=[
		Yields the current coroutine until the next fire.

		@return The values the signal was fired with.
	]=]
	wait: (self: Signal<T...>) -> T...,

	--[=[
		Runs every connected handler, and resumes the coroutines waiting on the signal.
		Handlers connected or disconnected while it runs only take effect from the next fire.
		An error in a handler is reported and doesn't stop the others.

		@param ... The values to pass to the handlers.
		@return Whether a handler or waiting coroutine ran.
	]=]
	fire: (self: Signal<T...>, T...) -> boolean,

	--[=[
		Disconnects every handler.
	]=]
	disconnectAll: (self: Signal<T...>) -> (),
}

local signal = {}

--[=[
	Creates a signal.

	@return A signal with no handlers.
]=]
function signal.new<T...>(): Signal<T...>
    return nil :: any
end

return table.freeze(signal)
