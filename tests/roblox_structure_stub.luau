-- Structural generation smoke test only. This is NOT a Roblox engine or playtest.
local vecMT={}
vecMT.__index=function(v,k) if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end end
vecMT.__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vecMT) end
vecMT.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},vecMT) end
vecMT.__mul=function(a,b) return setmetatable({X=a.X*b,Y=a.Y*b,Z=a.Z*b},vecMT) end
vecMT.__div=function(a,b) return setmetatable({X=a.X/b,Y=a.Y/b,Z=a.Z/b},vecMT) end
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vecMT) end}
local Vector3int16=Vector3
local cfMT={}; cfMT.__mul=function(a,b) return setmetatable({Position=a.Position+b.Position},cfMT) end
local CFrame={new=function(x,y,z) return setmetatable({Position=type(x)=='table' and x or Vector3.new(x,y,z)},cfMT) end}
CFrame.Angles=function() return CFrame.new() end
CFrame.lookAt=function(a,b) return CFrame.new(a) end
local Color3={fromRGB=function(r,g,b) return {R=r,G=g,B=b} end,new=function(r,g,b) return {R=r,G=g,B=b} end}
local UDim2={fromScale=function() return {} end,fromOffset=function() return {} end,new=function() return {} end}
local Enum=setmetatable({},{__index=function(t,k) local e=setmetatable({},{__index=function(_,v) return k..'.'..v end}); rawset(t,k,e); return e end})
local Region3={new=function(a,b) return {Min=a,Max=b} end}; local Region3int16=Region3
local deferred={}; local spawned={}
local task={defer=function(fn) table.insert(deferred,fn) end,spawn=function(fn) table.insert(spawned,fn) end,wait=function() end}
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
local methods={}; local mt={}
mt.__index=function(o,k)
 if methods[k] then return methods[k] end
 if k=='Changed' or k=='ChildAdded' or k=='ChildRemoved' then if not o.signals[k] then o.signals[k]=signal() end; return o.signals[k] end
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
local Instance={new=function(class) return setmetatable({props={Name=class,ClassName=class},children={},attrs={},signals={}},mt) end}
function methods:GetChildren() return table.clone(self.children) end
function methods:FindFirstChild(name) for _,c in ipairs(self.children) do if c.Name==name then return c end end end
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
 assert(res==4 and #m==80 and #o==80)
 for x=1,80 do assert(#m[x]==20 and #o[x]==20)
  for y=1,20 do assert(#m[x][y]==80 and #o[x][y]==80)
   for z=1,80 do assert(o[x][y][z]>=0 and o[x][y][z]<=1) end
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
local require
local cache={}
require=function(module)
 if cache[module] then return cache[module] end
 local fn,err=loadstring('local game,workspace,script,require,Instance,Enum,Vector3,CFrame,Color3,task,warn = ...\n'..module.Source)
 assert(fn,err)
 local result=fn(game,workspace,module,require,Instance,Enum,Vector3,CFrame,Color3,task,print)
 cache[module]=result; return result
end
local function generate()
-- GENERATOR_GOES_HERE
end

local function check()
 local map=Workspace:FindFirstChild('LunarCleanup'); assert(map)
 assert(#map.Patches:GetChildren()==588,'patch count')
 local ids,cells={},{}
 for _,p in ipairs(map.Patches:GetChildren()) do
  local id=p:GetAttribute('PatchId'); assert(not ids[id]); ids[id]=true
  assert(p.Position.Y==1.53 and p:GetAttribute('Health')==12)
  local key=math.floor(p.Position.X/0.85)..':'..math.floor(p.Position.Z/0.85)
  assert(not cells[key],'duplicate grid cell'); cells[key]=true
 end
 assert(map.Depot.Position.X==-12 and map.Terminal.Position.X==12)
 assert(map.Depot.Sell and map.Terminal.Upgrade)
 local count=0
 local function walk(o) for _,c in ipairs(o:GetChildren()) do if c:IsA('BasePart') then count+=1 end; walk(c) end end
 walk(map)
 print('Generated geometry parts:',count,'; patches:',#map.Patches:GetChildren())
 return count
end
generate(); local count=check()
generate(); assert(check()==count,'rerun accumulated parts')
assert(copies==1 and writes==2,'snapshot/rerun contract')
assert(baseplate.Parent==services.ServerStorage.LunarCleanupOriginalEnvironment)
for _,service in ipairs({'Workspace','ReplicatedStorage','ServerScriptService'}) do
 local n=0; for _,c in ipairs(services[service]:GetChildren()) do if c.Name=='LunarCleanup' then n+=1 end end
 assert(n==1,'duplicate service roots')
end
local net=services.ReplicatedStorage.LunarCleanup
local Environment=require(net.Environment)
local archive=services.ServerStorage.LunarCleanupOriginalEnvironment.LightingBeforeOverhaul
Environment.Start(archive)
local sky=Instance.new('Sky'); sky.Name='InjectedSky'; sky.Parent=services.Lighting
local atmosphere=Instance.new('Atmosphere'); atmosphere.Parent=services.Lighting
local clouds=Instance.new('Clouds'); clouds.Enabled=true; clouds.Parent=terrain
services.Lighting.Brightness=0; services.Lighting.ClockTime=0
flush()
assert(sky.Parent==archive and atmosphere.Parent==archive)
assert(clouds.Parent==archive and clouds.Enabled==false)
assert(services.Lighting.Brightness==3.5 and services.Lighting.ClockTime==15.7)
assert(services.Lighting.EnvironmentSpecularScale==0)
local lunar=services.Lighting.LunarSky; lunar:Destroy(); flush()
assert(services.Lighting.LunarSky and services.Lighting.LunarSky~=lunar)
local localSpace,walls=Environment.CreateBackdrop(Workspace)
assert(#walls==6)
for _,wall in ipairs(walls) do
 assert(wall.Part.Parent==localSpace and wall.Part.Anchored and wall.Part.CastShadow==false)
 assert(wall.Part.CanCollide==false and wall.Part.CanQuery==false and wall.Part.CanTouch==false)
 assert(wall.Part.Color.R==0 and wall.Part.Color.G==0 and wall.Part.Color.B==0)
end
-- Removing server backdrop parts cannot remove the independently created client backdrop.
for _,object in ipairs(Workspace.LunarCleanup:GetChildren()) do if object.Name=='SpaceBackdrop' then object:Destroy() end end
assert(#localSpace:GetChildren()==6)
print('STRUCTURE PASS: repeat generation, voxels, patch grid, anchors, runtime environment repair, independent local backdrop')
