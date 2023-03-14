if on ~= false and on ~= true and on ~= nil then on = true end -- Preventing funny stuff like setting on to a string
if on == nil then on = false end -- Changing nil to false

-- Anti AFK --
repeat task.wait() until game:GetService("Players").LocalPlayer
for i,v in pairs(getconnections(game:GetService("Players").LocalPlayer.Idled)) do
	v:Disable()
end

local ci = game.ReplicatedStorage:WaitForChild("CargoInfo") -- Folder for the three traders
local remote = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop") -- Remote for buying and selling
local Main = { -- Tables for the three traders, to organize and so I don't need an entire function just to get what you can buy from each, just to use in the function below
    Bricklandia = {
        CFrame = CFrame.new(-461, -25, 234),
        Info = ci:WaitForChild("BricklandiaCargoTrader"),
        Cargo = {"flowers", "iron", "chalices"},
    },
    Farlands = {
        CFrame = CFrame.new(1090, -25, -185),
        Info = ci:WaitForChild("FarlandsCargoTrader"),
        Cargo = {"coal", "lumber", "potions"},
    },
    Pirate = {
        CFrame = CFrame.new(160, -25, -1535),
        Info = ci:WaitForChild("PirateCargoTrader"),
        Cargo = {"fish", "gunpowder", "gold"},
    }
}

function Main:GetSellerFromItem(item) -- Get the trader that sells the inputted item
    if table.find(Main.Bricklandia.Cargo, item) then return Main.Bricklandia end
    if table.find(Main.Farlands.Cargo, item) then return Main.Farlands end
    if table.find(Main.Pirate.Cargo, item) then return Main.Pirate end
end

function Main:GetHighestValuedItem()
    -- Get the item that sells for the most, and from who.
    -- For each item, you can sell to 2 traders for a price usually $200+, and 1 trader you can buy it from for $50.
    -- The 2 traders that you can sell to have different prices, and so it is necessary to know which trader the higher sell value actually comes from.
    local highestmoney
    local highestitem
    local trader
    local function ForLoop(item, tr) -- I need to do 3 different for loops for each trader to do the exact same thing, so it's more efficient to make a function
        if not highestmoney and not highestitem and not trader then
            highestmoney = item.Value
            highestitem = item.Name
            trader = tr
        elseif item.Value > highestmoney then
            highestmoney = item.Value
            highestitem = item.Name
            trader = tr
        end
    end
    for _, v in pairs(Main.Bricklandia.Info.Sell:GetChildren()) do ForLoop(v, Main.Bricklandia) end
    for _, v in pairs(Main.Farlands.Info.Sell:GetChildren()) do ForLoop(v, Main.Farlands) end
    for _, v in pairs(Main.Pirate.Info.Sell:GetChildren()) do ForLoop(v, Main.Pirate) end
    return highestitem, trader, highestmoney
end

function Main:Shop(item, isbuying) -- Function for the remote
    remote:FireServer(item, false, isbuying)
end

Main.DoYourThing = function(chr) -- The main thing, connects to CharacterAdded and then executes on your character (if it exists)
    local ncf = nil
    local hrp = chr:WaitForChild("HumanoidRootPart")
    local hum = chr:WaitForChild("Humanoid")
    local noclip = game:GetService("RunService").Stepped:Connect(function() -- Noclip and teleporting
        if ncf then
            hrp.CFrame = ncf
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
        for _, v in pairs(chr:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end)
    task.wait(3) -- Just in case, wait 3 seconds before actually starting the repeat loop
    repeat
        local buy, seller, mon = Main:GetHighestValuedItem() -- Get the item with highest sell price, the actual sell price, and the trader that it is from
        Buying.Text = "Highest Valued Item: " .. buy .. " ($" .. tostring(mon) .. ")" -- Update the UI with the item and its price
        local buyer = Main:GetSellerFromItem(buy) -- Get the trader you can buy the item from
        ncf = buyer.CFrame -- Loop tp to the trader you buy from
        task.wait(0.5) -- Just in case, wait a moment before buying
        Main:Shop(buy, true) -- Buy the item
        task.wait(10.5) -- Wait 10 seconds, because if you do it quicker than that the game will not let you sell (the added .5 is a failsafe)
        ncf = seller.CFrame -- Loop tp to the trader you can sell to
        task.wait(0.5) -- Just in case, wait a moment before selling
        Main:Shop(buy, false) -- Sell the item
        task.wait(0.5) -- Wait a moment just in case it doesn't sell before tping away
    until hum.Health <= 0 or not on -- Stop the loop if it is turned off or if you die (if you die, it re-initializes when you respawn. That's what the task.wait(3) above the loop was for.)
    noclip:Disconnect() -- Stop the noclip and loop tp
    hum.Health = 0 -- You should kill yourself, NOW! (in case you turned it off manually)
end

if showui then -- Only disable rendering if showing UI
    game:GetService("RunService"):Set3dRenderingEnabled(not on) -- The reason why I had that thing that checks if on is actually true/false at the top
else
    game:GetService("RunService"):Set3dRenderingEnabled(true)
end

if on and not conn then -- If the script is toggled on and isn't already on, turn it on
    ls = game.Players.LocalPlayer:WaitForChild("leaderstats")
    coins = ls:WaitForChild("coins")
    if coins.Value < 50 then -- Send a notification if you don't have enough coins to buy cargo
        game:GetService("StarterGui"):SetCore("SendNotification", {
	        Title = "PMEBGE Cargo Farm";
	        Text = "You need 50 coins to start using this. Go make around 9 caik and sell them.";
	        Duration = 10;
        })
        game:GetService("RunService"):Set3dRenderingEnabled(true) -- Re-enable rendering
        getgenv().on = false
        return -- Don't execute anything below
    end
    if game.Players.LocalPlayer.Team == game:GetService("Teams").choosing then -- Send a notification if you haven't chosen a team
        game:GetService("StarterGui"):SetCore("SendNotification", {
	        Title = "PMEBGE Cargo Farm";
	        Text = "Please select a team before executing.";
	        Duration = 5;
        })
        game:GetService("RunService"):Set3dRenderingEnabled(true) -- Re-enable rendering
        getgenv().on = false
        return -- Don't execute anything below
    end
    
    -- The UI
    -- Locals aren't used so the functions can access it
    
	CargoShipper = Instance.new("ScreenGui")
	Background = Instance.new("Frame")
	Title = Instance.new("TextLabel")
	Subtitle = Instance.new("TextLabel")
	Profit = Instance.new("TextLabel")
	Loss = Instance.new("TextLabel")
	Total = Instance.new("TextLabel")
	Buying = Instance.new("TextLabel")

	CargoShipper.Name = "CargoShipper"
	CargoShipper.Parent = game.CoreGui
	CargoShipper.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	CargoShipper.Enabled = showui

	Background.Name = "Background"
	Background.Parent = CargoShipper
	Background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Background.BorderSizePixel = 0
	Background.Size = UDim2.new(1, 0, 1.05, 0)
	Background.Position = UDim2.new(0, 0, -0.05, 0)

	Title.Name = "Title"
	Title.Parent = Background
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1.000
	Title.BorderSizePixel = 0
	Title.Size = UDim2.new(1, 0, 0.200000003, 0)
	Title.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Bold)
	Title.Text = "PMEBGE Cargo Farm"
	Title.TextColor3 = Color3.fromRGB(255, 255, 0)
	Title.TextScaled = true
	Title.TextSize = 14.000
	Title.TextWrapped = true

	Subtitle.Name = "Subtitle"
	Subtitle.Parent = Background
	Subtitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Subtitle.BackgroundTransparency = 1.000
	Subtitle.BorderSizePixel = 0
	Subtitle.Position = UDim2.new(0, 0, 0.120370358, 0)
	Subtitle.Size = UDim2.new(1, 0, 0.100000001, 0)
	Subtitle.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
	Subtitle.Text = "by hountor haziste"
	Subtitle.TextColor3 = Color3.fromRGB(255, 255, 0)
	Subtitle.TextSize = 36.000
	Subtitle.TextWrapped = true

	Profit.Name = "Profit"
	Profit.Parent = Background
	Profit.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Profit.BackgroundTransparency = 1.000
	Profit.BorderSizePixel = 0
	Profit.Position = UDim2.new(0, 0, 0.300000012, 0)
	Profit.Size = UDim2.new(1, 0, 0.100000001, 0)
	Profit.Font = Enum.Font.Arcade
	Profit.Text = "Profits: $0"
	Profit.TextColor3 = Color3.fromRGB(0, 255, 0)
	Profit.TextSize = 75.000
	Profit.TextWrapped = true

	Loss.Name = "Loss"
	Loss.Parent = Background
	Loss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Loss.BackgroundTransparency = 1.000
	Loss.BorderSizePixel = 0
	Loss.Position = UDim2.new(0, 0, 0.600000024, 0)
	Loss.Size = UDim2.new(1, 0, 0.100000001, 0)
	Loss.Font = Enum.Font.Arcade
	Loss.Text = "Expenses: $0"
	Loss.TextColor3 = Color3.fromRGB(255, 0, 0)
	Loss.TextSize = 75.000
	Loss.TextWrapped = true

	Total.Name = "Total"
	Total.Parent = Background
	Total.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Total.BackgroundTransparency = 1.000
	Total.BorderSizePixel = 0
	Total.Position = UDim2.new(0, 0, 0.450000018, 0)
	Total.Size = UDim2.new(1, 0, 0.100000001, 0)
	Total.Font = Enum.Font.Arcade
	Total.Text = "Total: $0"
	Total.TextColor3 = Color3.fromRGB(255, 255, 255)
	Total.TextSize = 100.000
	Total.TextWrapped = true

	Buying.Name = "Buying"
	Buying.Parent = Background
	Buying.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Buying.BackgroundTransparency = 1.000
	Buying.BorderSizePixel = 0
	Buying.Position = UDim2.new(0, 0, 0.9, 0)
	Buying.Size = UDim2.new(1, 0, 0.100000001, 0)
	Buying.Font = Enum.Font.Arcade
	Buying.Text = "Highest Valued Item: ???? ($???)"
	Buying.TextColor3 = Color3.fromRGB(255, 255, 0)
	Buying.TextSize = 75.000
	Buying.TextWrapped = true
    getgenv().conn = conn or {} -- Table for connections
    -- Stuff for the profits/expenses/total in the UI
    local ov = coins.Value
    local win = 0
    local lose = 0
    local tot = 0
    local d  = coins.Changed:Connect(function(nv)
        local diff = nv - ov
        ov = nv
        if diff == 0 then return end
        if diff < 0 then
            lose = lose + math.abs(diff)
            Loss.Text = "Expenses: -$" .. tostring(lose)
            tot = win - lose
        elseif diff > 0 then
            win = win + math.abs(diff)
            Profit.Text = "Profits: +$" .. tostring(win)
            tot = win - lose
        end
        if tot == 0 then
            Total.TextColor3 = Color3.new(1, 1, 1)
            Total.Text = "Total: $0"
        elseif tot > 0 then
            Total.TextColor3 = Color3.new(1, 1, 0)
            Total.Text = "Total: +$" .. tostring(math.abs(tot))
        elseif tot < 0 then
            Total.TextColor3 = Color3.fromRGB(255, 100, 0)
            Total.Text = "Total: -$" .. tostring(math.abs(tot))
        end
    end)
    local c = game.Players.LocalPlayer.CharacterAdded:Connect(Main.DoYourThing) -- Connect to CharacterAdded in case you die in the farm
    table.insert(conn, c) -- Add to table of connections
    if game.Players.LocalPlayer.Character then -- Execute on character if one is already spawned
        Main.DoYourThing(game.Players.LocalPlayer.Character)
    end
elseif not on and conn then -- If the script is toggled off and is currently on, turn it off
    game:GetService("StarterGui"):SetCore("SendNotification", { -- Send a notification that it turned off
	   Title = "PMEBGE Cargo Farm";
	   Text = "Turned script off. It will finish the current cycle of buy and sell before shutting off.";
	   Duration = 10;
    })
    for _, con in pairs(conn) do -- Disconnect both connections
        con:Disconnect()
    end
    conn = nil -- Delete the whole table
    if game.CoreGui:FindFirstChild("CargoShipper") then game.CoreGui:FindFirstChild("CargoShipper"):Destroy() end -- Delete the UI
    game:GetService("RunService"):Set3dRenderingEnabled(true) -- Re-enable rendering
elseif  on and conn then -- If the script is toggled on but is already on, toggle the UI based on getgenv().showui
    local CargoShipper = game.CoreGui:FindFirstChild("CargoShipper")
    game:GetService("RunService"):Set3dRenderingEnabled(not showui) -- If showing UI then disable rendering, enable it if otherwise
    if CargoShipper then -- Only enable the UI if it actually exists
        CargoShipper.Enabled = showui
    end
end
