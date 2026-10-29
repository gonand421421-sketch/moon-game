-- LUNAR CLEANUP | Paste this entire file into Studio's Command Bar in EDIT mode.
-- Original smooth-terrain / primitive environment. No external downloads. Generated content is namespaced.
local RunService = game:GetService('RunService')
assert(not RunService:IsRunning(), 'Stop the play session. Run this generator in EDIT mode.')
local Workspace = game:GetService('Workspace')
local Lighting = game:GetService('Lighting')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local StarterPlayer = game:GetService('StarterPlayer')
local NAME = 'LunarCleanup'
-- Replace generated roots only. Bounded Terrain generation below preserves its original region.
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
-- Owned, bounded smooth Terrain. Keep the pre-overhaul terrain and any Baseplate
-- in ServerStorage so generation is repeatable without Terrain:Clear().
local ServerStorage=game:GetService('ServerStorage')
local terrain=Workspace.Terrain
local region=Region3.new(Vector3.new(-160,-40,-160),Vector3.new(160,40,160))
local preservation=ServerStorage:FindFirstChild('LunarCleanupOriginalEnvironment')
if not preservation then
 preservation=Instance.new('Folder'); preservation.Name='LunarCleanupOriginalEnvironment'
 local original=terrain:CopyRegion(Region3int16.new(Vector3int16.new(-40,-10,-40),Vector3int16.new(39,9,39)))
 original.Name='TerrainBeforeOverhaul'; original.Parent=preservation
 local tint=Instance.new('Color3Value'); tint.Name='OriginalSandColor'; tint.Value=terrain:GetMaterialColor(Enum.Material.Sand); tint.Parent=preservation
 preservation.Parent=ServerStorage
end
-- Preserve template sky/haze/post effects rather than stacking them with lunar lighting.
local originalLighting=preservation:FindFirstChild('LightingBeforeOverhaul')
if not originalLighting then
 originalLighting=Instance.new('Folder'); originalLighting.Name='LightingBeforeOverhaul'; originalLighting.Parent=preservation
end
for _,effect in ipairs(Lighting:GetChildren()) do
 if effect:IsA('Sky') or effect:IsA('Atmosphere') or effect:IsA('PostEffect') then
  effect.Parent=originalLighting
 end
end
local baseplate=Workspace:FindFirstChild('Baseplate')
if baseplate and baseplate:IsA('BasePart') then baseplate.Parent=preservation end
terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(112,113,115))
local rng=Random.new(74219)
local craters={
 {X=-65,Z=-45,R=23,Depth=9},{X=72,Z=47,R=29,Depth=12},
 {X=-55,Z=76,R=17,Depth=6},{X=47,Z=-77,R=14,Depth=5},
 {X=-108,Z=12,R=32,Depth=12},{X=5,Z=113,R=21,Depth=8},
}
local function groundHeight(x,z)
 local n=math.noise(x/65,z/65,8)*12+math.noise(x/21,z/21,19)*3+math.noise(x/8,z/8,32)*0.6
 local h=-2+n
 for _,c in ipairs(craters) do
  local d=math.sqrt((x-c.X)^2+(z-c.Z)^2)/c.R
  h+=-c.Depth*math.exp(-d*d*3.2)+3.8*math.exp(-((d-1.02)/0.19)^2)
 end
 local edge=math.clamp((math.max(math.abs(x),math.abs(z))-100)/60,0,1)
 h+=edge*edge*(12+math.noise(x/40,z/40,51)*12)
 -- Preserve exact working surface heights and unobstructed walking routes in the yard.
 local blend=math.clamp((math.max(math.abs(x)/34,math.abs(z-7)/34)-1)*1.6,0,1)
 blend=blend*blend*(3-2*blend)
 return -0.6+(h+0.6)*blend
end
local materials,occupancy={},{}
for ix=1,80 do
 materials[ix]={}; occupancy[ix]={}
 for iy=1,20 do materials[ix][iy]={}; occupancy[ix][iy]={} end
 for iz=1,80 do
  local x,z=-160+(ix-0.5)*4,-160+(iz-0.5)*4
  local h=groundHeight(x,z)
  for iy=1,20 do
   local bottom=-40+(iy-1)*4
   local amount=math.clamp((h-bottom)/4,0,1)
   occupancy[ix][iy][iz]=amount
   materials[ix][iy][iz]=amount==0 and Enum.Material.Air or (bottom>h-8 and Enum.Material.Sand or Enum.Material.Rock)
  end
 end
end
terrain:WriteVoxels(region,4,materials,occupancy)
-- All scenery stays out of cleaning raycasts. Only actual surfaces and patches are queried.
local function detail(name,size,cf,color,material)
 local p=part(name,size,cf,color,material); p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; return p
end
local function rod(name,a,b,r,color,material)
 local delta=b-a
 -- A Roblox cylinder's length is its local X axis.
 local p=detail(name,Vector3.new(delta.Magnitude,r*2,r*2),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),color,material)
 p.Shape=Enum.PartType.Cylinder
 return p
end
local pale=Color3.fromRGB(158,162,160)
local safety=Color3.fromRGB(161,143,98)
for i=1,100 do
 local x,z=rng:NextNumber(-150,150),rng:NextNumber(-150,150)
 if math.abs(x)>37 or math.abs(z-7)>38 then
  local h=groundHeight(x,z); local scale=rng:NextNumber(0.6,4.5)
  local rock=detail('FracturedBasalt',Vector3.new(scale*1.9,scale,scale*1.3),
   CFrame.new(x,h+scale*0.2,z)*CFrame.Angles(rng:NextNumber(-0.5,0.5),rng:NextNumber(0,6.28),rng:NextNumber(-0.45,0.45)),
   Color3.fromRGB(74+i%22,75+i%22,78+i%22),Enum.Material.Rock)
  if i%3==0 then
   local wedge=Instance.new('WedgePart'); wedge.Name='RockFracture'; wedge.Size=rock.Size*0.7
   wedge.CFrame=rock.CFrame*CFrame.new(scale*0.6,0,0); wedge.Color=rock.Color
   wedge.Material=Enum.Material.Rock; wedge.Anchored=true; wedge.CanQuery=false; wedge.Parent=map
  end
 end
end
-- Raised expedition habitat with thermal ribs, airlock seals and service fittings.
part('BaseFoundation',Vector3.new(36,1,18),CFrame.new(0,0.5,23),dark,Enum.Material.DiamondPlate)
part('Habitat',Vector3.new(16,9,10),CFrame.new(0,5.5,27),pale)
detail('ThermalRoof',Vector3.new(18,0.8,12),CFrame.new(0,10.4,27),Color3.fromRGB(181,180,169))
for _,x in ipairs({-8.2,-4.1,0,4.1,8.2}) do
 detail('HabitatStructuralRib',Vector3.new(0.22,9.3,10.5),CFrame.new(x,5.6,27),dark)
end
local door=part('Airlock',Vector3.new(4,6,0.4),CFrame.new(0,4,21.8),dark); label(door,'LUNAR\nCLEANUP')
for _,x in ipairs({-2.25,2.25}) do detail('DoorSeal',Vector3.new(0.25,6.5,0.6),CFrame.new(x,4,21.7),pale) end
for _,y in ipairs({0.85,7.2}) do detail('DoorLintel',Vector3.new(4.8,0.25,0.6),CFrame.new(0,y,21.7),pale) end
for _,x in ipairs({-5.5,5.5}) do
 detail('WindowFrame',Vector3.new(3.4,2.5,0.4),CFrame.new(x,6,21.7),dark)
 local w=detail('Window',Vector3.new(2.9,2,0.2),CFrame.new(x,6,21.45),Color3.fromRGB(76,94,101),Enum.Material.Glass)
 w.Reflectance=0.12
 for i=1,3 do detail('WindowBrace',Vector3.new(0.06,2,0.09),CFrame.new(x-1.45+i*0.72,6,21.3),pale) end
end
for i=1,4 do
 detail('AirlockStep',Vector3.new(5,0.18,0.7),CFrame.new(0,0.1+i*0.2,19.1+i*0.6),dark,Enum.Material.DiamondPlate)
end
-- Keep the authoritative Depot and Terminal anchors and prompt positions unchanged.
local depot=part('Depot',Vector3.new(6,4,4),CFrame.new(-12,3,20),dark)
label(depot,'DUST DEPOT\n[E] SELL')
local terminal=part('Terminal',Vector3.new(4,4,3),CFrame.new(12,3,20),dark)
label(terminal,'EQUIPMENT\n[E] UPGRADES')
for _,x in ipairs({-15.25,-8.75}) do
 detail('DepotFrame',Vector3.new(0.28,6,4.8),CFrame.new(x,3.5,20),pale)
end
detail('DepotCanopy',Vector3.new(7.2,0.35,5.2),CFrame.new(-12,6.6,19.8),pale)
detail('IntakeLip',Vector3.new(5.7,0.18,0.6),CFrame.new(-12,1.35,17.8),safety)
for i=1,9 do detail('IntakeGrille',Vector3.new(0.24,0.6,0.16),CFrame.new(-14.5+i*0.5,1.8,17.85),pale) end
for _,x in ipairs({-14,-10}) do
 rod('DustSeparator',Vector3.new(x,1.2,23.5),Vector3.new(x,6.2,23.5),0.8,pale)
 for _,y in ipairs({1.5,5.6}) do rod('TankBand',Vector3.new(x,y,23.5),Vector3.new(x,y+0.2,23.5),0.88,dark) end
 rod('SeparatorFeed',Vector3.new(x,5.8,23.5),Vector3.new(x,5.8,21),0.15,dark)
end
detail('TerminalPlinth',Vector3.new(5,0.3,4),CFrame.new(12,1.15,20),pale)
detail('TerminalHood',Vector3.new(4.6,0.3,3.5),CFrame.new(12,5.2,20),pale)
for _,x in ipairs({9.9,14.1}) do detail('TerminalCheek',Vector3.new(0.2,4,3.2),CFrame.new(x,3.1,20),pale) end
local display=detail('DiagnosticScreen',Vector3.new(3.4,0.75,0.1),CFrame.new(12,4.45,18.43),Color3.fromRGB(32,50,54),Enum.Material.Neon)
label(display,'SYSTEM READY  /  LC-03')
for i=1,6 do detail('TerminalVent',Vector3.new(0.1,0.6,0.08),CFrame.new(10.7+i*0.37,1.7,18.44),pale) end
-- Cables run at the back and sides; no decoration covers the cleanable grid.
for _,x in ipairs({-21,21}) do
 local a=Vector3.new(x,0.07,-6); local b=Vector3.new(x,0.07,18)
 rod('PowerCable',a,b,0.065,Color3.fromRGB(31,32,33),Enum.Material.SmoothPlastic)
 for z=-6,18,4 do detail('CableClamp',Vector3.new(0.3,0.12,0.15),CFrame.new(x,0.1,z),pale) end
end
for _,x in ipairs({-25,25}) do
 local z=13
 detail('FloodlightFoot',Vector3.new(2,0.25,2),CFrame.new(x,0.12,z),dark)
 rod('FloodlightMast',Vector3.new(x,0.2,z),Vector3.new(x,8,z),0.11,pale)
 local lamp=detail('FloodlightHousing',Vector3.new(1.8,0.8,0.7),CFrame.lookAt(Vector3.new(x,8,z),Vector3.new(x*0.5,1,-4)),dark)
 local lens=detail('FloodlightLens',Vector3.new(1.5,0.5,0.08),lamp.CFrame*CFrame.new(0,0,-0.38),Color3.fromRGB(206,214,207),Enum.Material.Neon)
 local light=Instance.new('SpotLight'); light.Face=Enum.NormalId.Front; light.Angle=70; light.Range=32
 light.Brightness=1.4; light.Color=lens.Color; light.Shadows=false; light.Parent=lens
end
rod('AntennaMast',Vector3.new(6,10.8,28),Vector3.new(6,19,28),0.07,pale)
for i=1,3 do rod('AntennaElement',Vector3.new(4.7,15+i,28),Vector3.new(7.3,15+i,28),0.035,dark) end
for i=1,3 do
 local x=22+(i-1)*4.4
 detail('CargoContainer',Vector3.new(3.6,3.2,5),CFrame.new(x,1.3,25),Color3.fromRGB(99,106,106))
 for _,dx in ipairs({-1.5,1.5}) do detail('CargoCorner',Vector3.new(0.15,3.4,5.2),CFrame.new(x+dx,1.3,25),dark) end
 local plate=detail('CargoIdentification',Vector3.new(2,0.65,0.08),CFrame.new(x,1.8,22.45),dark); label(plate,'LC / 0'..i)
end
-- A small seismometer and primitive solar array beyond the working yard.
local instrument=detail('Seismometer',Vector3.new(2,1.1,2),CFrame.new(-28,0.2,-23),pale)
for _,v in ipairs({Vector3.new(-1.6,0,1),Vector3.new(1.6,0,1),Vector3.new(0,0,-1.6)}) do
 rod('InstrumentLeg',instrument.Position,instrument.Position+v-Vector3.new(0,0.7,0),0.055,dark)
end
rod('SensorProbe',Vector3.new(-28,0.7,-23),Vector3.new(-28,3,-23),0.035,pale)
for i=1,3 do
 local x=-24-i*5
 rod('SolarMount',Vector3.new(x,-0.5,33),Vector3.new(x,2,33),0.12,pale)
 local cf=CFrame.new(x,2.6,33)*CFrame.Angles(math.rad(-18),0,0)
 detail('SolarFrame',Vector3.new(4.7,0.2,7),cf,pale)
 detail('SolarCells',Vector3.new(4.4,0.08,6.7),cf*CFrame.new(0,0.15,0),Color3.fromRGB(32,41,52),Enum.Material.Glass)
 for j=1,5 do detail('CellConductor',Vector3.new(4.35,0.015,0.035),cf*CFrame.new(0,0.2,-3.35+j*1.12),Color3.fromRGB(97,109,119)) end
end
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
 local surface=part('MaintenanceDeck',Vector3.new(12.5,0.3,12.5),CFrame.new(x,1.35,-4),Color3.fromRGB(137,147,151),Enum.Material.Metal)
 for line=0,3 do
  part('DeckSeam',Vector3.new(0.035,0.012,12.4),CFrame.new(x-6.15+line*4.1,1.507,-4),dark)
 end
 for row=1,C.Rows do for col=1,C.Columns do
  local id=(deck-1)*C.Rows*C.Columns+(row-1)*C.Columns+col
  local px=x+(col-(C.Columns+1)/2)*C.PatchSize
  local pz=-4+(row-(C.Rows+1)/2)*C.PatchSize
  -- Continuous low-frequency tint avoids a random checkerboard while keeping every patch.
  local shade=math.floor(92+math.noise(px/5,pz/5,4)*11+math.noise(px/1.8,pz/1.8,9)*3)
  local p=part('Dust_'..id,Vector3.new(C.PatchSize,0.035,C.PatchSize),CFrame.new(px,1.53,pz),Color3.fromRGB(shade,shade-2,shade-4),Enum.Material.Sand,patches)
  p.CanCollide=false; p.CanTouch=false; p.CastShadow=false; p:SetAttribute('PatchId',id)
  p:SetAttribute('Health',C.PatchHealth); p:SetAttribute('Deck',deck)
 end end
 -- Peripheral rail, fasteners, landing plates and service conduit: outside the grid.
 for _,side in ipairs({-1,1}) do
  detail('DeckEdgeBeam',Vector3.new(0.24,0.18,12.8),CFrame.new(x+side*6.25,1.45,-4),pale)
  for j=0,6 do
   local bolt=detail('FlushFastener',Vector3.new(0.11,0.045,0.11),CFrame.new(x+side*6.08,1.52,-9.8+j*1.9),dark)
   bolt.Shape=Enum.PartType.Ball
  end
  detail('ServiceFoot',Vector3.new(1,0.8,1.5),CFrame.new(x+side*5.1,0.05,-4),pale)
 end
 for j=1,4 do
  detail('WornEdgeMarking',Vector3.new(0.65,0.018,0.18),CFrame.new(x-4.5+j*1.7,1.515,2.08),safety)
 end
 detail('DeckAccessStep',Vector3.new(4,0.35,0.75),CFrame.new(x,0.75,2.8),dark,Enum.Material.DiamondPlate)
 rod('ServiceConduit',Vector3.new(x-5,0.6,-10.5),Vector3.new(x+5,0.6,-10.5),0.12,pale)
 local sign=part('DeckMarker' ,Vector3.new(5,1,0.2),CFrame.new(x,2.3,-11),dark); label(sign,'RECLAMATION DECK 0'..deck)
end
-- Current unified lighting; guard for Studio versions without this property.
local lightingOK = pcall(function()
 Lighting.LightingStyle=Enum.LightingStyle.Realistic
 Lighting.PrioritizeLightingQuality=true
end)
if not lightingOK then warn('Select Realistic lighting in Lighting properties if available in your Studio version.') end
Lighting.ClockTime=15.7; Lighting.GeographicLatitude=12; Lighting.Brightness=3.5
Lighting.GlobalShadows=true; Lighting.ShadowSoftness=0.06; Lighting.ExposureCompensation=-0.35
Lighting.Ambient=Color3.fromRGB(9,11,16); Lighting.OutdoorAmbient=Color3.fromRGB(24,26,32)
Lighting.EnvironmentDiffuseScale=0.15; Lighting.EnvironmentSpecularScale=0.5
Lighting.FogStart=1400; Lighting.FogEnd=1800; Lighting.FogColor=Color3.new(0,0,0)
-- No atmospheric haze: the Moon has essentially no atmosphere. Particles are local impacts only.
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
local color=Instance.new('ColorCorrectionEffect'); color.Name='LunarGrade'; color.Saturation=-0.24
color.Contrast=0.16; color:SetAttribute('LunarCleanupOwned',true); color.Parent=Lighting
local bloom=Instance.new('BloomEffect'); bloom.Name='LunarOptics'; bloom.Intensity=0.08
bloom.Size=12; bloom.Threshold=2.3; bloom:SetAttribute('LunarCleanupOwned',true); bloom.Parent=Lighting
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
local white=Color3.fromRGB(225,230,230); local muted=Color3.fromRGB(144,159,164)
local function text(parent,value,size,pos,dim)
 local t=Instance.new('TextLabel'); t.BackgroundTransparency=1; t.Text=value; t.TextColor3=white
 t.Font=Enum.Font.GothamMedium; t.TextSize=size; t.TextXAlignment=Enum.TextXAlignment.Left
 t.Position=pos; t.Size=dim; t.Parent=parent; return t
end
local function panel(size,pos)
 local f=Instance.new('Frame'); f.Size=size; f.Position=pos; f.BackgroundColor3=Color3.fromRGB(15,20,24)
 f.BackgroundTransparency=0.07; f.BorderSizePixel=0; f.Parent=gui
 local stroke=Instance.new('UIStroke'); stroke.Color=Color3.fromRGB(68,83,91); stroke.Transparency=0.3; stroke.Parent=f
 local corner=Instance.new('UICorner'); corner.CornerRadius=UDim.new(0,5); corner.Parent=f
 local gradient=Instance.new('UIGradient'); gradient.Rotation=105
 gradient.Color=ColorSequence.new(Color3.fromRGB(38,49,56),Color3.fromRGB(15,20,24)); gradient.Parent=f
 local accent=Instance.new('Frame'); accent.Size=UDim2.new(0,2,1,-24); accent.Position=UDim2.fromOffset(0,12)
 accent.BackgroundColor3=Color3.fromRGB(143,175,177); accent.BorderSizePixel=0; accent.Parent=f
 return f
end
local hud=panel(UDim2.fromOffset(320,172),UDim2.fromOffset(24,24))
text(hud,'L U N A R   C L E A N U P',13,UDim2.fromOffset(16,12),UDim2.fromOffset(270,22))
text(hud,'SURFACE OPERATIONS   /   SECTOR 03',10,UDim2.fromOffset(16,33),UDim2.fromOffset(290,18)).TextColor3=muted
local money=text(hud,'CONNECTING...',22,UDim2.fromOffset(16,57),UDim2.fromOffset(270,27))
local storage=text(hud,'',13,UDim2.fromOffset(16,94),UDim2.fromOffset(270,20))
local toolText=text(hud,'',10,UDim2.fromOffset(16,139),UDim2.fromOffset(290,20)); toolText.TextColor3=muted
local track=Instance.new('Frame'); track.Position=UDim2.fromOffset(16,121); track.Size=UDim2.fromOffset(288,4)
track.BackgroundColor3=Color3.fromRGB(50,60,65); track.BorderSizePixel=0; track.Parent=hud
local fill=Instance.new('Frame'); fill.Size=UDim2.fromScale(0,1); fill.BorderSizePixel=0
fill.BackgroundColor3=Color3.fromRGB(179,204,207); fill.Parent=track
local cross=text(gui,'·',24,UDim2.new(0.5,-7,0.5,-12),UDim2.fromOffset(20,24))
local progress=text(gui,'AIM AT A RECLAMATION DECK',12,UDim2.new(0.5,-180,0.5,30),UDim2.fromOffset(360,24))
progress.TextXAlignment=Enum.TextXAlignment.Center
local aimTrack=Instance.new('Frame'); aimTrack.Size=UDim2.fromOffset(180,2)
aimTrack.Position=UDim2.new(0.5,-90,0.5,60); aimTrack.BorderSizePixel=0
aimTrack.BackgroundColor3=Color3.fromRGB(53,63,67); aimTrack.BackgroundTransparency=0.3; aimTrack.Parent=gui
local aimFill=Instance.new('Frame'); aimFill.Size=UDim2.fromScale(0,1); aimFill.BorderSizePixel=0
aimFill.BackgroundColor3=Color3.fromRGB(166,191,190); aimFill.Parent=aimTrack
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
 local corner=Instance.new('UICorner'); corner.CornerRadius=UDim.new(0,4); corner.Parent=b
 local edge=Instance.new('UIStroke'); edge.Color=Color3.fromRGB(80,98,105); edge.Transparency=0.65; edge.Parent=b
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
 local alloy=Color3.fromRGB(153,160,160)
 local polymer=Color3.fromRGB(44,51,55)
 local bristle=Color3.fromRGB(192,190,171)
 if tier==1 then
  -- An intentionally tiny expedition toothbrush: tapered handle, neck, ferrule and tufts.
  local handle=viewPart(Vector3.new(0.11,0.105,0.9),alloy,CFrame.new(0,0,0.13))
  handle.Material=Enum.Material.SmoothPlastic
  viewPart(Vector3.new(0.08,0.08,0.45),polymer,CFrame.new(0,0.02,-0.49)*CFrame.Angles(0.08,0,0))
  viewPart(Vector3.new(0.19,0.09,0.43),alloy,CFrame.new(0,0.06,-0.87))
  viewPart(Vector3.new(0.17,0.035,0.39),polymer,CFrame.new(0,0.115,-0.87))
  for row=1,8 do for col=1,3 do
   local tuft=viewPart(Vector3.new(0.033,0.105+(row%2)*0.015,0.032),bristle,
    CFrame.new((col-2)*0.05,0.17,-0.65-row*0.049))
   tuft.Material=Enum.Material.SmoothPlastic
  end end
  for i=1,7 do viewPart(Vector3.new(0.115,0.012,0.026),polymer,CFrame.new(0,0.055,0.04+i*0.058)) end
  viewPart(Vector3.new(0.07,0.012,0.14),Color3.fromRGB(173,156,110),CFrame.new(0,0.057,0.45))
 elseif tier==2 then
  viewPart(Vector3.new(0.16,0.18,1.2),alloy,CFrame.new())
  viewPart(Vector3.new(0.19,0.2,0.5),polymer,CFrame.new(0,0,0.26))
  viewPart(Vector3.new(0.65,0.17,0.45),alloy,CFrame.new(0,0,-0.73))
  viewPart(Vector3.new(0.59,0.07,0.39),polymer,CFrame.new(0,-0.1,-0.73))
  for i=1,9 do for j=1,3 do
   viewPart(Vector3.new(0.042,0.13,0.055),bristle,CFrame.new((i-5)*0.062,-0.18,-0.6-j*0.08))
  end end
 else
  viewPart(Vector3.new(0.35,0.32,1.15),alloy,CFrame.new())
  viewPart(Vector3.new(0.38,0.34,0.35),polymer,CFrame.new(0,0,0.35))
  viewPart(Vector3.new(0.85,0.22,0.85),polymer,CFrame.new(0,-0.1,-0.8))
  local disc=viewPart(Vector3.new(0.12,0.72,0.72),bristle,CFrame.new(0,-0.25,-0.8)*CFrame.Angles(0,0,math.pi/2))
  disc.Shape=Enum.PartType.Cylinder
  for _,x in ipairs({-0.28,0.28}) do viewPart(Vector3.new(0.065,0.025,0.52),alloy,CFrame.new(x,0.025,-0.8)) end
  for i=1,5 do viewPart(Vector3.new(0.2,0.035,0.025),polymer,CFrame.new(0,0.17,-0.22+i*0.08)) end
 end
 -- Restrained neutral glove and cuff suggest a pressurized suit without covering the brush.
 viewPart(Vector3.new(0.28,0.22,0.38),Color3.fromRGB(124,128,124),CFrame.new(0,-0.09,0.4))
 viewPart(Vector3.new(0.32,0.26,0.16),polymer,CFrame.new(0,-0.09,0.64))
 for i=1,3 do viewPart(Vector3.new(0.29,0.026,0.045),alloy,CFrame.new(0,-0.19,0.26+i*0.08)) end
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
emitter.Lifetime=NumberRange.new(0.24,0.5); emitter.Speed=NumberRange.new(0.3,0.85)
emitter.Drag=0.1; emitter.Rotation=NumberRange.new(0,360); emitter.RotSpeed=NumberRange.new(-20,20)
emitter.SpreadAngle=Vector2.new(72,72); emitter.Acceleration=Vector3.new(0,-1.6,0)
emitter.Color=ColorSequence.new(Color3.fromRGB(139,136,128)); emitter.LightEmission=0
emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.045),NumberSequenceKeypoint.new(0.35,0.12),NumberSequenceKeypoint.new(1,0)})
emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.72),NumberSequenceKeypoint.new(1,1)})
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
local brushBlend=0; local visualTime=0
Run:BindToRenderStep('LunarCleanupCamera',Enum.RenderPriority.Camera.Value+1,function(frameDt)
 local camera=workspace.CurrentCamera; if not camera then return end
 view.Parent=camera; puff.Parent=camera
 local tier=math.max(1,value('Tool')); if tier~=lastTier then rebuild(tier) end
 local char=player.Character; local hum=char and char:FindFirstChildOfClass('Humanoid')
 local alive=hum and hum.Health>0
 local scrub=holding and not shop.Visible and alive and player:GetAttribute('DataReady')
 if brushSound.IsPlaying and (not scrub or os.clock()-lastFeedback>0.25) then brushSound:Stop() end
 local dt=math.min(frameDt,0.1); visualTime+=dt
 local contact=scrub and os.clock()-lastFeedback<0.25
 brushBlend+=( (contact and 1 or 0)-brushBlend )*(1-math.exp(-dt*16))
 local moving=alive and hum.MoveDirection.Magnitude or 0
 local phase=visualTime*24
 local offset=CFrame.new(0.56,-0.51,-1.05)*CFrame.Angles(-0.13,0.10,-0.16)
 offset*=CFrame.new(math.sin(visualTime*7)*0.008*moving,math.cos(visualTime*14)*0.008*moving,0)
 offset*=CFrame.new(math.sin(phase)*0.048*brushBlend,math.sin(phase*2)*0.006*brushBlend,math.cos(phase)*0.035*brushBlend)
 offset*=CFrame.Angles(math.cos(phase)*0.018*brushBlend,math.sin(phase)*0.035*brushBlend,0)
 for _,item in ipairs(pieces) do
  item[1].LocalTransparencyModifier=alive and not shop.Visible and 0 or 1
  item[1].CFrame=camera.CFrame*offset*item[2]
 end
 if shop.Visible then UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true
 else UIS.MouseIconEnabled=false end
 cross.TextColor3=os.clock()<flashUntil and Color3.fromRGB(180,215,208) or white
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={char or view,view,puff}
 aimTrack.Visible=false
 local hit=workspace:Raycast(camera.CFrame.Position,camera.CFrame.LookVector*C.Range,params)
 if hit and hit.Instance:IsDescendantOf(patches) then
  local deck=hit.Instance:GetAttribute('Deck'); local percent=map:GetAttribute('Progress'..deck) or 0
  aimTrack.Visible=not shop.Visible; aimFill.Size=UDim2.fromScale(percent,1)
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
