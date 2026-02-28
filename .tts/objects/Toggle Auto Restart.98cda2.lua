Enabled = true

ToggleStateData = {
    [true] = {
        color   = {0.6, 1, 0.6, 1},
        tooltip = "Disable automatic restarts"
    },
    [false] = {
        color   = {1, 1, 1, 1},
        tooltip = "Enable automatic restarts"
    }
}

function onSave()
    return JSON.encode({ enabled = Enabled })
end

function onLoad(savedData)
    if savedData ~= "" then
        Enabled = JSON.decode(savedData).enabled or Enabled
    end

    self.createButton({
        click_function = "None",
        function_owner = self,
        position       = {0, 0.25, 0.75},
        rotation       = {0, 180, 0},
        height         = 0,
        width          = 0,
        label          = [[Automatic
Restarts]],
        color          = {1, 1, 1, 1},
        font_color     = {1, 1, 1, 1},
        font_size      = 160
    })

    self.createButton({
        click_function = "ToggleState",
        function_owner = self,
        position       = {0, 0.25, 0},
        rotation       = {0, 0, 0},
        height         = 400,
        width          = 400,
        color          = {1, 1, 1, 0},
        tooltip        = ToggleStateData[Enabled].tooltip
    })

    self.setColorTint(ToggleStateData[Enabled].color)
end

function ToggleState()
    Enabled = not Enabled

    self.editButton({
        index   = 0,
        tooltip = ToggleStateData[Enabled].tooltip
    })

    self.setColorTint(ToggleStateData[Enabled].color)

    -- update game options in global lua
    Global.call("UpdateGameOptions", { UseAutoRestart = Enabled })
end

function None() end