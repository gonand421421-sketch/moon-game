-- tools/validate_generator.py prepends actual Config, Economy, and profile sanitizer.
local function near(a,b) assert(math.abs(a-b)<1e-7,string.format('%.12f ~= %.12f',a,b)) end
local function profile(storage) return {Money=0,Dust=0,DustCarry=0,Storage=storage or 0} end
-- The actual starting tool must meet the 4–5 second center-contact target.
assert(C.PatchHealth/C.Tools[1].Power>=4 and C.PatchHealth/C.Tools[1].Power<=5)
local start=profile(); local patch=C.PatchHealth
for i=1,50 do patch=E.Scrub(start,patch,C.Tools[1].Power,0.1,0,C.Tools[1].Radius) end
near(patch,0); near(start.Dust+start.DustCarry,C.PatchHealth*C.DustPerHealth)
-- Slow scrubs must fade immediately, with no one-unit floor and no lost sub-unit rewards.
local d=profile(); local health=12
local remaining,removed=E.Scrub(d,health,1.2,0.1,0,0.48)
near(removed,0.12); near(remaining,11.88); near(d.Dust+d.DustCarry,0.06)
-- A shared patch cannot pay twice even when two accounts alternate requests.
local a,b=profile(),profile(); health=12
for i=1,1000 do
 local target=i%2==0 and a or b
 health=E.Scrub(target,health,1.2,0.1,0,0.48)
end
near(health,0); near(a.Dust+a.DustCarry+b.Dust+b.DustCarry,12*C.DustPerHealth)
-- Full storage must stop removal instead of destroying unrewarded health.
d=profile(); d.Dust=99; d.DustCarry=0.95
health,removed=E.Scrub(d,12,10000,0.1,0,0.48)
near(removed,0.1); near(health,11.9); assert(d.Dust==100); near(d.DustCarry,0)
local second=E.Scrub(d,health,10000,0.1,0,0.48); near(second,health)
-- Selling is integer-priced and repeat selling cannot mint credits or erase fractional carry.
d=profile(); d.Dust=7; d.DustCarry=0.375
assert(E.Sell(d)==14 and d.Money==14 and d.Dust==0); near(d.DustCarry,0.375)
assert(E.Sell(d)==0 and d.Money==14)
-- Frame/request subdivision should not change total damage or dust rewards.
local slow,fast=profile(),profile(); local h1,h2=12,12
for i=1,10 do h1=E.Scrub(slow,h1,1.2,0.1,0,0.48) end
for i=1,20 do h2=E.Scrub(fast,h2,1.2,0.05,0,0.48) end
near(h1,h2); near(slow.Dust+slow.DustCarry,fast.Dust+fast.DustCarry)
-- Inactive time is capped; an old request cannot deliver seconds of accumulated damage.
d=profile(); local _,hit=E.Scrub(d,12,1.2,600,0,0.48); near(hit,1.2*C.MaxScrubDelta)
-- Real old schema values keep money, carried dust, tools and every purchased upgrade.
for storage=0,5 do for tool=1,3 do
 local oldCapacity=100+storage*100+storage*storage*25
 local old={Money=12345,Dust=oldCapacity,Tool=tool,Speed=4,Radius=3,Storage=storage}
 local loaded=sanitize(old)
 for k,v in pairs(old) do assert(loaded[k]==v,'legacy field changed: '..k) end
 assert(loaded.DustCarry==0 and C.Capacity(storage)>=oldCapacity)
end end
assert(sanitize({DustCarry=0/0}).DustCarry==0)
-- Conservation over many sells and save/load cycles, including nearly full bags.
d=profile(); local total=0
for i=1,7000 do
 local _,damage=E.Scrub(d,12,1.2,0.1,(i%8)*0.1,0.48)
 total+=damage
 if i%37==0 then E.Sell(d) end
 if i%53==0 then
  local saved=sanitize(d); saved.Money=d.Money; d=saved
 end
end
near(d.Money/C.SellPrice+d.Dust+d.DustCarry,total*C.DustPerHealth)
print('ACCOUNTING PASS: fractional fade, shared rewards, bag caps, sales, timing, legacy saves, conservation')

-- Deterministic mathematical pacing model. Not measured player behavior.
-- Integrate brush falloff over uniformly distributed aim offsets in a 0.85-stud cell.
local function rawRate(tool,speed,radiusLevel)
 local radius=tool.Radius*(1+C.RadiusPerLevel*radiusLevel)
 local sum=0; local samples=40; local reach=math.ceil((radius+C.PatchSize)/C.PatchSize)
 for a=1,samples do for b=1,samples do
  local ox,oz=(a-0.5)*C.PatchSize/samples,(b-0.5)*C.PatchSize/samples
  for x=-reach,reach do for z=-reach,reach do
   local distance=math.sqrt((x*C.PatchSize-ox)^2+(z*C.PatchSize-oz)^2)
   if distance<=radius+C.PatchSize*0.38 then sum+=1-C.Falloff*math.min(distance/radius,1) end
  end end
 end end
 return sum/(samples*samples)*tool.Power*(1+C.SpeedPerLevel*speed)
end
local function creditsPerSecond(tier,speed,radius,storage)
 local health=rawRate(C.Tools[tier],speed,radius)*C.Timing.ContactEfficiency
 local dust=health*C.DustPerHealth
 local cycle=C.Capacity(storage)/dust+C.Timing.SellRoundTripSeconds
 return C.Capacity(storage)*C.SellPrice/cycle
end
local function route(efficiency)
 local oldEfficiency=C.Timing.ContactEfficiency; C.Timing.ContactEfficiency=efficiency
 local tier,speed,radius,storage=1,0,0,0; local minutes=0
 local function buy(kind)
  local cost
  if kind=='Storage' then cost=C.StoragePrices[storage+1]
  elseif kind=='Speed' then cost=C.SpeedPrices[speed+1]
  elseif kind=='Radius' then cost=C.RadiusPrices[radius+1]
  else cost=C.Tools[tier+1].Price end
  minutes+=cost/creditsPerSecond(tier,speed,radius,storage)/60
  if kind=='Storage' then storage+=1 elseif kind=='Speed' then speed+=1 elseif kind=='Radius' then radius+=1 else tier+=1 end
 end
 buy('Storage'); buy('Tool'); local first=minutes
 for _,kind in ipairs({'Speed','Radius','Storage'}) do buy(kind) end
 buy('Tool'); local advanced=minutes
 for _,kind in ipairs({'Storage','Speed','Radius','Speed','Storage','Radius','Speed','Storage'}) do buy(kind) end
 local complete=minutes
 C.Timing.ContactEfficiency=oldEfficiency
 return first,advanced,complete
end
for _,eff in ipairs({0.5,0.65,0.8}) do
 local first,advanced,complete=route(eff)
 print(string.format('MODEL contact=%.0f%%: brush %.1f min, industrial %.1f min, all tools/upgrades %.1f min',eff*100,first,advanced,complete))
end
local f,a,c=route(0.65)
assert(f>=10 and f<=20 and a>=25 and a<=40 and c>=45 and c<=60,'baseline target route missed')
for tier=1,3 do print(string.format('MODEL tool %d raw health/s %.3f',tier,rawRate(C.Tools[tier],0,0))) end
