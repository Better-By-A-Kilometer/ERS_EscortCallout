local PossibleLocations = {
    ["Standard"] = {
        StartingLocations = {
            vector3(0, 0, 0)
        },
        Destinations = {
            vector3(0, 0, 0)
        },
        NumberOfVIPs = 1,
        NumberOfEnemies = 0,
        EnemyTimeout = { 0.25, 0.5 } -- [min, max] -- Decimal percentages represent the distance to destination. 
    },
    ["Danger"] = {
        StartingLocations = {
            vector3(0, 0, 0)
        },
        Destinations = {
            vector3(0, 0, 0)
        },
        NumberOfVIPs = 1,
        NumberOfEnemies = 2,
        EnemyTimeout = { 0.25, 0.7 } -- [min, max] -- Decimal percentages represent the distance to destination.
    }
}

function GetLocations()
    local t = {};
    for _, obj in pairs(PossibleLocations) do
        if obj.Enabled then
            for _, vec in pairs(obj.StartingLocations) do
                table.insert(t, vec);
            end
        end
    end
    return t;
end

Config.Callouts["kilo_escorts"] = {
    Enabled = true,
    CalloutName = "VIP Escort",
    CalloutDescriptions = {
        "A VIP has requested the police's help getting to a destination!",
    },
    CalloutUnitsRequired = {
        description = "Police.",
        policeRequired = true,
        ambulanceRequired = false,
        fireRequired = false,
        towRequired = false,
    },
    CalloutLocations = GetLocations(),
    PedChanceToFleeFromPlayer = 0, -- Value between 0 and 100 -> Lower is less chance.
    PedChanceToAttackPlayer = 100, -- Value between 0 and 100 -> Lower is less chance.
    PedChanceToSurrender = 0, -- Value between 0 and 100 -> Lower is less chance.
    PedChanceToObtainWeapons = 100, -- Value between 0 and 100 -> Lower is less chance.
    PedActionMinimumTimeoutInMs = 10000, -- Milliseconds for the minimum timeout time to start the secondary action listed above.
    PedActionMaximumTimeoutInMs = 15000, -- Milliseconds for the maximum timeout time to start the secondary action. Must be a higher number than the minimum!
    PedActionOnNoActionFound = "attack", -- When no action of the above options is found. It'll perform this action after the set timeout. Options: "none", "attack", "flee", "surrender"
    PedWeaponData = { -- The ped will be given one randomly selected weapon (in hand) from these weapons if PedChanceToObtainWeapons passed.
        "weapon_knife",
        "weapon_pistol",
        "weapon_smg",
        "weapon_machinepistol",
        "weapon_appistol"
    },
    client = function(plyPed, pedList, vehicleList, playersList, objectList, propList, fireList, smokeList, calloutDataClient)
        isActive = true;
        local Text3DInProgress = {};
        local Utils = {
            GetRandomModel = function(typeName)
                local code = math.random(0, 999999999999999);
                local modelName = nil;
                local waiting = true;
                local callback;
                callback = RegisterNetEvent("KiloERS:Callback="..tostring(code), function(_modelName)
                    waiting = false;
                    modelName = _modelName;
                    CreateThread(function()
                        Wait(1000);
                        RemoveEventHandler(callback);
                    end)
                end)
                TriggerServerEvent("KiloERS:GetRandomModel", calloutDataClient, typeName, code);
                while waiting do
                    Wait(100);
                end
                return modelName;
            end,
            CreateMathPed = function(coords, deleteTimeout)
                if not deleteTimeout then
                    deleteTimeout = 10000;
                end
                local ped = CreatePed(0, "s_m_y_cop_01", coords.x, coords.y, coords.z, 0.0, true, true);
                SetEntityVisible(ped, false, 0);
                Wait(100);
                SetPedKeepTask(ped, true);
                BlockPedDeadBodyShockingEvents(ped, true);
                FreezeEntityPosition(ped, true);
                CreateThread(function()
                    Wait(deleteTimeout);
                    DeleteEntity(ped);
                    ped = nil;
                end)
                return ped;
            end,
            GetCurrentRoomSize = function(ped)
                local interiorId = GetInteriorFromEntity(ped);
                local roomHash = GetRoomKeyFromEntity(ped);
                local roomId = GetInteriorRoomIndexByHash(interiorId, roomHash)
                if roomId ~= -1 then
                    local minX, minY, minZ, maxX, maxY, maxZ = GetInteriorRoomExtents(interiorId, roomId);
                    local sizeX, sizeY, sizeZ = (maxX - minX), (maxY - minY), (maxZ - minZ);
                    local size = vector3(sizeX, sizeY, sizeZ);
                    return size;
                end
                return nil;
            end,
            SubtitleChat = function(entity, text, red, green, blue, opacity, force)
                if force == nil then
                    force = true
                end;
                if not red then
                    red = 255;
                end
                if not green then
                    green = 255;
                end
                if not blue then
                    blue = 255;
                end
                if not opacity then
                    opacity = 255;
                end
                if not text then
                    text = "";
                end
                if force then
                    Text3DInProgress = {};
                end
                local i = table.insert(Text3DInProgress, text);
                for _i, v in pairs(Text3DInProgress) do
                    if v == text then
                        i = _i;
                    end
                end
                local time = string.len(text) * 150;
                local timePassed = 0;
                local offset = vector3(0.0, 0.0, 1.0);
                local scaleFactor = 0.5;
                CreateThread(function()
                    while Text3DInProgress[i] ~= nil and isActive do
                        if (HasEntityClearLosToEntityInFront(plyPed, entity)) then
                            local pos = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z);
                            local result, screenX, screenY = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z);
                            local p = GetGameplayCamCoord();
                            local dist = GetDistanceBetweenCoords(p.x, p.y, p.z, pos.x, pos.y, pos.z, true);
                            local scale = (1 / dist) * 2;

                            local fov = (1 / GetGameplayCamFov()) * 100;
                            scale = scale * fov * scaleFactor;
                            if not result then
                                return
                            end;
                            SetTextScale(0.0, scale);
                            SetTextFont(0);
                            SetTextProportional(true);
                            SetTextColour(red, green, blue, opacity);
                            SetTextDropshadow(0, 0, 0, 0, 255);
                            SetTextEdge(2, 0, 0, 0, 150);
                            SetTextDropShadow();
                            SetTextOutline();
                            SetTextEntry("STRING");
                            SetTextCentre(true);
                            AddTextComponentString(text);
                            DrawText(screenX, screenY);
                        end
                        Wait(0);
                    end
                end)
                while timePassed < time and isActive do
                    local loopTimeout = 100; -- Increase for better performance, at expense of script performance.
                    timePassed = timePassed + loopTimeout;
                    Citizen.Wait(loopTimeout);
                end
                table.remove(Text3DInProgress, i);
                Citizen.Wait(1000);
            end,
            ShowDialog = function(text, duration, drawImmediately)
                if not duration then
                    duration = (string.len(text) * 150)
                end;
                if drawImmediately == nil then
                    drawImmediately = false
                end;
                BeginTextCommandPrint("STRING");
                AddTextComponentString(text);
                EndTextCommandPrint(duration, drawImmediately);
            end,
            SpawnPed = function(model, location, keepTask)
                if not keepTask then
                    keepTask = true
                end;
                local ped = nil;
                local pedNetId = nil;
                local code = math.random(0, 999999999999999);
                local callback;
                callback = RegisterNetEvent("KiloERS:Callback=" .. tostring(code), function(netId, updatedPedList)
                    Wait(500);
                    ped = NetworkGetEntityFromNetworkId(netId);
                    pedNetId = netId;
                    pedList = updatedPedList;
                    CreateThread(function()
                        Wait(1000);
                        RemoveEventHandler(callback);
                    end)
                end)
                TriggerServerEvent("KiloERS:SpawnPed", calloutDataClient, model, location, code);
                while (pedNetId == nil) and isActive do
                    Wait(100);
                end
                if DoesEntityExist(ped) then
                    ERS_RequestNetControlForEntity(ped)
                    if keepTask then
                        ERS_ClearPedTasksAndBlockEvents(ped);
                    end
                end
                return ped, pedNetId;
            end,
            SpawnObject = function(model, location)
                local object = nil;
                local netId = nil;
                local code = math.random(0, 999999999999999);
                local callback;
                callback = RegisterNetEvent("KiloERS:Callback=" .. tostring(code), function(_netId, updatedPropList)
                    Wait(100);
                    object = NetworkGetEntityFromNetworkId(_netId);
                    netId = _netId;
                    if DoesEntityExist(object) then
                        propList = updatedPropList;
                        ERS_RequestNetControlForEntity(object)
                    end
                    CreateThread(function()
                        Wait(1000);
                        RemoveEventHandler(callback);
                    end)
                end)
                TriggerServerEvent("KiloERS:SpawnObject", calloutDataClient, model, location, code);
                while (netId == nil) and isActive do
                    Wait(100);
                end
                return object, netId;
            end,
            SpawnVehicle = function(model, location)
                local veh = nil;
                local vehNetId = nil;
                local code = math.random(0, 999999999999999);
                local callback;
                callback = RegisterNetEvent("KiloERS:Callback=" .. tostring(code), function(_vehNetId, updatedVehicleList)
                    Wait(100);
                    veh = NetworkGetEntityFromNetworkId(_vehNetId);
                    vehNetId = _vehNetId;
                    vehicleList = updatedVehicleList;
                    CreateThread(function()
                        Wait(1000);
                        RemoveEventHandler(callback);
                    end)
                end)
                TriggerServerEvent("KiloERS:SpawnVehicle", calloutDataClient, model, location, code);
                while (vehNetId == nil) and isActive do
                    Wait(100);
                end
                if DoesEntityExist(veh) then
                    ERS_RequestNetControlForEntity(veh)
                end
                return veh, vehNetId;
            end,
            TaskEnterVehicle = function(ped, veh, seat, timeout)
                if not timeout then
                    timeout = 30000
                end;
                if not seat then
                    seat = -1;
                end;
                local seatIndex = seat;
                local function Timeout()
                    Wait(timeout)
                    SetPedIntoVehicle(ped, veh, seatIndex);
                end
                CreateThread(Timeout);
                while not IsVehicleSeatFree(veh, seatIndex) and seatIndex < (GetVehicleMaxNumberOfPassengers(veh) - 1) do
                    seatIndex = seatIndex + 1;
                    Wait(100);
                end
                if GetVehicleNumberOfPassengers(veh) == GetVehicleMaxNumberOfPassengers(veh) then
                    ERS_SetPedToFleeFromPlayer(ped);
                else
                    if not IsVehicleSeatAccessible(ped, veh, seatIndex, GetVehicleClass(veh) == 8, true) then
                        SetPedIntoVehicle(ped, veh, seatIndex);
                    else
                        TaskEnterVehicle(ped, veh, -1, seatIndex, 2.0, 1, 0);
                    end
                end
                return seatIndex;
            end,
            IsPedCuffed = function(ped)
                if DecorExistOn(ped, 'PED_IS_CUFFED') then
                    if DecorGetInt(ped, 'PED_IS_CUFFED') == 1 then
                        return true
                    end
                end
                return false
            end,
        }

        for _, pedNetId in pairs(pedList) do
            local ped = NetToPed(pedNetId)
            if DoesEntityExist(ped) then
                ERS_RequestNetControlForEntity(ped)
            end
        end
        local locations = {};
        for i, v in pairs(PossibleLocations) do
            for name, v2 in pairs(v) do
                if v2.CalloutLocation == calloutDataClient.Coordinates then
                    locations[name] = v2;
                end
            end
        end

        local Location = locations[math.random(1, #locations)];
        local Destination = Location.Destinations[math.random(1, #Location.Destinations)];
        local NumberOfVIPs = Location.NumberOfVIPs;
        local NumberOfEnemies = Location.NumberOfEnemies;
        local EnemyTimeout = Location.EnemyTimeout;
        
        -- Spawning VIPs
        for i = 1, NumberOfVIPs do
            local succ, res = pcall(function()
                local vip = Utils.SpawnPed(Utils.GetRandomModel("randomPeds"), calloutDataClient.Coordinates, true);
                Entity(vip).state:set('PedType', 'VIP', false);
                table.insert(pedList, vip);
                -- TODO?: Add marker and animation logic.\
                
                CreateThread(function()
                    -- TODO: Make VIPs wait until a player driving a vehicle is nearby.
                    local closestVeh;
                    while isActive do
                        Wait(100);
                        local allVehicles = GetGamePool("CVehicle");
                        local maxDistance = 10.0;
                        for _,handle in pairs(allVehicles) do
                            if Vdist(GetEntityCoords(handle), GetEntityCoords(PlayerPedId()) < maxDistance) and IsPedAPlayer(GetPedInVehicleSeat(handle, -1) or -1) then
                                maxDistance = Vdist(GetEntityCoords(handle), GetEntityCoords(PlayerPedId()));
                                closestVeh = handle;
                            end;
                        end
                        if closestVeh and DoesEntityExist(closestVeh) then
                            break;
                        end
                    end
                    -- Got a vehicle to get into: closestVeh!
                    -- TODO: Make VIP enter first unoccupied passenger seat of vehicle.
                end)
            end)
            if not succ then
                print("^8Error while spawning VIPs: ^0"..tostring(res));
            end
        end

        -- Spawning Enemies
        for i = 1, NumberOfEnemies do
            local succ, res = pcall(function()
                CreateThread(function()
                    local desiredProgress = math.random(EnemyTimeout[1], EnemyTimeout[2]);
                    -- TODO: Wait until route progress reaches desired %.
                    local vehicleModel = Utils.GetRandomModel("randomLuxuryVehicles"); 
                    -- TODO: Spawn suspect in random [luxury] vehicle.
                    -- TODO: Chase the VIPs asynchronously. Not exactly the players and once multiple enemies are in the chase, smartly distribute enemies after each VIP. 
                end)
            end)
            if not succ then
                print("^8Error while spawning enemies: ^0"..tostring(res));
            end
        end
        
        -- TODO: Make VIPs enter player vehicle when nearby. If vehicle is full, wait for another player-driven vehicle to arrive and then get in.
        
        -- TODO: Generate waypoint route.
        
        -- TODO: Deliver waypoint to the driver players asynchronously once at least one VIP enters any player's vehicle.
        
        -- TODO: VIPs exit vehicles upon arrival asynchronously.
        
        ERS_CreateTemporaryBlipForEntities(pedList, 150000)

        function OnEndedACallout()
            isActive = false;
            for i, netId in pairs(pedList) do
                local ped = NetworkGetEntityFromNetworkId(netId);
                if DoesEntityExist(ped) then
                    if Utils.IsPedCuffed(ped) then
                        pedList[i] = nil; -- Removes the ped from deletion.
                    end
                end
            end
            TriggerServerEvent("KiloERS:CalloutEnd", pedList, vehicleList, propList) -- Important because it cleans up the additional threads running on the server.
        end
    end,
    server = function(request, src, calloutData, pedList, vehicleList, objectList, propList, playersList, fireList, smokeList)
        -- Delegates for Utils functions.
        local function SpawnVehicle(vehModel, location)
            local vehNetId = ERS_CreateVehicle(vehModel, "automobile", vector3(location.x, location.y, location.z),
                    location.w);
            local veh = NetworkGetEntityFromNetworkId(vehNetId);
            table.insert(vehicleList, vehNetId);
            return veh, vehNetId;
        end

        local function SpawnPed(model, location, veh)
            if not model then
                model = ERS_GetRandomModel(Config.randomPeds)
            end ;
            local netId = ERS_CreatePed(model, vector3(location.x, location.y, location.z), location.w);
            local ped = NetworkGetEntityFromNetworkId(netId);
            table.insert(pedList, netId);
            return ped, netId;
        end

        local function SpawnObject(model, location)
            local netId = ERS_CreateObject(model, vector3(location.x, location.y, location.z), location.w);
            local object = NetworkGetEntityFromNetworkId(netId);
            table.insert(propList, netId);
            return object, netId;
        end

        local vehicleEvent = RegisterNetEvent("KiloERS:SpawnVehicle", function(_calloutData, vehModel, location, code)
            local src = source;
            if calloutData.calloutId ~= _calloutData.calloutId or src ~= calloutData.hostId then
                return
            end ;
            local veh, netId = SpawnVehicle(vehModel, location);
            TriggerClientEvent("KiloERS:Callback=" .. tostring(code), src, netId, vehicleList);
        end)

        local pedEvent = RegisterNetEvent("KiloERS:SpawnPed", function(_calloutData, model, location, code)
            local src = source;
            if calloutData.calloutId ~= _calloutData.calloutId or src ~= calloutData.hostId then
                return
            end ;
            local ped, netId = SpawnPed(model, location);
            TriggerClientEvent("KiloERS:Callback=" .. tostring(code), src, netId, pedList);
        end)

        local objectEvent = RegisterNetEvent("KiloERS:SpawnObject", function(_calloutData, model, location, code)
            local src = source;
            if calloutData.calloutId ~= _calloutData.calloutId or src ~= calloutData.hostId then
                return
            end ;
            local ped, netId = SpawnObject(model, location);
            TriggerClientEvent("KiloERS:Callback=" .. tostring(code), src, netId, propList);
        end)
        
        local modelEvent = RegisterNetEvent("KiloERS:GetRandomModel", function(_calloutData, configName, code)
            if calloutData.calloutId ~= _calloutData.calloutId or source ~= calloutData.hostId then return end;
            TriggerClientEvent("KiloERS:Callback="..tostring(code), source, ERS_GetRandomModel(Config[configName]))
        end)

        local endEvent;
        endEvent = RegisterNetEvent("KiloERS:CalloutEnd", function(pedList, vehicleList, propList)
            for _, netId in pairs(pedList) do
                local ped = NetworkGetEntityFromNetworkId(netId);
                if DoesEntityExist(ped) then
                    DeleteEntity(ped);
                end
            end
            for _, netId in pairs(vehicleList) do
                local veh = NetworkGetEntityFromNetworkId(netId);
                if DoesEntityExist(veh) then
                    DeleteEntity(veh);
                end
            end
            for _, netId in pairs(propList) do
                local prop = NetworkGetEntityFromNetworkId(netId);
                if DoesEntityExist(prop) then
                    DeleteEntity(prop);
                end
            end
            Citizen.CreateThread(function()
                Citizen.Wait(1000);
                -- Cleans up the events
                RemoveEventHandler(endEvent);
                RemoveEventHandler(vehicleEvent);
                RemoveEventHandler(pedEvent);
                RemoveEventHandler(objectEvent);
                RemoveEventHandler(modelEvent);
            end)
        end)

        -- Build VIP
        local pedModel = ERS_GetRandomModel(Config.randomPeds)
        local pedCoords = vector3(calloutData.Coordinates.x, calloutData.Coordinates.y, calloutData.Coordinates.z + 1.0)
        local pedHeading = math.random(360)
        local pedNetId = ERS_CreatePed(pedModel, pedCoords, pedHeading)
        table.insert(pedList, pedNetId)

        return true
    end
}