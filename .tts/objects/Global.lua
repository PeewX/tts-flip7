function onLoad()
    StartBtn = getObjectFromGUID("5324c0")
    HitBtn = getObjectFromGUID("e7358b")
    StayBtn = getObjectFromGUID("83c6d4")
    NewroundBtn = getObjectFromGUID("4c4180")
    Scale = StartBtn.getScale()
    Bound = StartBtn.getBoundsNormalized()
    FirstplayerToken = getObjectFromGUID("de0d25")
    baseBag = getObjectFromGUID("314599")
    expBag = getObjectFromGUID("ff1e2d")
    stayBag = getObjectFromGUID("5e7ab9")
    baseBag.interactable = false
    expBag.interactable = false
    stayBag.interactable = false
    buttonSetup()


end

function buttonSetup()
        StartBtn.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Flip 7",
        position       = {0/Scale.x,0.5,3/Scale.z},
        rotation       = {0,180,0},
        scale          = {1/Scale.x,1,1/Scale.z},
        width          = 8000,
        height         = 1000,
        color          = {0.9,0.9,0.9,1},
        font_color     = "Black",
        font_size      = 700
    })

    StartBtn.createButton({
        click_function = "startgame",
        function_owner = self,
        label          = "Start Game",
        position       = {0/Scale.x,0.5,-2/Scale.z},
        rotation       = {0,180,0},
        scale          = {1/Scale.x,1,1/Scale.z},
        width          = 4000,
        height         = 1000,
        color          = {0.6,0.85,0.6},        
        font_color     = "Black",
        font_size      = 700
    })    
    
    StartBtn.createButton({
        click_function = "selection",
        label="<",
        function_owner = self,
        width = 700,
        height = 1000,
        position = {-9.3/Scale.x,0.5,3/Scale.z},
        scale = {1/Scale.x,1,1/Scale.z},
        font_size = 549,
        color = {0.9,0.9,0.9,1},
    })
    StartBtn.createButton({
        click_function = "selection",
        label=">",
        function_owner = self,
        width = 700,
        height = 1000,
        position = {9.3/Scale.x,0.5,3/Scale.z},
        scale = {1/Scale.x,1,1/Scale.z},
        font_size = 549,
        color = {0.9,0.9,0.9,1},
    })

    StartBtn.createButton({
        click_function = "brutal",
        function_owner = self,
        label          = "",
        position       = {0/Scale.x,0.5,0.5/Scale.z},
        rotation       = {0,180,0},
        scale          = {1/Scale.x,1,1/Scale.z},
        width          = 6000,
        height         = 1000,
        color          = {0,0,0,0},        
        font_color     = {1,1,1,100},
        font_size      = 700
    })    

    deck2 = scan2()
    deck2.destruct()

    deck2 = baseBag.takeObject()
    deck2.setPosition({-1.60, 2.1, 1.13})
    deck2.setRotation({0,180,180})
    deck2.shuffle()

    pColors = {"White","Yellow","Red","Purple","Green","Pink","Blue","Orange"}
    scriptzone ={}
    setupCount = 1
    for i,v in ipairs(getObjects()) do
        if v.type == "Scripting" then
            table.insert(scriptzone,v)
            v.createButton({
                click_function = "none",
                function_owner = self,
                label          = "0",
                position       = {0.4,0.25,-1},
                rotation       = {0,180,0},
                scale          = {0.2,0,0.25},
                width          = 0,
                height         = 0,
                font_size      = 500,
                color          = "White",
                font_color     = "Grey",
            })
            setupCount = setupCount+1
        end
    end
    timerID = self.getGUID()..math.random(9999999999999)
    --Sets position/color for the button, spawns it
    --Start timer which repeats forever, running countItems() every second
    Timer.create({
        identifier=timerID,
        function_name="countItems", function_owner=self,
        repetitions=0, delay=0.5
    })
    score = {}
    numberSum = {}
    plusSum = {}
    mult = {}
    countNumbercard = {}
    isbase = true
    isbrutal = false
end

function newgame()
    posCount = 0.1
    HitBtn.clearButtons()
    StayBtn.clearButtons()
    NewroundBtn.clearButtons()
    Timer.destroy(timerID)
    for i,v in ipairs(getObjects()) do
        if v.hasTag("score") then
            v.clearButtons()
            v.editInput({
            index          = 0,
            value          = 0,
         })
        end
        if v.type == "Scripting" then
            v.clearButtons()
        end
    end
    for _, v in ipairs(getObjects()) do 
        if v.type == "Deck" or v.type == "Card" or v.hasTag("stay") then
            v.destruct()
        end
    end
    buttonSetup()
end

function none()
end

function brutal()
    if isbrutal then
        isbrutal = false
        StartBtn.editButton({index=4,label="Brutal Mode [ ]"})
    else
        isbrutal = true
        StartBtn.editButton({index=4,label="Brutal Mode [✓]"})
    end
end

function startgame()
    Turns.enable = false
    local seatedPlayers = getSeatedPlayers()
    if #seatedPlayers == 0 then
        broadcastToAll("No players seated")
        return 
    end
        StartBtn.clearButtons()
    HitBtn.createButton({
        click_function = "hit",
        function_owner = self,
        label          = "Hit",
        position       = {0/Scale.x,0.5,0/Scale.z},
        rotation       = {0,180,0},
        scale          = {0.8/Scale.x,1,0.8/Scale.z},
        width          = 700*Bound.size.x,
        height         = 700*Bound.size.z,
        color          = {0.6,0.85,0.6},
        font_color     = "Black",
        font_size      = 900*Bound.size.z
    })

    StayBtn.createButton({
        click_function = "stay",
        function_owner = self,
        label          = "Stay",
        position       = {0/Scale.x,0.5,0/Scale.z},
        rotation       = {0,180,0},
        scale          = {0.8/Scale.x,1,0.8/Scale.z},
        width          = 700*Bound.size.x,
        height         = 700*Bound.size.z,
        color          = {0.8,0.8,0.8},
        font_color     = "Black",
        font_size      = 900*Bound.size.z
    })
    for i,v in ipairs(getObjects()) do
        if v.hasTag("score") then
            v.createButton({
                click_function = "bust",
                function_owner = self,
                label          = "Bust",
                position       = {0/Scale.x,0,3/Scale.z},
                rotation       = {0,0,0},
                scale          = {1.8/Scale.x,1,0.8/Scale.z},
                width          = 650*Bound.size.x,
                height         = 600*Bound.size.z,
                color          = {0.8,0.6,0.6},
                font_color     = "Black",
                font_size      = 900*Bound.size.z
            })
            if isbrutal then
                v.createButton({
                    click_function = "minus",
                    function_owner = self,
                    label          = "-15",
                    position       = {8/Scale.x,0,3/Scale.z},
                    rotation       = {0,0,0},
                    scale          = {1.8/Scale.x,1,0.8/Scale.z},
                    width          = 400*Bound.size.x,
                    height         = 600*Bound.size.z,
                    color          = {0.8,0.6,0.6},
                    font_color     = "Black",
                    font_size      = 900*Bound.size.z
                })
            end
        end

    end

    --if isbase == false then
        if isbase then
            t = "Start the next round."
        else
            t= "Calculate the scores and start the next round."
        end
        NewroundBtn.createButton({
            click_function = "newround",
            function_owner = self,
            label          = "Next Round",
            position       = {0/Scale.x,0.5,0/Scale.z},
            rotation       = {0,180,0},
            scale          = {1/Scale.x,1,1/Scale.z},
            width          = 4000,
            height         = 1000,
            color          = "White",
            font_color     = "Black",
            font_size      = 700,
            tooltip        = t
        })
    --end
    local found = false

    local startIndex = math.random(1, 8)
    currentIndex = startIndex

    for i = 1, 8 do
        local currentColor = pColors[currentIndex]
        
        for _, playerColor in ipairs(seatedPlayers) do
            if playerColor == currentColor then
                FP = currentColor
                found = true
                break 
            end
        end

        if found then break end 

        currentIndex = currentIndex % 8 + 1
    end

    broadcastToAll(FP.." is a starting player.",FP)
    FirstplayerToken.setColorTint(FP)
    for i,v in ipairs(getObjects()) do
        if v.type == "Scripting" then
            if v.getGMNotes() == FP then
                FirstplayerToken.setPosition(v.positionToWorld({0.4,0.25,-1}))
            end
        end
    end
end



function selection()
    if isbase then
        isbase = false
        isbrutal = false
        deck2.destruct()
        deck2 = expBag.takeObject()
        deck2.setPosition({-1.60, 2.1, 1.13})
        deck2.setRotation({0,180,180})
        deck2.shuffle()

        StartBtn.editButton({index=0,label="Flip 7 With A Vengeance"})
        StartBtn.editButton({index=4,label="Brutal Mode [ ]"})

    else
        isbase = true
        isbrutal = false
        deck2.destruct()
        deck2 = baseBag.takeObject()
        deck2.setPosition({-1.60, 2.1, 1.13})
        deck2.setRotation({0,180,180})
        deck2.shuffle()

        StartBtn.editButton({index=0,label="Flip 7"})
        StartBtn.editButton({index=4,label=""})

    end
end


function newround()

        if WAIT_newround then
            return
        else
            WAIT_newround=true
            Wait.time(function()
                WAIT_newround = false
            end,0.8)
        end
    local seatedPlayers = getSeatedPlayers()
    if #seatedPlayers == 0 then
        broadcastToAll("No players seated")
        return 
    end
     deck2 = scan2()
     posCount = 0.1
    for i,v in ipairs(getObjects()) do
        if v ~= deck2 and (v.type=="Deck" or v.type=="Card") then
            v.setPosition({2.06, 1.49+posCount, 1.07})
            v.setRotation({0,180,0})
            posCount = posCount + 0.1
        end
    end

    for i,v in ipairs(getObjects()) do 
        if v.hasTag("stay") then
            v.destruct()
        end
    end

    if not isbase then
        for _,c in ipairs(pColors) do
            for i,v in ipairs(getObjects()) do
                if v.getGMNotes()== c then
                Playerscore = getScore(v)
                end
            end   
            for i,v in ipairs(getObjects()) do
                if v.hasTag("score") and v.hasTag(c) then
                    Score1 = v.getInputs()[1].value
                    Score2 = Score1 + Playerscore
                    v.editInput({
                        index          = 0,
                        value          = Score2,
                    })
                end
            end
        end
    end

    local found = false
    if currentIndex<8 then
        currentIndex = currentIndex+1
    else
        currentIndex = 1
    end
    for i = 1, 8 do
        local currentColor = pColors[currentIndex]
        
        for _, playerColor in ipairs(seatedPlayers) do
            if playerColor == currentColor then
                FP = currentColor
                found = true
                break 
            end
        end

        if found then break end 

        currentIndex = currentIndex % 8 + 1
    end
    FirstplayerToken.setColorTint(FP)
    for i,v in ipairs(getObjects()) do
        if v.type == "Scripting" then
            if v.getGMNotes() == FP then
                FirstplayerToken.setPosition(v.positionToWorld({0.4,0.25,-1}))
            end
        end
    end

    for i,v in ipairs(getObjects()) do
        if v.type == "Scripting" then
            if v.getGMNotes() == FP then
                FirstplayerToken.setPosition(v.positionToWorld({0.4,0.25,-1}))
            end
        end
    end
end

function minus(o,p,c)
    Score1 = o.getInputs()[1].value
    Score2 = Score1 + -15
    if isbrutal == false then
        if Score2 < 0 then
            Score2 = 0
        end
    end
    o.editInput({
        index          = 0,
        value          = Score2,
    })
end


function countItems()
    for i= 1,8 do
        score[i] = 0
        numberSum[i] = 0
        plusSum[i] = 0
        mult[i] = 1
        countNumbercard[i] = 0
    end
    for i, v in ipairs(scriptzone) do
        local objects = v.getObjects() -- get objects already in the zone
        for key,object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
            if object.hasTag("number") and object.is_face_down == false then
                local description = object.getDescription() -- get the description
                local number = tonumber(description)  -- convert it to a number
                if(number ~= nil) then -- check if you actually get a number (tonumber returns nil if it isn't)
                    numberSum[i] = numberSum[i] + number
                end
                countNumbercard[i] = countNumbercard[i] +1
            end
        end
    
        for key,object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
            if object.hasTag("plus") and object.is_face_down == false then
                local description = object.getDescription() -- get the description
                local plus = tonumber(description)  -- convert it to a number
                plusSum[i] = plusSum[i] + plus
            end
        end
    
        for key,object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
            if object.hasTag("mult") and object.is_face_down == false then
                local description = object.getDescription() -- get the description
                mult[i] = tonumber(description)  -- convert it to a number
            end
        end

        score[i] = math.floor(numberSum[i]*mult[i]+plusSum[i])

        if countNumbercard[i] == 7 then
            score[i] = score[i] +15
        end

        for key,object in ipairs(objects) do
            if object.hasTag("zero") and countNumbercard[i] < 7 then
                score[i] = 0
            end
        end

        if isbrutal == false then
            if score[i] < 0 then
                score[i] = 0
            end
        end

        v.editButton({label = score[i]})
    end
end


function updateScore(zone)
    local scoreValue = getScore(zone)
    zone.editButton({
        index          = 0,
        label          = scoreValue,
    })
end

function getScore(zone)
    local score = 0
    local numberSum = 0
    local plusSum = 0
    local mult = 1
    local countNumbercard = 0
    local objects = zone.getObjects() -- get objects already in the zone
    for key,object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("number") and object.is_face_down == false then
            local description = object.getDescription() -- get the description
            local number = tonumber(description)  -- convert it to a number
            if(number ~= nil) then -- check if you actually get a number (tonumber returns nil if it isn't)
                 numberSum = numberSum + number
            end
            countNumbercard = countNumbercard +1

        end
    end

    for key,object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("plus") and object.is_face_down == false then
            local description = object.getDescription() -- get the description
            local plus = tonumber(description)  -- convert it to a number
             plusSum = plusSum + plus
        end
    end

    for key,object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("mult") and object.is_face_down == false then
            local description = object.getDescription() -- get the description
             mult = tonumber(description)  -- convert it to a number
            
        end
    end
        score = math.floor(numberSum*mult+plusSum)
        if countNumbercard == 7 then
            score = score +15
        end

        if isbrutal == false then
            if score < 0 then
                score = 0
            end
        end

    return score
end

function bust(o,c,a)
    posCount = 0.1

    -- 플레이어 기준 위치 및 회전
    local handTransform = Player[c].getHandTransform()

    -- 회전 각도 (플레이어 기준 정방향)
    local angleY = math.rad(handTransform.rotation.y)
    local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
    local center = handTransform.position + forward * 16

    local spacingX = 3
    local offsetZ_up = 2
    local offsetZ_down = -2

-- 회전 보조 함수 (회전 반대로 적용)
local function rotateOffset(x, z)
    local rx = math.cos(-angleY) * x - math.sin(-angleY) * z
    local rz = math.sin(-angleY) * x + math.cos(-angleY) * z
    return Vector(rx, 0, rz)
    end
    for i = -1, 1 do
        local localOffset = rotateOffset(spacingX * i, offsetZ_up)
        local origin = center + localOffset
        local hitList = Physics.cast({
            origin       = origin + vector(0, -3, 0),
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            orientation  = {0, 0, 0},
            max_distance = 3,
            debug        = false,
        })
        if not isbrutal or seven then
        for _, v in ipairs(hitList) do 
            if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                v.hit_object.setPosition({2.06, 1.49+posCount, 1.07})
                v.hit_object.setRotation({0,180,0})
                posCount = posCount + 0.1
            end
        end
        else
            for _, v in ipairs(hitList) do 
                if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                    v.hit_object.setRotationSmooth({0,180,180},false,false)
                end
            end
        end
    end
    for i = -2, 1 do
        local x = spacingX * i + spacingX / 2
        local localOffset = rotateOffset(x, offsetZ_down)
        local origin = center + localOffset
        local hitList2 = Physics.cast({
            origin       = origin + vector(0, -3, 0),
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            orientation  = {0, 0, 0},
            max_distance = 3,
            debug        = false,
        })
        if not isbrutal or seven then
            for _, v in ipairs(hitList2) do 
                if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                    v.hit_object.setPosition({2.06, 1.49+posCount, 1.07})
                    v.hit_object.setRotation({0,180,0})
                    posCount = posCount + 0.1
                end
            end
        else
            for _, v in ipairs(hitList2) do 
                if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                    v.hit_object.setRotationSmooth({0,180,180},false,false)
                end
            end
        end
    end
    for i = -2, 2 do  -- 5개 칸 (i = -2, -1, 0, 1, 2)
        local x = spacingX * i  -- x 값 조정: 좌우 간격 유지
        local localOffset = rotateOffset(x, offsetZ_down)
        local origin = handTransform.position + forward * 11 + localOffset
        local hitList3 = Physics.cast({
            origin       = origin + vector(0, -3, 0),
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            orientation  = {0, 0, 0},
            max_distance = 3,
            debug        = false,
        })
        
        if not isbrutal or seven then
            for k, v in ipairs(hitList3) do 
                if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                    v.hit_object.setPosition({2.06, 1.49+posCount, 1.07})
                    v.hit_object.setRotation({0,180,0})
                    posCount = posCount + 0.1
                end
            end
        else
            for _, v in ipairs(hitList3) do 
                if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                    v.hit_object.setRotationSmooth({0,180,180},false,false)
                end
            end
        end
    end
    seven = false
end

function stay(o,c,a)
    if isbase then
        bust(o,c,a)
        for i,v in ipairs(getObjects()) do
            if v.getGMNotes()== c then
            Playerscore = getScore(v)
            end
        end   
        for i,v in ipairs(getObjects()) do
            if v.hasTag("score") and v.hasTag(c) then
                Score1 = v.getInputs()[1].value
                Score2 = Score1 + Playerscore
                v.editInput({
                    index          = 0,
                    value          = Score2,
                })
            end
        end
    else
                -- 플레이어 기준 위치 및 회전
        local handTransform = Player[c].getHandTransform()
        -- 회전 각도 (플레이어 기준 정방향)
        local angleY = math.rad(handTransform.rotation.y)
        local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
        local center = handTransform.position + forward * 16

        local spacingX = 3
        local offsetZ_up = 2
        local offsetZ_down = -2

        -- 회전 보조 함수 (회전 반대로 적용)
        local function rotateOffset(x, z)
            local rx = math.cos(-angleY) * x - math.sin(-angleY) * z
            local rz = math.sin(-angleY) * x + math.cos(-angleY) * z

            return Vector(rx, 0, rz)
        end
        stayToken = stayBag.takeObject()
        stayToken.setPosition(center+rotateOffset(0,6))
        stayToken.setRotation(Vector(0, handTransform.rotation.y+180, 0))
    end
end

function wait(time)
    local start = os.time()
    repeat
        coroutine.yield(0)
    until os.time() > start + time
  end

function hit(o,c,a)
    if clicked then
        return
    else
        clicked = true
        Wait.time(function() 
            clicked = false
        end,0.5)
    end
    hit_o=o
    hit_a=a
    Pcolor=c
    startLuaCoroutine(Global, "hit2")
end

function hit2()
    seven = false
    local count = 0

    -- 플레이어 기준 위치 및 회전
    local handTransform = Player[Pcolor].getHandTransform()
    -- 회전 각도 (플레이어 기준 정방향)
    
    local angleY = math.rad(handTransform.rotation.y)

    local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
    
    local center = handTransform.position + forward * 16

    local spacingX = 3
    local offsetZ_up = 2
    local offsetZ_down = -2

-- 회전 보조 함수 (회전 반대로 적용)
local function rotateOffset(x, z)
    local rx = math.cos(-angleY) * x - math.sin(-angleY) * z
    local rz = math.sin(-angleY) * x + math.cos(-angleY) * z

    return Vector(rx, 0, rz)
end


local emptyIndex = nil
local filled = false

-- 위쪽 3칸 (1 ~ 3)
for i = -1, 1 do
    local localOffset = rotateOffset(spacingX * i, offsetZ_up)
    local origin = center + localOffset
    local hitList = Physics.cast({
        origin       = origin + vector(0, -3, 0),
        direction    = {0, -1, 0},
        type         = 3,
        size         = {1, 1, 1},
        orientation  = {0, 0, 0},
        max_distance = 3,
        debug        = false,
    })

    filled = false
    for _, v in ipairs(hitList) do 
        if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
            filled = true
            break
        end
    end

    if not filled then
        emptyIndex = (i + 2)  -- i = -1 → 1번칸, 0 → 2번칸, 1 → 3번칸
        emptyPos = origin + vector(0, -3.3, 0)
        break
    end
end

-- 위쪽 3칸이 차면 아래쪽 첫 번째 칸에서 드로우 시작
if not emptyIndex then
    for i = -2, 1 do
        local x = spacingX * i + spacingX / 2
        local localOffset = rotateOffset(x, offsetZ_down)
        local origin = center + localOffset
        local hitList2 = Physics.cast({
            origin       = origin + vector(0, -3, 0),
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            orientation  = {0, 0, 0},
            max_distance = 3,
            debug        = false,
        })

        filled = false
        for _, v in ipairs(hitList2) do 
            if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                filled = true
                break
            end 
        end

        -- 비어있는 칸을 찾으면 emptyIndex를 설정
        if not filled then
            emptyIndex = (i + 5)  -- i = -2 → 3번 + 1 = 4, -1 → 5, 0 → 6, 1 → 7
            emptyPos = origin + vector(0, -3.3, 0)
            break
        end
    end
end

for i = -2, 2 do  -- 5개 칸 (i = -2, -1, 0, 1, 2)
    local x = spacingX * i  -- x 값 조정: 좌우 간격 유지
    local localOffset = rotateOffset(x, offsetZ_down)
    local origin = handTransform.position + forward * 11 + localOffset
    local hitList3 = Physics.cast({
        origin       = origin + vector(0, -3, 0),
        direction    = {0, -1, 0},
        type         = 3,
        size         = {1, 1, 1},
        orientation  = {0, 0, 0},
        max_distance = 3,
        debug        = false,
    })

    filled2 = false
    for _, v in ipairs(hitList3) do 
        if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
            filled2 = true
            break
        end
    end

    if not filled2 then
        emptyIndex2 = (i + 2)  -- i = -1 → 1번칸, 0 → 2번칸, 1 → 3번칸
        emptyPos2 = origin + vector(0, -3.3, 0)
        break
    end
end
    local drawcard = scan()
if isempty then
    
    local discardCheck = Physics.cast({
        origin       = {2.06, 1.49, 1.07},
        direction    = {0, -1, 0},
        type         = 3,
        size         = {1, 1, 1},
        max_distance = 3,
    })

    for _, v in ipairs(discardCheck) do 
        if v.hit_object.type == "Deck" then
            
            local discardDeck = v.hit_object

            -- draw pile 위치로 이동
            discardDeck.setPositionSmooth({-1.60, 2.3, 1.13}, false, true)
            discardDeck.setRotation({0, 180, 180})

            wait(0.5)
            discardDeck.shuffle()

            wait(0.5)

            -- 다시 scan
            drawcard = scan()

            break
        end
    end

    if isempty then
        return 1
    end
end
    if drawcard.hasTag("special") then
        drawcard.setPositionSmooth(emptyPos2,false,false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y+180, 0))
    else
        drawcard.setPositionSmooth(emptyPos,false,false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y+180, 0))
    end

    if drawcard.hasTag("seven") then
        seven = true
        bust(hit_o,Pcolor,hit_a)
        local firstSlotOffset = rotateOffset(spacingX * -1, offsetZ_up)
        local firstSlotPos = center + firstSlotOffset + vector(0, -3.3, 0)
        drawcard.setPositionSmooth(firstSlotPos,false,false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y+180, 0))

    end

    isDeck = false
    local hitcheck = Physics.cast({
        origin       = {-1.60, 1.83, 1.13},
        direction    = {0, -1, 0},
        type         = 3,
        size         = {1, 1, 1},
        orientation  = {0, 0, 0},
        max_distance = 3,
        debug        = false,
    })

    for _, v in ipairs(hitcheck) do 
        if v.hit_object.type == "Deck" then
            isDeck = true
        end
    end
    if isDeck == false then
        local hitcheck2 = Physics.cast({
            origin       = {2.06, 1.49, 1.07},
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            orientation  = {0, 0, 0},
            max_distance = 3,
            debug        = false,
        })
    
        for _, v in ipairs(hitcheck2) do 
            if v.hit_object.type == "Deck" then
                v.hit_object.setPositionSmooth({-1.60, 2.3, 1.13}, false, true)
                v.hit_object.setRotation({0, 180, 180})
                wait(0.5)
                v.hit_object.shuffle()
            end
        end
    end
local thirteenCount = 0
local sameNumber = false
local hasLucky13 = false

for _,v in ipairs(scriptzone) do
    if v.getGMNotes() == Pcolor then
        for _,k in ipairs(v.getObjects()) do

            -- Lucky13 보유 여부
            if k.hasTag("lucky13") then
                hasLucky13 = true
            end

            -- 🔥 drawcard도 Lucky13이면 포함
            if drawcard.hasTag("lucky13") then
                hasLucky13 = true
            end

            -- 숫자 중복 검사
            if k.hasTag("number") and drawcard.hasTag("number") then
                if k.getDescription() == drawcard.getDescription() then

                    if tonumber(k.getDescription()) == 13 then
                        thirteenCount = thirteenCount + 1
                    else
                        sameNumber = true
                    end

                end
            end

        end
    end
end


-- 🔥 숫자 처리 (핑만 찍고 종료)

if drawcard.hasTag("number") then

    local num = tonumber(drawcard.getDescription())

    -- 13일 경우
    if num == 13 then
        
        if hasLucky13 then
            -- Lucky13 있으면 3번째 13에서만 핑
            if thirteenCount >= 2 then
                Player[Pcolor].pingTable(emptyPos)
                return 1
            end
        else
            -- Lucky13 없으면 2번째 13에서 핑
            if thirteenCount >= 1 then
                Player[Pcolor].pingTable(emptyPos)
                return 1
            end
        end

    else
        -- 13이 아닌 숫자 중복
        if sameNumber then
            if drawcard.hasTag("seven") == false then
                Player[Pcolor].pingTable(emptyPos)
            return 1
            end
        end
    end

end


return 1
end
function scan()
    isempty = true
    deckscan = Physics.cast({
        origin       = {-2,2,1},
        direction    = {0, -1, 0},
        type         = 3,
        size         = {1, 1, 1},
        orientation  = {0, 0, 0},
        max_distance = 1,
        debug        = false,
    })

    for _,v in ipairs(deckscan) do
        if v.hit_object.type == "Deck"  then
            isempty = false

            return v.hit_object.takeObject()
        elseif v.hit_object.type == "Card" then
            isempty = false

            return v.hit_object
        end
    end
end

function scan2()
    deckscan = Physics.cast({
        origin       = {-2,2,1},
        direction    = {0, -1, 0},
        type         = 3,
        size         = {1, 1, 1},
        orientation  = {0, 0, 0},
        max_distance = 1,
        debug        = false,
    })

    for _,v in ipairs(deckscan) do
        if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
            return v.hit_object
        end
    end
end