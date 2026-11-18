-- The threat: thief waves on a clock, touch-to-bonk, shield zaps, robbed rivals and revenge raids.
local Players=game:GetService("Players")
local Cat=require(game:GetService("ReplicatedStorage").BrainrotCatalog)
local Base=require(script.Parent.BasePadsLockAndRebirth)
local new,cash=Cat.new,Cat.formatCash
local V,CF,hex=Vector3.new,CFrame.new,Cat.hex
local Thieves={}
local CALM,CALM1,WARN,RAID=50,35,8,40
local BONK,RUN,LOOT=5.5,21,13.5
local RED=hex(0xFF4646)
local thieves,wave={},0
local world,send,bonk,bandit,arrive,moveThieves
function Thieves.runThiefWaveClockCalmThenWarnThenRaid()
local function setPhase(phase,seconds)
workspace:SetAttribute("WavePhase",phase)
workspace:SetAttribute("WaveEndsAt",Cat.now()+seconds)
workspace:SetAttribute("WaveNumber",wave)
end
local calm=CALM1
while true do
setPhase("calm",calm)
local calmEnds=os.clock()+calm
while os.clock()<calmEnds do
task.wait(math.min(14,math.max(.5,calmEnds-os.clock())))
local rival=Thieves.pickStockedRivalBaseToRob()
if rival and os.clock()<calmEnds-4 then
send(rival)
end
end
calm=CALM
setPhase("warn",WARN)
task.wait(WARN)
wave+=1
setPhase("raid",RAID)
for round=1,math.min(1+wave//2,4) do
for _,plr in Players:GetPlayers() do
local pl=Base.plotOf(plr)
if pl and #pl.rots>=2 then
send(pl)
end
end
local rival=round<=2 and Thieves.pickStockedRivalBaseToRob()
if rival then
send(rival)
end
task.wait(1.6)
end
local raidEnds=os.clock()+RAID
while #thieves>0 and os.clock()<raidEnds do
task.wait(.5)
end
end
end
function Thieves.sendBanditFromHideoutToStealBestBrainrot(pl)
local mdl=bandit()
mdl:ScaleTo(1.25)
local laneZ=pl.side*15
local th={
mdl=mdl,root=mdl.PrimaryPart,pl=pl,pos=world.DOOR,leg=1,st="approach",
path={V(98,world.GY,laneZ),V(pl.gate.X,world.GY,laneZ),pl.gate},
speed=RUN+math.min(wave,6),phase=math.random()*6,
}
mdl:PivotTo(CF(th.pos))
mdl.Parent=world.dir.Thieves
table.insert(thieves,th)
return th
end
send=Thieves.sendBanditFromHideoutToStealBestBrainrot
function Thieves.bonkThiefByTouchReturnsLootAndPaysBounty(th,by)
if th.st=="out" then
return
end
local loot=th.loot
th.loot,th.st,th.outAt=nil,"out",os.clock()
if loot then
Base.returnToPad(loot)
end
local tag=th.root:FindFirstChild("Label")
if tag then
tag:Destroy()
end
if by then
local bounty=20+15*wave
Base.addCash(by,bounty)
Base.tell(by,"bonk","BONK! +$"..cash(bounty),loot and (loot.ent.name.." is safe on its pad") or "One less snatcher in the bazaar",hex(0x78FF8C))
end
end
bonk=Thieves.bonkThiefByTouchReturnsLootAndPaysBounty
function Thieves.zapThievesWhenLockBaseShieldGoesUp(pl)
for _,th in thieves do
if th.pl==pl and (th.loot or Base.inside(pl,th.pos)) then
bonk(th)
end
end
end
function Thieves.sendRevengeRaidAfterRivalBaseRobbery(plr,count)
task.delay(4,function()
local pl=Base.plotOf(plr)
for _=1,pl and math.clamp(count,1,3) or 0 do
send(pl)
task.wait(1.4)
end
end)
end
function Thieves.pickStockedRivalBaseToRob()
local rivals={}
for _,pl in Base.allPlots() do
if not pl.own and #pl.rots>0 then
table.insert(rivals,pl)
end
end
return rivals[math.random(math.max(#rivals,1))]
end
function bandit()
local mdl=new("Model")
local root=new("Part",mdl,{Size=V(1,1,1),Transparency=1,Anchored=true,CanCollide=false,CanQuery=false,CFrame=CF(0,.5,0)})
mdl.PrimaryPart=root
local function body(sx,sy,sz,x,y,z,col,ball,mat,turn)
local p=new("Part",mdl,{Size=V(sx,sy,sz),Color=col,Material=mat or "SmoothPlastic",CanCollide=false,CanTouch=false,CanQuery=false,Massless=true,CFrame=CF(x,y,z)*(turn or CF())})
if ball then
new("SpecialMesh",p,{MeshType="Sphere"})
end
new("WeldConstraint",p,{Part0=root,Part1=p})
end
local fur,dark,white=hex(0x787A8A),hex(0x22202C),hex(0xF5F5F5)
body(2.6,3,2.3,0,2.4,0,dark,true)
body(2.7,.45,2.4,0,2,0,white,true)
body(2.7,.45,2.4,0,2.8,0,white,true)
body(2.6,2.4,2.4,0,4.6,0,fur,true)
body(2.7,.8,2.5,0,4.8,-.05,dark,true)
body(2.3,1.3,2.3,0,5.6,0,dark,true)
body(.5,.5,.5,0,6.3,0,RED,true,"Neon")
for side=-1,1,2 do
body(.65,.7,.4,side*.55,4.85,-1.2,white,true)
body(.3,.35,.3,side*.5,4.8,-1.38,dark,true)
body(.7,.9,.5,side*.9,5.9,0,fur,true)
body(.7,1.3,.7,side*.6,.65,0,dark)
body(.6,1.8,.6,side*1.5,2.8,-.5,fur,nil,nil,CFrame.Angles(math.rad(-50),0,0))
end
body(.7,.5,.6,0,4.3,-1.25,dark,true)
body(2.4,2.6,2.2,0,3,1.7,hex(0xC4A064),true,"Fabric")
for ring=0,2 do
body(.9,.9,.9,0,1.2+ring*.4,2.6+ring*.8,ring%2==0 and fur or dark,true)
end
local gui=new("BillboardGui",root,{Name="Label",Size=UDim2.fromScale(11,3.6),StudsOffsetWorldSpace=V(0,8.6,0),LightInfluence=0,MaxDistance=320,DistanceLowerLimit=50,DistanceUpperLimit=84})
Cat.label(gui,"THIEF!",RED,{Size=UDim2.fromScale(1,.6)})
Cat.label(gui,"TOUCH TO BONK",nil,{Size=UDim2.fromScale(1,.4),Position=UDim2.fromScale(0,.6)})
return mdl
end
function arrive(th)
local pl=th.pl
if th.st=="approach" then
if th.leg<#th.path then
th.leg+=1
return
end
if Base.isLocked(pl) then
return bonk(th)
end
local target=Base.bestOf(pl)
if target then
th.st,th.sneakTo="sneak",(target.pad.cf*CF(0,0,-3.6)).Position
else
th.st,th.leg="flee",#th.path-1
end
elseif th.st=="sneak" then
local rec=Base.bestOf(pl)
if rec then
th.loot=rec
Base.grab(rec,th.root)
if pl.own then
Base.tell(pl.own,"stolen","THIEF ALERT!",rec.ent.name.." was grabbed. Bonk the thief before it reaches the hideout!",RED)
end
end
th.st,th.speed,th.leg="flee",rec and LOOT or RUN,#th.path
elseif th.st=="flee" then
th.leg-=1
if th.leg<0 then
local loot=th.loot
if loot then
th.loot=nil
Base.lose(loot)
if pl.own then
Base.tell(pl.own,"stolen","STOLEN!",loot.ent.name.." is gone: -$"..cash(loot.inc).."/s. Guard your base next wave!",RED)
end
end
th.st="gone"
end
end
end
function moveThieves(dt)
local now=os.clock()
for idx=#thieves,1,-1 do
local th=thieves[idx]
if th.st=="out" then
local t=now-th.outAt
th.root.CFrame=CF(th.pos+V(0,.5+t*26,0))*CFrame.Angles(t*14,t*9,0)
if t>.8 then
th.st="gone"
end
elseif th.st~="gone" then
local goal=th.st=="sneak" and th.sneakTo or th.st=="flee" and th.leg==0 and world.DOOR or th.path[th.leg]
local offset,step=goal-th.pos,th.speed*dt
if offset.Magnitude<=step then
th.pos=goal
arrive(th)
else
th.pos+=offset.Unit*step
local flat=V(offset.X,0,offset.Z)
if flat.Magnitude>.01 then
local bob=math.abs(math.sin(now*11+th.phase))*.6
th.root.CFrame=CFrame.lookAt(th.pos,th.pos+flat.Unit)*CF(0,.5+bob,0)*CFrame.Angles(math.rad(-10),0,0)
end
end
if th.st~="out" and th.st~="gone" then
for _,plr in Players:GetPlayers() do
local hrp=Cat.rootOf(plr)
if hrp and ((hrp.Position-th.pos)*V(1,0,1)).Magnitude<BONK then
bonk(th,plr)
break
end
end
end
end
if th.st=="gone" then
table.remove(thieves,idx)
th.mdl:Destroy()
end
end
end
function Thieves.start(w)
world=w
Base.onBaseLocked=Thieves.zapThievesWhenLockBaseShieldGoesUp
Base.onRivalRobbed=Thieves.sendRevengeRaidAfterRivalBaseRobbery
game:GetService("RunService").Heartbeat:Connect(moveThieves)
task.spawn(Thieves.runThiefWaveClockCalmThenWarnThenRaid)
end
return Thieves
