-- This is the type system for the GUI API as it exists in C++ code.

--[=[
	The base common window descriptor for UI components.
]=]
export type CommonWindowDescriptor = {
    Left: number?,
    Top: number?,
    Width: number?,
    Height: number?
}

--[=[
	The descriptor types for each component.
]=]

export type WindowDescriptor = CommonWindowDescriptor & {
    Type: "Window",
    Title: string,
}

export type ButtonDescriptor = CommonWindowDescriptor & {
    Type: "Button",
    Caption: string,
    OnPressed: () -> (),
}

export type MenuItemDescriptor = {
    Type: "MenuItem",
    Title: string,
    OnSelected: () -> (),
}

export type MenuDescriptor = {
    Type: "Menu",
    Title: string,
    Items: { MenuItemDescriptor },
}

export type MenuBarDescriptor = {
    Type: "MenuBar",
    Menus: { MenuDescriptor },
}

export type WindowDescriptors = WindowDescriptor | ButtonDescriptor | MenuBarDescriptor

--[=[
	The types for each component object.
]=]

export type Window = {
    --[=[
		Shows the window.

		@param Window The window object
	]=]
    show: (Window) -> (),

    --[=[
		Closes the window.

		@param Window The window object
	]=]
    close: (Window) -> ()
}

export type Button = {}

export type MenuBar = {}

export type Gui = {
    --[=[
		Creates a new Window with the given descriptor.

		@param descriptor The window descriptor that defines the properties of the window.
		@return The new Window object.
	]=]
    createWindow: (descriptor: WindowDescriptor) -> Window,

    --[=[
		Creates a new Button with the given descriptor.

		@param descriptor The button descriptor that defines the properties of the button.
		@param parent The parent Window object.
		@return The new Button object.
	]=]
    createButton: (descriptor: ButtonDescriptor, parent: Window) -> Button,
    
    --[=[
		Creates a new MenuBar with the given descriptor.

		@param descriptor The menu bar descriptor that defines the properties of the menu bar.
		@param parent The parent Window object.
		@return The new MenuBar object.
	]=]
    createMenuBar: (descriptor: MenuBarDescriptor, parent: Window) -> MenuBar
}

return table.freeze({} :: Gui)
