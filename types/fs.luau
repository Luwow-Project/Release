-- This is the type system for the FS API as it exists in C++ code.

export type FileType = "file" | "dir" | "symlink" | "other"

export type SeekWhence = "set" | "cur" | "end"

export type OpenMode = "r" | "w" | "a" | "r+" | "w+" | "a+"

--[=[
	Metadata returned by `fs.stat`.
]=]
export type Metadata = {
	-- The type of the path, symlinks are followed.
	type: FileType,
	-- Size in bytes, always 0 for anything that isn't a regular file.
	size: number,
	-- Last modification time as a Unix timestamp in seconds.
	modified: number,
	-- Whether the owner lacks write permission.
	readonly: boolean
}

--[=[
	An entry returned by `fs.listdir`.
]=]
export type DirEntry = {
	-- The entry's file name, without its parent directory.
	name: string,
	-- The entry's type, symlinks are not followed.
	type: FileType
}

--[=[
	Members shared by every file handle.
	The handle is closed automatically when garbage collected.
]=]
export type BaseFile = {
	-- The path the file was opened with.
	read path: string,
	-- Whether `close` has been called.
	read closed: boolean,

	--[=[
		Moves the file position and returns the new position.

		@param whence Where `offset` is relative to, defaults to `"cur"`.
		@param offset Offset in bytes, defaults to 0.
		@return The new position from the start of the file.
	]=]
	seek: (self: BaseFile, whence: SeekWhence?, offset: number?) -> number,

	--[=[
		@return The current position from the start of the file.
	]=]
	tell: (self: BaseFile) -> number,

	--[=[
		Flushes pending writes, then returns the file size.

		@return The size of the file in bytes.
	]=]
	size: (self: BaseFile) -> number,

	--[=[
		Flushes pending writes to disk.
	]=]
	flush: (self: BaseFile) -> (),

	--[=[
		Closes the file. Using any method besides `close` afterwards raises an error.
	]=]
	close: (self: BaseFile) -> ()
}

--[=[
	A file handle opened for reading.
]=]
export type ReadableFile = BaseFile & {
	--[=[
		Reads from the current position.

		@param count Number of bytes to read, reads until EOF when omitted.
		@return The bytes read, shorter than `count` at EOF.
	]=]
	read: (self: ReadableFile, count: number?) -> string
}

--[=[
	A file handle opened for writing.
]=]
export type WritableFile = BaseFile & {
	--[=[
		Writes at the current position, or at the end in append mode.

		@param data The bytes to write.
	]=]
	write: (self: WritableFile, data: string | buffer) -> ()
}

--[=[
	A file handle opened for both reading and writing.
]=]
export type ReadWriteFile = ReadableFile & WritableFile
export type File = ReadableFile | WritableFile | ReadWriteFile

type Open =
	((path: string, mode: nil) -> ReadableFile)
	& ((path: string, mode: "r") -> ReadableFile)
	& ((path: string, mode: "w") -> WritableFile)
	& ((path: string, mode: "a") -> WritableFile)
	& ((path: string, mode: "r+") -> ReadWriteFile)
	& ((path: string, mode: "w+") -> ReadWriteFile)
	& ((path: string, mode: "a+") -> ReadWriteFile)
	& ((path: string, mode: OpenMode?) -> File)

local fs = {}

--[=[
	Reads the whole file.

	@param path The file to read.
	@return The file contents.
]=]
function fs.readFile(path: string): string
    return nil :: any
end

--[=[
	Writes data to a file, creating it or truncating it.

	@param path The file to write.
	@param data The bytes to write.
]=]
function fs.writeFile(path: string, data: string | buffer): ()
    return nil :: any
end

--[=[
	Appends data to the end of a file, creating it if needed.

	@param path The file to append to.
	@param data The bytes to append.
]=]
function fs.appendFile(path: string, data: string | buffer): ()
    return nil :: any
end

--[=[
	Checks whether a path exists. Never raises an error.

	@param path The path to check.
	@return Whether the path exists.
]=]
function fs.exists(path: string): boolean
    return nil :: any
end

--[=[
	Gets the type of a path without following symlinks.

	@param path The path to check.
	@return The type of the path.
]=]
function fs.type(path: string): FileType
    return nil :: any
end

--[=[
	Gets the metadata of a path, following symlinks.

	@param path The path to inspect.
	@return The path's metadata.
]=]
function fs.stat(path: string): Metadata
    return nil :: any
end

--[=[
	Lists the entries of a directory, in no particular order.

	@param path The directory to list.
	@return The directory's entries.
]=]
function fs.listdir(path: string): { DirEntry }
    return nil :: any
end

--[=[
	Creates a directory. Without `recursive`, raises an error if it already exists.

	@param path The directory to create.
	@param recursive Also create missing parent directories.
]=]
function fs.mkdir(path: string, recursive: boolean?): ()
    return nil :: any
end

--[=[
	Removes a file. Raises an error for directories, use `fs.rmdir` instead.

	@param path The file to remove.
]=]
function fs.remove(path: string): ()
    return nil :: any
end

--[=[
	Removes a directory. Without `recursive`, the directory must be empty.

	@param path The directory to remove.
	@param recursive Also remove everything inside the directory.
]=]
function fs.rmdir(path: string, recursive: boolean?): ()
    return nil :: any
end

--[=[
	Copies a file, or a directory with all of its contents.

	@param from The path to copy.
	@param to The destination path.
	@param overwrite Replace files that already exist at the destination.
]=]
function fs.copy(from: string, to: string, overwrite: boolean?): ()
    return nil :: any
end

--[=[
	Moves or renames a file or directory.

	@param from The path to move.
	@param to The destination path.
]=]
function fs.move(from: string, to: string): ()
    return nil :: any
end

--[=[
	Opens a file handle.
	`"r"` reads an existing file, `"w"` creates or truncates, `"a"` creates and appends.
	Adding `+` allows both reading and writing.

	@param path The file to open.
	@param mode The open mode, defaults to `"r"`.
	@return The open file handle.
]=]
fs.open = (nil :: any) :: Open

return table.freeze(fs)
