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
for _, name in ipairs({'Scrub','Action','Feedback','Surface'}) do
 local remote = Instance.new('RemoteEvent'); remote.Name = name; remote.Parent = net
end
local config = Instance.new('ModuleScript'); config.Name = 'Config'; config.Parent = net
config.Source = [==[
-- BALANCE CONFIGURATION: all pacing values live here. Save schema stays v1.
-- Power = health removed per second per patch before distance falloff.
-- Yield * SellPrice = credits per health (0.5 * 2 = 1).
local Config = {
 Version = 1, PatchSize = 0.85, Columns = 14, Rows = 14, PatchHealth = 12,
 Range = 14, Tick = 0.10, ResetSeconds = 12,
 DustPerHealth=0.5, SellPrice=2, SpeedPerLevel=0.20, RadiusPerLevel=0.10,
 Falloff=0.45, MaxScrubDelta=0.14,
 Tools = {
  {Name='TOOTHBRUSH', Radius=0.48, Power=12/4.5, Price=0},
  {Name='REGOLITH BRUSH', Radius=0.85, Power=4, Price=2000},
  {Name='INDUSTRIAL SCRUBBER', Radius=1.35, Power=6, Price=9000},
 },
 SpeedPrices={440,1300,4200,11000}, RadiusPrices={600,1900,8400}, StoragePrices={360,1100,2400,7600,15600},
 -- Every level is at least as large as the old bag: no legacy carried dust is discarded.
 StorageCapacities={100,260,560,1000,1700,2600},
 -- Timing-model assumptions only, never an artificial earning cap or wait timer.
 Timing={ContactEfficiency=0.65, SellRoundTripSeconds=12},
 Environment={
  -- Verified client-packaged RGB-black image; no uploaded asset or network dependency.
  SkyTexture='rbxasset://textures/blackBkg_square.png',
  Lighting={ClockTime=15.7,GeographicLatitude=12,Brightness=3.5,GlobalShadows=true,
   ShadowSoftness=0.06,ExposureCompensation=-0.35,
   Ambient=Color3.fromRGB(9,11,16),OutdoorAmbient=Color3.fromRGB(24,26,32),
   EnvironmentDiffuseScale=0,EnvironmentSpecularScale=0,
   FogStart=1400,FogEnd=1800,FogColor=Color3.new(0,0,0)},
 },
}
Config.Capacity=function(level) return Config.StorageCapacities[level+1] end
return Config
]==]
local C = require(config)
local environment=Instance.new('ModuleScript'); environment.Name='Environment'; environment.Parent=net
environment.Source=[==[
local Lighting=game:GetService('Lighting')
local C=require(script.Parent.Config)
local Environment={}
local faces={'Bk','Dn','Ft','Lf','Rt','Up'}
local function equal(a,b)
 -- Roblox numeric properties may round to float32: exact Lua-double comparison
 -- can repeatedly assign the same value and keep a repair loop alive.
 if type(a)=='number' and type(b)=='number' then return math.abs(a-b)<0.0001 end
 return a==b
end
local function profile()
 for property,value in pairs(C.Environment.Lighting) do
  if not equal(Lighting[property],value) then Lighting[property]=value end
 end
end
local function configure(object)
 if object:IsA('Sky') then
  for _,face in ipairs(faces) do
   local property='Skybox'..face
   if object[property]~=C.Environment.SkyTexture then object[property]=C.Environment.SkyTexture end
  end
  if object.CelestialBodiesShown then object.CelestialBodiesShown=false end
  if object.StarCount~=0 then object.StarCount=0 end
 elseif object:IsA('Atmosphere') then
  for _,property in ipairs({'Density','Haze','Glare'}) do
   if not equal(object[property],0) then object[property]=0 end
  end
 elseif object:IsA('Clouds') then
  if object.Enabled then object.Enabled=false end
 end
end
function Environment.Apply(archive)
 -- Edit/server authority only. Clients never create, delete or reparent replicated skies.
 profile()
 local sky=Lighting:FindFirstChild('LunarSky')
 if not sky or not sky:IsA('Sky') then
  if sky then sky.Parent=archive end
  sky=Instance.new('Sky'); sky.Name='LunarSky'; sky:SetAttribute('LunarCleanupOwned',true)
  configure(sky) -- Fully configured before becoming active; no default-blue intermediate state.
  sky.Parent=Lighting
 else configure(sky) end
 for _,object in ipairs(Lighting:GetChildren()) do
  if (object:IsA('Sky') and object~=sky) or object:IsA('Atmosphere') or object:IsA('Clouds') then
   warn('[LunarCleanup environment] Server preserving conflicting '..object.ClassName..' at '..object:GetFullName())
   if object:IsA('Clouds') then
    if object:GetAttribute('LunarCleanupOriginalEnabled')==nil then object:SetAttribute('LunarCleanupOriginalEnabled',object.Enabled) end
   end
   configure(object); object.Parent=archive
  end
 end
 for _,object in ipairs(workspace.Terrain:GetChildren()) do
  if object:IsA('Clouds') or object:IsA('Atmosphere') then
   warn('[LunarCleanup environment] Server preserving '..object.ClassName..' at '..object:GetFullName())
   if object:IsA('Clouds') and object:GetAttribute('LunarCleanupOriginalEnabled')==nil then object:SetAttribute('LunarCleanupOriginalEnabled',object.Enabled) end
   configure(object); object.Parent=archive
  end
 end
end
local function watch(profileChanged,topologyChanged)
 local bound=setmetatable({},{__mode='k'})
 local function attach(object)
  if not (object:IsA('Sky') or object:IsA('Atmosphere') or object:IsA('Clouds')) then return end
  if object:IsA('Clouds') and object:GetAttribute('LunarCleanupOriginalEnabled')==nil then
   object:SetAttribute('LunarCleanupOriginalEnabled',object.Enabled)
  end
  configure(object)
  if bound[object] then return end
  bound[object]=true
  local busy=false
  object.Changed:Connect(function()
   if busy or (object.Parent~=Lighting and object.Parent~=workspace.Terrain) then return end
   busy=true; configure(object); busy=false
  end)
 end
 Lighting.ChildAdded:Connect(function(object) attach(object); topologyChanged() end)
 Lighting.ChildRemoved:Connect(topologyChanged)
 workspace.Terrain.ChildAdded:Connect(function(object) attach(object); topologyChanged() end)
 Lighting.Changed:Connect(function(property)
  if C.Environment.Lighting[property]~=nil then profileChanged() end
 end)
 for _,object in ipairs(Lighting:GetChildren()) do attach(object) end
 for _,object in ipairs(workspace.Terrain:GetChildren()) do attach(object) end
end
function Environment.Start(archive)
 -- A single server owns Sky identity. Event-driven repairs only; no two-second polling.
 Environment.Apply(archive)
 local queued=false
 local function repair()
  if queued then return end
  queued=true
  task.defer(function() Environment.Apply(archive); queued=false end)
 end
 watch(repair,repair)
end
function Environment.StartClient()
 -- Client handles local-only effects and non-replicated Lighting settings, but never
 -- reparents the server's Sky. Any additional local Sky gets the same black faces.
 profile()
 local busy=false
 local function restoreProfile()
  if busy then return end
  busy=true; profile(); busy=false
 end
 watch(restoreProfile,function() end)
 -- Preload a shipped file, not an external download. Report failures instead of
 -- silently substituting an empty sky or starting another geometry overlay.
 task.spawn(function()
  local ok,err=pcall(function()
   game:GetService('ContentProvider'):PreloadAsync({C.Environment.SkyTexture},function(id,status)
    if status~=Enum.AssetFetchStatus.Success then warn('[LunarCleanup sky] Built-in texture load status: '..tostring(status)) end
   end)
  end)
  if not ok then warn('[LunarCleanup sky] Preload failed: '..tostring(err)) end
 end)
end
return Environment
]==]
local economy=Instance.new('ModuleScript'); economy.Name='Economy'; economy.Parent=net
economy.Source=[==[
local C=require(script.Parent.Config)
local Economy={}
-- Server-only mutations; exported separately so fractional accounting can be tested.
function Economy.Scrub(data,health,power,seconds,distance,radius)
 local carry=data.DustCarry or 0
 local room=C.Capacity(data.Storage)-data.Dust-carry
 local damage=power*math.min(seconds,C.MaxScrubDelta)*(1-C.Falloff*math.min(distance/radius,1))
 local removed=math.max(0,math.min(health,room/C.DustPerHealth,damage))
 local reward=carry+removed*C.DustPerHealth
 local earned=math.floor(reward+1e-9)
 data.Dust+=earned; data.DustCarry=math.max(0,reward-earned)
 return math.max(0,health-removed),removed,earned
end
function Economy.Sell(data)
 local value=data.Dust*C.SellPrice
 data.Money+=value; data.Dust=0
 -- Fractional dust stays in the profile; frequent selling cannot erase it or mint it twice.
 return value
end
return Economy
]==]

local regions=Instance.new('ModuleScript'); regions.Name='Regions'
regions.Parent=net
regions.Source=[==[
local C=require(script.Parent.Config)
local R={}
-- Regional presentation/state settings only. The existing economy Config is unchanged.
R.ChunkCells=12; R.RenderRadius=18; R.EdgeFade=2; R.MaxVisuals=1600; R.BuildPerStep=90
R.WorldSlots=16; R.LeaseSeconds=180; R.SaveSeconds=55; R.SharedAccessThreshold=0.05
R.Definitions={
 {Id=1,Name='TRANQUILITY APPROACH',X=0,Z=-12,RX=22,RZ=26,Tool=1},
 {Id=2,Name='BASALT EXPANSE',X=34,Z=-66,RX=72,RZ=53,Tool=2},
 {Id=3,Name='KEPLER OUTER RIM',X=-73,Z=-101,RX=73,RZ=75,Tool=3},
}
function R.Access(id,tool,previousProgress)
 return tool>=R.Definitions[id].Tool or (id>1 and previousProgress>=R.SharedAccessThreshold)
end
function R.At(x,z)
 -- Leave the habitat, depot, terminal and their shared walking apron uncovered.
 if math.abs(x)<20 and z>10 and z<38 then return nil end
 for _,region in ipairs(R.Definitions) do
  local dx,dz=(x-region.X)/region.RX,(z-region.Z)/region.RZ
  -- Low-frequency edge variation removes obvious circular/rectangular plot boundaries.
  local edge=1+0.06*math.noise(x/14,z/14,73)
  if dx*dx+dz*dz<=edge*edge then return region.Id end
 end
 return nil
end
function R.Cell(gx,gz)
 return R.At((gx+0.5)*C.PatchSize,(gz+0.5)*C.PatchSize)
end
function R.Chunk(gx,gz)
 local x,z=math.floor(gx/R.ChunkCells),math.floor(gz/R.ChunkCells)
 return x..':'..z,(gz-z*R.ChunkCells)*R.ChunkCells+(gx-x*R.ChunkCells)+1,x,z
end
function R.Unpack(key,id)
 local x,z=key:match('^(-?%d+):(-?%d+)$'); x,z=tonumber(x),tonumber(z)
 if not x or not z or type(id)~='number' or id%1~=0 or id<1 or id>R.ChunkCells^2 then return nil end
 return x*R.ChunkCells+(id-1)%R.ChunkCells,z*R.ChunkCells+math.floor((id-1)/R.ChunkCells)
end
function R.BuildIndex()
 local chunks={}; local totals={0,0,0}
 -- Bounded to this expedition map, not the whole Moon. No Part per cell.
 for gx=-190,150 do for gz=-220,35 do
  local region=R.Cell(gx,gz)
  if region then
   local key,id,x,z=R.Chunk(gx,gz)
   local chunk=chunks[key]
   if not chunk then chunk={X=x,Z=z,Cells={}}; chunks[key]=chunk end
   chunk.Cells[id]=region; totals[region]+=1
  end
 end end
 return chunks,totals
end
function R.Encode(health,cells)
 local list={}; local allClean=true
 for id in pairs(cells) do
  local value=health[id] or C.PatchHealth
  if value>0 then allClean=false end
  if value<C.PatchHealth then table.insert(list,id..'='..string.format('%.17g',value)) end
 end
 if allClean then return '*' end
 table.sort(list)
 return table.concat(list,';')
end
function R.Decode(text,cells)
 local health={}
 if text=='*' then for id in pairs(cells) do health[id]=0 end; return health end
 if type(text)~='string' or #text>6000 then return health end
 for id,value in text:gmatch('(%d+)=([^;]+)') do
  id,value=tonumber(id),tonumber(value)
  if cells[id] and value and value==value and value>=0 and value<C.PatchHealth then health[id]=value end
 end
 return health
end
function R.ChunkCellsAt(key)
 local cells={}
 for id=1,R.ChunkCells^2 do
  local gx,gz=R.Unpack(key,id)
  if not gx then return cells end
  local region=R.Cell(gx,gz); if region then cells[id]=region end
 end
 return cells
end
return R
]==]

local surfaceRender=Instance.new('ModuleScript'); surfaceRender.Name='SurfaceRender'
surfaceRender.Parent=net
surfaceRender.Source=[==[
local Players=game:GetService('Players')
local net=game:GetService('ReplicatedStorage'):WaitForChild('LunarCleanup')
local C=require(net.Config); local R=require(net.Regions)
local Render={Status=nil}
local chunks,metadata,visuals,pool={},{},{},{}
local retryAt={}
local folder=Instance.new('Folder'); folder.Name='LunarCleanupSurfaceVisuals'; folder.Parent=workspace
local terrainParams=RaycastParams.new(); terrainParams.FilterType=Enum.RaycastFilterType.Include; terrainParams.FilterDescendantsInstances={workspace.Terrain}
local function recycle(key)
 local record=visuals[key]
 if record then record.Part.Parent=nil; table.insert(pool,record.Part); visuals[key]=nil end
end
local function acquire()
 local p=table.remove(pool)
 if not p then
  p=Instance.new('Part'); p.Name='RegolithCoating'; p.Anchored=true; p.CanCollide=false
  p.CanTouch=false; p.CanQuery=false; p.CastShadow=false; p.Material=Enum.Material.Sand
 end
 return p
end
net.Surface.OnClientEvent:Connect(function(kind,data)
 if kind=='Snapshot' then
  Render.Status=data.Status
  local keep={}; for _,key in ipairs(data.Keep) do keep[key]=true end
  for key in pairs(chunks) do if not keep[key] then chunks[key]=nil; metadata[key]=nil end end
  for key,encoded in pairs(data.Chunks) do
   metadata[key]=metadata[key] or R.ChunkCellsAt(key)
   chunks[key]=R.Decode(encoded,metadata[key])
  end
 elseif kind=='Delta' then
  for _,cell in ipairs(data) do if chunks[cell.Key] then chunks[cell.Key][cell.Id]=cell.Health end end
 end
end)
local function accessible(id,tool)
 local status=Render.Status
 local previous=id>1 and status and status.Regions[id-1].Progress or 0
 return R.Access(id,tool,previous)
end
function Render.Describe(position,tool)
 local id=R.At(position.X,position.Z)
 if not id then return 'UNSURVEYED REGOLITH',0 end
 local definition=R.Definitions[id]
 if not accessible(id,tool) then return definition.Name..'  /  '..C.Tools[definition.Tool].Name..' OR 5% OF PREVIOUS REGION',0 end
 local status=Render.Status
 if not status or not status.Ready then return definition.Name..'  /  LOADING SURVEY',0 end
 if not status.Writable then return 'SURFACE SAVING UNAVAILABLE — CLEANING PAUSED',0 end
 local progress=status.Regions[id].Progress
 return string.format('%s  /  %.1f%% RESTORED',definition.Name,progress*100),progress
end
function Render.Summary()
 local status=Render.Status
 if not status then return 'CONNECTING TO LUNAR SURVEY...' end
 local title=status.Persistent and ('SURVEY WORLD '..status.Slot) or 'TEMPORARY STUDIO SURVEY'
 if not status.Ready then title='LOADING SURVEY WORLD...' elseif not status.Writable then title='SURVEY OFFLINE — CLEANING PAUSED' end
 local lines={title}
 for _,definition in ipairs(R.Definitions) do
  local pct=status.Regions[definition.Id].Progress*100
  local locked=not accessible(definition.Id,Players.LocalPlayer:GetAttribute('Tool') or 1)
  table.insert(lines,string.format('%s  %.1f%% %s',definition.Name,pct,locked and '[TOOL LOCK]' or ''))
 end
 return table.concat(lines,'\n')
end
function Render.Start()
 local player=Players.LocalPlayer
 task.spawn(function()
  while folder.Parent do net.Surface:FireServer('Subscribe'); task.wait(0.8) end
 end)
 task.spawn(function()
  while folder.Parent do
   task.wait(0.1)
   local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
   if root then
    local center=root.Position; local radius=R.RenderRadius; local reach=math.ceil(radius/C.PatchSize)
    local gx,gz=math.floor(center.X/C.PatchSize),math.floor(center.Z/C.PatchSize)
    local candidates={}; local desired={}
    for dx=-reach,reach do for dz=-reach,reach do
     local x,z=gx+dx,gz+dz
     local px,pz=(x+0.5)*C.PatchSize,(z+0.5)*C.PatchSize
     local dist2=(px-center.X)^2+(pz-center.Z)^2
     if dist2<radius^2 then
      local key,id=R.Chunk(x,z)
      local health=metadata[key] and metadata[key][id] and chunks[key] and (chunks[key][id] or C.PatchHealth)
      if health and health>0 then
       local cellKey=x..':'..z
       table.insert(candidates,{Key=cellKey,X=px,Z=pz,Distance=math.sqrt(dist2),Health=health})
      end
     end
    end end
    table.sort(candidates,function(a,b) return a.Distance<b.Distance end)
    for i=1,math.min(#candidates,R.MaxVisuals) do desired[candidates[i].Key]=true end
    for key in pairs(visuals) do if not desired[key] then recycle(key) end end
    for key in pairs(retryAt) do if not desired[key] then retryAt[key]=nil end end
    local built=0; local now=os.clock()
    for i=1,math.min(#candidates,R.MaxVisuals) do
     local item=candidates[i]; local record=visuals[item.Key]
     if not record and built<R.BuildPerStep and now>=(retryAt[item.Key] or 0) then
      built+=1
      -- Query the actual streamed voxel surface, not the analytic height approximation.
      local hit=workspace:Raycast(Vector3.new(item.X,80,item.Z),Vector3.new(0,-160,0),terrainParams)
      if hit and hit.Normal.Y>=0.35 then
       local normal=hit.Normal
       local right=(Vector3.new(1,0,0)-normal*normal.X).Unit
       local back=right:Cross(normal).Unit
       local p=acquire()
       local sx=C.PatchSize*1.035/math.max(0.45,Vector2.new(right.X,right.Z).Magnitude)
       local sz=C.PatchSize*1.035/math.max(0.45,Vector2.new(back.X,back.Z).Magnitude)
       p.Size=Vector3.new(sx,0.012,sz)
       p.CFrame=CFrame.fromMatrix(hit.Position+normal*0.025,right,normal,back)
       local shade=math.floor(73+math.noise(item.X/7,item.Z/7,4)*12)
       p.Color=Color3.fromRGB(shade,shade-1,shade-2); p.Transparency=1; p.Parent=folder
       record={Part=p,Born=now}; visuals[item.Key]=record; retryAt[item.Key]=nil
      else
       -- Missing streamed Terrain or a cliff must not starve all farther candidates.
       retryAt[item.Key]=now+(hit and 3 or 0.5)
      end
     end
     if record then
      local fade=math.clamp((radius-item.Distance)/R.EdgeFade,0,1)
      fade=fade*fade*(3-2*fade)
      record.Part.Transparency=1-(item.Health/C.PatchHealth)*fade*math.clamp((now-record.Born)/0.2,0,1)
     end
    end
   else for key in pairs(visuals) do recycle(key) end end
  end
 end)
end
return Render
]==]

local surfaceWorld=Instance.new('ModuleScript'); surfaceWorld.Name='SurfaceWorld'
surfaceWorld.Source=[==[
local Players=game:GetService('Players')
local DSS=game:GetService('DataStoreService')
local Run=game:GetService('RunService')
local net=game:GetService('ReplicatedStorage'):WaitForChild('LunarCleanup')
local C=require(net.Config); local R=require(net.Regions)
local World={Ready=false,Persistent=false,Slot=0,Active=true,Saving=false,Lost=false,Lease=0}
local index,totals=R.BuildIndex()
local storeOK,store=pcall(function() return DSS:GetDataStore('LunarCleanup_Surface_v1') end)
if not storeOK then warn('Lunar surface store initialization unavailable: '..tostring(store)); store=nil end
local encoded,live,dirty,changes={},{},{},{}
local removed={0,0,0}; local subscriptions={}; local requestTimes={}
local token
local function chunk(key)
 if not index[key] then return nil end
 if not live[key] then live[key]=R.Decode(encoded[key],index[key].Cells) end
 return live[key]
end
function World.Stats()
 local stats={}
 for i,definition in ipairs(R.Definitions) do
  stats[i]={Name=definition.Name,Tool=definition.Tool,Progress=math.clamp(removed[i]/math.max(1,totals[i]*C.PatchHealth),0,1),Cells=totals[i]}
 end
 return {Regions=stats,Slot=World.Slot,Persistent=World.Persistent,Ready=World.Ready,Writable=World.CanScrub()}
end
function World.CanScrub()
 return World.Ready and not World.Lost and (not World.Persistent or os.time()<World.Lease-15)
end
function World.Access(id,tool)
 local previous=id>1 and removed[id-1]/math.max(1,totals[id-1]*C.PatchHealth) or 0
 return R.Access(id,tool,previous)
end
function World.Get(gx,gz)
 local key,id=R.Chunk(gx,gz); local meta=index[key]
 if not meta or not meta.Cells[id] then return nil end
 local health=chunk(key)
 return health[id] or C.PatchHealth,meta.Cells[id],key,id
end
function World.Set(key,id,value)
 local meta=index[key]; if not meta or not meta.Cells[id] then return end
 local health=chunk(key); local previous=health[id] or C.PatchHealth
 value=math.clamp(value,0,previous) -- monotonic; only a new world/region can add new dirt.
 if value==previous then return end
 health[id]=value; removed[meta.Cells[id]]+=previous-value; dirty[key]=true
 changes[key]=changes[key] or {}; changes[key][id]=value
end
local function copyEncoded()
 for key in pairs(dirty) do encoded[key]=R.Encode(chunk(key),index[key].Cells); dirty[key]=nil end
 local result={}; for key,value in pairs(encoded) do result[key]=value end
 return result
end
function World.Save(release)
 if not World.Persistent or World.Lost or World.Saving then return false end
 World.Saving=true
 local snapshot=copyEncoded()
 local size=0; for key,value in pairs(snapshot) do size+=#key+#value end
 if size>2500000 then World.Saving=false; warn('Lunar surface snapshot limit reached; refusing an oversized save'); return false end
 local ok,result=pcall(function()
  return store:UpdateAsync('World_'..World.Slot,function(old)
   if type(old)~='table' or old.Session~=token then return nil end
   return {Version=1,Chunks=snapshot,Session=release and '' or token,Lease=release and 0 or os.time()+R.LeaseSeconds}
  end)
 end)
 World.Saving=false
 if ok and result then World.Lease=result.Lease; return true end
 if ok then World.Lost=true; warn('Lunar surface world lease lost; further surface rewards are paused.')
 else warn('Lunar surface save failed; retrying on the next scheduled save: '..tostring(result)) end
 return false
end
function World.Start(session)
 token=session
 for slot=1,(store and R.WorldSlots or 0) do
  local ok,result=pcall(function()
   return store:UpdateAsync('World_'..slot,function(old)
    old=type(old)=='table' and old or {}
    if old.Version and old.Version~=1 then return nil end
    if old.Session and old.Session~='' and (tonumber(old.Lease) or 0)>os.time() then return nil end
    return {Version=1,Chunks=type(old.Chunks)=='table' and old.Chunks or {},Session=token,Lease=os.time()+R.LeaseSeconds}
   end)
  end)
  if not ok then warn('Lunar surface load unavailable: '..tostring(result)); break end
  if result and result.Session==token then
   World.Slot=slot; World.Lease=result.Lease; World.Persistent=true
   for key,value in pairs(result.Chunks) do
    if index[key] and type(value)=='string' then
     encoded[key]=value
     local values=R.Decode(value,index[key].Cells)
     for id,h in pairs(values) do removed[index[key].Cells[id]]+=C.PatchHealth-h end
    end
   end
   break
  end
 end
 -- Studio API access is often disabled. Never silently invent a new persistent world.
 if not World.Persistent and not Run:IsStudio() then
  World.Lost=true; warn('No persistent lunar world available. Surface rewards paused; player profiles are unaffected.')
 end
 World.Ready=true
 task.spawn(function()
  while World.Active do task.wait(R.SaveSeconds); if World.Active then World.Save(false) end end
 end)
end
local function send(player,kind,data)
 if player.Parent then net.Surface:FireClient(player,kind,data) end
end
net.Surface.OnServerEvent:Connect(function(player,action)
 if action~='Subscribe' or not player:GetAttribute('DataReady') then return end
 local now=os.clock(); if now-(requestTimes[player] or 0)<0.6 then return end; requestTimes[player]=now
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 if not root then return end
 -- Derive subscriptions from the server character, never client-supplied coordinates.
 local width=R.ChunkCells*C.PatchSize
 local cx,cz=math.floor(root.Position.X/width),math.floor(root.Position.Z/width)
 local reach=math.ceil(R.RenderRadius/width)+1
 local previous=subscriptions[player] or {}; local keep,new,snapshots={},{},{}
 for x=cx-reach,cx+reach do for z=cz-reach,cz+reach do
  local key=x..':'..z
  if index[key] then
   new[key]=true; table.insert(keep,key)
   if not previous[key] and World.Ready then snapshots[key]=R.Encode(chunk(key),index[key].Cells) end
  end
 end end
 -- No cached 'loaded' subscriptions before world loading, so the next request sends snapshots.
 subscriptions[player]=World.Ready and new or {}
 send(player,'Snapshot',{Keep=keep,Chunks=snapshots,Status=World.Stats()})
end)
Players.PlayerRemoving:Connect(function(player) subscriptions[player]=nil; requestTimes[player]=nil end)
task.spawn(function()
 while World.Active do
  task.wait(0.2)
  local batch=changes; changes={}
  for player,subscribed in pairs(subscriptions) do
   local delta={}
   for key,values in pairs(batch) do if subscribed[key] then
    for id,value in pairs(values) do table.insert(delta,{Key=key,Id=id,Health=value}) end
   end end
   if #delta>0 then send(player,'Delta',delta) end
  end
 end
end)
return World
]==]

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
local region=Region3.new(Vector3.new(-256,-48,-256),Vector3.new(256,56,256))
local preservation=ServerStorage:FindFirstChild('LunarCleanupOriginalEnvironment')
if not preservation then
 preservation=Instance.new('Folder'); preservation.Name='LunarCleanupOriginalEnvironment'
 local original=terrain:CopyRegion(Region3int16.new(Vector3int16.new(-40,-10,-40),Vector3int16.new(39,9,39)))
 original.Name='TerrainBeforeOverhaul'; original.Parent=preservation
 local tint=Instance.new('Color3Value'); tint.Name='OriginalSandColor'; tint.Value=terrain:GetMaterialColor(Enum.Material.Sand); tint.Parent=preservation
 preservation.Parent=ServerStorage
end
-- Expanded footprint is preserved separately from the earlier 320-stud snapshot.
-- Never replace an existing snapshot when regenerating.
if not preservation:FindFirstChild('TerrainBeforeRegionalExpansion') then
 local snapshot=terrain:CopyRegion(Region3int16.new(Vector3int16.new(-64,-12,-64),Vector3int16.new(63,13,63)))
 snapshot.Name='TerrainBeforeRegionalExpansion'; snapshot.Parent=preservation
end
-- Read-only inventory identifies conflicts in the user's actual Studio place.
print('[LunarCleanup audit] StreamingEnabled = '..tostring(Workspace.StreamingEnabled))
for _,root in ipairs({Lighting,terrain}) do
 for _,object in ipairs(root:GetDescendants()) do
  if object:IsA('Sky') or object:IsA('Atmosphere') or object:IsA('Clouds') then
   print('[LunarCleanup audit] '..object.ClassName..' : '..object:GetFullName())
  end
 end
end
for _,object in ipairs(game:GetDescendants()) do
 if (object:IsA('BaseScript') or object:IsA('ModuleScript')) and not object:IsDescendantOf(net) then
  local ok,source=pcall(function() return object.Source end)
  if ok and (source:find('Lighting') or source:find('Skybox') or source:find('Atmosphere') or source:find('Clouds')) then
   warn('[LunarCleanup audit] Review environment references in '..object:GetFullName()..' (not automatically disabled)')
  end
 end
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
for ix=1,128 do
 materials[ix]={}; occupancy[ix]={}
 for iy=1,26 do materials[ix][iy]={}; occupancy[ix][iy]={} end
 for iz=1,128 do
  local x,z=-256+(ix-0.5)*4,-256+(iz-0.5)*4
  local h=groundHeight(x,z)
  for iy=1,26 do
   local bottom=-48+(iy-1)*4
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
for i=1,200 do
 local x,z=rng:NextNumber(-245,245),rng:NextNumber(-245,245)
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
-- Survey definitions replace the three framed maintenance decks. All cleaning
-- visuals are local terrain-aligned coating; no server-side Part per surface cell.
local regionFolder=Instance.new('Folder'); regionFolder.Name='SurfaceRegions'; regionFolder.Parent=map
local R=require(regions)
for _,definition in ipairs(R.Definitions) do
 local entry=Instance.new('Folder'); entry.Name='Region_'..definition.Id
 entry:SetAttribute('Title',definition.Name); entry:SetAttribute('RequiredTool',definition.Tool); entry.Parent=regionFolder
end
local sign=detail('SurveyBoard',Vector3.new(9,3,0.25),CFrame.new(-7,3.2,12),dark)
label(sign,'SURFACE RECLAMATION\nAPPROACH → PLAINS → OUTER RIM\nExplore freely / tools or shared restoration open regions')
for _,point in ipairs({Vector3.new(-23,0,-14),Vector3.new(2,0,-37),Vector3.new(5,0,-62),Vector3.new(-27,0,-82),Vector3.new(-58,0,-107)}) do
 local h=groundHeight(point.X,point.Z)
 rod('SurveyStake',Vector3.new(point.X,h,point.Z),Vector3.new(point.X,h+2,point.Z),0.06,pale)
 detail('SurveyMarker',Vector3.new(0.55,0.2,0.1),CFrame.new(point.X,h+1.8,point.Z),safety)
end
-- Current unified lighting; guard for Studio versions without this property.
local lightingOK = pcall(function()
 Lighting.LightingStyle=Enum.LightingStyle.Realistic
 Lighting.PrioritizeLightingQuality=true
end)
if not lightingOK then warn('Select Realistic lighting in Lighting properties if available in your Studio version.') end
require(environment).Apply(originalLighting)
-- Native skybox only: no world walls, camera-relative parts, render-step sky updates,
-- far-plane/culling dependence, or cleanup-triggered background changes.
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
local map=workspace:WaitForChild('LunarCleanup')
local R=require(net.Regions); local World=require(script:WaitForChild('SurfaceWorld'))
local Economy=require(net.Economy)
local original=game:GetService('ServerStorage'):WaitForChild('LunarCleanupOriginalEnvironment')
require(net.Environment).Start(original:WaitForChild('LightingBeforeOverhaul'))
local store=DSS:GetDataStore('LunarCleanup_v1')
local session=game.JobId..':'..Http:GenerateGUID(false)
task.spawn(World.Start,session)
local profiles={}
local surfaceGeometry={} -- Static generated Terrain: lazy cache only cells actually brushed.
local closing=false
local function cleanInteger(v, maximum)
 if type(v)~='number' or v~=v or math.abs(v)==math.huge then return 0 end
 return math.clamp(math.floor(v),0,maximum)
end
local function sanitize(data)
 data=type(data)=='table' and data or {}
 return {Money=cleanInteger(data.Money,100000000),Dust=cleanInteger(data.Dust,1000000),
 DustCarry=type(data.DustCarry)=='number' and data.DustCarry==data.DustCarry and math.clamp(data.DustCarry,0,0.999999999) or 0,
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
 -- Keep legacy carried dust even if a later balance change lowers capacity: sell normally.
 sync(p,s)
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
 if s.data.Dust<=0 then tell(p,'Collect at least 1 dust unit before selling. Keep scrubbing.'); return end
 local value=Economy.Sell(s.data); sync(p,s)
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
 if not hit or hit.Instance~=workspace.Terrain or hit.Normal.Y<0.35 or not World.CanScrub() then return end
 if (head.Position-hit.Position).Magnitude>C.Range then return end
 local sight=workspace:Raycast(head.Position,hit.Position-head.Position,params)
 -- Terrain is one Instance: compare hit positions, not only Instance identity.
 if sight and (sight.Position-hit.Position).Magnitude>0.12 then return end
 local tool=C.Tools[s.data.Tool]; local radius=tool.Radius*(1+C.RadiusPerLevel*s.data.Radius)
 local power=tool.Power*(1+C.SpeedPerLevel*s.data.Speed)
 local center=hit.Position; local regionId=R.At(center.X,center.Z)
 if not regionId or not World.Access(regionId,s.data.Tool) then return end
 local total=0
 local cx,cz=math.floor(center.X/C.PatchSize),math.floor(center.Z/C.PatchSize)
 local steps=math.ceil((radius+C.PatchSize)/C.PatchSize)
 local terrainParams=RaycastParams.new(); terrainParams.FilterType=Enum.RaycastFilterType.Include
 terrainParams.FilterDescendantsInstances={workspace.Terrain}
 for dx=-steps,steps do for dz=-steps,steps do
  local gx,gz=cx+dx,cz+dz
  local health,id,key,cell=World.Get(gx,gz)
  if health and health>0 and World.Access(id,s.data.Tool) then
   local x,z=(gx+0.5)*C.PatchSize,(gz+0.5)*C.PatchSize
   local distance=Vector2.new(x-center.X,z-center.Z).Magnitude
   if distance<=radius+C.PatchSize*0.38 then
    -- Raycast only the small brush neighborhood. This follows the generated voxel
    -- surface, rejects cliffs, and never trusts client coating Parts as reward targets.
    local geometryKey=key..'/'..cell
    local surface=surfaceGeometry[geometryKey]
    if surface==nil then
     surface=workspace:Raycast(Vector3.new(x,80,z),Vector3.new(0,-160,0),terrainParams) or false
     surfaceGeometry[geometryKey]=surface
    end
    if surface and surface.Normal.Y>=0.35 and (surface.Position-center).Magnitude<=radius+C.PatchSize*0.55 then
     local nextHealth,amount=Economy.Scrub(s.data,health,power,dt,distance,radius)
     if amount>0 then World.Set(key,cell,nextHealth); total+=amount end
    end
   end
  end
 end end
 if total>0 then
  sync(p,s); net.Feedback:FireClient(p,'Scrub',{Position=center,Amount=total,Region=regionId})
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
 closing=true; World.Active=false; local pending=1
 task.spawn(function() while World.Saving do task.wait(0.1) end; World.Save(true); pending-=1 end)
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
surfaceWorld.Parent=server
server.Parent=ServerScriptService
local client=Instance.new('LocalScript'); client.Name=NAME
client.Source=[==[
local Players=game:GetService('Players'); local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService'); local Run=game:GetService('RunService')
local player=Players.LocalPlayer; local net=RS:WaitForChild('LunarCleanup'); local C=require(net:WaitForChild('Config'))
local Environment=require(net:WaitForChild('Environment'))
Environment.StartClient()
local map=workspace:WaitForChild('LunarCleanup')
local Surface=require(net:WaitForChild('SurfaceRender')); Surface.Start()

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
local progress=text(gui,'AIM AT THE LUNAR SURFACE',11,UDim2.new(0.5,-260,0.5,30),UDim2.fromOffset(520,36))
progress.TextWrapped=true
progress.TextXAlignment=Enum.TextXAlignment.Center
local aimTrack=Instance.new('Frame'); aimTrack.Size=UDim2.fromOffset(180,2)
aimTrack.Position=UDim2.new(0.5,-90,0.5,72); aimTrack.BorderSizePixel=0
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
local survey=text(gui,'CONNECTING TO LUNAR SURVEY...',11,UDim2.new(1,-310,0,24),UDim2.fromOffset(286,98))
survey.TextYAlignment=Enum.TextYAlignment.Top; survey.TextColor3=muted
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
 if hit and hit.Instance==workspace.Terrain then
  local description,percent=Surface.Describe(hit.Position,math.max(1,value('Tool')))
  progress.Text=description; aimTrack.Visible=not shop.Visible; aimFill.Size=UDim2.fromScale(percent,1)
  if value('Dust')>=math.max(1,value('Capacity')) then progress.Text='STORAGE FULL — RETURN TO DUST DEPOT' end
 else progress.Text='AIM AT THE LUNAR SURFACE' end
 survey.Text=Surface.Summary()
 if scrub and os.clock()-lastSend>=C.Tick then
  lastSend=os.clock(); net.Scrub:FireServer(camera.CFrame.Position,camera.CFrame.LookVector)
 end
end)
message('Scrub the ground ahead. Tools or 5% shared restoration unlock the next region. All terrain is open to exploration.')
]==]
client.Parent=StarterPlayer.StarterPlayerScripts
print('LUNAR CLEANUP generated. Press Play to test. Enable Studio API access only in a separate test place for persistence testing.')
