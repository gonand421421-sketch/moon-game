-- The real generated scrub callback is inserted by tools/validate_generator.py.
-- Adversarial target/range/LOS tests use explicit ray results, not Roblox physics.
do
 local os=fakeOS
 local World=c -- Actual SurfaceWorld module instance in a fresh separately leased slot.
 local Economy=require(net.Economy)
 local center=Vector3.new(0.425,0,-11.475)
 local char=Instance.new('Model')
 local head=Instance.new('Part'); head.Name='Head'; head.CFrame=CFrame.new(center+Vector3.new(0,2,0)); head.Parent=char
 local root=Instance.new('Part'); root.Name='HumanoidRootPart'; root.CFrame=head.CFrame; root.Parent=char
 player.Character=char
 local profiles={[player]={data={Money=0,Dust=0,DustCarry=0,Tool=1,Speed=0,Radius=0,Storage=0},lastScrub=0}}
 local surfaceGeometry={}
 local function alive() return root,char end
 local syncs=0
 local function sync() syncs+=1 end
 local hints={}
 local function tell(_,message) table.insert(hints,message) end
 local typeof=function(value) return getmetatable(value)==vecMT and 'Vector3' or type(value) end
 -- SCRUB_HANDLER_GOES_HERE
 local calls=0; local blocked=true; local slope=0
 Workspace.Raycast=function(_,origin,delta,params)
  calls+=1
  if calls==1 then return {Instance=terrain,Position=center,Normal=Vector3.new(-slope,1,0).Unit} end
  if calls==2 then
   return {Instance=terrain,Position=blocked and (center+Vector3.new(0,0.5,0)) or center,Normal=Vector3.new(-slope,1,0).Unit}
  end
  return {Instance=terrain,Position=Vector3.new(origin.X,slope*origin.X,origin.Z),Normal=Vector3.new(-slope,1,0).Unit}
 end
 local function scrub(origin)
  simClock+=0.11; calls=0
  net.Scrub.OnServerEvent:Fire(player,origin or head.Position,Vector3.new(0,-1,0))
 end
 local data=profiles[player].data
 scrub()
 assert(data.Dust==0 and data.DustCarry==0 and syncs==0,'a nearer hit on the SAME Terrain Instance must block rewards')
 blocked=false; scrub()
 assert(data.Dust+data.DustCarry>0 and syncs==1 and World.Get(0,-14)<12,'valid Terrain scrub must pay and record shared health')
 local reward=data.Dust+data.DustCarry
 scrub(head.Position+Vector3.new(100,0,0))
 assert(calls==0 and data.Dust+data.DustCarry==reward,'untrusted origin must not grant rewards')
 center=Vector3.new(34.425,0,-66.725)
 head.CFrame=CFrame.new(center+Vector3.new(0,2,0)); root.CFrame=head.CFrame
 scrub()
 assert(data.Dust+data.DustCarry==reward,'Tool-1 client cannot scrub a locked outer region')
 -- Actual handler: a steep planar target formerly excluded by the 3D sphere.
 slope=2.5; surfaceGeometry={}; center=Vector3.new(0.825,2.5*0.825,-11.375)
 head.CFrame=CFrame.new(center+Vector3.new(0,2,0)); root.CFrame=head.CFrame
 local beforeSlope=World.Get(0,-14); scrub(); assert(World.Get(0,-14)<beforeSlope,'visible sloped target must scrub')
 slope=0; surfaceGeometry={}
 -- Find a genuine old raw-point/cell-center region disagreement near an existing boundary.
 local boundary
 for gx=-35,35 do for gz=-60,0 do
  local x,z=(gx+0.99)*C.PatchSize,(gz+0.99)*C.PatchSize
  if R.Cell(gx,gz)==1 and R.At(x,z)~=1 then boundary=Vector3.new(x,0,z); break end
 end if boundary then break end end
 assert(boundary,'expected regional edge case')
 center=boundary; head.CFrame=CFrame.new(center+Vector3.new(0,2,0)); root.CFrame=head.CFrame
 local beforeEdge=data.Dust+data.DustCarry; scrub(); assert(data.Dust+data.DustCarry>beforeEdge,'cell permission, not raw-point region, must govern border scrubs')
 for _,side in ipairs({-1,1}) do
  center=Vector3.new(math.sqrt(3)*R.HexRadius/2+side*1e-6,0,0)
  head.CFrame=CFrame.new(center+Vector3.new(0,2,0)); root.CFrame=head.CFrame
  local paid=data.Dust+data.DustCarry; scrub(); assert(data.Dust+data.DustCarry>paid,'both sides of an unlocked hex edge must scrub')
 end
 center=Vector3.new(0.425,0,-11.475)
 head.CFrame=CFrame.new(center+Vector3.new(0,2,0)); root.CFrame=head.CFrame
 data.Dust=C.Capacity(0); data.DustCarry=0; local healthBefore=World.Get(0,-14)
 scrub()
 assert(World.Get(0,-14)==healthBefore and calls==0,'full bag must stop both damage and ray work')
 data.Dust=0; World.Lease=99999
 scrub()
 assert(World.Get(0,-14)==healthBefore and data.Dust==0 and data.DustCarry==0,'stale world lease must stop surface rewards')
 print('SCRUB PASS: actual handler, slopes, region/hex boundaries, Terrain LOS, rewards, forged origins, locks, bag cap, lease')
end
