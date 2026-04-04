-- CONSTS
local MSG_BUSTED = "%s got busted!"
local MSG_2ND_CHANCE = "Time for %s to use their second chance!"
local MSG_WAIT_ROUND = "Please wait until a new round has started"
local BUSTED_CARD_HIGHLIGHT_DURATION = 3

DECK_INFO = {
    {Name = "Flip 7", ShortName = "Flip 7", Tooltip = "", Brutal = false},
    {Name = "Flip 7 With A Vengeance", ShortName = "Flip 7 Vengeance", Tooltip = "", Brutal = true},
    {Name = "Flip 7 Fusion Deck", ShortName = "Flip 7 Fusion ", Tooltip = "Base and Vengeance combined!", Brutal = true},
}

PLAYER_COLORS = {"White", "Yellow", "Red", "Purple", "Green", "Pink", "Blue", "Orange"}
TOKEN_COLORS = {["White"] = {1, 1, 1}, ["Yellow"] = {1, 0.99, 0.6}, ["Red"] = {1, 0.78, 0.78}, ["Purple"] = {0.89, 0.72, 1}, ["Green"] = {0.71, 1, 0.71}, ["Pink"] = {1, 0.75, 0.93}, ["Blue"] = {0.71, 0.85, 1}, ["Orange"] = {1, 0.73, 0.59}}

-- ENUMS
PlayerStatus = {
    Active = 0,
    ActionRequired = 1,
    Stayed = 2,
    Busted = 3
}

SpecialCards = {
    SecondChance = "SecondChance"
}

DeckModes = {
    Base = 1,
    Vengeance = 2,
    Fusion = 3
}

-- Globals
PlayerData = {}
GameOptions = {}
NextPlayerStartToken = nil
AutostartTimer = nil
DebugTimer = nil
WaitForNewRound = true
Flip7Reached = false
BrutalScoreDecision = {active = false, by = ""}
GameOptions = {}
LastButtonHit = os.time()

function UpdateGameOptions(options)
    GameOptions = options

    if DebugTimer then Wait.stop(DebugTimer) end
    if GameOptions.Debug then
        DebugTimer = Wait.time(PrintDebugLogs, 10, -1)
    end

    UI.setAttribute("table", "active", tostring(GameOptions.Scoreboard))

    if GameOptions.Autostart == CONFIG.AUTOSTART.OFF then
        if WaitForNewRound and AutostartTimer then
            Wait.stop(AutostartTimer)
            HitBtn.call("AutostartCancel", false)
            WaitForNewRound = false
        end
    end

    if not GameOptions.ActionBlocker then
        ActionBlocker.reset()
    end
end

-- Overwrite getSeatedPlayers to return the colors in correct order
local _getSeatedPlayers = getSeatedPlayers
function getSeatedPlayers()
    local sortedPlayers = {}
    for _, color in ipairs(PLAYER_COLORS) do
        if Player[color].seated then
            table.insert(sortedPlayers, color)
        end
    end

    return sortedPlayers
end

function IsSnapPointOccupied(snapPoint)
    local snapPos = snapPoint.position

    -- get objects near the snap point
    local nearby = UsePhysicsCast({
        origin       = snapPos,
        direction    = {0, 1, 0},
        max_distance = 0
    })

    for _, v in pairs(nearby) do
        if v.hit_object ~= nil and (v.hit_object.type == "Deck" or v.hit_object.type == "Card") then
            return true
        end
    end

    return false
end

function onObjectDrop(color, object)
    if ActionBlocker.isBlocked() and ActionBlocker.isAny(object) then
        local zones = object.getZones()
        if #zones > 0 then
            local droppedZone = zones[1].getGMNotes()
            local playerData = PlayerData[droppedZone]
            if ActionBlocker.get().by ~= droppedZone then
                if droppedZone == "Discard" or object:hasTag("modifier") then
                    ActionBlocker.discard(object)
                elseif playerData and playerData.status ~= PlayerStatus.Busted then
                    playerData.resetState = playerData.status
                    playerData.status = PlayerStatus.ActionRequired
                    ActionBlocker.update(object, droppedZone)
                end
            end
        end
    end

    if DeckMode == DeckModes.Base then return end

    if object.type == "Card" and object.hasTag("action") then
        local tagSet = GenTagSet(object.getTags(), true)
        local description = object.getDescription()

        if tagSet["action"] and (description == "Flip3" or description == "Flip4" or description == "OneMore") then
            local targetColor = false
            for _, v in pairs(object.getZones()) do if PlayerData[v.getGMNotes()] and v.getGMNotes() ~= color then targetColor = v.getGMNotes() end end
            if targetColor then
                local playerData = PlayerData[targetColor]
                if  IsObject(playerData.token) and (playerData.status == PlayerStatus.Stayed or playerData.status == PlayerStatus.ActionRequired) then
                    playerData.tokenReset = true
                    playerData.token.setColorTint(Color(TOKEN_COLORS[targetColor]):lerp(Color.Black, 0.8))
                end
            end
        end
    end
end

function onObjectLeaveZone(zone, object)
    if DeckMode == DeckModes.Base then return end
    if not IsObject(object) then return end
    if object.type ~= "Card" or not object.hasTag("action") then return end

    local playerColor = zone.getGMNotes()
    if PlayerData[playerColor] and Color.fromString(playerColor) and PlayerData[playerColor].tokenReset then
        if not PlayerHasCard(playerColor, "action", {"Flip3", "Flip4", "OneMore"}) then
            PlayerData[playerColor].tokenReset = false
            if IsObject(PlayerData[playerColor].token) then
                PlayerData[playerColor].token.setColorTint(GameOptions.ColoredTokens and TOKEN_COLORS[playerColor] or {1, 1, 1})
            end
        end
    end
end

function onLoad()
    InitPlayerData()
    InitButtonsAndObjects()
    ActionBlocker.reset()

    Score = {} -- could be moved to PlayerData?
    IsBrutal = false -- only available in vengeance mode
    HasBeenPewd = false
    StartingPlayer = -1

    -- Init deck with base game
    DeckMode = DeckModes.Base
    Deck2 = GetDrawPile()
    SetModeSelection()

    local hotKeyFunctions = {"Hit", "Stay", "Bust"}
    for _, func in pairs(hotKeyFunctions) do
        addHotkey(func, function(color, object, pos, keyUp) if keyUp and StartingPlayer > 0 then _G[func](object, color, false) end end, true)
    end

    Wait.time(CountItems, 0.5, -1)
end

function InitPlayerData()
    -- Sort snap points row-by-row (center → player, left → right)
    local function sortSnapPointsForPlayer(snapPointTable, center, forward)
        -- Right vector (perpendicular to forward)
        local right = Vector(forward.z, 0, -forward.x)

        for _, sp in ipairs(snapPointTable) do
            local offset = sp.position - center
            sp._depth = offset:dot(forward) -- depth to center
            sp._horizontal = offset:dot(right)
        end

        -- 1) Rows: closest to center first
        -- 2) Inside row: left to right
        table.sort(snapPointTable, function(a, b)
            if math.abs(a._depth - b._depth) > 0.1 then
                return a._depth > b._depth
            end
            return a._horizontal < b._horizontal
        end)

        for _, sp in pairs(snapPointTable) do
            sp._depth = nil
            sp._horizontal = nil
        end
    end

    local snapPoints = Global.getSnapPoints()
    for _, playerColor in pairs(PLAYER_COLORS) do
        local handTransform = Player[playerColor].getHandTransform()
        local angleY = math.rad(handTransform.rotation.y)
        local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
        local center = handTransform.position + forward * 16

        PlayerData[playerColor] = {
            status = PlayerStatus.Active,
            scoreTile = getObjectsWithAllTags({"score", playerColor})[1],
            positionData = {
                handTransform = handTransform,
                angleY = angleY,
                forward = forward,
                center = center
            },
            snapPoints = {
                numbers = {},
                special = {},
                chance = {}
            }
        }

        local snapPointsNumbers = PlayerData[playerColor].snapPoints.numbers
        local snapPointsSpecial = PlayerData[playerColor].snapPoints.special
        local snapPointsChance = PlayerData[playerColor].snapPoints.chance

        for _, snapPoint in pairs(snapPoints) do
            local tagSet = GenTagSet(snapPoint.tags)
            if tagSet[playerColor] then
                if tagSet["number"] then table.insert(snapPointsNumbers, snapPoint) end
                if tagSet["Special"] then table.insert(snapPointsSpecial, snapPoint) end
                if tagSet["Chance"] then table.insert(snapPointsChance, snapPoint) end
            end
        end

        sortSnapPointsForPlayer(snapPointsNumbers, center, forward)
        sortSnapPointsForPlayer(snapPointsSpecial, center, forward)
    end

    -- save scriptingZone to PlayerData
    for _, v in pairs(getObjects()) do
        if v.type == "Scripting" and PlayerData[v.getGMNotes()] then
            PlayerData[v.getGMNotes()].scriptZone = v
        end
    end
end

function InitButtonsAndObjects()
    StartBtn = getObjectFromGUID("5324c0")
    HitBtn = getObjectFromGUID("e7358b")
    Scale = StartBtn.getScale()
    Bound = StartBtn.getBoundsNormalized()

    StartBtn.call("CreateGamemodeSelection")

    BaseBag = getObjectFromGUID("314599")
    ExpBag = getObjectFromGUID("ff1e2d")
    StayBag = getObjectFromGUID("5e7ab9")
    BustedBag = getObjectFromGUID("5e7ab8")
    NextPlayerBag = getObjectFromGUID("5e7ab7")
    BaseBag.interactable = false
    ExpBag.interactable = false
    StayBag.interactable = false
    BustedBag.interactable = false
    NextPlayerBag.interactable = false
end

function None() end

function Brutal()
    if not DECK_INFO[DeckMode].Brutal then return end
    IsBrutal = not IsBrutal
    StartBtn.editButton({index = 4, label = ("Brutal Mode [%s]"):format(IsBrutal and "✓" or " ")})
    UI.setAttribute("state", "text", ("%s%s"):format(DECK_INFO[DeckMode].Name, IsBrutal and " (Brutal)" or ""))
end

function StartGame()
    StartBtn.clearButtons()
    HitBtn.call("CreateGameButtons")
    HitBtn.call("CreateScoreTileUI", {PlayerData, IsBrutal, Scale, Bound})

    WaitForNewRound = false
    ShiftStartingPlayer(true)
end

function ResetGame(_, color, _)
    if not Player[color].admin then
        broadcastToColor("You need to be promoted to use this feature", color)
        return
    end

    if os.time() - LastButtonHit < 5 then return end
    LastButtonHit = os.time()

    -- reset player specific data
    for _, v in pairs(PlayerData) do
        v.status = PlayerStatus.Active
        v.resetState = false
        v.scoreTile.editInput({index = 0, value = 0})
    end

    -- put all cards back
    local drawDeck = GetDrawPile()
    for _, v in pairs(getObjects()) do
        if v ~= drawDeck and (v.type == "Deck" or v.type == "Card") then
            v.setPosition({-1.60, 2.3, 1.13})
            v.setRotation({0, 180, 180})
        end

        -- destroy begin/stay/busted marker
        if v.hasTag("token") then v.destruct() end
    end

    drawDeck.shuffle()
    WaitForNewRound, AutostartCanceled, Flip7Reached = false, false, false
    ShiftStartingPlayer(true)
end

function ModeSelUp()
    DeckMode = DeckMode + 1
    if DeckMode > table.size(DeckModes) then DeckMode = 1 end
    SetModeSelection()
end

function ModeSelDown()
    DeckMode = DeckMode - 1
    if DeckMode < 1 then DeckMode = 3 end
    SetModeSelection()
end

function SetModeSelection()
    if Deck2 then Deck2.destruct() end

    if DeckMode == DeckModes.Base then
        Deck2 = BaseBag.takeObject()
    elseif DeckMode == DeckModes.Vengeance then
        Deck2 = ExpBag.takeObject()
    elseif DeckMode == DeckModes.Fusion then
        Deck2 = BuildFusionDeck()
    end

    IsBrutal = false

    StartBtn.editButton({index = 0, label = DECK_INFO[DeckMode].Name, tooltip = DECK_INFO[DeckMode].Tooltip})
    StartBtn.editButton({index = 4, label = DECK_INFO[DeckMode].Brutal and "Brutal Mode [ ]" or ""})
    UI.setAttribute("state", "text", ("%s%s"):format(DECK_INFO[DeckMode].Name, IsBrutal and " (Brutal)" or ""))

    Deck2.setPosition({-1.60, 2.1, 1.13})
    Deck2.setRotation({0, 180, 180})
    Deck2.shuffle()
end

function BuildFusionDeck()
    local baseDeck = BaseBag.takeObject()
    local expDeck  = ExpBag.takeObject()

    if not baseDeck or not expDeck then return end
    local baseData = baseDeck.getData()
    local expData = expDeck.getData()

    local fusionCardObjects = {}
    local fusionCardIds = {}
    local fusionCustomDeck = {}

    -- Add filtered cards
    for _, card in pairs(baseData.ContainedObjects) do if FilterFusion(DeckModes.Base, card) then table.insert(fusionCardObjects, card) end end
    for _, card in pairs(expData.ContainedObjects) do if FilterFusion(DeckModes.Vengeance, card) then table.insert(fusionCardObjects, card) end end

    -- Recreate DeckIDs
    for _, card in ipairs(fusionCardObjects) do table.insert(fusionCardIds, card.CardID) end

    -- Combine customdecks and replace back covers
    for _, CustomDecks in pairs({baseData.CustomDeck, expData.CustomDeck}) do
        for id, deck in pairs(CustomDecks) do
            if id then
                if deck.BackURL then deck.BackURL = "https://steamusercontent-a.akamaihd.net/ugc/10220899063260540649/E869999FB450AA4C05C38DBDB4D81496C6A45C3B/" end
                fusionCustomDeck[id] = deck
            end
        end
    end

    baseDeck.destruct()
    expDeck.destruct()

    local fusionData = baseDeck.getData()
    fusionData.ContainedObjects = fusionCardObjects
    fusionData.DeckIDs = fusionCardIds
    fusionData.CustomDeck = fusionCustomDeck

    baseDeck.destruct()
    expDeck.destruct()
    return spawnObjectData({data = fusionData})
end

function FilterFusion(mode, card)
    local tagSet = GenTagSet(card.Tags, true)
    if mode == DeckModes.Base then
        if tagSet["number"] and tonumber(card.Description) == 7 then return false end
        if tagSet["number"] and tonumber(card.Description) == 0 then return false end
        return true
    end

    if mode == DeckModes.Vengeance then
        if tagSet["number"] and tonumber(card.Description) == 7 then return true end
        if tagSet["number"] and tonumber(card.Description) == 13 then return true end
        if tagSet["special"] then return true end
        if tagSet["zero"] then return true end
        if tagSet["seven"] then return true end
        if tagSet["thirteen"] then return true end
        return false
    end

    return false
end

function NewRoundCheck(object, color, alt)
    if alt then return end
    if WaitForNewRound then
        if AutostartTimer then 
            Wait.stop(AutostartTimer)
            broadcastToAll(("Autostart canceled by %s"):format(Player[color].steam_name or color))
            HitBtn.call("AutostartCancel", false)
            WaitForNewRound = false
            AutostartCanceled = true
        end
        return
    end
    if os.time() - LastButtonHit < 3 then return end
    if AllPlayersDone() then return NewRound() end
    LastButtonHit = os.time()

    Player[color].showConfirmDialog("Not everyone has finished. Start the next round anyway?", NewRound)
end

function NewRound()
    local posCount = 0.1
    Deck2 = GetDrawPile()

    for _, color in pairs(PLAYER_COLORS) do
        local playerData = PlayerData[color]
        playerData.status = PlayerStatus.Active
        playerData.resetState = false

        -- update score
        local currentScore = playerData.scoreTile.getInputs()[1].value
        playerData.scoreTile.editInput({index = 0, value = currentScore + Score[color]})
    end

    for _, v in pairs(getObjects()) do
        if v ~= Deck2 and (v.type == "Deck" or v.type == "Card") then
            v.setPosition({2.06, 1.49+posCount, 1.07})
            v.setRotation({0, 180, 0})
            posCount = posCount + 0.1
        end

        -- destroy begin/stay/busted marker
        if v.hasTag("token") then v.destruct() end
    end

    -- hide brutal mode extra buttons
    if IsBrutal then
        HitBtn.call("ResetBrutalButton", PlayerData)
        BrutalScoreDecision.active = false
    end

    WaitForNewRound, AutostartCanceled, Flip7Reached = false, false, false
    ShiftStartingPlayer()
    ActionBlocker.reset()
    HitBtn.call("AutostartCancel", false)
end

function SetBrutalModeEndScore(object, color, alt)
    if alt then return end
    if not IsBrutal then return end
    if not BrutalScoreDecision.active then return end
    if not (BrutalScoreDecision.by == color) then return end
    local targetPlayerColor = GetPlayerColorFromTags(GenTagSet(object.getTags(), false))
    if not Player[targetPlayerColor].seated then return end

    local currentScore = object.getInputs()[1].value
    local modifierValue = targetPlayerColor == color and 15 or -15

    object.editInput({index = 0, value = currentScore + modifierValue})
    HitBtn.call("ResetBrutalButton", PlayerData)

    --broadcastToAll(("%s has made their decision and ends the round"):format(Player[color].steam_name or color))
    if targetPlayerColor == color then
        broadcastToAll(("%s takes the 15 points for themselves"):format(Player[color].steam_name or color))
    else
        broadcastToAll(("%s removed 15 points from %s"):format(Player[color].steam_name or color, Player[targetPlayerColor].steam_name or targetPlayerColor))
    end

    if GameOptions.Autostart == CONFIG.AUTOSTART.ALWAYS or GameOptions.Autostart == CONFIG.AUTOSTART.FLIP7 then
        AutostartNextRound()
    end
    UpdateScoreBoard()
end

function UnbundleObjects(objects)
    local unbundledObjects = {}

    for _, object in pairs(objects) do
        if object.type == "Card" then
            table.insert(unbundledObjects, {src = object, is_face_down = object.is_face_down, tagSet = GenTagSet(object.getTags(), true), description = object.getDescription()})
        elseif object.type == "Deck" then
            for _, element in pairs(object.getObjects() or {}) do
                -- In a deck you don't actually get an object, just metadata
                table.insert(unbundledObjects, {src = object, is_face_down = object.is_face_down, tagSet = GenTagSet(element.tags, true), description = element.description})
            end
        end
    end

    return unbundledObjects
end

function GetAllPlayerObjects(color, unbundled)
    local playerObjects = {}
    local scriptZone = PlayerData[color].scriptZone

    for _, object in pairs(scriptZone.getObjects() or {}) do
        table.insert(playerObjects, object)
    end

    for _, object in pairs(Player[color].getHandObjects() or {}) do
        table.insert(playerObjects, object)
    end

    return unbundled and UnbundleObjects(playerObjects) or playerObjects
end

function CountItems()
    if WaitForNewRound then return end

    local anyDuplicate = false
    for _, color in pairs(PLAYER_COLORS) do
        local score, numberSum, plusSum, numbercardCount, mult = 0, 0, 0, 0, 1
        local allObjects = GetAllPlayerObjects(color, true)
        local hasDuplicateNumber = false
        local seenNumbers = {}
        local hasSecondChance = nil
        local hasLuckyThirteen = false
        local hasTheZero = false

        -- handle some special card flags before we iterate through all cards
        -- this is necessary to handle edge cases, e.g. player lost a special card during the round
        for _, object in pairs(allObjects) do
            if not object.is_face_down then
                if object.tagSet["chance"] then hasSecondChance = object.src end
                if object.tagSet["thirteen"] then hasLuckyThirteen = true end
                if object.tagSet["zero"] then hasTheZero = true end
            end
        end

        for _, object in pairs(allObjects) do
            if object.is_face_down then goto continue end

            if object.tagSet["number"] then
                local number = tonumber(object.description)

                if number then
                    local seenNumberCount = 0
                    local seenNumberTableData = seenNumbers[number]
                    if seenNumberTableData then
                        seenNumberCount = seenNumberTableData.count
                    end

                    if seenNumberCount == 0 or (number == 13 and seenNumberCount == 1 and hasLuckyThirteen) then
                        numberSum = numberSum + number

                        if not seenNumbers[number] then
                            seenNumbers[number] = {}
                        end

                        seenNumbers[number].count = seenNumberCount + 1
                        -- save the seen object, except for the lucky 13
                        if not object.tagSet["thirteen"] then
                            seenNumbers[number].obj = object.src
                        end
                    else
                        hasDuplicateNumber, anyDuplicate = true, true
                        if not HasBeenPewd then
                            local player = Player[color]
                            local broadcastMessage = (hasSecondChance and MSG_2ND_CHANCE or MSG_BUSTED):format(player.steam_name or color)
                            broadcastToAll(broadcastMessage, color)
                            PlayerData[color].status = PlayerStatus.ActionRequired
                            HasBeenPewd = true

                            -- visual notifications
                            object.src.highlightOn("Red", BUSTED_CARD_HIGHLIGHT_DURATION)
                            seenNumberTableData.obj.highlightOn("Red", BUSTED_CARD_HIGHLIGHT_DURATION)
                            if hasSecondChance then
                                local pingPosition = hasSecondChance.getPosition()
                                if GameOptions.MoveSecondChance then
                                    local _, topCard = GetSecondChances(color)
                                    if topCard then
                                        pingPosition =  object.src.positionToWorld(Vector(0, 0.5, 2))
                                        topCard.setPositionSmooth(pingPosition, false, false)
                                    end
                                end

                               if player.seated then player.pingTable(pingPosition) end
                               hasSecondChance.highlightOn("White", BUSTED_CARD_HIGHLIGHT_DURATION)
                            end
                        end
                    end
                end

                numbercardCount = numbercardCount + 1

            elseif object.tagSet["plus"]  then
                plusSum = plusSum + (tonumber(object.description) or 0)

            elseif object.tagSet["mult"] then
                mult = mult * (tonumber(object.description) or 1)
            end
            ::continue::
        end

        if not hasDuplicateNumber and not ActionBlocker.isBlocked(color) and PlayerData[color].status == PlayerStatus.ActionRequired then
            PlayerData[color].status = PlayerData[color].resetState or PlayerStatus.Active
        end

        score = math.floor(numberSum * mult + plusSum)

        if numbercardCount == 7 and not HasBeenPewd then
            if IsBrutal then
                if not BrutalScoreDecision.active then
                    BrutalScoreDecision.active = true
                    BrutalScoreDecision.by = color
                    for _, brutalPlayerColor in pairs(getSeatedPlayers()) do
                        local buttonLabel = brutalPlayerColor == color and "+15" or "-15"
                        local buttonColor = brutalPlayerColor == color and {0.6, 0.8, 0.6} or {0.8, 0.6, 0.6}

                        PlayerData[brutalPlayerColor].scoreTile.editButton({index = 2,
                            label = buttonLabel,
                            color = buttonColor,
                            width = 1500,
                            height = 1040
                        })
                    end
                end
            else
                if not Flip7Reached then
                    Flip7Reached = color
                    broadcastToAll(("%s has 7 cards and ends the round"):format(Player[color].steam_name or color))
                end
                score = score + 15
                if GameOptions.Autostart == CONFIG.AUTOSTART.ALWAYS or GameOptions.Autostart == CONFIG.AUTOSTART.FLIP7 then
                    AutostartNextRound()
                end
            end
        else
            if Flip7Reached == color then Flip7Reached = false end
        end

        if hasTheZero and numbercardCount < 7 then score = 0 end
        if hasDuplicateNumber and not hasSecondChance then score = 0 end
        Score[color] = IsBrutal and score or math.max(0, score)

        PlayerData[color].cardCount = numbercardCount
        PlayerData[color].scoreTile.editButton({index = 0, label = Score[color]})
    end

    if not anyDuplicate then HasBeenPewd = false end

    UpdateScoreBoard()

    if GameOptions.Autostart == CONFIG.AUTOSTART.ALWAYS or GameOptions.Autostart == CONFIG.AUTOSTART.ROUND then
        if AllPlayersDone() then AutostartNextRound() end
    end
end

function RemoveToken(color, position, object)
    if object and object.type == "Tile" and object.hasTag("token") then
        if object.getGMNotes() == color then
            object.destroy()
            PlayerData[color].status = PlayerStatus.Active
            PlayerData[color].resetState = false
        end
    end
end

function Bust(object, color, alt)
    if alt then return end
    if WaitForNewRound then return end
    if os.time() - LastButtonHit < 0.5 then return end
    if Flip7Reached then return broadcastToColor(MSG_WAIT_ROUND, color) end
    if not ActionBlocker.isPermitted(color) then return ActionBlocker.HighlightCard(color) end
    if IsPlayerDoneWithRound(color) then return broadcastToColor(MSG_WAIT_ROUND, color) end
    LastButtonHit = os.time()

    ActionBlocker.discardFor(color)

    for _, v in pairs(PlayerData[color].scriptZone.getObjects()) do
        if (v.type == "Deck" or v.type == "Card") and not v.is_face_down then
            v.flip()
        end
    end

    local playerData = PlayerData[color]
    playerData.status = PlayerStatus.Busted

    CreateTokenForPlayer(color, BustedBag)
    ResetPlayerCards(color, function(obj) return obj.tagSet["action"] end, true)
end

function Stay(object, color, alt)
    if alt then return end
    if WaitForNewRound then return end
    if HasBeenPewd then return end
    if os.time() - LastButtonHit < 0.5 then return end
    if Flip7Reached then return broadcastToColor(MSG_WAIT_ROUND, color) end
    if not ActionBlocker.isPermitted(color) then return ActionBlocker.HighlightCard(color) end
    if IsPlayerDoneWithRound(color) then return broadcastToColor(MSG_WAIT_ROUND, color) end
    if PlayerHasCard(color, "zero") and not PlayerHasCard(color, "action", {"Freeze", "OneMore"}) then return broadcastToColor("You've gotten THE ZERO!", color) end
    LastButtonHit = os.time()

    ActionBlocker.discardFor(color)

    local playerData = PlayerData[color]
    playerData.status = PlayerStatus.Stayed

    CreateTokenForPlayer(color, StayBag)
    ResetPlayerCards(color, function(obj) return obj.tagSet["action"] end, true)
end

function Hit(object, color, alt)
    if alt then return end
    if WaitForNewRound then return end
    if HasBeenPewd then return end
    if os.time() - LastButtonHit < 0.5 then return end
    if Flip7Reached then return broadcastToColor(MSG_WAIT_ROUND, color) end
    if not ActionBlocker.isPermitted(color) then return ActionBlocker.HighlightCard(color) end
    if IsPlayerDoneWithRound(color) then return broadcastToColor(MSG_WAIT_ROUND, color) end
    LastButtonHit = os.time()

    if IsObject(NextPlayerStartToken) then NextPlayerStartToken.destruct() end

    local playerData = PlayerData[color]
    local drawcard = GetDrawPile(true)
    if drawcard == nil then return end

    if drawcard.hasTag("seven") then
        ResetPlayerCards(color, function(obj) return not obj.tagSet["action"] end)
    end

    if drawcard.hasTag("action") or (drawcard.hasTag("modifier") and (tonumber(drawcard.getDescription()) or 1) < 1) then
        ActionBlocker.add(color, drawcard)
        playerData.status = PlayerStatus.ActionRequired
    end

    local targetSnapPoints
    if drawcard.hasTag("number") then
        targetSnapPoints = playerData.snapPoints.numbers
    elseif drawcard.hasTag("special") then
        targetSnapPoints = playerData.snapPoints.special
    end

    -- SecondChance
    if drawcard.hasTag("chance") then
        local point = playerData.snapPoints.chance[1]
        local _, top = GetSecondChances(color)
        local targetPosition = point.position
        if top then targetPosition = top.positionToWorld(Vector(-1, 0.5, 0)) end

        drawcard.setPositionSmooth(targetPosition, false, false)
        drawcard.setRotationSmooth(Vector(0, playerData.positionData.handTransform.rotation.y + 180, 0), false, false)
        targetSnapPoints = nil -- we don't need further positioning
    end

    if targetSnapPoints then
        local foundSpaceForCard = false
        for _, point in ipairs(targetSnapPoints) do
            if not IsSnapPointOccupied(point) then
                drawcard.setPositionSmooth(point.position, false, false)
                drawcard.setRotationSmooth(Vector(0, playerData.positionData.handTransform.rotation.y + 180, 0), false, false)
                foundSpaceForCard = true
                break
            end
        end

        -- if no more space, just deal to the players hand
        if not foundSpaceForCard then
            drawcard.deal(1, color)
        end
    end

    -- reshuffle draw deck if empty
    local drawPileHasCards = false
    local objectsNearDrawPile = UsePhysicsCast({
        origin       = {-1.60, 1.83, 1.13},
        max_distance = 3,
    })

    for _, v in pairs(objectsNearDrawPile) do
        if v.hit_object.type == "Deck" then
            drawPileHasCards = true
        end
    end
    if not drawPileHasCards then
        local objectsNearDiscardPile = UsePhysicsCast({
            origin       = {2.06, 1.49, 1.07},
            max_distance = 3
        })

        for _, v in pairs(objectsNearDiscardPile) do
            if v.hit_object.type == "Deck" then
                v.hit_object.setPositionSmooth({-1.60, 2.3, 1.13}, false, true)
                v.hit_object.setRotation({0, 180, 180})
                v.hit_object.shuffle()
            end
        end
    end
end

function GetSecondChances(color)
    local point = PlayerData[color].snapPoints.chance[1]
    local cards = UsePhysicsCast({origin = point.position, size = {4, 2, 1}})
    local topCard = nil

    local secondChances = {}
    for i, card in ipairs(cards) do
        if card.hit_object.hasTag("chance") then
            table.insert(secondChances, card.hit_object)

            -- It seems the topmost card is always the first index..
            if i == 1 then
                topCard = (card.hit_object.type == "Deck" and card.hit_object.takeObject() or card.hit_object) or card.hit_object
            end
        end
    end

    return secondChances, topCard
end

-- Rotate Offset
function RotateOffset(x, z, Yangle)
    local rx = math.cos(-Yangle) * x - math.sin(-Yangle) * z
    local rz = math.sin(-Yangle) * x + math.cos(-Yangle) * z
    return Vector(rx, 0, rz)
end

function IsPlayerDoneWithRound(color)
    local playerStatus = PlayerData[color].status
    if DeckMode == DeckModes.Base then
        return playerStatus == PlayerStatus.Busted or playerStatus == PlayerStatus.Stayed
    end

    if playerStatus == PlayerStatus.Busted then return true end

    -- In Vengeance and Fusion you may need to hit even if stayed
    if PlayerHasCard(color, "action", {"Flip3", "Flip4", "OneMore"}) then return false end

    return playerStatus == PlayerStatus.Busted or playerStatus == PlayerStatus.Stayed
end

function PlayerHasCard(color, tag, descriptions)
    local allObjects = GetAllPlayerObjects(color, true)
    for _, object in pairs(allObjects) do
        if object.tagSet[tag] and not object.src.held_by_color then
            if descriptions then
                for _, description in pairs(descriptions) do
                    if object.description == description then
                        return true
                    end
                end
            else
                return true
            end
        end
    end

    return false
end

function ResetPlayerCards(color, filterFunc, smooth)
    local allObjects = GetAllPlayerObjects(color, true)
    for _, object in pairs(allObjects) do
        if not filterFunc or (filterFunc and filterFunc(object)) then
            local posFunc = smooth and "setPositionSmooth" or "setPosition"
            object.src[posFunc]({2.06, 2.3, 1.07}, false, true)
            object.src.setRotation({0, 180, 0})
        end
    end
end

function AllPlayersDone()
    if Flip7Reached then return true end
    for color in pairs(PlayerData) do
        if Player[color].seated and not IsPlayerDoneWithRound(color) then return false end
    end
    return true
end

function GetDrawPile(takeCard)
    local deckscan = UsePhysicsCast({origin = {-2, 2, 1}})

    for _, v in pairs(deckscan) do
        if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
            return takeCard and (v.hit_object.type == "Deck" and v.hit_object.takeObject() or v.hit_object) or v.hit_object
        end
    end
end

function GetTotalScore(color)
    local inputs = PlayerData[color].scoreTile.getInputs()
    if inputs[1] then
        return tonumber(inputs[1].value) or 0
    end
    return 0
end

function ShiftStartingPlayer(init)
    local seatedPlayers = getSeatedPlayers()
    if #seatedPlayers > 0 then
        if init or (GameOptions.NextRoundPlayer == CONFIG.NEXT_PLAYER.RANDOM) then
            StartingPlayer = math.random(1, #seatedPlayers)
        else
            if GameOptions.NextRoundPlayer == CONFIG.NEXT_PLAYER.CW then
                StartingPlayer = StartingPlayer + 1
            elseif GameOptions.NextRoundPlayer == CONFIG.NEXT_PLAYER.CCW then
                StartingPlayer = StartingPlayer - 1
            elseif GameOptions.NextRoundPlayer == CONFIG.NEXT_PLAYER.HIGHEST then
                StartingPlayer = HighestPlayer and HighestPlayer or math.random(1, #seatedPlayers)
            elseif GameOptions.NextRoundPlayer == CONFIG.NEXT_PLAYER.LOWEST then
                StartingPlayer = LowestPlayer and LowestPlayer or math.random(1, #seatedPlayers)
            end
        end

        if StartingPlayer > #seatedPlayers then StartingPlayer = 1 end
        if StartingPlayer < 1 then StartingPlayer = #seatedPlayers end

        local player = Player[seatedPlayers[StartingPlayer]]
        CreateTokenForPlayer(player.color, NextPlayerBag)
        broadcastToAll(("%s begins.."):format(player.steam_name or player.color), player.color)
    end
end

function UpdateScoreBoard()
    local activePlayers = {}
    for i, color in ipairs(getSeatedPlayers()) do
        if Player[color].seated then
            local roundScore = Score[color] or 0
            local gameScore = GetTotalScore(color)
            local potentialScore = gameScore + roundScore

            local textColor = "#FFFFFF"
            if PlayerData[color].status == PlayerStatus.ActionRequired then
                textColor = "#FF8888"
            elseif potentialScore >= 200 then
                textColor = "#88CC88"
            elseif IsPlayerDoneWithRound(color) then
                textColor = "#AAAAAA"
            end

            table.insert(activePlayers, {
                index = i,
                name = {text = " " .. Player[color].steam_name, color = textColor},
                round = {text = roundScore, color = textColor},
                game = {text = gameScore, color = textColor},
                total = {text = potentialScore, color = textColor}
            })
        end
    end

    table.sort(activePlayers, function(a, b) return a.total.text > b.total.text end)
    HighestPlayer = activePlayers[1].index
    LowestPlayer = activePlayers[#activePlayers].index

    UI.setAttribute("table", "height", 40 + (#activePlayers * 24))
    for i, player in ipairs(activePlayers) do
        UI.setAttribute(("player%d"):format(i), "active", "true")
        UI.setAttributes(("player%d-name"):format(i), player.name)
        UI.setAttributes(("player%d-round"):format(i), player.round)
        UI.setAttributes(("player%d-game"):format(i), player.game)
        UI.setAttributes(("player%d-total"):format(i), player.total)
    end

    -- hide all rows without an active player
    for i = #activePlayers + 1, #PLAYER_COLORS do
        UI.setAttribute(("player%d"):format(i), "active", "false")
    end
end

------ TTS specific utils
function IsObject(object)
    return (object and not object.isDestroyed())
end

function UsePhysicsCast(customCastParams)
    return Physics.cast({
        origin       = customCastParams.origin       or {0, 0, 0},
        direction    = customCastParams.direction    or {0, -1, 0},
        type         = customCastParams.type         or 3,
        size         = customCastParams.size         or {1, 1, 1},
        orientation  = customCastParams.orientation  or {0, 0, 0},
        max_distance = customCastParams.max_distance or 1,
        debug        = customCastParams.debug        or false,
    })
end

function AutostartNextRound()
    if AutostartCanceled then return end
    if WaitForNewRound then return end
    if GameOptions.Autostart == CONFIG.AUTOSTART.OFF then return end
    HitBtn.call("AutostartCancel", true)
    WaitForNewRound = true

    local countdown = GameOptions.AutostartSeconds or 5
    broadcastToAll("Next round will start in")
    broadcastToAll(("%d.."):format(countdown))
    AutostartTimer = Wait.time(
        function()
            countdown = countdown - 1
            if countdown == 0 then return NewRound() end
            broadcastToAll(("%d.."):format(countdown))
        end, 1, countdown
    )
end

function CreateTokenForPlayer(color, bag)
    local playerData = PlayerData[color]
    local player3DData = playerData.positionData
    local token = bag.takeObject()
    if not token then return end

    if playerData.token and IsObject(playerData.token) then playerData.token.destruct() end

    token.setPosition(player3DData.center + RotateOffset(0, 6, player3DData.angleY))
    token.setRotation(Vector(0, player3DData.handTransform.rotation.y + 180, 0))

    local bagDescription = bag.getDescription()
    if bagDescription == "begins" then
        NextPlayerStartToken = token
    else
        token.setGMNotes(color)
        token.addContextMenuItem(("Unset %s Status"):format(bagDescription), RemoveToken)
        playerData.token = token
    end

    if GameOptions.ColoredTokens then
        --local newColor = Color.fromString(color):lerp(Color.White, 0.3)
        token.setColorTint(TOKEN_COLORS[color])
    end

    Wait.time(function() token.lock() end, 1, 1)
end

function GenTagSet(tags, lowercase)
    local tagSet = {}
    for _, tag in pairs(tags or {}) do tagSet[lowercase and tag:lower() or tag] = true end
    return tagSet
end

function HasTag(tags, tag)
    tag = tag and tag:lower() or ""
    for _, t in pairs(tags or {}) do
        if t:lower() == tag then return true end
    end
    return false
end

function GetPlayerColorFromTags(tags)
    for _, color in pairs(PLAYER_COLORS) do
        if tags[color] ~= nil then return color end
    end
end

------ Utils
function table.size(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function PrintDebugLogs()
    local flags = {
        ["HasBeenPewd"]=HasBeenPewd,
        --["NextPlayerStartToken"]=IsObject(NextPlayerStartToken),
        ["WaitForNewRound"]=WaitForNewRound,
        ["BrutalScoreDecision"]=BrutalScoreDecision,
        ["ActionBlocker"]=ActionBlocker,
        ["GameOptions"]=GameOptions
    }
    printToColor(JSON.encode_pretty(flags), "White")
end

--- Action Card Blocker
ActionBlocker = {}

function ActionBlocker.reset()
    ActionBlocker.cards = {}
end

function ActionBlocker.add(color, object)
    local new = {by = color, src = object}
    table.insert(ActionBlocker.cards, new)
end

function ActionBlocker.isBlocked(color)
    if not GameOptions.ActionBlocker then return false end
    if not color then return #ActionBlocker.cards > 0 end
    for _, card in pairs(ActionBlocker.cards) do
        if card.by == color then
            return true
        end
    end
end

function ActionBlocker.isPermitted(color)
    if not GameOptions.ActionBlocker then return true end
    if not ActionBlocker.isBlocked() then return true end

    local card = ActionBlocker.get()
    if card.by == color then return true end
    if PlayerData[color].status == PlayerStatus.ActionRequired then return true end
    return false
end

function ActionBlocker.get()
    return ActionBlocker.cards[1]
end

function ActionBlocker.isAny(object)
    for _, card in pairs(ActionBlocker.cards) do
        if card.src == object then
            return true
        end
    end
end

function ActionBlocker.update(object, color)
    for _, card in pairs(ActionBlocker.cards) do
        if card.src == object then
            card.by = color
        end
    end
end

function ActionBlocker.discard(object)
    for i, card in ipairs(ActionBlocker.cards) do
        if card.src == object then
            return table.remove(ActionBlocker.cards, i)
        end
    end
end

function ActionBlocker.discardFor(color)
    for i = #ActionBlocker.cards, 1, -1 do
        local card = ActionBlocker.cards[i]
        if card.by == color then
            table.remove(ActionBlocker.cards, i)
        end
    end
end

function ActionBlocker.HighlightCard(fromColor)
    if not ActionBlocker.isBlocked() then return end
    local actionCard = ActionBlocker.get().src
    if IsObject(actionCard) then
        if Player[fromColor].seated then Player[fromColor].pingTable(actionCard.getPosition()) end
        actionCard.highlightOn("Red", 3)
    end
end