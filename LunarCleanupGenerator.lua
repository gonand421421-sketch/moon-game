-- LUNAR CLEANUP | Paste this entire file into Studio's Command Bar in EDIT mode.
-- Original primitive-only prototype. No external assets. Generated content is namespaced.
local RunService = game:GetService('RunService')
assert(not RunService:IsRunning(), 'Stop the play session. Run this generator in EDIT mode.')
local Workspace = game:GetService('Workspace')
local Lighting = game:GetService('Lighting')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local StarterPlayer = game:GetService('StarterPlayer')
local NAME = 'LunarCleanup'
-- Only remove objects owned by this generator; leave Terrain and other projects untouched.
for _, parent in ipairs({Workspace, ReplicatedStorage, ServerScriptService, StarterPlayer.StarterPlayerScripts}) do
 local old = parent:FindFirstChild(NAME)
 if old then old:Destroy() end
end
for _, child in ipairs(Lighting:GetChildren()) do
 if child:GetAttribute('LunarCleanupOwned') then child:Destroy() end
end
local map = Instance.new('Model'); map.Name = NAME; map.Parent = Workspace
local net = Instance.new('Folder'); net.Name = NAME; net.Parent = ReplicatedStorage
for _, name in ipairs({'Scrub','Action','Feedback'}) do
 local remote = Instance.new('RemoteEvent'); remote.Name = name; remote.Parent = net
end
local config = Instance.new('ModuleScript'); config.Name = 'Config'; config.Parent = net
config.Source = [==[
return {
 Version = 1, PatchSize = 0.85, Columns = 14, Rows = 14, PatchHealth = 12,
 Range = 14, Tick = 0.10, ResetSeconds = 35,
 Tools = {
  {Name='TOOTHBRUSH', Radius=0.48, Power=16, Price=0},
  {Name='REGOLITH BRUSH', Radius=1.05, Power=24, Price=240},
  {Name='INDUSTRIAL SCRUBBER', Radius=1.8, Power=34, Price=1100},
 },
 SpeedPrices={90,260,650,1400}, RadiusPrices={120,340,800}, StoragePrices={70,200,520,1100,2200},
 Capacity=function(level) return 100 + level*100 + level*level*25 end,
}
]==]
local C = require(config)
local function part(name, size, cf, color, material, parent)
 local p = Instance.new('Part'); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
 p.Material=material or Enum.Material.Metal; p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth
 p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent or map; return p
end
local gray=Color3.fromRGB(101,103,105)
local dark=Color3.fromRGB(37,41,45)
local function label(p, text)
 local gui=Instance.new('SurfaceGui'); gui.Face=Enum.NormalId.Front; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
 gui.PixelsPerStud=45; gui.Parent=p
 local t=Instance.new('TextLabel'); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1
 t.Text=text; t.TextColor3=Color3.fromRGB(213,224,226); t.Font=Enum.Font.GothamMedium
 t.TextScaled=true; t.Parent=gui
end
-- A bounded primitive landscape avoids destructive Terrain:Clear() and survives reruns cleanly.
part('MoonSurface',Vector3.new(320,8,320),CFrame.new(0,-4,0),gray,Enum.Material.Sand)
local rng=Random.new(74219)
for i=1,65 do
 local x,z=rng:NextNumber(-145,145),rng:NextNumber(-145,145)
 if math.abs(x)>33 or math.abs(z)>38 then
  local rock=part('Basalt',Vector3.new(rng:NextNumber(2,10),rng:NextNumber(1,6),rng:NextNumber(2,8)),
   CFrame.new(x,0,z)*CFrame.Angles(rng:NextNumber(-0.4,0.4),rng:NextNumber(0,6.28),rng:NextNumber(-0.3,0.3)),
   Color3.fromRGB(70+i%25,72+i%25,74+i%25),Enum.Material.Rock)
 end
end
for i=1,14 do
 local angle=i*math.pi*2/14
 local p=part('DistantHill',Vector3.new(65,30+rng:NextNumber(0,20),55),
  CFrame.new(math.cos(angle)*145,-7,math.sin(angle)*145),gray,Enum.Material.Slate)
 p.Shape=Enum.PartType.Ball
end
for _, crater in ipairs({Vector3.new(-65,0,-45),Vector3.new(68,0,42),Vector3.new(-50,0,70)}) do
 local bowl=part('CraterFloor',Vector3.new(27,0.15,27),CFrame.new(crater+Vector3.new(0,0.08,0)),Color3.fromRGB(76,78,80),Enum.Material.Slate)
 bowl.Shape=Enum.PartType.Cylinder; bowl.Size=Vector3.new(0.15,27,27); bowl.CFrame=CFrame.new(crater+Vector3.new(0,0.1,0))*CFrame.Angles(0,0,math.pi/2)
 for j=1,18 do
  local a=j*math.pi*2/18
  local rim=part('CraterRim',Vector3.new(7,2.5,5),CFrame.new(crater+Vector3.new(math.cos(a)*15,0.2,math.sin(a)*15))*CFrame.Angles(0,-a,0),gray,Enum.Material.Slate)
  rim.Shape=Enum.PartType.Ball
 end
end
-- Base sits behind the cleaning yard. Spawn faces toward the work surfaces.
part('BaseFoundation',Vector3.new(36,1,18),CFrame.new(0,0.5,23),dark)
part('Habitat',Vector3.new(16,9,10),CFrame.new(0,5.5,27),Color3.fromRGB(147,151,151))
part('HabitatRoof',Vector3.new(18,0.8,12),CFrame.new(0,10.4,27),dark)
local door=part('Airlock',Vector3.new(4,6,0.4),CFrame.new(0,4,21.8),dark); label(door,'LUNAR\nCLEANUP')
for _, x in ipairs({-5.5,5.5}) do
 part('WindowFrame',Vector3.new(3.4,2.5,0.4),CFrame.new(x,6,21.7),dark)
 part('Window',Vector3.new(2.9,2,0.2),CFrame.new(x,6,21.45),Color3.fromRGB(112,138,143),Enum.Material.Glass)
end
local depot=part('Depot',Vector3.new(6,4,4),CFrame.new(-12,3,20),dark)
label(depot,'DUST DEPOT\n[E] SELL')
local terminal=part('Terminal',Vector3.new(4,4,3),CFrame.new(12,3,20),dark)
label(terminal,'EQUIPMENT\n[E] UPGRADES')
for _, entry in ipairs({{depot,'Sell','Sell lunar dust'},{terminal,'Upgrade','Open equipment terminal'}}) do
 local prompt=Instance.new('ProximityPrompt'); prompt.Name=entry[2]; prompt.ActionText=entry[3]
 prompt.ObjectText='LUNAR CLEANUP'; prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.HoldDuration=0.25
 prompt.MaxActivationDistance=10; prompt.RequiresLineOfSight=true; prompt.Parent=entry[1]
end
local spawn=Instance.new('SpawnLocation'); spawn.Name='Arrival'; spawn.Size=Vector3.new(5,0.2,5)
spawn.CFrame=CFrame.new(0,1.2,15); spawn.Transparency=1; spawn.Anchored=true; spawn.Neutral=true
spawn.Duration=0; spawn.Parent=map
-- Three maintenance decks: 588 small patches, all static, no physics or per-patch scripts.
local patches=Instance.new('Folder'); patches.Name='Patches'; patches.Parent=map
for deck=1,3 do
 local x=(deck-2)*15
 part('DeckSupport',Vector3.new(13,1.2,13),CFrame.new(x,0.6,-4),dark)
 local surface=part('MaintenanceDeck',Vector3.new(12.5,0.3,12.5),CFrame.new(x,1.35,-4),Color3.fromRGB(165,171,174))
 for line=0,3 do
  part('DeckSeam',Vector3.new(0.035,0.012,12.4),CFrame.new(x-6.15+line*4.1,1.507,-4),dark)
 end
 for row=1,C.Rows do for col=1,C.Columns do
  local id=(deck-1)*C.Rows*C.Columns+(row-1)*C.Columns+col
  local px=x+(col-(C.Columns+1)/2)*C.PatchSize
  local pz=-4+(row-(C.Rows+1)/2)*C.PatchSize
  local shade=rng:NextInteger(56,77)
  local p=part('Dust_'..id,Vector3.new(C.PatchSize,0.035,C.PatchSize),CFrame.new(px,1.53,pz),Color3.fromRGB(shade,shade-2,shade-4),Enum.Material.Sand,patches)
  p.CanCollide=false; p.CanTouch=false; p.CastShadow=false; p:SetAttribute('PatchId',id)
  p:SetAttribute('Health',C.PatchHealth); p:SetAttribute('Deck',deck)
 end end
 local sign=part('DeckMarker',Vector3.new(5,1,0.2),CFrame.new(x,2.3,-11),dark); label(sign,'RECLAMATION DECK 0'..deck)
end
-- Current unified lighting; guard for Studio versions without this property.
local lightingOK = pcall(function()
 Lighting.LightingStyle=Enum.LightingStyle.Realistic
 Lighting.PrioritizeLightingQuality=true
end)
if not lightingOK then warn('Select Realistic lighting in Lighting properties if available in your Studio version.') end
Lighting.ClockTime=13.4; Lighting.GeographicLatitude=15; Lighting.Brightness=3
Lighting.GlobalShadows=true; Lighting.ShadowSoftness=0.12; Lighting.ExposureCompensation=-0.25
Lighting.Ambient=Color3.fromRGB(20,22,28); Lighting.OutdoorAmbient=Color3.fromRGB(35,37,44)
-- Sky has no asset IDs; black backdrop walls create a dark lunar sky.
local sky=Instance.new('Sky'); sky.Name='LunarSky'; sky.CelestialBodiesShown=false; sky.StarCount=0
sky:SetAttribute('LunarCleanupOwned',true); sky.Parent=Lighting
for _, face in ipairs({'Bk','Dn','Ft','Lf','Rt','Up'}) do sky['Skybox'..face]='' end
-- Six black, non-queryable walls enclose the play area without external sky textures.
for _, v in ipairs({Vector3.new(0,800,0),Vector3.new(0,-800,0),Vector3.new(800,0,0),Vector3.new(-800,0,0),Vector3.new(0,0,800),Vector3.new(0,0,-800)}) do
 local size=Vector3.new(1600,1600,2)
 if v.Y~=0 then size=Vector3.new(1600,2,1600) elseif v.X~=0 then size=Vector3.new(2,1600,1600) end
 local wall=part('SpaceBackdrop',size,CFrame.new(v),Color3.new(0,0,0),Enum.Material.Neon)
 wall.CanCollide=false; wall.CanQuery=false; wall.CastShadow=false
end
local color=Instance.new('ColorCorrectionEffect'); color.Name='LunarGrade'; color.Saturation=-0.32
color.Contrast=0.12; color:SetAttribute('LunarCleanupOwned',true); color.Parent=Lighting
StarterPlayer.CameraMode=Enum.CameraMode.LockFirstPerson
StarterPlayer.EnableMouseLockOption=false
local server=Instance.new('Script'); server.Name=NAME
server.Source=[==[
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local DSS=game:GetService('DataStoreService')
local Http=game:GetService('HttpService')
local net=RS:WaitForChild('LunarCleanup'); local C=require(net.Config)
local map=workspace:WaitForChild('LunarCleanup'); local folder=map:WaitForChild('Patches')
local store=DSS:GetDataStore('LunarCleanup_v1')
local session=game.JobId..':'..Http:GenerateGUID(false)
local profiles={}; local patches={}; local cells={}; local deckState={}
local closing=false
for _, p in ipairs(folder:GetChildren()) do
 local id=p:GetAttribute('PatchId'); patches[id]=p
 local key=math.floor(p.Position.X/C.PatchSize)..':'..math.floor(p.Position.Z/C.PatchSize)
 cells[key]=p
 local d=p:GetAttribute('Deck'); deckState[d]=deckState[d] or {remaining=C.Rows*C.Columns,resetAt=0}
end
local function cleanInteger(v, maximum)
 if type(v)~='number' or v~=v or math.abs(v)==math.huge then return 0 end
 return math.clamp(math.floor(v),0,maximum)
end
local function sanitize(data)
 data=type(data)=='table' and data or {}
 return {Money=cleanInteger(data.Money,100000000),Dust=cleanInteger(data.Dust,1000000),
 Tool=math.max(1,cleanInteger(data.Tool,#C.Tools)),Speed=cleanInteger(data.Speed,#C.SpeedPrices),
 Radius=cleanInteger(data.Radius,#C.RadiusPrices),Storage=cleanInteger(data.Storage,#C.StoragePrices)}
end
local function tell(p,message,kind) net.Feedback:FireClient(p,kind or 'Message',message) end
local function sync(p,s)
 for _, key in ipairs({'Money','Dust','Tool','Speed','Radius','Storage'}) do p:SetAttribute(key,s.data[key]) end
 p:SetAttribute('Capacity',C.Capacity(s.data.Storage)); p:SetAttribute('DataReady',true)
 p:SetAttribute('Persistent',s.persistent)
end
local function snapshot(s)
 local copy={}; for k,v in pairs(s.data) do copy[k]=v end; return copy
end
local function save(p, release)
 local s=profiles[p]; if not s or not s.persistent or s.saving then return false end
 s.saving=true
 local data=snapshot(s)
 local ok,result=pcall(function()
  return store:UpdateAsync('Player_'..p.UserId,function(old)
   if type(old)~='table' or old.Session~=session then return nil end
   return {Data=data,Session=release and '' or session,Lease=release and 0 or os.time()+180}
  end)
 end)
 s.saving=false
 if not ok then warn('Lunar Cleanup save failed: '..tostring(result))
 elseif result==nil then
  s.persistent=false
  if p.Parent then sync(p,s); tell(p,'Saving paused: profile lease was lost. Rejoin before continuing.') end
 end
 return ok and result~=nil
end
local function load(p)
 local s={data=sanitize(nil),persistent=false,lastScrub=0,lastAction=0,saving=false}
 profiles[p]=s
 local acquired=false
 for attempt=1,3 do
  local ok,result=pcall(function()
   return store:UpdateAsync('Player_'..p.UserId,function(old)
    old=type(old)=='table' and old or {}
    if old.Session and old.Session~='' and old.Session~=session and (tonumber(old.Lease) or 0)>os.time() then return nil end
    return {Data=sanitize(old.Data),Session=session,Lease=os.time()+180}
   end)
  end)
  if ok and type(result)=='table' and result.Session==session then
   s.data=sanitize(result.Data); s.persistent=true; acquired=true; break
  end
  if not p.Parent then break end
  task.wait(attempt)
 end
 if not p.Parent then if acquired then save(p,true) end; profiles[p]=nil; return end
 s.data.Dust=math.min(s.data.Dust,C.Capacity(s.data.Storage)); sync(p,s)
 if not acquired then tell(p,'SESSION ONLY — saving unavailable or profile in use. Existing saved data will not be overwritten.') end
end
Players.PlayerAdded:Connect(function(p)
 p.CharacterAdded:Connect(function(char)
  local hum=char:WaitForChild('Humanoid'); hum.WalkSpeed=13; hum.JumpHeight=4
 end)
 task.spawn(load,p)
end)
Players.PlayerRemoving:Connect(function(p)
 local s=profiles[p]
 if s then
  while s.saving do task.wait(0.1) end
  save(p,true); profiles[p]=nil
 end
end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(load,p) end
local function alive(p)
 local char=p.Character; local hum=char and char:FindFirstChildOfClass('Humanoid')
 local root=char and char:FindFirstChild('HumanoidRootPart')
 return hum and hum.Health>0 and root, char
end
local function nearby(p,target)
 local root=alive(p); return root and (root.Position-target.Position).Magnitude<=12
end
local function sell(p)
 local s=profiles[p]; if not s or not p:GetAttribute('DataReady') or not nearby(p,map.Depot) then return end
 if s.data.Dust<=0 then tell(p,'Storage is empty. Scrub a reclamation deck first.'); return end
 local value=s.data.Dust; s.data.Money+=value; s.data.Dust=0; sync(p,s)
 tell(p,'Sold lunar dust for $'..value,'Sold')
end
map.Depot.Sell.Triggered:Connect(sell)
map.Terminal.Upgrade.Triggered:Connect(function(p)
 if profiles[p] and p:GetAttribute('DataReady') and nearby(p,map.Terminal) then net.Feedback:FireClient(p,'Shop') end
end)
net.Action.OnServerEvent:Connect(function(p,action)
 local s=profiles[p]; if not s or not p:GetAttribute('DataReady') then return end
 local now=os.clock(); if now-s.lastAction<0.25 then return end; s.lastAction=now
 if action=='Sell' then sell(p); return end
 if not nearby(p,map.Terminal) then tell(p,'Stand beside the equipment terminal.'); return end
 local field,prices
 if action=='Tool' then field='Tool'
 elseif action=='Speed' then field='Speed'; prices=C.SpeedPrices
 elseif action=='Radius' then field='Radius'; prices=C.RadiusPrices
 elseif action=='Storage' then field='Storage'; prices=C.StoragePrices
 else return end
 local level=s.data[field]
 local cost=field=='Tool' and (C.Tools[level+1] and C.Tools[level+1].Price) or (prices and prices[level+1])
 if not cost then tell(p,'Upgrade already at maximum.'); return end
 if s.data.Money<cost then tell(p,'Not enough credits. Keep reclaiming dust.'); return end
 s.data.Money-=cost; s.data[field]+=1; sync(p,s); tell(p,'Equipment upgraded.','Bought')
end)
local function finite(v)
 return typeof(v)=='Vector3' and v.X==v.X and v.Y==v.Y and v.Z==v.Z and v.Magnitude<100000
end
net.Scrub.OnServerEvent:Connect(function(p,origin,direction)
 local s=profiles[p]; if not s or not p:GetAttribute('DataReady') then return end
 local now=os.clock(); local dt=now-s.lastScrub
 if dt<C.Tick*0.85 then return end; s.lastScrub=now
 local root,char=alive(p); local head=char and char:FindFirstChild('Head')
 if not root or not head or not finite(origin) or not finite(direction) then return end
 if (origin-head.Position).Magnitude>2.5 or direction.Magnitude<0.99 or direction.Magnitude>1.01 then return end
 if s.data.Dust>=C.Capacity(s.data.Storage) then return end
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={char}
 local hit=workspace:Raycast(origin,direction*C.Range,params)
 if not hit or not hit.Instance:IsDescendantOf(folder) then return end
 if (head.Position-hit.Position).Magnitude>C.Range then return end
 local sight=workspace:Raycast(head.Position,hit.Position-head.Position,params)
 if sight and sight.Instance~=hit.Instance and (sight.Position-hit.Position).Magnitude>0.12 then return end
 local tool=C.Tools[s.data.Tool]; local radius=tool.Radius*(1+0.15*s.data.Radius)
 local power=tool.Power*(1+0.3*s.data.Speed)*math.min(dt,0.14)
 local center=hit.Position; local deck=hit.Instance:GetAttribute('Deck'); local total=0; local touched=0
 local cx,cz=math.floor(center.X/C.PatchSize),math.floor(center.Z/C.PatchSize)
 local steps=math.ceil((radius+C.PatchSize)/C.PatchSize)
 for dx=-steps,steps do for dz=-steps,steps do
  local patch=cells[(cx+dx)..':'..(cz+dz)]
  if patch and patch:GetAttribute('Deck')==deck then
   local distance=(Vector2.new(patch.Position.X,patch.Position.Z)-Vector2.new(center.X,center.Z)).Magnitude
   if distance<=radius+C.PatchSize*0.38 then
    local health=patch:GetAttribute('Health')
    local room=C.Capacity(s.data.Storage)-s.data.Dust
    if health>0 and room>0 then
     local amount=math.min(health,room,math.max(1,math.floor(power*(1-0.45*math.min(distance/radius,1)))))
     health-=amount; s.data.Dust+=amount; total+=amount; touched+=1
     patch:SetAttribute('Health',health); patch.Transparency=1-health/C.PatchHealth
     -- Invisible patches remain queryable so a brush can sweep through cleaned areas.
     if health==0 then
      deckState[deck].remaining-=1
      if deckState[deck].remaining==0 then deckState[deck].resetAt=now+C.ResetSeconds end
     end
    end
   end
  end
 end end
 if total>0 then
  sync(p,s); net.Feedback:FireClient(p,'Scrub',{Position=center,Amount=total,Deck=deck,
   Progress=1-deckState[deck].remaining/(C.Rows*C.Columns)})
 end
end)
task.spawn(function()
 while not closing do
  task.wait(1)
  for deck,state in pairs(deckState) do
   map:SetAttribute('Progress'..deck,1-state.remaining/(C.Rows*C.Columns))
   if state.resetAt>0 and os.clock()>=state.resetAt then
    for _,patch in pairs(patches) do if patch:GetAttribute('Deck')==deck then
     patch:SetAttribute('Health',C.PatchHealth); patch.Transparency=0
    end end
    state.remaining=C.Rows*C.Columns; state.resetAt=0
   end
  end
 end
end)
task.spawn(function()
 while not closing do
  task.wait(55)
  for p,s in pairs(profiles) do
   if s.persistent then task.spawn(save,p,false) end
  end
 end
end)
game:BindToClose(function()
 closing=true; local pending=0
 for p in pairs(profiles) do
  pending+=1; task.spawn(function()
   local s=profiles[p]; while s and s.saving do task.wait(0.1) end
   save(p,true); pending-=1
  end)
 end
 local deadline=os.clock()+25
 while pending>0 and os.clock()<deadline do task.wait(0.1) end
end)
]==]
server.Parent=ServerScriptService
local client=Instance.new('LocalScript'); client.Name=NAME
client.Source=[==[
local Players=game:GetService('Players'); local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService'); local Run=game:GetService('RunService')
local player=Players.LocalPlayer; local net=RS:WaitForChild('LunarCleanup'); local C=require(net:WaitForChild('Config'))
local map=workspace:WaitForChild('LunarCleanup'); local patches=map:WaitForChild('Patches')
local gui=Instance.new('ScreenGui'); gui.Name='LunarCleanupHUD'; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false
 gui.Parent=player:WaitForChild('PlayerGui')
local white=Color3.fromRGB(224,232,234); local muted=Color3.fromRGB(139,154,161)
local function text(parent,value,size,pos,dim)
 local t=Instance.new('TextLabel'); t.BackgroundTransparency=1; t.Text=value; t.TextColor3=white
 t.Font=Enum.Font.GothamMedium; t.TextSize=size; t.TextXAlignment=Enum.TextXAlignment.Left
 t.Position=pos; t.Size=dim; t.Parent=parent; return t
end
local function panel(size,pos)
 local f=Instance.new('Frame'); f.Size=size; f.Position=pos; f.BackgroundColor3=Color3.fromRGB(15,20,24)
 f.BackgroundTransparency=0.12; f.BorderSizePixel=0; f.Parent=gui
 local stroke=Instance.new('UIStroke'); stroke.Color=Color3.fromRGB(65,78,86); stroke.Parent=f
 return f
end
local hud=panel(UDim2.fromOffset(300,144),UDim2.fromOffset(24,24))
text(hud,'L U N A R   C L E A N U P',14,UDim2.fromOffset(16,12),UDim2.fromOffset(270,22))
local money=text(hud,'CONNECTING...',20,UDim2.fromOffset(16,38),UDim2.fromOffset(270,27))
local storage=text(hud,'',13,UDim2.fromOffset(16,72),UDim2.fromOffset(270,20))
local toolText=text(hud,'',12,UDim2.fromOffset(16,112),UDim2.fromOffset(270,20)); toolText.TextColor3=muted
local track=Instance.new('Frame'); track.Position=UDim2.fromOffset(16,98); track.Size=UDim2.fromOffset(268,3)
track.BackgroundColor3=Color3.fromRGB(50,60,65); track.BorderSizePixel=0; track.Parent=hud
local fill=Instance.new('Frame'); fill.Size=UDim2.fromScale(0,1); fill.BorderSizePixel=0
fill.BackgroundColor3=Color3.fromRGB(179,204,207); fill.Parent=track
local cross=text(gui,'+',18,UDim2.new(0.5,-7,0.5,-12),UDim2.fromOffset(20,24))
local progress=text(gui,'AIM AT A RECLAMATION DECK',12,UDim2.new(0.5,-180,0.5,30),UDim2.fromOffset(360,24))
progress.TextXAlignment=Enum.TextXAlignment.Center
local hint=text(gui,'HOLD LEFT MOUSE · SCRUB     |     E · DEPOT / EQUIPMENT',12,UDim2.new(0.5,-290,1,-46),UDim2.fromOffset(580,24))
hint.TextXAlignment=Enum.TextXAlignment.Center; hint.TextColor3=muted
local toast=text(gui,'',14,UDim2.new(0.5,-320,0,24),UDim2.fromOffset(640,64))
toast.TextXAlignment=Enum.TextXAlignment.Center; toast.TextWrapped=true
local shop=panel(UDim2.fromOffset(400,360),UDim2.new(0.5,-200,0.5,-180)); shop.Visible=false
text(shop,'EQUIPMENT TERMINAL',18,UDim2.fromOffset(22,16),UDim2.fromOffset(355,30))
text(shop,'Stand near terminal to purchase.  [TAB] close',12,UDim2.fromOffset(22,48),UDim2.fromOffset(360,25))
local buttons={}
for index,key in ipairs({'Tool','Speed','Radius','Storage'}) do
 local b=Instance.new('TextButton'); b.Position=UDim2.fromOffset(22,82+(index-1)*60)
 b.Size=UDim2.fromOffset(356,50); b.BackgroundColor3=Color3.fromRGB(37,47,54); b.BorderSizePixel=0
 b.Font=Enum.Font.GothamMedium; b.TextSize=13; b.TextColor3=white; b.Parent=shop
 b.Activated:Connect(function() net.Action:FireServer(key) end); buttons[key]=b
end
local close=Instance.new('TextButton'); close.Text='CLOSE'; close.Size=UDim2.fromOffset(356,28)
close.Position=UDim2.fromOffset(22,324); close.BackgroundTransparency=1; close.TextColor3=muted
close.Font=Enum.Font.GothamMedium; close.TextSize=12; close.Parent=shop
local holding=false
local function setShop(open)
 shop.Visible=open; holding=false
 UIS.MouseBehavior=open and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
 UIS.MouseIconEnabled=open
end
close.Activated:Connect(function() setShop(false) end)
local function value(key) return player:GetAttribute(key) or 0 end
local function refresh()
 local ready=player:GetAttribute('DataReady')
 money.Text=ready and ('$'..value('Money')..'  CREDITS') or 'CONNECTING...'
 local cap=math.max(1,value('Capacity')); storage.Text=string.format('DUST  %d / %d',value('Dust'),cap)
 fill.Size=UDim2.fromScale(math.clamp(value('Dust')/cap,0,1),1)
 fill.BackgroundColor3=value('Dust')>=cap and Color3.fromRGB(214,174,112) or Color3.fromRGB(179,204,207)
 local tier=math.max(1,value('Tool')); toolText.Text=C.Tools[tier].Name..(player:GetAttribute('Persistent')==false and '  |  SESSION ONLY' or '')
 for key,b in pairs(buttons) do
  local level=value(key); local cost; local title
  if key=='Tool' then
   local nextTool=C.Tools[tier+1]; cost=nextTool and nextTool.Price; title=nextTool and nextTool.Name or 'TOOL'
  else
   local list=key=='Speed' and C.SpeedPrices or key=='Radius' and C.RadiusPrices or C.StoragePrices
   cost=list[level+1]; title=string.upper(key)..'  '..level..' → '..(level+1)
  end
  b.Text=title..(cost and ('     $'..cost) or '     MAXED')
 end
end
player.AttributeChanged:Connect(refresh); refresh()
local toastVersion=0
local function message(msg)
 toastVersion+=1; local version=toastVersion; toast.Text=msg
 task.delay(5,function() if version==toastVersion then toast.Text='' end end)
end
-- Local first-person primitive equipment; never accepts authoritative rewards.
local view=Instance.new('Model'); view.Name='LunarCleanupViewmodel'
local pieces={}; local lastTier=0
local function viewPart(size,color,offset)
 local p=Instance.new('Part'); p.Size=size; p.Color=color; p.Material=Enum.Material.Metal
 p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=false
 p.Parent=view; table.insert(pieces,{p,offset}); return p
end
local function rebuild(tier)
 view:ClearAllChildren(); pieces={}; lastTier=tier
 if tier==1 then
  viewPart(Vector3.new(0.1,0.12,1.25),Color3.fromRGB(156,161,155),CFrame.new(0,0,0))
  viewPart(Vector3.new(0.18,0.12,0.4),Color3.fromRGB(65,73,78),CFrame.new(0,0,-0.72))
  for i=1,5 do viewPart(Vector3.new(0.13,0.13,0.035),Color3.fromRGB(210,207,189),CFrame.new(0,0.1,-0.56-i*0.062)) end
 elseif tier==2 then
  viewPart(Vector3.new(0.16,0.18,1.2),Color3.fromRGB(105,113,116),CFrame.new())
  viewPart(Vector3.new(0.65,0.2,0.4),Color3.fromRGB(73,82,85),CFrame.new(0,0,-0.7))
  for i=1,7 do viewPart(Vector3.new(0.055,0.16,0.32),Color3.fromRGB(177,175,162),CFrame.new((i-4)*0.085,-0.15,-0.7)) end
 else
  viewPart(Vector3.new(0.35,0.32,1.15),Color3.fromRGB(101,112,117),CFrame.new())
  viewPart(Vector3.new(0.85,0.22,0.85),Color3.fromRGB(49,57,63),CFrame.new(0,-0.1,-0.8))
  viewPart(Vector3.new(0.72,0.12,0.72),Color3.fromRGB(163,164,151),CFrame.new(0,-0.25,-0.8))
 end
end
-- Quiet brush texture uses a Roblox-shipped local sound, never a marketplace asset ID.
local brushSound=Instance.new('Sound'); brushSound.Name='BrushTexture'
brushSound.SoundId='rbxasset://sounds/action_footsteps_plastic.mp3'
brushSound.Volume=0.065; brushSound.PlaybackSpeed=1.45; brushSound.Looped=true
brushSound.Parent=gui
local lastFeedback=0
local puff=Instance.new('Part'); puff.Name='LunarDustFeedback'; puff.Size=Vector3.new(0.1,0.1,0.1)
puff.Anchored=true; puff.Transparency=1; puff.CanCollide=false; puff.CanQuery=false; puff.CanTouch=false
local attachment=Instance.new('Attachment'); attachment.Parent=puff
local emitter=Instance.new('ParticleEmitter'); emitter.Texture='rbxasset://textures/particles/smoke_main.dds'; emitter.Rate=0
emitter.Lifetime=NumberRange.new(0.2,0.45); emitter.Speed=NumberRange.new(0.7,1.8)
emitter.SpreadAngle=Vector2.new(65,65); emitter.Acceleration=Vector3.new(0,-1.6,0)
emitter.Color=ColorSequence.new(Color3.fromRGB(139,136,128)); emitter.LightEmission=0
emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.07),NumberSequenceKeypoint.new(1,0)})
emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.45),NumberSequenceKeypoint.new(1,1)})
emitter.Parent=attachment
local flashUntil=0
net.Feedback.OnClientEvent:Connect(function(kind,data)
 if kind=='Shop' then setShop(true)
 elseif kind=='Scrub' then
  lastFeedback=os.clock()
  if not brushSound.IsPlaying then brushSound:Play() end
  puff.Position=data.Position+Vector3.new(0,0.08,0); emitter:Emit(3); flashUntil=os.clock()+0.12
 elseif type(data)=='string' then message(data) end
end)
UIS.InputBegan:Connect(function(input,processed)
 if input.KeyCode==Enum.KeyCode.Tab and shop.Visible then setShop(false); return end
 if processed or shop.Visible then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 then holding=true end
end)
UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then holding=false end end)
UIS.WindowFocusReleased:Connect(function() holding=false end)
player.CharacterAdded:Connect(function() holding=false; setShop(false) end)
local lastSend=0
Run:BindToRenderStep('LunarCleanupCamera',Enum.RenderPriority.Camera.Value+1,function()
 local camera=workspace.CurrentCamera; if not camera then return end
 view.Parent=camera; puff.Parent=camera
 local tier=math.max(1,value('Tool')); if tier~=lastTier then rebuild(tier) end
 local char=player.Character; local hum=char and char:FindFirstChildOfClass('Humanoid')
 local alive=hum and hum.Health>0
 local scrub=holding and not shop.Visible and alive and player:GetAttribute('DataReady')
 if brushSound.IsPlaying and (not scrub or os.clock()-lastFeedback>0.25) then brushSound:Stop() end
 local phase=os.clock()*27
 local offset=CFrame.new(0.58,-0.52,-1.05)*CFrame.Angles(-0.12,0.1,-0.15)
 if scrub then offset*=CFrame.new(math.sin(phase)*0.04,0,math.cos(phase)*0.055) end
 for _,item in ipairs(pieces) do
  item[1].LocalTransparencyModifier=alive and not shop.Visible and 0 or 1
  item[1].CFrame=camera.CFrame*offset*item[2]
 end
 if shop.Visible then UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true
 else UIS.MouseIconEnabled=false end
 cross.TextColor3=os.clock()<flashUntil and Color3.fromRGB(180,215,208) or white
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={char or view,view,puff}
 local hit=workspace:Raycast(camera.CFrame.Position,camera.CFrame.LookVector*C.Range,params)
 if hit and hit.Instance:IsDescendantOf(patches) then
  local deck=hit.Instance:GetAttribute('Deck'); local percent=map:GetAttribute('Progress'..deck) or 0
  progress.Text=string.format('DECK 0%d   •   %.0f%% RECLAIMED',deck,percent*100)
  if value('Dust')>=math.max(1,value('Capacity')) then progress.Text='STORAGE FULL — RETURN TO DUST DEPOT' end
 else progress.Text='AIM AT A RECLAMATION DECK' end
 if scrub and os.clock()-lastSend>=C.Tick then
  lastSend=os.clock(); net.Scrub:FireServer(camera.CFrame.Position,camera.CFrame.LookVector)
 end
end)
message('Hold left mouse to scrub. Sell dust at the depot behind you. E opens equipment.')
]==]
client.Parent=StarterPlayer.StarterPlayerScripts
print('LUNAR CLEANUP generated. Press Play to test. Enable Studio API access only in a separate test place for persistence testing.')
