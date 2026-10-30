-- Uses the actual generated SurfaceWorld and SurfaceRender sources in explicit service stubs.
-- This is not a real DataStore, client/server simulation, Terrain renderer or Studio test.
local C=require(net.Config); local R=require(net.Regions)
services.Players=Instance.new('Players')
local records={}; local requests=0; local failStore=false; local studio=true
services.DataStoreService={GetDataStore=function(_,name)
 assert(name=='LunarCleanup_Surface_v1','regional state must not touch player account storage')
 return {UpdateAsync=function(_,key,callback)
  requests+=1; if failStore then error('simulated unavailable DataStore') end
  local record=callback(records[key])
  if record==nil then return nil end
  records[key]=record; return record
 end}
end}
services.RunService.IsStudio=function() return studio end
local source=services.ServerScriptService.LunarCleanup.SurfaceWorld.Source
local function newWorld()
 local module=Instance.new('ModuleScript'); module.Name='TestWorld'; module.Source=source
 return require(module)
end
local a=newWorld(); a.Start('SERVER_A'); assert(a.Persistent and a.Slot==1 and a.CanScrub())
local health,region,key,id=a.Get(0,-14); assert(health==12 and region==1)
a.Set(key,id,health-2.345678901234567)
local exact=a.Get(0,-14); assert(exact<12)
a.Set(key,id,11); assert(a.Get(0,-14)==exact,'world health must be monotonic')
-- Subscriptions are derived from the server root; no client-provided coordinates are accepted.
local player=Instance.new('Player'); player.Name='SurveyTester'; player:SetAttribute('DataReady',true); player:SetAttribute('Tool',1); player.Parent=services.Players
local char=Instance.new('Model'); local root=Instance.new('Part'); root.Name='HumanoidRootPart'; root.CFrame=CFrame.new(0,2,-12); root.Parent=char; player.Character=char
net.Surface.OnServerEvent:Fire(player,'Subscribe',{X=999999,Z=999999})
local reply=messages[#messages]; assert(reply.Kind=='Snapshot' and reply.Player==player)
assert(#reply.Data.Keep>0 and #reply.Data.Keep<=49 and next(reply.Data.Chunks))
local before=requests; simClock+=1
net.Surface.OnServerEvent:Fire(player,'Subscribe')
assert(requests==before,'streaming subscriptions must not perform DataStore writes')
assert(next(messages[#messages].Data.Chunks)==nil,'unchanged subscriptions should not resend chunks')
assert(a.Save(true))
local b=newWorld(); b.Start('SERVER_B'); assert(b.Persistent and b.Slot==1)
assert(b.Get(0,-14)==exact,'surface damage must survive release and reacquisition exactly')
assert(b.Stats().Regions[1].Progress>0)
assert(not b.Access(2,1) and b.Access(2,2) and not b.Access(3,1))
local allCells=R.BuildIndex()
for chunkKey,meta in pairs(allCells) do
 for localId,regionId in pairs(meta.Cells) do
  if regionId==1 and not (chunkKey==key and localId==id) then b.Set(chunkKey,localId,0) end
  if b.Access(2,1) then break end
 end
 if b.Access(2,1) then break end
end
assert(b.Access(2,1),'shared restoration must keep late-joining beginners from being stuck in a cleared starter region')
local c=newWorld(); c.Start('SERVER_C'); assert(c.Slot==2,'two live servers must not own the same world')
assert(c.Get(0,-14)==12,'separate survey slots must not share mutable state')
b.Lease=99999; assert(not b.CanScrub(),'expired leases must stop rewards')
records.World_1.Session='ANOTHER_OWNER'
assert(not b.Save(false) and b.Lost and not b.CanScrub(),'stale writer must not overwrite another owner')
failStore=true
local temporary=newWorld(); temporary.Start('STUDIO_OFFLINE'); assert(temporary.Ready and not temporary.Persistent and temporary.CanScrub())
studio=false
local paused=newWorld(); paused.Start('PUBLISHED_OFFLINE'); assert(paused.Ready and paused.Lost and not paused.CanScrub())
local constructor=services.DataStoreService.GetDataStore
services.DataStoreService.GetDataStore=function() error('simulated unpublished-store constructor') end
studio=true
local noStore=newWorld(); noStore.Start('NO_STORE'); assert(noStore.Ready and noStore.CanScrub() and not noStore.Persistent)
services.DataStoreService.GetDataStore=constructor
-- Render protocol description/gates can be checked without pretending to draw Terrain.
services.Players.LocalPlayer=player
local Surface=require(net.SurfaceRender)
net.Surface.OnClientEvent:Fire('Snapshot',reply.Data)
local label,progress=Surface.Describe(Vector3.new(0,0,-12),1); assert(label:find('TRANQUILITY') and progress>=0)
local locked=Surface.Describe(Vector3.new(34,0,-66),1); assert(locked:find('LOCKED') and locked:find('REGOLITH BRUSH') and locked:find('5%%'))
assert(Surface.Summary():find('SURVEY WORLD 1'))
assert(Surface.Describe(Vector3.new(0,0,-12),1,Vector3.new(1,0.1,0)):find('NO CLEANABLE COATING'))
print('WORLD PASS: save/reload, exclusive leases, stale-writer rejection, subscription budget, Studio fallback, published pause, regional HUD gates')
-- Exercise the actual client's visual loop with synthetic terrain hits and coroutine scheduling.
-- This checks allocation bounds/cleanup and code paths, not visual fidelity or frame rate.
local normal=Vector3.new(0,0.8,0.6)
Workspace.Raycast=function(_,origin,delta,params)
 assert(params.FilterDescendantsInstances[1]==terrain,'coating must query actual Terrain only')
 return {Position=Vector3.new(origin.X,-0.75*origin.Z,origin.Z),Normal=normal,Instance=terrain}
end
local function packet(x,z)
 local meta=R.BuildIndex(); local keep,snapshots={},{}
 local width=R.ChunkCells*C.PatchSize; local cx,cz=math.floor(x/width),math.floor(z/width)
 for xx=cx-3,cx+3 do for zz=cz-3,cz+3 do
  local k=xx..':'..zz; if meta[k] then table.insert(keep,k); snapshots[k]='' end
 end end
 return {Keep=keep,Chunks=snapshots,Status=reply.Data.Status}
end
net.Surface.OnClientEvent:Fire('Snapshot',packet(0,-12))
Surface.Start()
local allocatedBefore=createdPartCount
local visualLoop=coroutine.create(spawned[#spawned])
local function step(count)
 for i=1,count do simClock+=0.1; local ok,err=coroutine.resume(visualLoop); assert(ok,err) end
end
step(22)
local coating=Workspace.LunarCleanupSurfaceVisuals
assert(#coating:GetChildren()>500 and #coating:GetChildren()<=R.MaxVisuals)
for _,part in ipairs(coating:GetChildren()) do
 assert(not part.CanQuery and not part.CanCollide and not part.CastShadow)
 assert(part.CFrame.UpVector==normal,'coating must align its up vector with Terrain normal')
 assert(part.Transparency>=0 and part.Transparency<=1)
end
local _,cellId=R.Chunk(0,-14)
net.Surface.OnClientEvent:Fire('Delta',{{Key=key,Id=cellId,Health=0}})
step(2)
local px,pz=0.5*C.PatchSize,(-14+0.5)*C.PatchSize+normal.Z*0.025
for _,part in ipairs(coating:GetChildren()) do
 assert(math.abs(part.Position.X-px)>1e-8 or math.abs(part.Position.Z-pz)>1e-8,'cleared cell must expose bare Terrain')
end
root.CFrame=CFrame.new(34,2,-66)
net.Surface.OnClientEvent:Fire('Snapshot',packet(34,-66))
step(25)
assert(#coating:GetChildren()>500 and #coating:GetChildren()<=R.MaxVisuals)
assert(createdPartCount-allocatedBefore<=R.MaxVisuals,'pool must bound total allocations across region movement')
player.Character=nil; step(2); assert(#coating:GetChildren()==0,'death/character removal must release visuals')
-- Unavailable near-center Terrain must not starve all loaded cells farther away.
player.Character=char
Workspace.Raycast=function(_,origin)
 if (origin.X-34)^2+(origin.Z+66)^2<25 then return nil end
 return {Position=Vector3.new(origin.X,-0.75*origin.Z,origin.Z),Normal=normal,Instance=terrain}
end
step(4)
assert(#coating:GetChildren()>0,'missing Terrain retry backoff must leave budget for farther loaded cells')
print('RENDER LOOP PASS: Terrain alignment, bounded pooling, shared clearing, character cleanup, missing-Terrain retry fairness')
