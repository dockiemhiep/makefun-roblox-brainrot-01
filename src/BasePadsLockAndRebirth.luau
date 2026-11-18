-- Bases and money: pads, carry / place, upgrades, sell, cash + income, LOCK BASE shield, rebirth.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Cat=require(RS.BrainrotCatalog)
local new,cash=Cat.new,Cat.formatCash
local incOf,priceOf=Cat.incomePerSecondBaseXMutationXLevelBonus,Cat.priceGolden2xRadioactive3xRainbow5x
local hex=Cat.hex
local RED,GREEN,CYAN=hex(0xFF5A5A),hex(0x78FF8C),hex(0x50E6FF)
local Base={}
local plots,plotOf,carried,profs={},{},{},{}
local world,Rot
local remotes=new("Folder",RS,{Name="Remotes"})
local actRemote=new("RemoteEvent",remotes,{Name="Action"})
local noteRemote=new("RemoteEvent",remotes,{Name="Notice"})
local function set(plr,name,value)
plr:SetAttribute(name,value)
end
local tell,pub,refresh,relabel,padPrompts,removeRec,shieldOn,clear,stockRival
function Base.placeCarriedBrainrotOnFreePadToEarnCashPerSecond(plr)
local load,pl=carried[plr],plotOf[plr]
local pad=load and pl and Base.freePad(pl)
if not pad then
return false
end
Base.drop(plr)
local rec=Base.addToPad(pl,pad,load.ent,load.mut,load.lvl)
local prof=profs[plr]
if prof and not prof.seen[load.ent.id] then
prof.seen[load.ent.id]=true
local ids={}
for id in prof.seen do
table.insert(ids,id)
end
table.sort(ids)
set(plr,"Discovered",table.concat(ids,","))
end
tell(plr,"placed",load.ent.name.." is home!","+$"..cash(rec.inc*Base.multOf(plr)).."/s  •  "..load.ent.quip,load.ent.col)
return true
end
function Base.upgradeBrainrotLevel1To5ForMoreIncome(plr,rec)
if rec.taken or rec.lvl>=Cat.MaxLevel then
return
end
local cost=Cat.upgradeCostForLevels1To5(rec.ent,rec.lvl)
if not Base.pay(plr,cost) then
return tell(plr,"error","Not enough cash","Upgrade costs $"..cash(cost))
end
rec.lvl+=1
rec.inc=incOf(rec.ent,rec.mut,rec.lvl)
Rot.resize(rec.mdl,1+.07*(rec.lvl-1))
relabel(rec)
padPrompts(rec)
refresh(rec.pl)
tell(plr,"upgrade",rec.ent.name.." is now Lv "..rec.lvl,"Now earning $"..cash(rec.inc*Base.multOf(plr)).."/s",rec.ent.col)
end
function Base.tryLockBaseShieldWithNeonForcefieldBars(plr)
local pl,hrp=plotOf[plr],Cat.rootOf(plr)
local now=Cat.now()
if not pl or not hrp or now<pl.lockReady then
return false
end
if not Base.inside(pl,hrp.Position) then
tell(plr,"error","Get home first!","You can only lock the base from inside it")
return false
end
pl.lockTo,pl.lockReady=now+Cat.LockSeconds,now+Cat.LockCooldown
set(plr,"LockUntil",pl.lockTo)
set(plr,"LockReadyAt",pl.lockReady)
shieldOn(pl,true)
task.delay(Cat.LockSeconds,function()
if Cat.now()>=pl.lockTo-.1 then
shieldOn(pl,false)
end
end)
Base.onBaseLocked(pl)
tell(plr,"lock","BASE LOCKED!","Thieves bounce off for "..Cat.LockSeconds.." seconds",CYAN)
return true
end
function Base.rebirthResetForPermanentIncomeMultiplier(plr)
local prof=profs[plr]
local cost=Cat.rebirthCost50kTimes5PerRebirth(prof.rebs)
if prof.cash<cost then
return tell(plr,"error","Not enough cash","Rebirth costs $"..cash(cost))
end
prof.rebs+=1
prof.cash=Cat.StartingCash
pub(plr)
Base.drop(plr)
if plotOf[plr] then
clear(plotOf[plr])
end
tell(plr,"rebirth","REBIRTH! Income x"..Base.multOf(plr),"Everything you earn is multiplied forever. Rebuild the bazaar!",hex(0xC878FF))
end
function Base.unlockNextPadUpTo8(plr)
local pl=plotOf[plr]
if not pl or pl.open>=#pl.pads then
return
end
local cost=Cat.PadPrices[pl.open+1]
if not Base.pay(plr,cost) then
return tell(plr,"error","Not enough cash","This pad costs $"..cash(cost))
end
pl.open+=1
refresh(pl)
tell(plr,"upgrade","Pad "..pl.open.." unlocked!","Room for one more brainrot",pl.col)
end
function Base.sellBrainrotForHalfItsPrice(plr,rec)
if rec.taken or not table.find(rec.pl.rots,rec) then
return
end
local refund=math.floor(priceOf(rec.ent,rec.mut)*.5)
removeRec(rec)
Base.addCash(plr,refund)
tell(plr,"sold","Sold "..rec.ent.name,"+$"..cash(refund),GREEN)
end
function Base.stealFromRivalBaseAndTriggerRevengeRaid(plr,rec)
local pl=rec.pl
if pl.own or rec.taken or not table.find(pl.rots,rec) then
return
end
if not Base.giveCarried(plr,rec.ent,rec.mut,1) then
return tell(plr,"error","Hands full!","Take your brainrot home first")
end
Base.lose(rec)
tell(plr,"steal","You stole "..rec.ent.name.."!",pl.rival.." is sending a REVENGE RAID. Run home!",rec.ent.col)
Base.onRivalRobbed(plr,rec.ent.rank)
end
function Base.payIncomeEverySecond()
while task.wait(1) do
for plr,prof in profs do
if prof.inc>0 then
prof.cash+=prof.inc*Base.multOf(plr)
pub(plr)
end
end
end
end
function tell(plr,kind,title,body,col)
noteRemote:FireClient(plr,{kind=kind,title=title,body=body,col=col or RED})
end
Base.tell=tell
function pub(plr)
local prof=profs[plr]
if prof then
set(plr,"Cash",prof.cash)
set(plr,"Income",prof.inc*Base.multOf(plr))
set(plr,"Rebirths",prof.rebs)
set(plr,"RebirthCost",Cat.rebirthCost50kTimes5PerRebirth(prof.rebs))
end
end
function Base.multOf(plr)
return 1+(profs[plr] and profs[plr].rebs or 0)
end
function Base.addCash(plr,amount)
if profs[plr] then
profs[plr].cash+=amount
pub(plr)
end
end
function Base.pay(plr,cost)
local prof=profs[plr]
if not prof or prof.cash<cost then
return false
end
prof.cash-=cost
pub(plr)
return true
end
function Base.baseInc(pl)
local total=0
for _,rec in pl.rots do
total+=rec.taken and 0 or rec.inc
end
return total
end
function Base.freePad(pl)
for n=1,pl.open do
if not pl.pads[n].rec then
return pl.pads[n]
end
end
end
function refresh(pl)
local own=pl.own
for n,pad in pl.pads do
local isOpen=n<=pl.open
pad.part.Color=isOpen and pl.col or hex(0x3C3850)
local old=pad.part:FindFirstChild("BuyPad")
if old then
old:Destroy()
end
pad.tag.Text=isOpen and "" or "LOCKED"
if n==pl.open+1 and own then
local price="$"..cash(Cat.PadPrices[n])
pad.tag.Text="NEW PAD "..price
new("ProximityPrompt",pad.part,{Name="BuyPad",ActionText="Unlock pad",ObjectText=price,HoldDuration=.4,MaxActivationDistance=10,RequiresLineOfSight=false}).Triggered:Connect(function(who)
if who==pl.own then
Base.unlockNextPadUpTo8(who)
end
end)
end
end
local inc=Base.baseInc(pl)
pl.ownLabel.Text=string.upper(own and own.DisplayName or pl.rival).."'S BASE\n$"..cash(inc*(own and Base.multOf(own) or 1)).."/s"
for _,gui in pl.ownBoard:GetChildren() do
gui.Text.Text=pl.ownLabel.Text
gui.Text.TextColor3=own and hex(0xFFEC82) or hex(0xFFFFFF)
end
if own then
if profs[own] then
profs[own].inc=inc
pub(own)
end
set(own,"Brainrots",#pl.rots)
set(own,"Pads",pl.open)
end
end
function relabel(rec)
local own=rec.pl.own
Rot.setLabel(rec.mdl,rec.mut,rec.inc*(own and Base.multOf(own) or 1),Rot.stars(rec.lvl))
end
function padPrompts(rec)
local pl,mdl,ent=rec.pl,rec.mdl,rec.ent
Rot.clearPrompts(mdl)
local function prompt(run,...)
Rot.addPrompt(mdl,...).Triggered:Connect(function(who)
if who==pl.own or not pl.own then
run(who,rec)
end
end)
end
if not pl.own then
return prompt(Base.stealFromRivalBaseAndTriggerRevengeRaid,"Steal","Steal",ent.name,.8+ent.rank*.6)
end
if rec.lvl<Cat.MaxLevel then
prompt(Base.upgradeBrainrotLevel1To5ForMoreIncome,"Upgrade","Upgrade to Lv "..(rec.lvl+1),"$"..cash(Cat.upgradeCostForLevels1To5(ent,rec.lvl)),.3)
end
prompt(Base.sellBrainrotForHalfItsPrice,"Sell","Sell","+$"..cash(priceOf(ent,rec.mut)*.5),1.2,"R",-80)
end
function Base.addToPad(pl,pad,ent,mut,lvl)
local mdl=Rot.build(ent,mut)
mdl:PivotTo(pad.cf)
mdl.PrimaryPart.Label.MaxDistance=pl.own and 80 or 55
mdl.Parent=pl.rotDir
local rec={ent=ent,mut=mut,lvl=lvl,inc=incOf(ent,mut,lvl),mdl=mdl,pl=pl,pad=pad,taken=false}
pad.rec=rec
table.insert(pl.rots,rec)
relabel(rec)
padPrompts(rec)
refresh(pl)
return rec
end
function removeRec(rec)
local pl=rec.pl
local at=table.find(pl.rots,rec)
if at then
table.remove(pl.rots,at)
end
if rec.pad.rec==rec then
rec.pad.rec=nil
end
rec.mdl:Destroy()
refresh(pl)
end
function Base.giveCarried(plr,ent,mut,lvl)
local hrp=Cat.rootOf(plr)
if carried[plr] or not hrp or not plotOf[plr] then
return false
end
local mdl=Rot.build(ent,mut,Rot.CARRIED)
Rot.setLabel(mdl,mut,incOf(ent,mut,lvl),"RUN HOME!")
mdl:PivotTo(hrp.CFrame*CFrame.new(0,2.9,0))
local root=mdl.PrimaryPart
root.Anchored=false
new("WeldConstraint",root,{Part0=hrp,Part1=root})
mdl.Parent=world.dir.Carried
carried[plr]={ent=ent,mut=mut,lvl=lvl,mdl=mdl}
set(plr,"Carrying",ent.name)
return true
end
function Base.carries(plr)
return carried[plr]~=nil
end
function Base.drop(plr)
local load=carried[plr]
if load then
carried[plr]=nil
load.mdl:Destroy()
set(plr,"Carrying","")
end
end
local function restock(pl,pad)
task.delay(40,function()
if not pl.own and not pad.rec and pad.idx<=pl.open then
local pool=Cat.ByRarity[math.random()<.65 and "Common" or "Rare"]
Base.addToPad(pl,pad,pool[math.random(#pool)],nil,1)
end
end)
end
local RIVAL_NAMES={"GrannyGrindset","SigmaToaster99","CaptainRizzbeard","xX_NoodleKing_Xx","MoldyMogul","BeanTycoon42","LordOfSocks","DJ_Pigeonhands"}
local RIVAL_STOCK={
"noodlino toasty cactopus sockpuppeto conehead",
"toasty sockpuppeto bananaphone noodlino",
"sockpuppeto cactopus noodlino toasty fridgezilla conehead",
"conehead noodlino toasty spinnerino bananaphone",
"bananaphone toasty cactopus noodlino discopigeon sockpuppeto",
"noodlino conehead sockpuppeto fridgezilla",
"cactopus toasty bananaphone kaboomba noodlino",
"sockpuppeto noodlino spinnerino toasty conehead",
}
function stockRival(pl)
pl.open=6
for n,id in string.split(RIVAL_STOCK[pl.idx]," ") do
local mut=(n==2 and pl.idx%2==0) and "Golden" or (n==3 and pl.idx%3==0) and "Radioactive" or nil
Base.addToPad(pl,pl.pads[n],Cat.ById[id],mut,1)
end
refresh(pl)
end
function clear(pl)
for _,rec in table.clone(pl.rots) do
removeRec(rec)
end
refresh(pl)
end
function Base.inside(pl,pos)
local at=pl.origin:PointToObjectSpace(pos)
return math.abs(at.X)<17 and math.abs(at.Z)<16.5
end
function Base.isLocked(pl)
return Cat.now()<pl.lockTo
end
function shieldOn(pl,on)
pl.shield.Transparency=on and .72 or 1
pl.field.Transparency=on and .6 or 1
pl.glow1.Enabled=on
for _,bar in pl.bars do
bar.Transparency=on and 0 or 1
end
pl.lockBtn.Color=on and CYAN or hex(0xFF323C)
end
function Base.bestOf(pl)
local best
for _,rec in pl.rots do
if not rec.taken and (not best or rec.inc>best.inc) then
best=rec
end
end
return best
end
function Base.grab(rec,carrier)
rec.taken=true
Rot.clearPrompts(rec.mdl)
local root=rec.mdl.PrimaryPart
Rot.resize(rec.mdl,Rot.CARRIED)
rec.mdl:PivotTo(carrier.CFrame*CFrame.new(0,7.4,.6))
root.Anchored=false
new("WeldConstraint",root,{Name="ThiefGrip",Part0=carrier,Part1=root})
Rot.setLabel(rec.mdl,rec.mut,rec.inc,"HELP! STOLEN!")
refresh(rec.pl)
end
function Base.returnToPad(rec)
if not rec.taken then
return
end
rec.taken=false
local root=rec.mdl.PrimaryPart
local grip=root:FindFirstChild("ThiefGrip")
if grip then
grip:Destroy()
end
root.Anchored=true
Rot.resize(rec.mdl,1+.07*(rec.lvl-1))
rec.mdl:PivotTo(rec.pad.cf)
relabel(rec)
padPrompts(rec)
refresh(rec.pl)
end
function Base.lose(rec)
local pl,pad=rec.pl,rec.pad
removeRec(rec)
if not pl.own then
restock(pl,pad)
end
end
function Base.plotOf(plr)
return plotOf[plr]
end
function Base.allPlots()
return plots
end
local function claim(plr)
for _,idx in {2,6,3,7,1,5,4,8} do
local pl=plots[idx]
if not pl.own then
clear(pl)
pl.own,pl.open,pl.lockTo,pl.lockReady=plr,Cat.StartingPads,0,0
plotOf[plr]=pl
set(plr,"PlotIndex",idx)
set(plr,"LockUntil",0)
set(plr,"LockReadyAt",0)
set(plr,"Carrying","")
pl.dir:SetAttribute("Owner",plr.Name)
refresh(pl)
return pl
end
end
end
local function release(plr)
Base.drop(plr)
local pl=plotOf[plr]
if pl then
plotOf[plr],pl.own=nil,nil
pl.dir:SetAttribute("Owner",nil)
clear(pl)
shieldOn(pl,false)
stockRival(pl)
end
profs[plr]=nil
end
local function watchCarriers()
local lastFull={}
while task.wait(.2) do
for plr in carried do
local pl,hrp=plotOf[plr],Cat.rootOf(plr)
if not hrp then
Base.drop(plr)
elseif pl and Base.inside(pl,hrp.Position) and not Base.placeCarriedBrainrotOnFreePadToEarnCashPerSecond(plr) and os.clock()-(lastFull[plr] or 0)>4 then
lastFull[plr]=os.clock()
tell(plr,"error","No free pad!","Unlock a pad or sell a brainrot (hold R)")
end
end
end
end
local function sendHome(plr,char)
local pl=plotOf[plr]
local hum=char:WaitForChild("Humanoid",10)
if pl and hum and char:WaitForChild("HumanoidRootPart",10) then
hum.WalkSpeed=22
task.wait()
char:PivotTo(pl.origin*CFrame.new(0,3.5,-11)*CFrame.Angles(0,math.pi,0))
end
if hum then
hum.Died:Connect(function()
Base.drop(plr)
end)
end
end
local function welcome(plr)
profs[plr]={cash=Cat.StartingCash,rebs=0,inc=0,seen={}}
set(plr,"Discovered","")
pub(plr)
if not claim(plr) then
tell(plr,"error","The bazaar is full","Every base is taken. You can still bonk thieves for cash!")
end
plr.CharacterAdded:Connect(function(char)
sendHome(plr,char)
end)
if plr.Character then
task.spawn(sendHome,plr,plr.Character)
end
task.delay(3,function()
if plr.Parent then
tell(plr,"tip","Welcome to BRAINROT BAZAAR!","Buy a brainrot off the conveyor (E) and carry it to your base",hex(0xFFE25A))
end
end)
end
function Base.init(w)
world,Rot,Base.world=w,w.creature,w
for idx,pl in world.plots do
pl.rival,pl.rots,pl.lockTo,pl.lockReady=RIVAL_NAMES[idx],{},0,0
plots[idx]=pl
new("ProximityPrompt",pl.lockBtn,{ActionText="LOCK BASE",ObjectText="Big red button",KeyboardKeyCode="F",MaxActivationDistance=9,RequiresLineOfSight=false}).Triggered:Connect(function(who)
if who==pl.own then
Base.tryLockBaseShieldWithNeonForcefieldBars(who)
end
end)
stockRival(pl)
end
actRemote.OnServerEvent:Connect(function(plr,action)
if not profs[plr] then
return
elseif action=="LockBase" then
Base.tryLockBaseShieldWithNeonForcefieldBars(plr)
elseif action=="Rebirth" then
Base.rebirthResetForPermanentIncomeMultiplier(plr)
end
end)
Players.PlayerRemoving:Connect(release)
Players.PlayerAdded:Connect(welcome)
for _,plr in Players:GetPlayers() do
task.spawn(welcome,plr)
end
task.spawn(Base.payIncomeEverySecond)
task.spawn(watchCarriers)
end
return Base
