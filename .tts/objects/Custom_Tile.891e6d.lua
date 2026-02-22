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