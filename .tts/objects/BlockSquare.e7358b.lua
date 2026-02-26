function CreateGameButtons()
    local Scale = self.getScale()
    local Bound = self.getBoundsNormalized()

    self.createButton({
        click_function = "Hit",
        function_owner = Global,
        label          = "Hit",
        position       = {0, 0.5, 0},
        rotation       = {0, 180, 0},
        scale          = {0.8/Scale.x, 1, 0.8/Scale.z},
        width          = 700*Bound.size.x,
        height         = 700*Bound.size.z,
        color          = {0.6, 0.85, 0.6},
        font_color     = "Black",
        font_size      = 900*Bound.size.z
    })

    self.createButton({
        click_function = "Stay",
        function_owner = Global,
        label          = "Stay",
        position       = {0, 0.5, -1.5},
        rotation       = {0, 180, 0},
        scale          = {0.8/Scale.x, 1, 0.8/Scale.z},
        width          = 700*Bound.size.x,
        height         = 700*Bound.size.z,
        color          = {0.8, 0.8, 0.8},
        font_color     = "Black",
        font_size      = 900*Bound.size.z
    })

    self.createButton({
        click_function = "NewRoundCheck",
        function_owner = Global,
        label          = "Next Round",
        position       = {0, 0.5, 5},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 4000,
        height         = 1000,
        color          = {0, 0, 0.2, 0.9},
        font_color     = {0.8, 0.8, 0.8, 0.9},
        font_size      = 700,
        tooltip        = "Update scores, start next round"
    })

    self.createButton({
        click_function = "ResetGame",
        function_owner = Global,
        label          = "New Game",
        position       = {-7, 0.5, -18.25},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 4000,
        height         = 1000,
        color          = "White",
        font_color     = "Black",
        font_size      = 700,
        tooltip        = "Reset all player points and cards"
    })
end