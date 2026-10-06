-- This is the type system for the IO API as it exists in C++ code.

--[=[
	Which standard streams are attached to a terminal, returned by `io.isTerminal`.
]=]
export type TerminalStreams = {
	stdin: boolean,
	stdout: boolean,
	stderr: boolean
}

--[=[
	The size of the terminal in characters, returned by `io.terminalSize`.
]=]
export type TerminalSize = {
	columns: number,
	rows: number
}

local io = {}

--[=[
	Writes every argument to stdout, without separators or a trailing newline.
	Numbers are written like `tostring` would.

	@param ... The strings or buffers to write.
]=]
function io.write(...: string | buffer | number): ()
    return nil :: any
end

--[=[
	Writes every argument to stderr, without separators or a trailing newline.

	@param ... The strings or buffers to write.
]=]
function io.writeErr(...: string | buffer | number): ()
    return nil :: any
end

--[=[
	Writes out anything buffered for stdout.
]=]
function io.flush(): ()
    return nil :: any
end

--[=[
	Writes out anything buffered for stderr.
]=]
function io.flushErr(): ()
    return nil :: any
end

--[=[
	Reads bytes from stdin, waiting until `count` bytes arrived or the input ended.

	@param count The number of bytes to read.
	@return The bytes read, fewer than `count` only at the end of input. nil once the input has ended.
]=]
function io.read(count: number): string?
    return nil :: any
end

--[=[
	Reads one line from stdin.

	@param keepNewline Keep the line's `"\n"` ending, removed by default. A `"\r"` before it is always removed.
	@return The line, or nil once the input has ended.
]=]
function io.readLine(keepNewline: boolean?): string?
    return nil :: any
end

--[=[
	Reads stdin until the input ends.

	@return Everything read, an empty string if nothing was left.
]=]
function io.readAll(): string
    return nil :: any
end

--[=[
	Checks which standard streams are attached to a terminal, rather than a file or pipe.

	@return Whether stdin, stdout and stderr are terminals.
]=]
function io.isTerminal(): TerminalStreams
    return nil :: any
end

--[=[
	Gets the size of the terminal stdout is attached to.

	@return The size in characters, or nil when stdout isn't a terminal.
]=]
function io.terminalSize(): TerminalSize?
    return nil :: any
end

--[=[
	Switches stdin's raw mode. In raw mode, input is available as soon as a key is pressed
	instead of after Enter, and isn't echoed. Ctrl+C still works. The terminal is restored on exit.

	@param enabled Whether to turn raw mode on.
	@return Whether the change worked, false when stdin isn't a terminal.
]=]
function io.setRawMode(enabled: boolean): boolean
    return nil :: any
end

--[=[
	@return Whether stdin is in raw mode.
]=]
function io.isRawMode(): boolean
    return nil :: any
end

return table.freeze(io)
