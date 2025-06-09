local App = require "astal.gtk3.app"
local Widget = require("astal.gtk3.widget")
local Anchor = require("astal.gtk3").Astal.WindowAnchor

local function bar(monitor)
    return Widget.Window({
        monitor = monitor,
        anchor = Anchor.TOP + Anchor.LEFT + Anchor.RIGHT,
        exclusivity = "EXCLUSIVE",
        Widget.Label({
            label = "Example label content",
        }),
    })
end

App:start {
  main = function()
    bar(0)
  end,
}
