function CreateGamemodeSelection()
    local Scale = self.getScale()
    local Bound = self.getBoundsNormalized()

    self.createButton({
        click_function = "None",
        function_owner = Global,
        label          = "Flip 7",
        position       = {0, 0.5, 3/Scale.z},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 8000,
        height         = 1000,
        color          = {0.9, 0.9, 0.9, 1},
        font_color     = "Black",
        font_size      = 700
    })

    self.createButton({
        click_function = "StartGame",
        function_owner = Global,
        label          = "Start Game",
        position       = {0, 0.5, -2/Scale.z},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 4000,
        height         = 1000,
        color          = {0.6, 0.85, 0.6},
        font_color     = "Black",
        font_size      = 700
    })

    self.createButton({
        click_function  = "ModeSelUp",
        label           = "<",
        function_owner  = Global,
        width           = 700,
        height          = 1000,
        position        = {-9.3/Scale.x, 0.5, 3/Scale.z},
        scale           = {1/Scale.x, 1, 1/Scale.z},
        font_size       = 549,
        color           = {0.9, 0.9, 0.9, 1},
    })

    self.createButton({
        click_function  = "ModeSelDown",
        label           = ">",
        function_owner  = Global,
        width           = 700,
        height          = 1000,
        position        = {9.3/Scale.x, 0.5, 3/Scale.z},
        scale           = {1/Scale.x, 1, 1/Scale.z},
        font_size       = 549,
        color           = {0.9, 0.9, 0.9, 1},
    })

    self.createButton({
        click_function = "Brutal",
        function_owner = Global,
        label          = "",
        position       = {0, 0.5, 0.5/Scale.z},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 6000,
        height         = 1000,
        color          = {0, 0, 0, 0},
        font_color     = {1, 1, 1, 100},
        font_size      = 700
    })
end