-- Structural generation smoke test only. This is NOT a Roblox engine or playtest.
local vecMT={}
vecMT.__index=function(v,k) if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
 if k=='Unit' then return v/v.Magnitude end
 if k=='Cross' then return function(a,b) return setmetatable({X=a.Y*b.Z-a.Z*b.Y,Y=a.Z*b.X-a.X*b.Z,Z=a.X*b.Y-a.Y*b.X},vecMT) end end
end
vecMT.__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vecMT) end
vecMT.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},vecMT) end
vecMT.__mul=function(a,b) return setmetatable({X=a.X*b,Y=a.Y*b,Z=a.Z*b},vecMT) end
vecMT.__div=function(a,b) return setmetatable({X=a.X/b,Y=a.Y/b,Z=a.Z/b},vecMT) end
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vecMT) end}
local Vector3int16=Vector3
local Vector2={new=function(x,y) return setmetatable({X=x,Y=y},{__index=function(v,k) if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y) end end}) end}
local cfMT={}; cfMT.__mul=function(a,b) return setmetatable({Position=a.Position+b.Position},cfMT) end
local CFrame={new=function(x,y,z) return setmetatable({Position=type(x)=='table' and x or Vector3.new(x,y,z)},cfMT) end}
CFrame.Angles=function() return CFrame.new() end
CFrame.lookAt=function(a,b) return CFrame.new(a) end
CFrame.fromMatrix=function(position,right,up,back) return setmetatable({Position=position,RightVector=right,UpVector=up,BackVector=back},cfMT) end
local Color3={fromRGB=function(r,g,b) return {R=r,G=g,B=b} end,new=function(r,g,b) return {R=r,G=g,B=b} end}
local UDim2={fromScale=function() return {} end,fromOffset=function() return {} end,new=function() return {} end}
local Enum=setmetatable({},{__index=function(t,k) local e=setmetatable({},{__index=function(_,v) return k..'.'..v end}); rawset(t,k,e); return e end})
local Region3={new=function(a,b) return {Min=a,Max=b} end}; local Region3int16=Region3
local deferred={}; local spawned={}
local task={defer=function(fn) table.insert(deferred,fn) end,spawn=function(fn) table.insert(spawned,fn) end,wait=function() coroutine.yield() end}
local function flush()
 local passes=0
 while #deferred>0 do
  passes+=1; assert(passes<20,'environment event repair loop')
  local batch=deferred; deferred={}; for _,fn in ipairs(batch) do fn() end
 end
end
local function signal()
 local callbacks={}
 return {Connect=function(_,fn) table.insert(callbacks,fn) end,Fire=function(_,...) for _,fn in ipairs(callbacks) do fn(...) end end}
end
local messages={}
local methods={}; local mt={}
mt.__index=function(o,k)
 if methods[k] then return methods[k] end
 if k=='Changed' or k=='ChildAdded' or k=='ChildRemoved' or k=='OnServerEvent' or k=='OnClientEvent' or k=='PlayerRemoving' then if not o.signals[k] then o.signals[k]=signal() end; return o.signals[k] end
 if k=='Position' and o.props.CFrame then return o.props.CFrame.Position end
 if o.props[k]~=nil then return o.props[k] end
 for _,c in ipairs(o.children) do if c.Name==k then return c end end
end
mt.__newindex=function(o,k,v)
 local prior=o.props[k]
 if prior==v then return end
 if k=='Parent' then
  local parent=o.props.Parent
  if parent then for i,c in ipairs(parent.children) do if c==o then table.remove(parent.children,i); break end end end
  o.props.Parent=v
  if parent and parent.signals.ChildRemoved then parent.signals.ChildRemoved:Fire(o) end
  if v then table.insert(v.children,o); if v.signals.ChildAdded then v.signals.ChildAdded:Fire(o) end end
 else o.props[k]=v end
 if o.signals.Changed then o.signals.Changed:Fire(k) end
end
local createdPartCount=0
local Instance={new=function(class) if class=='Part' then createdPartCount+=1 end; return setmetatable({props={Name=class,ClassName=class},children={},attrs={},signals={}},mt) end}
function methods:FireClient(player,kind,data) table.insert(messages,{Player=player,Kind=kind,Data=data}) end
function methods:GetChildren() return table.clone(self.children) end
function methods:FindFirstChild(name) for _,c in ipairs(self.children) do if c.Name==name then return c end end end
function methods:WaitForChild(name) local child=self:FindFirstChild(name); assert(child,'missing reference '..name); return child end
function methods:SetAttribute(k,v) self.attrs[k]=v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:IsA(c) return self.ClassName==c or (c=='BasePart' and (self.ClassName=='Part' or self.ClassName=='WedgePart' or self.ClassName=='SpawnLocation')) end
function methods:Destroy() for _,c in ipairs(self:GetChildren()) do c:Destroy() end; self.Parent=nil end
function methods:GetDescendants()
 local result={}; local function walk(o) for _,c in ipairs(o.children) do table.insert(result,c); walk(c) end end
 walk(self); return result
end
function methods:IsDescendantOf(root)
 local parent=self.Parent
 while parent do if parent==root then return true end; parent=parent.Parent end
 return false
end
function methods:GetFullName()
 local result=self.Name; local p=self.Parent
 while p do result=p.Name..'.'..result; p=p.Parent end; return result
end
local services={}
for _,n in ipairs({'Workspace','Lighting','ReplicatedStorage','ServerScriptService','StarterPlayer','ServerStorage'}) do services[n]=Instance.new(n) end
local scripts=Instance.new('Folder'); scripts.Name='StarterPlayerScripts'; scripts.Parent=services.StarterPlayer
local terrain=Instance.new('Terrain'); terrain.Parent=services.Workspace
local copies,writes=0,0
terrain.CopyRegion=function(self,r) copies+=1; return Instance.new('TerrainRegion') end
terrain.GetMaterialColor=function() return Color3.new(1,1,1) end
terrain.SetMaterialColor=function() end
terrain.WriteVoxels=function(self,r,res,m,o)
 assert(res==4 and #m==128 and #o==128)
 for x=1,128 do assert(#m[x]==26 and #o[x]==26)
  for y=1,26 do assert(#m[x][y]==128 and #o[x][y]==128)
   for z=1,128 do assert(o[x][y][z]>=0 and o[x][y][z]<=1) end
  end
 end
 writes+=1
end
services.RunService={IsRunning=function() return false end}
local game={GetService=function(_,name) assert(services[name],name); return services[name] end}
function game:GetDescendants()
 local result={}; for _,service in pairs(services) do if service.GetDescendants then for _,object in ipairs(service:GetDescendants()) do table.insert(result,object) end end end; return result
end
local Workspace=services.Workspace; local workspace=Workspace; Workspace.StreamingEnabled=true
local baseplate=Instance.new('Part'); baseplate.Name='Baseplate'; baseplate.Parent=Workspace
local Random={new=function(seed)
 local state=seed
 local function nextValue() state=(state*48271)%2147483647; return state/2147483647 end
 return {NextNumber=function(_,a,b) return a+(b-a)*nextValue() end,NextInteger=function(_,a,b) return math.floor(a+(b-a+1)*nextValue()) end}
end}
local simClock=100; local fakeOS={clock=function() return simClock end,time=function() return 100000 end}
local RaycastParams={new=function() return {} end}
local require
local cache={}
require=function(module)
 if cache[module] then return cache[module] end
 local fn,err=loadstring('local game,workspace,script,require,Instance,Enum,Vector3,CFrame,Color3,task,warn,os,RaycastParams,Vector2 = ...\n'..module.Source)
 assert(fn,err)
 local result=fn(game,workspace,module,require,Instance,Enum,Vector3,CFrame,Color3,task,print,fakeOS,RaycastParams,Vector2)
 cache[module]=result; return result
end
local function generate()
-- GENERATOR_GOES_HERE
end

local function check()
 local map=Workspace:FindFirstChild('LunarCleanup'); assert(map)
 assert(map.Patches==nil and #map.SurfaceRegions:GetChildren()==3,'plots must be replaced by region metadata')
 assert(map.Depot.Position.X==-12 and map.Terminal.Position.X==12)
 assert(map.Depot.Sell and map.Terminal.Upgrade)
 local count=0
 local function walk(o) for _,c in ipairs(o:GetChildren()) do if c:IsA('BasePart') then count+=1 end; walk(c) end end
 walk(map)
 print('Generated static geometry parts:',count,'; region definitions:',#map.SurfaceRegions:GetChildren())
 return count
end
generate(); local count=check()
generate(); assert(check()==count,'rerun accumulated parts')
assert(copies==2 and writes==2,'snapshot/rerun contract')
assert(baseplate.Parent==services.ServerStorage.LunarCleanupOriginalEnvironment)
for _,service in ipairs({'Workspace','ReplicatedStorage','ServerScriptService'}) do
 local n=0; for _,c in ipairs(services[service]:GetChildren()) do if c.Name=='LunarCleanup' then n+=1 end end
 assert(n==1,'duplicate service roots')
end
local net=services.ReplicatedStorage.LunarCleanup
local Environment=require(net.Environment)
local texture=require(net.Config).Environment.SkyTexture
local function blackFaces(object)
 for _,face in ipairs({'Bk','Dn','Ft','Lf','Rt','Up'}) do assert(object['Skybox'..face]==texture,'unconfigured sky face') end
end
local originalSky=services.Lighting.LunarSky
blackFaces(originalSky)
-- No client-created Sky, archive or moving geometry. Local-only conflicts get black faces in place.
originalSky.Parent=nil
Environment.StartClient()
assert(services.Lighting.LunarSky==nil,'client must not create a competing Sky')
originalSky.Parent=services.Lighting
assert(services.Lighting.LunarSky==originalSky)
local clientSky=Instance.new('Sky'); clientSky.Name='LocalConflict'; clientSky.Parent=services.Lighting
blackFaces(clientSky); assert(clientSky.Parent==services.Lighting)
clientSky.SkyboxUp='BLUE'; blackFaces(clientSky)
local localAtmosphere=Instance.new('Atmosphere'); localAtmosphere.Density=0.4; localAtmosphere.Haze=2; localAtmosphere.Glare=1
localAtmosphere.Parent=services.Lighting; assert(localAtmosphere.Density==0 and localAtmosphere.Haze==0 and localAtmosphere.Glare==0)
local localClouds=Instance.new('Clouds'); localClouds.Enabled=true; localClouds.Parent=terrain
assert(not localClouds.Enabled and localClouds.Parent==terrain)
localClouds.Enabled=true; assert(not localClouds.Enabled)
local archive=services.ServerStorage.LunarCleanupOriginalEnvironment.LightingBeforeOverhaul
Environment.Start(archive); flush()
assert(clientSky.Parent==archive and localAtmosphere.Parent==archive and localClouds.Parent==archive)
local sky=Instance.new('Sky'); sky.Name='InjectedSky'; sky.Parent=services.Lighting
local atmosphere=Instance.new('Atmosphere'); atmosphere.Parent=services.Lighting
local clouds=Instance.new('Clouds'); clouds.Enabled=true; clouds.Parent=terrain
services.Lighting.Brightness=0; services.Lighting.ClockTime=0
flush()
assert(sky.Parent==archive and atmosphere.Parent==archive)
assert(clouds.Parent==archive and clouds.Enabled==false)
assert(services.Lighting.Brightness==3.5 and services.Lighting.ClockTime==15.7)
assert(services.Lighting.EnvironmentSpecularScale==0)
-- Float-rounded engine property readings must not cause repeated assignments/repair cycles.
services.Lighting.Brightness=3.50000001; flush(); assert(services.Lighting.Brightness==3.50000001)
local lunar=services.Lighting.LunarSky; lunar:Destroy(); flush()
assert(services.Lighting.LunarSky and services.Lighting.LunarSky~=lunar)
blackFaces(services.Lighting.LunarSky)
services.Lighting.LunarSky.SkyboxFt='BLUE'; flush(); blackFaces(services.Lighting.LunarSky)
assert(Environment.CreateBackdrop==nil)
assert(#spawned==1,'only the client preload task should be spawned; no periodic sky loops')
for _,object in ipairs(Workspace:GetDescendants()) do
 assert(object.Name~='SpaceBackdrop' and object.Name~='BlackSpace' and object.Name~='LunarCleanupLocalSpace')
end
print('STRUCTURE PASS: repeat generation, voxels, grid, native black faces, one Sky authority, no geometry/timers, float tolerance')
