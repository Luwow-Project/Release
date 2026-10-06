const task = require("@Luwow/task")
const gui = require("@Luwow/gui")

local window = gui.createWindow({
  Type = "Window" :: "Window",
  Title = "Luwow Created Window",
  Width = 400,
  Height = 300,
})

local _menuBar = gui.createMenuBar({
  Type = "MenuBar" :: "MenuBar",
  Menus = {
    {
      Type = "Menu" :: "Menu",
      Title = "&File",
      Items = {
        {
          Type = "MenuItem" :: "MenuItem",
          Title = "&Demo",
          OnSelected = function()
            print("Hello from the menu")
          end,
        },
        {
          Type = "MenuItem" :: "MenuItem",
          Title = "&Quit",
          OnSelected = function()
            print("Quit selected")
            window:close()
          end,
        },
      },
    },
  },
}, window)

local numPresses = 0
local _button = gui.createButton({
  Type = "Button" :: "Button",
  Caption = "Click me",
  OnPressed = function()
    numPresses += 1
    print("Button pressed " .. numPresses .. " times")
  end,
  Width = 100,
  Height = 30,
  Left = 40,
  Top = 40,
}, window)

window:show()