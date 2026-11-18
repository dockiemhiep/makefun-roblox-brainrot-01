-- ScreenGui HUD + client world FX. Shows replicated attributes; sends LockBase and Rebirth.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Cat=require(RS:WaitForChild("BrainrotCatalog"))
local remotes=RS:WaitForChild("Remotes")
local actRemote=remotes:WaitForChild("Action")
local new,cash=Cat.new,Cat.formatCash
local hex,px,U2,V2=Cat.hex,UDim2.fromOffset,UDim2.new,Vector2.new
local plr,bazaar=Players.LocalPlayer,workspace:WaitForChild("Bazaar")
local C={
panel=hex(0x221A3A),ink=hex(0x140E22),text=hex(0xFFFFFF),money=hex(0x68FF80),
gold=hex(0xFFD640),danger=hex(0xFF4848),lock=hex(0x40C8FF),rebirth=hex(0xBE6EFF),
}
local canvas,coin,cashTxt,incLabel,chipRow,padsChip,foundChip,incomeChip,waveBox,waveTxt
local lockBtn,rebBtn,carryBox,carryTxt,toasts
local rowOf,toastN,shown={},0,0
local panel,text,bigButton,setBtn
local function attr(name,default)
return plr:GetAttribute(name) or default
end
local function commas(amount)
if amount>=1e7 then
return cash(amount)
end
return (tostring(math.floor(amount)):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,",""))
end
local function buildScreenGuiHudCashIncomePadsAndBraindex()
local screen=new("ScreenGui",plr:WaitForChild("PlayerGui"),{ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior="Sibling"})
canvas=new("Frame",screen,{BackgroundTransparency=1,AnchorPoint=V2(.5,.5),Position=UDim2.fromScale(.5,.5)})
local cScale=new("UIScale",canvas)
local function fit()
local view=workspace.CurrentCamera.ViewportSize
local width,ht=view.X,view.Y
if workspace:GetAttribute("PhotoFrame16x9") and width/ht<16/9 then
ht=width*9/16
end
local scale=math.clamp(math.min(width/1100,ht/620),.45,2.4)
cScale.Scale=scale
canvas.Size=px(width/scale,ht/scale)
end
fit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
workspace:GetAttributeChangedSignal("PhotoFrame16x9"):Connect(fit)
local cashPanel=panel(canvas,px(380,96),U2(.5,0,0,8),V2(.5,0))
coin=panel(cashPanel,px(64,64),U2(0,18,.5,0),V2(0,.5),C.gold,36)
text(coin,"$",44)
cashTxt=text(cashPanel,"$0",50,nil,U2(1,-104,0,54),px(94,2),"Left")
incLabel=text(cashPanel,"+$0/s",27,C.money,U2(1,-104,0,30),px(96,56),"Left")
chipRow=new("Frame",canvas,{BackgroundTransparency=1,Size=px(560,36),Position=U2(.5,0,0,111),AnchorPoint=V2(.5,0)})
new("UIListLayout",chipRow,{FillDirection="Horizontal",HorizontalAlignment="Center",Padding=UDim.new(0,10)})
local function chip(width,col)
local frame=panel(chipRow,px(width,36),U2(),nil,nil,18)
frame.Edge.Thickness=2
return text(frame,"",21,col)
end
padsChip,foundChip,incomeChip=chip(150),chip(170,C.gold),chip(160)
waveBox=panel(canvas,px(300,46),U2(1,-14,0,12),V2(1,0),nil,20)
waveTxt=text(waveBox,"",22)
lockBtn=bigButton("LOCK BASE",C.lock,U2(.5,-135,1,-16))
rebBtn=bigButton("REBIRTH",C.rebirth,U2(.5,135,1,-16))
carryBox=panel(canvas,px(520,42),U2(.5,0,1,-94),V2(.5,1),nil,21)
carryBox.Edge.Color,carryBox.Edge.Transparency,carryBox.Visible=C.gold,0,false
carryTxt=text(carryBox,"",24,C.gold)
local ladder=panel(canvas,px(196,206),U2(0,14,.5,-20),V2(0,.5))
text(ladder,"BRAINDEX",22,C.gold,U2(1,0,0,28),px(0,8))
for idx,rar in Cat.RarityOrder do
local y=8+idx*31
text(ladder,string.upper(rar),20,Cat.Rarities[rar].col,px(120,26),px(14,y),"Left")
rowOf[rar]=text(ladder,"0/0",20,nil,px(50,26),U2(1,-64,0,y),"Right")
end
toasts=new("Frame",canvas,{BackgroundTransparency=1,Size=px(360,400),Position=U2(1,-14,0,176),AnchorPoint=V2(1,0)})
new("UIListLayout",toasts,{Padding=UDim.new(0,10),SortOrder="LayoutOrder"})
end
local function showToastPopupInRarityColour(payload)
toastN+=1
local col=payload.col or C.text
local toast=panel(toasts,px(360,100),U2(),nil,col:Lerp(C.ink,.72),16)
toast.LayoutOrder,toast.Edge.Color,toast.Edge.Transparency=toastN,col,0
local title=text(toast,payload.title or "",23,col,U2(1,-24,0,30),px(12,8),"Left")
title.TextScaled=true
new("UITextSizeConstraint",title,{MaxTextSize=23,MinTextSize=14})
local body=text(toast,payload.body or "",21,nil,U2(1,-24,0,52),px(12,40),"Left")
body.TextWrapped,body.TextTruncate,body.TextYAlignment,body.TextScaled=true,"None","Top",true
new("UITextSizeConstraint",body,{MaxTextSize=21,MinTextSize=15})
for _,old in toasts:GetChildren() do
if old:IsA("Frame") and old.LayoutOrder<=toastN-4 then
old:Destroy()
end
end
task.delay(payload.kind=="stolen" and 6 or 4.5,toast.Destroy,toast)
end
local function refreshThiefWaveBannerCountdownAndRaidAlert(now)
local phase=workspace:GetAttribute("WavePhase") or "calm"
chipRow.Visible=phase=="calm"
local left=math.max(0,math.ceil((workspace:GetAttribute("WaveEndsAt") or now)-now))
local centre=phase~="calm"
waveBox.AnchorPoint=V2(centre and .5 or 1,0)
waveBox.Position=centre and U2(.5,0,0,110) or U2(1,-14,0,12)
if phase=="warn" then
waveBox.Size=px(600,58)
waveBox.BackgroundColor3=C.danger:Lerp(C.ink,.4+.15*math.sin(os.clock()*10))
waveTxt.TextSize=34
waveTxt.Text="THIEF WAVE INCOMING!  "..left
elseif phase=="raid" then
waveBox.Size=px(600,50)
waveBox.BackgroundColor3=C.danger:Lerp(C.ink,.35)
waveTxt.TextSize=27
waveTxt.Text="WAVE "..(workspace:GetAttribute("WaveNumber") or 1)..": THIEVES ARE IN!  BONK THEM!"
else
waveBox.Size=px(300,46)
waveBox.BackgroundColor3=left<=10 and C.danger:Lerp(C.ink,.3) or C.panel
waveTxt.TextSize=left<=10 and 26 or 23
waveTxt.Text=string.format("THIEF WAVE IN  %d:%02d",left//60,left%60)
end
end
local function refreshLockBaseAndRebirthButtons(now)
local lockTo,readyAt=attr("LockUntil",0),attr("LockReadyAt",0)
if now<lockTo then
setBtn(lockBtn,string.format("SHIELD UP  %ds",math.ceil(lockTo-now)),(lockTo-now)/Cat.LockSeconds,true)
elseif now<readyAt then
setBtn(lockBtn,string.format("RECHARGING  %ds",math.ceil(readyAt-now)),1-(readyAt-now)/(Cat.LockCooldown-Cat.LockSeconds),false)
else
setBtn(lockBtn,"READY  [F]",1,true)
end
local cost,money=attr("RebirthCost",Cat.RebirthBaseCost),attr("Cash",0)
setBtn(rebBtn,"$"..cash(cost).." = x"..(2+(attr("Rebirths",0))).." INCOME",money/cost,money>=cost)
end
local function popCashOverMyEarningBrainrots()
while task.wait(1) do
local pl=bazaar.Plots:FindFirstChild("Plot"..(attr("PlotIndex",0)))
for _,brainrot in pl and pl.Brainrots:GetChildren() or {} do
local root,inc=brainrot.PrimaryPart,brainrot:GetAttribute("Income")
if root and inc and root.Anchored then
local pop=new("BillboardGui",root,{Size=UDim2.fromScale(7,2.2),StudsOffsetWorldSpace=Vector3.new(0,4,-2),AlwaysOnTop=true,LightInfluence=0,Adornee=root})
local label=Cat.label(pop,"+$"..cash(inc),C.money)
local tween=TweenInfo.new(.9,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
Tween:Create(pop,tween,{StudsOffsetWorldSpace=Vector3.new(0,8.5,-2)}):Play()
Tween:Create(label,TweenInfo.new(.9,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{TextTransparency=1,TextStrokeTransparency=1}):Play()
task.delay(.95,pop.Destroy,pop)
end
end
end
end
local function animateConveyorChevronsAndCarryHomeBeam()
local X0,GAP,stripes=-86,6,{}
local dir=new("Folder",bazaar)
for idx=0,28 do
for side=-1,1,2 do
table.insert(stripes,{idx=idx,side=side,part=new("Part",dir,{Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false,Size=Vector3.new(.9,.08,5.4),Color=hex(0xFFCE28),Material="Neon"})})
end
end
Run.RenderStepped:Connect(function()
local shift=(os.clock()*7)%GAP
for _,s in stripes do
s.part.CFrame=CFrame.new(X0+s.idx*GAP+shift,1.63,s.side*1.9)*CFrame.Angles(0,math.rad(s.side*50),0)
end
end)
local beam=new("Beam",bazaar,{Width0=1.4,Width1=1.4,FaceCamera=true,LightEmission=1,Color=ColorSequence.new(hex(0xFFE25A)),Transparency=NumberSequence.new(.25),Segments=1,Enabled=false})
local home=new("Attachment",nil,{Position=Vector3.new(0,1.5,0)})
local function refresh()
local pl=bazaar.Plots:FindFirstChild("Plot"..(attr("PlotIndex",0)))
local hrp=Cat.rootOf(plr)
local feet=hrp and hrp:FindFirstChild("RootAttachment")
beam.Enabled=(attr("Carrying",""))~="" and pl~=nil and feet~=nil
if beam.Enabled then
home.Parent=pl.BaseFloor
beam.Attachment0,beam.Attachment1=feet,home
end
end
plr:GetAttributeChangedSignal("Carrying"):Connect(refresh)
plr.CharacterAdded:Connect(function()
task.wait(1)
refresh()
end)
end
local function refreshChips()
incLabel.Text="+$"..commas(attr("Income",0)).." / sec"
padsChip.Text="PADS "..(attr("Brainrots",0)).."/"..(attr("Pads",Cat.StartingPads))
local found,count={},0
for id in string.gmatch(attr("Discovered",""),"[^,]+") do
local ent=Cat.ById[id]
if ent then
found[ent.rar]=(found[ent.rar] or 0)+1
count+=1
end
end
foundChip.Text="FOUND "..count.."/"..#Cat.List
for rar,label in rowOf do
label.Text=(found[rar] or 0).."/"..#Cat.ByRarity[rar]
end
incomeChip.Text="INCOME x"..(1+(attr("Rebirths",0)))
local held=attr("Carrying","")
carryBox.Visible=held~=""
carryTxt.Text="RUN HOME with "..held.."!"
end
function panel(parent,size,pos,anchor,col,radius)
local frame=new("Frame",parent,{Size=size,Position=pos,AnchorPoint=anchor or V2(),BackgroundColor3=col or C.panel,BorderSizePixel=0})
new("UICorner",frame,{CornerRadius=UDim.new(0,radius or 18)})
new("UIStroke",frame,{Name="Edge",Thickness=3,Color=C.text,Transparency=.15})
return frame
end
function text(parent,content,size,col,dims,pos,alignX)
local label=new("TextLabel",parent,{BackgroundTransparency=1,Size=dims or UDim2.fromScale(1,1),Position=pos or U2(),Font="FredokaOne",Text=content,TextSize=size,TextColor3=col or C.text,TextXAlignment=alignX or "Center",TextTruncate="AtEnd"})
new("UIStroke",label,{Thickness=math.clamp(size/14,1.5,3.5),Color=C.ink})
return label
end
function bigButton(title,col,pos)
local button=new("TextButton",canvas,{Text="",Size=px(250,70),Position=pos,AnchorPoint=V2(.5,1),BackgroundColor3=col,BorderSizePixel=0,ClipsDescendants=true})
new("UICorner",button,{CornerRadius=UDim.new(0,18)})
new("UIStroke",button,{Thickness=3,Color=C.text,ApplyStrokeMode="Border"})
local fill=new("Frame",button,{BackgroundColor3=C.text,BackgroundTransparency=.45,BorderSizePixel=0,AnchorPoint=V2(0,1),Position=UDim2.fromScale(0,1),Size=px(0,10)})
text(button,title,28,nil,U2(1,0,0,34),px(0,3))
return {button=button,status=text(button,"",21,nil,U2(1,-12,0,24),px(6,35)),fill=fill,col=col}
end
function setBtn(kit,status,progress,enabled)
kit.status.Text=status
kit.fill.Size=U2(math.clamp(progress,0,1),0,0,10)
kit.button.BackgroundColor3=enabled and kit.col or kit.col:Lerp(C.ink,.55)
end
pcall(function()
local StarterGui=game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
end)
buildScreenGuiHudCashIncomePadsAndBraindex()
local function askLock()
actRemote:FireServer("LockBase")
end
lockBtn.button.Activated:Connect(askLock)
rebBtn.button.Activated:Connect(function()
actRemote:FireServer("Rebirth")
end)
game:GetService("ContextActionService"):BindAction("BazaarLockBase",function(_,st)
if st==Enum.UserInputState.Begin then
askLock()
end
return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.F)
remotes:WaitForChild("Notice").OnClientEvent:Connect(showToastPopupInRarityColour)
for _,att in {"Income","Brainrots","Pads","Discovered","Rebirths","Carrying"} do
plr:GetAttributeChangedSignal(att):Connect(refreshChips)
end
refreshChips()
Run.RenderStepped:Connect(function(dt)
local now=Cat.now()
local target=attr("Cash",0)
shown=math.abs(target-shown)<1 and target or shown+(target-shown)*math.min(1,dt*8)
cashTxt.Text="$"..commas(shown+.5)
refreshThiefWaveBannerCountdownAndRaidAlert(now)
refreshLockBaseAndRebirthButtons(now)
end)
plr:GetAttributeChangedSignal("Cash"):Connect(function()
coin.Size=px(72,72)
Tween:Create(coin,TweenInfo.new(.25,Enum.EasingStyle.Back),{Size=px(64,64)}):Play()
end)
animateConveyorChevronsAndCarryHomeBeam()
task.spawn(popCashOverMyEarningBrainrots)
