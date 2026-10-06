-- This is the type system for the Net API as it exists in C++ code.

local signal = require("@Luwow/signal")
type Signal<T...> = signal.Signal<T...>

--[=[
	Members shared by every socket.
	A socket is closed automatically when garbage collected.
]=]
export type BaseSocket = {
	-- The local IP address the socket is bound to.
	read localAddress: string,
	-- The local port the socket is bound to.
	read localPort: number,
	-- The current timeout in seconds, nil when operations wait forever.
	read timeout: number?,
	-- Whether `close` has been called.
	read closed: boolean,

	--[=[
		Sets how long operations wait before giving up.

		@param seconds The timeout in seconds, nil waits forever (the default).
	]=]
	setTimeout: (self: BaseSocket, seconds: number?) -> (),

	--[=[
		Closes the socket. Closing twice does nothing.
		An operation waiting on the socket from another thread is woken up.
	]=]
	close: (self: BaseSocket) -> (),
}

--[=[
	A connected TCP socket, from `net.tcpConnect` or `TcpServer:accept`.
]=]
export type TcpSocket = BaseSocket & {
	-- The IP address of the other end.
	read remoteAddress: string,
	-- The port of the other end.
	read remotePort: number,

	-- Fires with the data each time some arrives. Reading it (or `disconnected`) makes the socket
	-- read through its events: `receive` can't be used anymore, and the program stays alive until
	-- the socket closes. Needs the task library.
	read received: Signal<string>,
	-- Fires once when the other end closes the connection or it fails. The socket is closed by then.
	read disconnected: Signal<()>,

	--[=[
		Sends all of the data. Raises an error if the timeout passes first.

		@param data The bytes to send.
	]=]
	send: (self: TcpSocket, data: string | buffer) -> (),

	--[=[
		Receives the bytes that have arrived, waiting for at least one.

		@param count The most bytes to receive, defaults to 4096.
		@return The bytes received. An empty string once the other end closed the connection, nil on timeout.
	]=]
	receive: (self: TcpSocket, count: number?) -> string?,
}

--[=[
	A listening TCP socket, from `net.tcpListen`.
]=]
export type TcpServer = BaseSocket & {
	-- Fires with each incoming connection. Reading it makes the server accept through its events:
	-- `accept` can't be used anymore, and the program stays alive until the server closes.
	-- Needs the task library.
	read connected: Signal<TcpSocket>,

	--[=[
		Waits for the next incoming connection.

		@return The connection, or nil on timeout.
	]=]
	accept: (self: TcpServer) -> TcpSocket?,
}

--[=[
	A UDP socket, from `net.udpBind`.
]=]
export type UdpSocket = BaseSocket & {
	-- Fires with each datagram and its sender. Reading it makes the socket read through its events:
	-- `receiveFrom` can't be used anymore, and the program stays alive until the socket closes.
	-- Needs the task library.
	read received: Signal<string, string, number>,

	--[=[
		Sends one datagram. The host is resolved for the socket's address family.

		@param data The bytes to send.
		@param host The host name or IP address to send to.
		@param port The port to send to.
	]=]
	sendTo: (self: UdpSocket, data: string | buffer, host: string, port: number) -> (),

	--[=[
		Waits for the next datagram.

		@param count The most bytes to receive, defaults to 65536. A longer datagram raises an error on Windows and is cut off elsewhere.
		@return The data and the sender's address and port, or nil on timeout.
	]=]
	receiveFrom: (self: UdpSocket, count: number?) -> (string?, string?, number?),
}

local net = {}

--[=[
	Connects to a TCP server, trying each address of the host until one accepts.

	@param host The host name or IP address to connect to.
	@param port The port to connect to.
	@param timeout How long each attempt may take in seconds, waits as long as the system allows when nil.
	@return The connected socket.
]=]
function net.tcpConnect(host: string, port: number, timeout: number?): TcpSocket
    return nil :: any
end

--[=[
	Starts a TCP server.

	@param port The port to listen on, 0 picks a free port (read it from `server.localPort`).
	@param host The address to listen on, defaults to `"0.0.0.0"` (every IPv4 interface). Use `"::"` for IPv6.
	@param backlog How many connections may wait to be accepted, defaults to the system's maximum.
	@return The listening server.
]=]
function net.tcpListen(port: number, host: string?, backlog: number?): TcpServer
    return nil :: any
end

--[=[
	Opens a UDP socket.

	@param port The port to bind to, defaults to 0, which picks a free port.
	@param host The address to bind to, defaults to `"0.0.0.0"` (every IPv4 interface). Use `"::"` for IPv6.
	@return The bound socket.
]=]
function net.udpBind(port: number?, host: string?): UdpSocket
    return nil :: any
end

--[=[
	Resolves a host name.

	@param host The host name to resolve.
	@return Its numeric IPv4 and IPv6 addresses, without duplicates.
]=]
function net.resolve(host: string): { string }
    return nil :: any
end

return table.freeze(net)
