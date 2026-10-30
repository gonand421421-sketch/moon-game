-- Scene presentation smoke tests, using explicit synthetic Terrain and simple Instance stubs.
do
 local R=require(net.Regions); local Hex=require(net.SectorView)
 local status=a.Stats()
 Workspace.Raycast=function(_,origin) return {Position=Vector3.new(origin.X,0.01*origin.X,origin.Z),Normal=Vector3.new(0,1,0),Instance=terrain} end
 Hex.Update(status,Vector3.new(0,2,-12),1)
 local folder=Workspace.LunarCleanupHexSectors; local filaments,labels=0,0
 for _,part in ipairs(folder:GetChildren()) do
  if part.Name=='SurveyFilament' then filaments+=1 else labels+=1 end
  assert(not part.CanQuery and not part.CanCollide and not part.CastShadow)
 end
 assert(filaments>0 and filaments<=R.MaxSectorLines and labels>0)
 Hex.Update(status,Vector3.new(34,2,-66),2)
 local n=0; for _,part in ipairs(folder:GetChildren()) do if part.Name=='SurveyFilament' then n+=1 end end
 assert(n<=R.MaxSectorLines)
 -- Verify old and new sector counters are recomputed from the same persisted cell health.
 local sx=R.CellSector(0,-14)
 assert(a.Stats().Sectors[sx].Progress>0)
 assert(b.Stats().Sectors[sx].Progress>0,'old-format save must restore derived sector progress')
 print('HEX SCENE PASS: bounded draped filaments, local identifiers, derived saved progress')
end
do
 local sky=services.Lighting.LunarSky; local clock=services.Lighting.ClockTime; local brightness=services.Lighting.Brightness
 local camera=Instance.new('Camera'); camera.CFrame=CFrame.new(0,4,0); Workspace.CurrentCamera=camera
 require(net.Celestial).Start()
 local model=Workspace.LunarCleanupCelestial; assert(model and model.EarthOcean)
 local parts,stars,land=0,0,0
 for _,part in ipairs(model:GetChildren()) do if part:IsA('BasePart') then
  parts+=1; assert(not part.CanCollide and not part.CanQuery and not part.CastShadow)
  if part.Name=='Star' then stars+=1 elseif part.Name=='EarthLand' then land+=1 end
 end end
 assert(parts<450 and stars>20 and land>50)
 camera.CFrame=CFrame.new(20,6,-30); renderCallbacks.LunarCleanupCelestial()
 assert(model.LastPivot.Position.X==20 and model.LastPivot.Position.Z==-30)
 assert(services.Lighting.LunarSky==sky and services.Lighting.ClockTime==clock and services.Lighting.Brightness==brightness)
 blackFaces(sky)
 print('CELESTIAL PASS:',parts,'local primitive parts; Earth/stars are non-queryable and never modify the native black sky')
end
