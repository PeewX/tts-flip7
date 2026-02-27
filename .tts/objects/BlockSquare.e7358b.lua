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

function CreateScoreTileUI(params)
    local PlayerData = params[1]
    local isBrutal = params[2]
    local Scale = params[3]
    local Bound = params[4]


    for _, v in pairs(PlayerData) do
        local scoreTile = v.scoreTile
        local scriptZone = v.scriptZone
        scoreTile.clearButtons()
        scoreTile.clearInputs()
        scriptZone.clearButtons()

        -- Create bust buttons
        scoreTile.createButton({
            click_function = "Bust",
            function_owner = Global,
            label          = "Bust",
            position       = {0, 0, 3/Scale.z},
            rotation       = {0, 0, 0},
            scale          = {1.8/Scale.x, 1, 0.8/Scale.z},
            width          = 650*Bound.size.x,
            height         = 600*Bound.size.z,
            color          = {0.8, 0.6, 0.6},
            font_color     = "Black",
            font_size      = 900*Bound.size.z
        })

        -- Brutal mode buttons (-15 / + 15)
        if isBrutal then
            scoreTile.createButton({
                click_function = "SetBrutalModeEndScore",
                function_owner = Global,
                label          = "",
                position       = {8/Scale.x, 0, 3/Scale.z},
                rotation       = {0, 0, 0},
                scale          = {1.8/Scale.x, 1, 0.8/Scale.z},
                width          = 400*Bound.size.x,
                height         = 600*Bound.size.z,
                color          = {0, 0, 0, 0},
                font_color     = "Black",
                font_size      = 900*Bound.size.z
            })
        end

        -- Create round score label (why not attach to scoreTile?)
        scriptZone.createButton({
            click_function = "None",
            function_owner = self,
            label          = "0",
            position       = {0.4, 0.25, -1},
            rotation       = {0, 180, 0},
            scale          = {0.2, 0, 0.25},
            width          = 0,
            height         = 0,
            font_size      = 500,
            color          = "White",
            font_color     = "Grey",
        })

        -- Create game score input
        scoreTile.createInput({
            input_function = "None",
            function_owner = self,
            validation = 2,
            value      = "0",
            alignment  = 3,
            position   = {0, 0.3, 0},
            width      = 800,
            height     = 600,
            rotation   = {0, 0, 0},
            font_size  = 400,
            scale      = {1, 1, 1},
            font_color = {0, 0, 0, 99},
            color      = {1, 1, 1, 0},
            tab        = 2
        })
    end
end

function None() end