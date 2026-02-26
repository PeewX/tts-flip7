function onLoad()
    function None() end
    self.clearInputs()

    self.createInput({
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

function CreateButtons(params)
    local isBrutal = params[1]
    local Scale = params[2]
    local Bound = params[3]

    self.createButton({
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

    if isBrutal then
        self.createButton({
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
end