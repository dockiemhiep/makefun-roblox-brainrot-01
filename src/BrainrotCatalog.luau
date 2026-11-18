-- BRAINROT BAZAAR: 13 brainrots (Common..Mythic), Golden/Radioactive/Rainbow mutations
-- 3D tycoon: buy brainrots off a moving conveyor (E), carry them home, each pad pays cash per second.
-- 8 walled bases (NPC rivals hold the spare ones), 8 pads, 5 upgrade levels, sell, rebirth = income x2, x3...
-- Thief waves raid on a clock: bonk bandits by touch, LOCK BASE neon forcefield zaps them at the gate.
-- Rob a rival base for free loot and it sends a revenge raid. Mutated and Mythic brainrots glow and sparkle.
-- HUD: cash + income, pads, Braindex ladder, wave banner, toasts, cash pops, carry-home beam.
-- Scripts: BrainrotCatalog (data + math), Bazaar3DWorldAndConveyor (server entry),
-- BasePadsLockAndRebirth, ThiefWavesAndRivalRaids, HudAndWorldFx (client HUD). Server owns all state.
local Catalog={}
local rgb,V=Color3.fromRGB,Vector3.new
Catalog.RarityOrder={"Common","Rare","Epic","Legendary","Mythic"}
Catalog.Mutations={
{id="Golden",mult=2,chance=.10,col=rgb(255,204,48)},
{id="Radioactive",mult=3,chance=.06,col=rgb(120,255,60)},
{id="Rainbow",mult=5,chance=.03,col=rgb(255,110,220)},
}
Catalog.Rarities={
Common={rank=1,weight=40,col=rgb(196,204,214),beam=false},
Rare={rank=2,weight=28,col=rgb(64,162,255),beam=false},
Epic={rank=3,weight=17,col=rgb(184,92,255),beam=true},
Legendary={rank=4,weight=10,col=rgb(255,198,40),beam=true},
Mythic={rank=5,weight=5,col=rgb(255,64,120),beam=true},
}
Catalog.MaxLevel=5
Catalog.StartingCash=60
Catalog.StartingPads=3
Catalog.PadPrices={0,0,0,300,1500,8000,40000,200000}
Catalog.RebirthBaseCost=50000
Catalog.LockSeconds=10
Catalog.LockCooldown=30
Catalog.MutationOf={}
for _,m in Catalog.Mutations do
Catalog.MutationOf[m.id]=m
end
function Catalog.incomePerSecondBaseXMutationXLevelBonus(ent,mutId,lvl)
local m=Catalog.MutationOf[mutId]
return math.floor(ent.inc*(m and m.mult or 1)*(1+.5*(lvl-1))+.5)
end
function Catalog.priceGolden2xRadioactive3xRainbow5x(ent,mutId)
return Catalog.incomePerSecondBaseXMutationXLevelBonus(ent,mutId,1)/ent.inc*ent.price
end
function Catalog.upgradeCostForLevels1To5(ent,lvl)
return math.floor(ent.price*.6*lvl)
end
function Catalog.rebirthCost50kTimes5PerRebirth(rebs)
return Catalog.RebirthBaseCost*5 ^ rebs
end
function Catalog.formatCash(amount)
local units={"","K","M","B","T"}
local scaled,unit=math.floor(amount),1
if scaled<1000 then
return tostring(scaled)
end
while scaled>=1000 and unit<#units do
scaled/=1000
unit+=1
end
local text=string.format(scaled>=100 and "%.0f" or scaled>=10 and "%.1f" or "%.2f",scaled)
return text:gsub("(%.%d-)0+$","%1"):gsub("%.$","")..units[unit]
end
function Catalog.new(class,parent,props)
local o=Instance.new(class)
for k,v in props or {} do
o[k]=v
end
o.Parent=parent
return o
end
function Catalog.label(parent,text,col,props)
local l=Instance.new("TextLabel")
l.BackgroundTransparency,l.Size,l.Font,l.TextScaled,l.TextStrokeTransparency=1,UDim2.fromScale(1,1),"FredokaOne",true,0
l.TextColor3,l.Text=col or Color3.new(1,1,1),text
for k,v in props or {} do
l[k]=v
end
l.Parent=parent
return l
end
function Catalog.hex(n)
return rgb(n//65536,n//256%256,n%256)
end
local hex=Catalog.hex
function Catalog.now()
return workspace:GetServerTimeNow()
end
function Catalog.rootOf(plr)
return plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
end
local B,K,C,W="Ball","Block","Cyl","Wedge"
local N,F,G="Neon","Foil","Glass"
local rows={
{"noodlino","Noodlino Wigglini",1,25,1,"Al dente and it knows it.",5.4,{4.1,-1.2,.5,.7,"smile"},false,{
{B,3.6,1.3,3.6,0,.65,0,0xFAD660},
{B,3,1.3,3,.2,1.6,0,0xF6CC54},
{B,2.4,1.3,2.4,-.1,2.5,0,0xFAD660},
{B,2.5,2.5,2.5,0,4,0,0x964830},
{B,1,.3,.6,.3,5.3,0,0x46BE50},
{C,.35,1.6,.35,1.9,1.6,0,0xFAD660,{0,0,-50},true},
}},
{"toasty","Toasty Loafer",1,100,3,"Slightly burnt. Emotionally too.",5.6,{3.3,-.6,.6,.75,"o"},{1.3,.8,0xF4D08C,0xE63C3C},{
{K,3.6,3.8,.9,0,3.2,.1,0x965C2C},
{K,3,3.2,1,0,3.2,-.05,0xF4D08C},
{B,1.6,1,1,-.9,5.2,0,0x965C2C,true},
{K,1.1,.35,.5,.6,4.3,-.6,0xFFE85A,{0,0,14}},
}},
{"sockpuppeto","Sockpuppeto Stinko",1,250,6,"Lost its twin in the dryer. Still looking.",5.6,{3,-.6,.5,.7,"teeth"},false,{
{K,2,3.6,2,0,3,.4,0xF0F0EB},
{K,2,1.6,3.6,0,.8,-.4,0xF0F0EB},
{B,2.1,1.7,1.6,0,.8,-2.1,0xE23E46},
{K,2.15,.5,2.15,0,4.3,.4,0xE23E46},
{K,2.15,.3,2.15,0,3.6,.4,0x3C78DC},
{B,.9,.9,.9,1.7,4.6,0,0x96DC46,N,.45},
{B,.6,.6,.6,-1.6,5.2,.3,0x96DC46,N,.45},
}},
{"cactopus","Cactopus Pricklini",2,800,15,"Eight hugs. Zero survivors.",6,{3.8,-1.65,.6,.8,"smile"},false,{
{B,3.4,3.8,3.4,0,3.6,0,0x46B056},
{C,.9,2.6,.9,1.5,1.2,1,0x3C9C4C,{20,0,-24},true},
{C,.9,2.6,.9,1.5,1.2,-1,0x3C9C4C,{-20,0,-24},true},
{B,1.3,.7,1.3,0,5.6,0,0xFF78BE},
{B,.6,.6,.6,0,5.9,0,0xFFDE50},
{C,.8,1.5,.8,2.1,4,0,0x46B056,{0,0,-30},true},
}},
{"conehead","Conehead Honko",2,2000,30,"Directs traffic. Into walls.",6.2,{3.7,-1.2,.5,.7,"none"},{1.1,.9,0xFFAA32,0xFFAA32},{
{K,4,.5,4,0,1.3,0,0xFF781E},
{C,3.2,1.5,3.2,0,2.2,0,0xFF781E},
{C,2.5,1.2,2.5,0,3.5,0,0xF5F5F5},
{C,1.8,1.2,1.8,0,4.7,0,0xFF781E},
{C,1,.9,1,0,5.7,0,0xFF781E},
{W,1.2,.6,1.5,0,3.1,-1.9,0xFFCD3C,{0,180,0}},
}},
{"bananaphone","Bananaphone Ringo",2,4500,55,"Ring ring. It's for you. It's always for you.",6.4,{4,-.85,.42,.6,"smile"},{1,.6,0xFFDE3C,0x466EE6},{
{K,1.7,2,1.5,.5,2.1,0,0xFFDE3C,{0,0,24}},
{K,1.8,2,1.6,0,3.6,0,0xFFDE3C},
{K,1.7,2,1.5,.5,5.1,0,0xFFDE3C,{0,0,-24}},
{K,.8,.7,.8,1.1,6.1,0,0x6E4C28,{0,0,-24}},
{K,.8,.6,.8,1.1,1.1,0,0x6E4C28,{0,0,24}},
{C,.2,1.6,.2,-.7,5.6,0,0x3C3C46},
{B,.5,.5,.5,-.7,6.5,0,0xFF3C3C,N},
{K,1,1.2,.2,0,2.4,-.85,0x3C3C46},
}},
{"fridgezilla","Fridgezilla Chillaroni",3,12000,120,"Ate the city. Kept the leftovers.",7.4,{5.9,-1.45,.6,.75,"teeth"},{1.3,1,0x50C864,0x3CA050},{
{K,3.4,5.2,2.8,0,3.9,0,0xD6EEF4},
{K,3.5,.2,2.9,0,4.9,0,0x7896A5},
{K,.3,1.2,.4,1.2,5.7,-1.5,0x78828C},
{K,.3,1.8,.4,1.2,3.6,-1.5,0x78828C},
{W,1.2,1.2,1.2,0,7,-.8,0x50C864},
{W,1.2,1.4,1.2,0,7.1,.4,0x50C864},
{K,1.6,1.4,2.4,0,2.2,2.4,0x50C864,{18,0,0}},
{K,1,.9,2,0,1.5,4.2,0x50C864,{24,0,0}},
{K,.7,.5,1.4,1.9,3.8,-.9,0x50C864,true},
}},
{"spinnerino","Washa Spinnerino",3,28000,220,"Permanently on spin cycle. Send help.",6.6,{4.9,-1.7,.6,.7,"none"},{1.3,1.1,0xC8C8D2,0xFF9628},{
{K,3.8,3.8,3.2,0,3.2,0,0xF6F6FA},
{K,3.9,.7,3.3,0,4.9,0,0x5AC8E6},
{C,2.4,.4,2.4,0,2.9,-1.6,0x3C465A,{90,0,0}},
{C,1.9,.5,1.9,0,2.9,-1.65,0x6ED2FF,G,{90,0,0},.25},
{B,.9,.9,.9,-.8,5.9,.2,0xC8F0FF,G,.35},
{B,1.3,1.3,1.3,.5,6.2,-.2,0xC8F0FF,G,.35},
{B,.6,.6,.6,1.5,5.7,.5,0xC8F0FF,G,.35},
{B,.4,.4,.4,1.4,4.9,-1.7,0xFF5050,N},
}},
{"discopigeon","Disco Pigeon Groovini",3,60000,400,"Coo-coo. Unts unts unts.",6.8,{5.3,-1.65,.55,.7,"none"},{1.3,.7,0xFFA028,0xFFA028},{
{B,3.2,3,3.6,0,2.7,.2,0x8C96AA},
{B,2.5,2.5,2.5,0,5,-.5,0xDCE2F0,F},
{W,.7,.5,1.2,0,4.7,-2,0xFFA028,{0,180,0}},
{K,.5,2,2.4,1.8,2.9,.4,0x6E788C,{0,0,-18},true},
{K,1.6,.4,2,0,2.4,2.6,0x6E788C,{-25,0,0}},
{B,.5,.5,.5,1.2,6.4,-.3,0xFF46C8,N},
{B,.5,.5,.5,-1.2,6.4,-.3,0x3CDCFF,N},
{B,.5,.5,.5,0,6.7,.3,0xFFE63C,N},
}},
{"kaboomba","Llamacano Kaboomba",4,160000,900,"Spits lava. Apologises never.",8,{7,-3,.5,.65,"teeth"},false,{
{K,2.8,2.4,4.6,0,3.2,.4,0xFAF4E6},
{K,1.4,3.2,1.4,0,5.2,-1.6,0xFAF4E6},
{B,1.9,1.7,2.3,0,6.9,-1.9,0xFAF4E6},
{K,.4,.9,.4,.6,7.9,-1.5,0xFAF4E6,true},
{C,3,1,3,0,4.9,1,0x6E4632},
{C,2.2,1,2.2,0,5.9,1,0x603C2C},
{C,1.5,.8,1.5,0,6.8,1,0x543428},
{B,1.3,1,1.3,0,7.4,1,0xFF6E14,N},
{B,.6,.6,.6,.5,8.3,1.1,0xFFBE28,N},
{C,.7,2,.7,.9,1,-1.2,0xECE2CE,true},
{C,.7,2,.7,.9,1,2,0xECE2CE,true},
}},
{"moolander","UFO Cow Moolander",4,400000,1800,"Abducts itself for the content.",7.2,{4.7,-1.2,.5,.65,"none"},false,{
{B,6,1.6,6,0,2.6,0,0x96A0B4,F},
{B,4,4.2,4,0,4,0,0x8CE6FF,G,.55},
{B,2.5,2.3,2.5,0,4.3,0,0xFAFAFA},
{B,1,.9,.5,.6,4.9,1,0x28282E},
{B,1.5,1,.9,0,3.8,-1.2,0xFFAABE},
{C,.3,.8,.3,.9,5.6,0,0xF0E6C8,{0,0,-24},true},
{B,.7,.7,.7,3,2.5,0,0x6EFF5A,N,true},
{B,.7,.7,.7,0,2.5,-3,0xFF50C8,N},
{B,.7,.7,.7,0,2.5,3,0xFF50C8,N},
{C,2.6,1.8,2.6,0,1,0,0x78FFC8,N,.7},
}},
{"knittoria","Galaxy Granny Knittoria",5,1500000,5000,"Knits black holes. Calls them 'cosy'.",7.6,{5.4,-1.2,.5,.6,"smile"},false,{
{B,4.4,2.2,4.4,0,1.1,0,0x462896},
{B,3.4,3.2,3.4,0,2.9,0,0x6038BE},
{B,2.5,2.5,2.5,0,5.3,0,0xD6BEFF},
{B,2.7,1.5,2.7,0,6.1,.3,0xE6E8F0},
{B,1.3,1.3,1.3,0,7.2,.4,0xE6E8F0},
{K,1.9,.5,.15,0,5.5,-1.25,0x281E3C},
{B,1.3,1.3,1.3,1.9,3,-1.4,0xFF46BE,N},
{C,.15,2.4,.15,1.6,3.6,-1.4,0xF0F0FA,{0,0,40}},
{C,.15,2.4,.15,2.2,3.6,-1.4,0xF0F0FA,{0,0,-40}},
{B,.5,.5,.5,-2.6,5.4,0,0xFFF078,N},
{B,.4,.4,.4,2.4,6.6,.6,0x78DCFF,N},
{B,.35,.35,.35,-1.8,7.3,-.6,0xFF96F0,N},
}},
{"goudalord","Goudalord the Cheese Emperor",5,4000000,12000,"Rules with an iron rind.",8,{4.2,-2.35,.6,.75,"teeth"},{1.2,1,0xFFCC32,0x9628C8},{
{W,4.2,3.8,4.6,0,3.4,0,0xFFCC32,{0,180,0}},
{K,4.2,.5,4.6,0,1.4,0,0xF0AA28},
{B,.9,.9,.5,1.2,2.6,-2.2,0xD6961E},
{B,.6,.6,.5,-1.4,3.6,-2.2,0xD6961E},
{C,2,.6,2,0,5.6,-1.7,0xFFD746,F},
{W,.5,.9,.5,.7,6.3,-1.7,0xFFD746,F,true},
{W,.5,.9,.5,0,6.3,-2.4,0xFFD746,F},
{B,.5,.5,.5,0,5.6,-2.7,0xFF3250,N},
{K,4.6,4.4,.3,0,3.2,2.5,0xC81E3C,{-10,0,0}},
{C,.3,4.6,.3,2.9,3.4,-1.2,0xFFD746,F},
{B,.9,.9,.9,2.9,5.9,-1.2,0x78FFF0,N},
}},
}
Catalog.List,Catalog.ById,Catalog.ByRarity={},{},{}
for i,r in rows do
local f,l,parts=r[8],r[9],{}
for _,p in r[10] do
local part,twin={p[1],V(p[2],p[3],p[4]),V(p[5],p[6],p[7]),hex(p[8])},false
for j=9,#p do
local v=p[j]
if v==true then
twin=true
else
part[type(v)=="table" and 6 or type(v)=="number" and 7 or 5]=type(v)=="table" and V(unpack(v)) or v
end
end
table.insert(parts,part)
if twin then
table.insert(parts,{part[1],part[2],part[3]*V(-1,1,1),part[4],part[5],part[6] and part[6]*V(1,-1,-1),part[7]})
end
end
local ent={
id=r[1],name=r[2],rar=Catalog.RarityOrder[r[3]],rank=r[3],price=r[4],inc=r[5],quip=r[6],ht=r[7],parts=parts,
face={y=f[1],z=f[2],gap=f[3],size=f[4],mouth=f[5]},
legs=l and {h=l[1],spread=l[2],col=hex(l[3]),shoe=hex(l[4])} or nil,
}
ent.col=Catalog.Rarities[ent.rar].col
Catalog.List[i],Catalog.ById[ent.id]=ent,ent
Catalog.ByRarity[ent.rar]=Catalog.ByRarity[ent.rar] or {}
table.insert(Catalog.ByRarity[ent.rar],ent)
end
return Catalog
