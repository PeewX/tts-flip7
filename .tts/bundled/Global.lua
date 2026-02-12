function onLoad()
    StartBtn = getObjectFromGUID("5324c0")
    HitBtn = getObjectFromGUID("e7358b")
    StayBtn = getObjectFromGUID("83c6d4")

    Scale = StartBtn.getScale()
    Bound = StartBtn.getBoundsNormalized()

    StartBtn.createButton({
        click_function = "startgame",
        function_owner = self,
        label          = "New Round",
        position       = {0/Scale.x,0.5,0/Scale.z},
        rotation       = {0,180,0},
        scale          = {0.4/Scale.x,1,0.4/Scale.z},
        width          = 1200*Bound.size.x,
        height         = 800*Bound.size.z,
        color          = "White",
        font_color     = "Black",
        font_size      = 700*Bound.size.z
    })

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
                position       = {10/Scale.x,0,0.8/Scale.z},
                rotation       = {0,0,0},
                scale          = {1.8/Scale.x,1,0.8/Scale.z},
                width          = 700*Bound.size.x,
                height         = 700*Bound.size.z,
                color          = {0.8,0.6,0.6},
                font_color     = "Black",
                font_size      = 900*Bound.size.z
            })
        end
    end

    local deck2 = scan2()
    deck2.shuffle()

    pColors = {"Yellow","Red","White","Orange","Blue","Pink","Green","Purple"}
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
    
    --Sets position/color for the button, spawns it
    --Start timer which repeats forever, running countItems() every second
    Wait.time(countItems, 0.5, -1)

    score = {}
    numberSum = {}
    plusSum = {}
    mult = {}
    countNumbercard = {}
    hasBeenPewd = false
end

function countItems()
    for i= 1,8 do
        score[i] = 0
        numberSum[i] = 0
        plusSum[i] = 0
        mult[i] = 1
        countNumbercard[i] = 0
    end
	local hasDuplicateNumber = false
    for i, v in ipairs(scriptzone) do
		local seenNumbers = {}
        local objects = v.getObjects() -- get objects already in the zone
        for key,object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
            if object.hasTag("number") then
                local description = object.getDescription() -- get the description
                local number = tonumber(description)  -- convert it to a number
                if(number ~= nil) then -- check if you actually get a number (tonumber returns nil if it isn't)
					if not seenNumbers[number] then
						seenNumbers[number] = true
						numberSum[i] = numberSum[i] + number
					else
						hasDuplicateNumber = true
						if not hasBeenPewd then
							broadcastToAll("YouGotPewd!", {1, 0, 0})
							hasBeenPewd = true
						end
					end
                end
                countNumbercard[i] = countNumbercard[i] +1

            elseif object.hasTag("plus") then
                local description = object.getDescription() -- get the description
                local plus = tonumber(description)  -- convert it to a number
                plusSum[i] = plusSum[i] + plus

            elseif object.hasTag("mult") then
                local description = object.getDescription() -- get the description
                mult[i] = tonumber(description)  -- convert it to a number
            end
        end

        score[i] = numberSum[i]*mult[i]+plusSum[i]
        if countNumbercard[i] == 7 then
            score[i] = score[i] +15
        end

        v.editButton({label = score[i]})
    end
	
	if not hasDuplicateNumber then
		hasBeenPewd = false
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
        if object.hasTag("number") then
            local description = object.getDescription() -- get the description
            local number = tonumber(description)  -- convert it to a number
            if(number ~= nil) then -- check if you actually get a number (tonumber returns nil if it isn't)
                 numberSum = numberSum + number
            end
            countNumbercard = countNumbercard +1

        end
    end

    for key,object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("plus") then
            local description = object.getDescription() -- get the description
            local plus = tonumber(description)  -- convert it to a number
             plusSum = plusSum + plus
        end
    end

    for key,object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("mult") then
            local description = object.getDescription() -- get the description
             mult = tonumber(description)  -- convert it to a number
            
        end
    end
        score = numberSum*mult+plusSum
        if countNumbercard == 7 then
            score = score +15
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
    local center = handTransform.position + forward * 14

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
    
        for _, v in ipairs(hitList) do 
            if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                v.hit_object.setPosition({2.06, 1.49+posCount, 1.07})
                v.hit_object.setRotation({0,180,0})
                posCount = posCount + 0.1
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

        for _, v in ipairs(hitList2) do 
            if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                v.hit_object.setPosition({2.06, 1.49+posCount, 1.07})
                v.hit_object.setRotation({0,180,0})
                posCount = posCount + 0.1
            end
        end
    end
    for i = -2, 2 do  -- 5개 칸 (i = -2, -1, 0, 1, 2)
        local x = spacingX * i  -- x 값 조정: 좌우 간격 유지
        local localOffset = rotateOffset(x, offsetZ_down)
        local origin = handTransform.position + forward * 9 + localOffset
        local hitList3 = Physics.cast({
            origin       = origin + vector(0, -3, 0),
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            orientation  = {0, 0, 0},
            max_distance = 3,
            debug        = false,
        })
    
        for k, v in ipairs(hitList3) do 
            if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                v.hit_object.setPosition({2.06, 1.49+posCount, 1.07})
                v.hit_object.setRotation({0,180,0})
                posCount = posCount + 0.1
            end
        end
    end
end

function startgame()
    local deck2 = scan2()
    local posCount = 0.1
    for i,v in ipairs(getObjects()) do
        if v ~= deck2 and (v.type=="Deck" or v.type=="Card") then
            v.setPosition({2.06, 1.49+posCount, 1.07})
            v.setRotation({0,180,0})
            posCount = posCount + 0.1
        end
    end

    if deck2 == nil or (deck2.getQuantity()<=#getSeatedPlayers()) then
        return
    end

    deck2.shuffle()
--[[
for i, v in ipairs(getSeatedPlayers()) do
    Wait.time(function() 
            -- 플레이어 기준 위치 및 회전
            local handTransform = Player[v].getHandTransform()

            -- 회전 각도 (플레이어 기준 정방향)
            local angleY = math.rad(handTransform.rotation.y)
            local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
            local center = handTransform.position + forward * 14
        
            local spacingX = 3
            local offsetZ_up = 2
            local offsetZ_down = -2
        
        -- 회전 보조 함수 (회전 반대로 적용)
        local function rotateOffset(x, z)
            local rx = math.cos(-angleY) * x - math.sin(-angleY) * z
            local rz = math.sin(-angleY) * x + math.cos(-angleY) * z
            return Vector(rx, 0, rz)
        end
        
            
            local localOffset = rotateOffset(spacingX * -1, offsetZ_up)
            local origin = center + localOffset
                emptyPos = origin + vector(0, -3.3, 0)
    
            local x = spacingX * -2  -- x 값 조정: 좌우 간격 유지
            local localOffset = rotateOffset(x, offsetZ_down)
            local origin = handTransform.position + forward * 9 + localOffset
                emptyPos2 = origin + vector(0, -3.3, 0)
            local drawcard = deck2.takeObject()
            if drawcard.hasTag("special") then
                drawcard.setPositionSmooth(emptyPos2,false,false)
                drawcard.setRotation(Vector(0, handTransform.rotation.y+180, 0))
            else
                drawcard.setPositionSmooth(emptyPos,false,false)
                drawcard.setRotation(Vector(0, handTransform.rotation.y+180, 0))
            end
          end, 1)
    end
    ]]--

end

function stay(o,c,a)
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
end

function wait(time)
    local start = os.time()
    repeat
        coroutine.yield(0)
    until os.time() > start + time
  end

function hit(o,c,a)
    Pcolor=c
    startLuaCoroutine(Global, "hit2")
end

function hit2()

    local count = 0

    -- 플레이어 기준 위치 및 회전
    local handTransform = Player[Pcolor].getHandTransform()
    -- 회전 각도 (플레이어 기준 정방향)
    local angleY = math.rad(handTransform.rotation.y)
    local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
    local center = handTransform.position + forward * 14

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
    local origin = handTransform.position + forward * 9 + localOffset
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
        return
    end
    if drawcard.hasTag("special") then
        drawcard.setPositionSmooth(emptyPos2,false,false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y+180, 0))
    else
        drawcard.setPositionSmooth(emptyPos,false,false)
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