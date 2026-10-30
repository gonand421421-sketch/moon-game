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
 local typeof=function(value) return getmetatable(value)==vecMT and 'Vector3' or type(value) end
 -- SCRUB_HANDLER_GOES_HERE
 local calls=0; local blocked=true
 Workspace.Raycast=function(_,origin,delta,params)
  calls+=1
  if calls==1 then return {Instance=terrain,Position=center,Normal=Vector3.new(0,1,0)} end
  if calls==2 then
   return {Instance=terrain,Position=blocked and (center+Vector3.new(0,0.5,0)) or center,Normal=Vector3.new(0,1,0)}
  end
  return {Instance=terrain,Position=Vector3.new(origin.X,0,origin.Z),Normal=Vector3.new(0,1,0)}
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
 center=Vector3.new(0.425,0,-11.475)
 head.CFrame=CFrame.new(center+Vector3.new(0,2,0)); root.CFrame=head.CFrame
 data.Dust=C.Capacity(0); data.DustCarry=0; local healthBefore=World.Get(0,-14)
 scrub()
 assert(World.Get(0,-14)==healthBefore and calls==0,'full bag must stop both damage and ray work')
 data.Dust=0; World.Lease=99999
 scrub()
 assert(World.Get(0,-14)==healthBefore and data.Dust==0 and data.DustCarry==0,'stale world lease must stop surface rewards')
 print('SCRUB PASS: actual server handler, Terrain LOS identity, valid rewards, forged origins, region permissions, full bag, expired lease')
end
