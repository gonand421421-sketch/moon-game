-- Real Regions functions. Plain coordinate tables intentionally need no Roblox engine.
local function close(a,b) assert(math.abs(a-b)<1e-7) end
local sectors=R.BuildSectors(index); local count,total=0,0
for key,sector in pairs(sectors) do
 count+=1; total+=sector.Cells
 local x,z=R.SectorCenter(sector.Q,sector.R)
 assert(R.SectorAt(x,z)==key)
 assert(R.SectorAt(x+0.001,z-0.001)==key)
 assert(sector.Regions[1]+sector.Regions[2]+sector.Regions[3]==sector.Cells)
 for edge=0,5 do
  local angle=math.rad(edge*60)
  -- Six apothems are outward normals for pointy-top hexagons.
  local dx,dz=math.cos(angle),math.sin(angle); local apothem=math.sqrt(3)*R.HexRadius/2
  local inside=R.SectorAt(x+dx*(apothem-1e-6),z+dz*(apothem-1e-6))
  local outside=R.SectorAt(x+dx*(apothem+1e-6),z+dz*(apothem+1e-6))
  assert(inside==key and outside~=key,'hex edge '..key..' e'..edge..' inside='..inside..' outside='..outside)
 end
end
assert(total==totals[1]+totals[2]+totals[3])
-- Sample every existing cell: canonical hit lookup and hex identity must agree at centers.
for key,chunk in pairs(index) do for id,region in pairs(chunk.Cells) do
 local gx,gz=R.Unpack(key,id); local x,z=(gx+0.5)*C.PatchSize,(gz+0.5)*C.PatchSize
 local actual,xx,zz=R.Resolve(x,z); assert(actual==region and xx==gx and zz==gz)
 local sector=R.CellSector(gx,gz); assert(sectors[sector])
end end
-- Preserve horizontal power/falloff while fixing the old 3D sphere veto on steep planes.
for _,slope in ipairs({0,0.25,0.75,1.5,2.5}) do
 local normal={X=-slope/math.sqrt(1+slope*slope),Y=1/math.sqrt(1+slope*slope),Z=0}
 local point={X=0.4,Y=slope*0.4,Z=0.1}
 local distance=R.BrushDistance({X=0,Y=0,Z=0},normal,point,normal,0.48,false)
 assert(distance,'a continuous cleanable slope must not be rejected by 3D center distance')
 close(distance,math.sqrt(0.17))
end
assert(R.BrushDistance({X=0,Y=0,Z=0},{X=0,Y=1,Z=0},{X=0.2,Y=3,Z=0},{X=0,Y=1,Z=0},0.48,false)==nil,'neighbors on a disconnected ledge must not be reached')
assert(R.BrushDistance({X=0,Y=0,Z=0},{X=0,Y=1,Z=0},{X=0.2,Y=3,Z=0},{X=0,Y=1,Z=0},0.48,true),'canonical visible target stays reachable at a sharp edge')
assert(R.BrushDistance({X=0,Y=0,Z=0},{X=0,Y=1,Z=0},{X=0,Y=0,Z=0},{X=1,Y=0.1,Z=0},0.48,true)==nil,'cliffs omitted by renderer must also be omitted by server')
local regions={{Progress=0},{Progress=0},{Progress=0}}
local mixed={Progress=0,Regions={2,3,0}}
assert(R.SectorState(mixed,1,regions)=='MIXED ACCESS')
assert(R.SectorState({Progress=0,Regions={0,3,0}},1,regions)=='LOCKED')
assert(R.SectorState({Progress=0,Regions={3,0,0}},1,regions)=='DIRTY')
assert(R.SectorState({Progress=0.4,Regions={3,0,0}},1,regions)=='IN PROGRESS')
assert(R.SectorState({Progress=1,Regions={0,3,0}},1,regions)=='COMPLETE')
regions[1].Progress=0.05; assert(R.SectorState({Progress=0,Regions={0,3,0}},1,regions)=='DIRTY')
print('HEX PASS:',count,'derived sectors, unchanged cell ownership, six boundaries, slopes, cliffs, mixed/locked/completed access')
