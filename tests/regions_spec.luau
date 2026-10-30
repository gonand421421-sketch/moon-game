-- Actual Regions module and unchanged C/E/sanitize are prepended by the validator.
local index,totals=R.BuildIndex()
local total,chunks=0,0
for _,n in ipairs(totals) do assert(n>1000); total+=n end
assert(total>25000 and total<100000,'unexpected survey scale')
local bytes=0
for key,meta in pairs(index) do
 chunks+=1
 local health={}
 for id,region in pairs(meta.Cells) do
  local gx,gz=R.Unpack(key,id)
  local k,i=R.Chunk(gx,gz)
  assert(k==key and i==id and R.Cell(gx,gz)==region,'negative-coordinate chunk mapping')
  health[id]=7.123456789012345
 end
 local encoded=R.Encode(health,meta.Cells); bytes+=#key+#encoded
 local decoded=R.Decode(encoded,meta.Cells)
 for id,value in pairs(health) do assert(decoded[id]==value,'17-digit persistence must preserve the float') end
 local clean={}; for id in pairs(meta.Cells) do clean[id]=0 end
 assert(R.Encode(clean,meta.Cells)=='*')
 local restored=R.Decode('*',meta.Cells)
 for id in pairs(meta.Cells) do assert(restored[id]==0) end
end
assert(bytes<2500000,'worst partial-health snapshot exceeds configured budget')
assert(R.At(0,23)==nil and R.At(-12,20)==nil and R.At(12,20)==nil,'keep the base/depot/terminal apron clear')
assert(R.At(0,-12)==1 and R.At(34,-66)==2 and R.At(-73,-101)==3)
for i,definition in ipairs(R.Definitions) do assert(definition.Tool==i) end
local maxCircle=math.ceil(math.pi*((R.RenderRadius/C.PatchSize)+1)^2)
assert(maxCircle<=R.MaxVisuals+100 and R.RenderRadius-R.EdgeFade>=C.Range+C.Tools[3].Radius,'brush neighborhood needs detailed visuals')
print(string.format('REGIONS PASS: %d cells / %d chunks / worst sampled packed size %d bytes',total,chunks,bytes))
for i,count in ipairs(totals) do print('REGION',i,count,'cells',count*C.PatchSize^2,'projected square studs') end
