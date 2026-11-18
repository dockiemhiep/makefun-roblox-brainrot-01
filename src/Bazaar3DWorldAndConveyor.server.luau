-- Server entry: builds the 3D bazaar, the brainrot creatures and the moving conveyor.
local Run=game:GetService("RunService")
local Cat=require(game:GetService("ReplicatedStorage").BrainrotCatalog)
local Base=require(script.Parent.BasePadsLockAndRebirth)
local Thieves=require(script.Parent.ThiefWavesAndRivalRaids)
local new,label,cash=Cat.new,Cat.label,Cat.formatCash
local incOf,priceOf=Cat.incomePerSecondBaseXMutationXLevelBonus,Cat.priceGolden2xRadioactive3xRainbow5x
local V,CF,ANG,hex,rad,rnd=Vector3.new,CFrame.new,CFrame.Angles,Cat.hex,math.rad,math.random
local BazaarWorld,Rot,Conveyor={},{CARRIED=.55},{}
local GY,BY,X0,X1,HALF=.4,1.6,-84,86,5
local SPEED,DROP_EVERY,STRAY_COUNT,SCALE=7,2.6,6,1.4
local DOOR,BLACK,WHITE,CYAN=V(106,.4,0),hex(0x18161E),hex(0xFFFFFF),hex(0x50E6FF)
local scale,riding,strays,beltDir,strayDir,into,cur,cRoot=SCALE,{},{}
local part,deco,pillar,sign,ground,lane,hideout,scenery
local addPart,addFace,addLegs,mutate,addBeam,roll,beltCF
function BazaarWorld.build3DPlazaMovingConveyorAnd8Bases()
local dir=new("Folder",nil,{Name="Bazaar"})
into=new("Folder",dir)
ground()
lane()
hideout()
scenery()
local plotDir,plots=new("Folder",dir,{Name="Plots"}),{}
for idx=1,8 do
plots[idx]=BazaarWorld.buildWalledBaseWith8PadsGateAndForcefieldBars(plotDir,idx)
end
for _,name in {"Conveyor","Strays","Thieves","Carried"} do
new("Folder",dir,{Name=name})
end
dir.Parent=workspace
return {dir=dir,plots=plots,creature=Rot,conveyor=Conveyor,GY=GY,DOOR=DOOR}
end
function Rot.buildBrainrotPartsFaceLabelAndMutationGlow(ent,mut,k)
scale=SCALE*(k or 1)
local mdl=new("Model",nil,{Name=ent.id})
mdl:SetAttribute("BrainrotId",ent.id)
mdl:SetAttribute("Rarity",ent.rar)
mdl:SetAttribute("Mutation",mut or "")
local root=new("Part",mdl,{Size=V(1,1,1),Transparency=1,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Massless=true,CFrame=CF(0,.5,0),PivotOffset=CF(0,-.5,0)})
mdl.PrimaryPart=root
cur,cRoot=mdl,root
for _,row in ent.parts do
local cf,r=CF(row[3]),row[6]
if r then
cf*=ANG(rad(r.X),rad(r.Y),rad(r.Z))
end
addPart(row[1],row[2],cf,row[4],row[5],row[7]).Name="Body"
end
if ent.legs then
addLegs(ent.legs)
end
addFace(ent.face)
if mut then
mutate(mdl,mut)
end
if Cat.Rarities[ent.rar].beam then
addBeam(ent.col,ent.ht)
end
local gui=new("BillboardGui",root,{Name="Label",Size=UDim2.fromScale(13,5.6),StudsOffsetWorldSpace=V(0,ent.ht*scale+3.4,0),LightInfluence=0,MaxDistance=80,DistanceLowerLimit=50})
new("UIListLayout",gui,{SortOrder="LayoutOrder"})
for order,line in {{"Rarity",.2,WHITE},{"BrainrotName",.3,WHITE},{"Money",.3,hex(0x60FF78)},{"Extra",.2,hex(0xFFE25A)}} do
label(gui,"",line[3],{Name=line[1],LayoutOrder=order,Size=UDim2.fromScale(1,line[2]),Font=line[2]<.3 and "GothamBlack" or nil,TextStrokeColor3=BLACK})
end
local point=new("Attachment",root,{Name="PromptPoint",Position=V(0,ent.ht*scale*.5,0)})
local glow=mut and Cat.MutationOf[mut].col or ent.rank==5 and ent.col
if glow then
Rot.addBrightHighlightOutlineAndSparkles(mdl,point,glow)
end
Rot.setLabel(mdl,mut,incOf(ent,mut,1),Rot.stars(1))
return mdl
end
function Rot.addBrightHighlightOutlineAndSparkles(mdl,point,col)
new("Highlight",mdl,{FillColor=col,FillTransparency=.8,OutlineColor=col:Lerp(WHITE,.35),DepthMode="Occluded"})
new("ParticleEmitter",point,{Color=ColorSequence.new(col,WHITE),LightEmission=1,Brightness=3,Rate=16,Lifetime=NumberRange.new(.8,1.5),Speed=NumberRange.new(4,8),SpreadAngle=Vector2.new(180,180),Size=NumberSequence.new(1.3*scale,0)})
end
function Conveyor.rollRarityAndMutationThenDropOnMovingBelt(atX,ent,mut)
if not ent then
ent,mut=roll()
end
local price=priceOf(ent,mut)
local mdl=Rot.build(ent,mut)
Rot.setLabel(mdl,mut,incOf(ent,mut,1),"BUY $"..cash(price))
local it={mdl=mdl,ent=ent,mut=mut,price=price,x=atX or X0,phase=rnd()*6}
mdl:PivotTo(beltCF(it.x,it.phase))
mdl.Parent=beltDir
Rot.addPrompt(mdl,"Buy","Buy",ent.name.."  $"..cash(price),0).Triggered:Connect(function(who)
Conveyor.buyBrainrotOffConveyorAndCarryItHome(who,it)
end)
table.insert(riding,it)
return it
end
function Conveyor.buyBrainrotOffConveyorAndCarryItHome(plr,it)
if not table.find(riding,it) or not Base.plotOf(plr) then
return
end
if Base.carries(plr) then
return Base.tell(plr,"error","Hands full!","Carry your brainrot home first")
end
if not Base.pay(plr,it.price) then
return Base.tell(plr,"error","Not enough cash",it.ent.name.." costs $"..cash(it.price))
end
if not Base.giveCarried(plr,it.ent,it.mut,1) then
return Base.addCash(plr,it.price)
end
table.remove(riding,table.find(riding,it))
it.mdl:Destroy()
Base.tell(plr,"bought","Bought "..(it.mut and it.mut.." " or "")..it.ent.name.."!",string.upper(it.ent.rar).."  •  Carry it to your base to start earning",it.ent.col)
end
function BazaarWorld.buildWalledBaseWith8PadsGateAndForcefieldBars(parent,idx)
local side=idx<=4 and 1 or -1
local center=V(({-60,-20,20,60})[(idx-1)%4+1],GY,side*42)
local origin=CFrame.lookAt(center,center-V(0,0,side))
local col=({hex(0xFF5C5C),hex(0xFFAA28),hex(0x50C878),hex(0x3CAAFF),hex(0xBE64FF),hex(0xFF6EBE),hex(0x3CD2D2),hex(0xF0DC3C)})[idx]
local dark=col:Lerp(hex(0x14101E),.45)
local dir=new("Folder",parent,{Name="Plot"..idx})
into=dir
dir:SetAttribute("PlotIndex",idx)
local function wall(size,x,y,z,c,...)
return part(size,origin*CF(x,y,z),c or col,...)
end
local floor=wall(V(34,.6,32),0,.3,0,col:Lerp(hex(0xFFFAF0),.62))
floor.Name="BaseFloor"
wall(V(34,4.4,1),0,2.2,16.5)
for x=-1,1,2 do
wall(V(1,4.4,34),x*17.5,2.2,0)
wall(V(10,4.4,1),x*12.5,2.2,-16.5)
wall(V(2,6.4,2),x*7,3.2,-16.5,dark)
wall(V(1.6,1.6,1.6),x*7,7.2,-16.5,col,"Neon","Ball",true)
wall(V(.8,12,.8),x*9,6,17.4,dark)
wall(V(.6,7.6,.6),x*16.4,3.8,11.4,0xF5F0E1,"Wood")
end
local board=wall(V(22,5.6,.8),0,13.4,17.4,0x301E60,nil,nil,true)
local ownLabel=sign(board,"FOR RENT",WHITE,true)
for stripe=0,7 do
deco(V(4.25,.4,6),origin*CF(-14.9+stripe*4.25,7.2,14)*ANG(rad(-14),0,0),stripe%2==0 and col or hex(0xFAF8F0),"Fabric")
end
local pads={}
for n=1,8 do
local padCf=origin*CF(-12+(n-1)%4*8,.6,-5+(n-1)//4*12)
local pad=part(V(.4,6.4,6.4),padCf*CF(0,.2,0)*ANG(0,0,rad(90)),0x3C3850,nil,"Cylinder")
pad:SetAttribute("PadIndex",n)
local tag=new("BillboardGui",pad,{Size=UDim2.fromScale(6,2.2),StudsOffsetWorldSpace=V(0,2.4,0),LightInfluence=0,MaxDistance=110,DistanceLowerLimit=36})
pads[n]={idx=n,part=pad,cf=padCf*CF(0,.4,0),tag=label(tag,"",nil,{Name="Text"})}
end
wall(V(2.4,2.6,2.4),11,1.9,-12.5,0x3C3850)
local lockBtn=pillar(2,.7,(origin*CF(11,3.5,-12.5)).Position,0xFF323C,"Neon")
local function neon(size,x,y,z,c)
local p=wall(size,x,y,z,c or CYAN,"Neon",nil,true)
p.Transparency,p.CastShadow=1,false
return p
end
local shield,bars=neon(V(36.4,13,34.4),0,6.5,0,0x50DCFF),{}
shield.CanQuery=false
for i=1,9 do
bars[i]=i<5 and neon(V(12,.7,.7),0,.2+i*1.6,-16.5) or neon(V(.7,7.4,.7),(i-7)*2.4,4.1,-16.5)
end
return {
idx=idx,side=side,origin=origin,col=col,dir=dir,floor=floor,pads=pads,
rotDir=new("Folder",dir,{Name="Brainrots"}),ownLabel=ownLabel,ownBoard=board,
lockBtn=lockBtn,shield=shield,bars=bars,field=neon(V(12,7.4,.3),0,4.1,-16.5),
glow1=new("PointLight",bars[7],{Color=CYAN,Range=26,Brightness=5,Enabled=false}),
gate=(origin*CF(0,0,-19)).Position,
}
end
function part(size,cf,col,mat,shape,ghost)
local p=Instance.new("Part")
p.Anchored,p.Size,p.CFrame,p.Color,p.Material=true,size,cf,type(col)=="number" and hex(col) or col,mat or "SmoothPlastic"
if shape then
p.Shape=shape
end
p.CanCollide=not ghost
p.Parent=into
return p
end
function deco(size,cf,col,mat,shape)
return part(size,cf,col,mat,shape,true)
end
function pillar(dia,ht,at,col,mat)
return part(V(ht,dia,dia),CF(at)*ANG(0,0,rad(90)),col,mat,"Cylinder")
end
local function sphere(p)
new("SpecialMesh",p,{MeshType="Sphere"})
return p
end
function sign(board,text,col,both)
local first
for _,face in both and {"Front","Back"} or {"Front"} do
local gui=new("SurfaceGui",board,{Face=face,SizingMode="PixelsPerStud",PixelsPerStud=40,LightInfluence=0})
local text=label(gui,text,col,{Name="Text",TextStrokeColor3=hex(0x14101E)})
new("UIPadding",text,{PaddingLeft=UDim.new(.04,0),PaddingRight=UDim.new(.04,0),PaddingTop=UDim.new(.06,0),PaddingBottom=UDim.new(.06,0)})
first=first or text
end
return first
end
local function palm(at)
pillar(1.6,14,at+V(0,7,0),0x966E46,"Wood")
for i=0,4 do
deco(V(2.4,.4,8),CF(at+V(0,14,0))*ANG(0,rad(i*72),0)*CF(0,-.6,-4)*ANG(rad(-18),0,0),0x3CB45A,"Grass")
end
deco(V(1.4,1.4,1.4),CF(at+V(.6,13.2,.4)),0x6E4628,nil,"Ball")
end
local function lamp(at,col)
pillar(.6,11,at+V(0,5.5,0),0x323242,"Metal")
local bulb=deco(V(2.2,2.2,2.2),CF(at+V(0,11.6,0)),col,"Neon","Ball")
new("PointLight",bulb,{Color=col,Range=22,Brightness=1.2})
deco(V(2.6,3.2,2.6),CF(at+V(1.6,16.5,.8)),Color3.fromHSV((at.X*.013+at.Z*.02)%1,.7,1),nil,"Ball")
deco(V(.12,4,.12),CF(at+V(1.2,13.4,.6))*ANG(0,0,rad(-12)),0xF0F0F0)
end
local function tent(at,facing,col,wares)
local base=CF(at)*ANG(0,rad(facing),0)
for _,corner in {V(-5,4,-3.5),V(5,4,-3.5),V(-5,4,3.5),V(5,4,3.5)} do
pillar(.5,8,(base*CF(corner)).Position,0xF5F0E1,"Wood")
end
for stripe=0,4 do
deco(V(2.2,.4,8.4),base*CF(-4.4+stripe*2.2,8.4,0),stripe%2==0 and col or hex(0xFAF8F0),"Fabric")
end
part(V(10,2.6,1.4),base*CF(0,1.3,-3),0xAA7846,"WoodPlanks")
sign(deco(V(9,1.8,.3),base*CF(0,9.6,-4.2),0x28223C),wares,hex(0xFFEC82))
for i=1,3 do
part(V(1.8,1.8,1.8),base*CF(-6.5,.9+(i==3 and 1.8 or 0),i==2 and 1.9 or 0)*ANG(0,i*.4,0),0xC4965A,"WoodPlanks")
end
end
function ground()
part(V(250,.4,126),CF(10,.2,0),0xDEBA80,"Sand")
local light,coral=hex(0xFAE2B0),hex(0xF4A06E)
for side=-1,1,2 do
for i=0,21 do
deco(V(8,.1,8),CF(-84+i*8,.42,side*12),i%2==0 and light or coral)
deco(V(8,.1,8),CF(-84+i*8,.42,side*20),i%2==1 and light or coral)
end
end
end
function lane()
local length,centerX,railZ=X1-X0+8,(X1+X0)/2,HALF+.35
part(V(length,1.2,HALF*2),CF(centerX,BY-.6,0),0x2C2E3E,"DiamondPlate").AssemblyLinearVelocity=V(SPEED,0,0)
for side=-1,1,2 do
deco(V(length,.7,.7),CF(centerX,BY+.1,side*railZ),0xFFCE28,"Neon")
for i=0,10 do
pillar(.8,1.2,V(X0+i*17,.8,side*railZ),0x1E1E28,"Metal")
end
end
local x,purple,ink=X0-10,hex(0x5A32A0),hex(0x100C1A)
part(V(16,16,18),CF(x,8.4,0),0x8246DC)
part(V(16.6,1.2,18.6),CF(x,16.6,0),0xFFCE28,"Neon")
deco(V(.6,7,9),CF(x+8,5.2,0),ink)
pillar(3,8,V(x-3,21,-4),purple)
pillar(2.2,6,V(x-3,20,4),purple)
local brain=deco(V(7,5.5,7),CF(x+2,20.4,0),0xFF82BE,"Neon","Ball")
new("ParticleEmitter",brain,{Rate=5,Lifetime=NumberRange.new(2,3),Speed=NumberRange.new(3,5),Size=NumberSequence.new(1.5,5),Transparency=NumberSequence.new(.3,1),Color=ColorSequence.new(hex(0xFFAAE6))})
sign(deco(V(17,4.4,.4),CF(x+8.3,12.4,0)*ANG(0,rad(-90),0),0x1E1632),"BRAINROT-O-MATIC",hex(0xFFE25A))
x=X1+8
part(V(10,10,14),CF(x,5.4,0),0xE23E46)
deco(V(.6,6,9),CF(x-5,4.6,0),ink)
for i=-3,3 do
new("WedgePart",into,{Anchored=true,CanCollide=false,Size=V(1.1,1.6,1.1),Color=hex(0xFAFAFA),CFrame=CF(x-5.4,7,i*1.25)*ANG(rad(180),rad(90),0)})
end
sign(deco(V(13,3,.4),CF(x-5.3,12.4,0)*ANG(0,rad(90),0),0x1E1632),"RECYCLER  (too slow!)",hex(0xFF7878))
end
function hideout()
local x,orange=DOOR.X+14,hex(0xFF821E)
sphere(deco(V(34,30,40),CF(x+4,2,0),0x4A465C,"Slate"))
deco(V(1,10,10),CF(x-11.6,5,0),0x0A0810)
for side=-1,1,2 do
pillar(.7,7,V(x-12.4,3.5,side*7),0x5A3C28,"Wood")
new("PointLight",deco(V(1.6,2.2,1.6),CF(x-12.4,7.8,side*7),orange,"Neon","Ball"),{Color=orange,Range=20})
end
sign(deco(V(16,3.6,.4),CF(x-12.2,13.4,0)*ANG(0,rad(90),0),0x1E0A0E),"THIEF HIDEOUT",hex(0xFF4646))
end
function scenery()
for side=-1,1,2 do
pillar(3.4,30,V(-72,15,side*23),0xFF5C8C)
deco(V(5,2,5),CF(-72,30.6,side*23),0xFFCE28,"Neon")
for _,x in {-40,0,40,80} do
lamp(V(x,GY,side*24.6),Color3.fromHSV((x+80)/200,.6,1))
end
for i=0,5 do
palm(V(-88+i*38,GY,side*(66+i%2*5)))
end
end
sign(deco(V(50,9,1.4),CF(-72,26,0)*ANG(0,rad(-90),0),0x301E60),"BRAINROT BAZAAR",hex(0xFFE25A),true)
tent(V(-104,GY,34),-90,hex(0xFF5C5C),"SOCKS (LEFT ONLY)")
tent(V(-104,GY,-34),-90,hex(0x3CAAFF),"PRE-CHEWED GUM")
tent(V(92,GY,40),90,hex(0x50C878),"ANTI-THIEF SPRAY")
tent(V(92,GY,-40),90,hex(0xFFAA28),"SIGMA LEMONADE")
for i=0,13 do
local angle,radius=i/14*math.pi*2,230+i%3*30
sphere(deco(V(150+i%4*30,70+i%5*16,150),CF(math.cos(angle)*radius+10,-6,math.sin(angle)*radius),Color3.fromHSV(.3+i%3*.03,.55,.62+i%2*.08),"Grass"))
end
for i=0,8 do
local at=V(-160+i*44,86+i%3*14,(i%2==0 and -1 or 1)*(90+i%4*28))
for puff=-1,1 do
sphere(deco(V(30-math.abs(puff)*8,13-math.abs(puff)*3,20),CF(at+V(puff*15,0,puff*3)),WHITE)).CastShadow=false
end
end
end
function addPart(shape,size,cf,col,mat,alpha)
size*=scale
cf=CF(cf.Position*scale)*cf.Rotation
local p=Instance.new(shape=="Wedge" and "WedgePart" or "Part")
if shape=="Cyl" then
p.Shape="Cylinder"
size=V(size.Y,size.X,size.Z)
cf*=ANG(0,0,rad(90))
elseif shape=="Ball" then
sphere(p)
end
p.Size,p.CFrame,p.Color,p.Material,p.Transparency=size,cf,col,mat or "SmoothPlastic",alpha or 0
p.CanCollide,p.CanTouch,p.CanQuery,p.Massless,p.CastShadow=false,false,false,true,(alpha or 0)<.3
p.Parent=cur
new("WeldConstraint",p,{Part0=cRoot,Part1=p})
return p
end
function addFace(face)
local s,y,z=face.size,face.y,face.z
for side=-1,1,2 do
addPart("Ball",V(s,s*1.15,s*.5),CF(side*face.gap,y,z),WHITE)
addPart("Ball",V(s*.5,s*.55,s*.3),CF(side*face.gap+side*-.06,y-.05,z-s*.2),BLACK)
end
y-=s*1.1
if face.mouth=="smile" then
addPart("Ball",V(s*1.3,s*.45,s*.3),CF(0,y,z-.02),BLACK)
elseif face.mouth=="o" then
addPart("Ball",V(s*.7,s*.8,s*.3),CF(0,y,z-.02),BLACK)
elseif face.mouth=="teeth" then
addPart("Block",V(s*1.6,s*.6,s*.2),CF(0,y,z-.02),BLACK)
addPart("Block",V(s*1.3,s*.25,s*.22),CF(0,y+s*.14,z-.04),WHITE)
end
end
function addLegs(legs)
for side=-1,1,2 do
addPart("Cyl",V(.5,legs.h,.5),CF(side*legs.spread,legs.h/2+.2,0),legs.col)
addPart("Block",V(1,.5,1.5),CF(side*legs.spread,.25,-.3),legs.shoe)
end
end
function mutate(mdl,mut)
local idx=0
for _,p in mdl:GetChildren() do
if p.Name=="Body" then
idx+=1
if mut=="Golden" then
p.Color,p.Material=hex(0xFFC828):Lerp(p.Color,.15),"Foil"
elseif mut=="Radioactive" then
p.Color,p.Material=hex(0x6EFF32):Lerp(p.Color,.25),"Neon"
else
p.Color,p.Material=Color3.fromHSV(idx*.13%1,.75,1),"Neon"
end
end
end
end
function addBeam(col,ht)
local beam=addPart("Cyl",V(.6,30,.6),CF(0,ht+17,0),col,"Neon",.6)
beam.CastShadow=false
new("PointLight",cRoot,{Color=col,Range=16,Brightness=1.6})
new("ParticleEmitter",cRoot,{Color=ColorSequence.new(col),LightEmission=1,Rate=6,Lifetime=NumberRange.new(1,1.8),Speed=NumberRange.new(2,4),SpreadAngle=Vector2.new(40,40),Size=NumberSequence.new(.9,0)})
end
function Rot.stars(lvl)
return "LVL "..lvl..string.rep("★",lvl)
end
function Rot.setLabel(mdl,mut,inc,extra)
local ent=Cat.ById[mdl.Name]
local gui=mdl.PrimaryPart:FindFirstChild("Label")
if gui then
gui.Rarity.Text=string.upper((mut and mut.." " or "")..ent.rar)
gui.Rarity.TextColor3=ent.col
gui.BrainrotName.Text=ent.name
gui.Money.Text="$"..cash(inc).."/s"
gui.Extra.Text=extra
mdl:SetAttribute("Income",inc)
end
end
function Rot.resize(mdl,factor)
mdl:ScaleTo(factor)
mdl.PrimaryPart.Label.StudsOffsetWorldSpace=V(0,Cat.ById[mdl.Name].ht*SCALE*factor+3.4,0)
end
function Rot.addPrompt(mdl,name,action,object,hold,key,offsetY)
return new("ProximityPrompt",mdl.PrimaryPart.PromptPoint,{Name=name,ActionText=action,ObjectText=object,HoldDuration=hold,KeyboardKeyCode=key or "E",MaxActivationDistance=13,RequiresLineOfSight=false,UIOffset=Vector2.new(0,offsetY or 0),Exclusivity="OnePerButton"})
end
function Rot.clearPrompts(mdl)
for _,child in mdl.PrimaryPart.PromptPoint:GetChildren() do
if child:IsA("ProximityPrompt") then
child:Destroy()
end
end
end
Rot.build=Rot.buildBrainrotPartsFaceLabelAndMutationGlow
function roll()
local roll,rarName,mut=rnd()*100,"Common",nil
for _,name in Cat.RarityOrder do
roll-=Cat.Rarities[name].weight
if roll<=0 then
rarName=name
break
end
end
local pool,chance=Cat.ByRarity[rarName],rnd()
for _,option in Cat.Mutations do
chance-=option.chance
if chance<=0 then
mut=option.id
break
end
end
return pool[rnd(#pool)],mut
end
function beltCF(x,phase)
local wobble=math.sin(os.clock()*3+phase)*.07
return CF(x,BY,0)*ANG(0,rad(-90),0)*ANG(0,wobble*2,wobble)
end
local function moveConveyor(dt)
for idx=#riding,1,-1 do
local it=riding[idx]
it.x+=SPEED*dt
if it.x>=X1 then
table.remove(riding,idx)
it.mdl:Destroy()
else
it.mdl.PrimaryPart.CFrame=beltCF(it.x,it.phase)*CF(0,.5,0)
end
end
end
local function plazaPoint(side)
return V(rnd(-76,78),GY,side*rnd(9,21))
end
function Conveyor.spawnStray()
local pool=Cat.ByRarity.Common
local ent,side=pool[rnd(#pool)],rnd()<.5 and -1 or 1
local mdl=Rot.build(ent)
Rot.setLabel(mdl,nil,ent.inc,"STRAY - FREE!")
local stray={mdl=mdl,ent=ent,side=side,pos=plazaPoint(side),target=plazaPoint(side),pause=0,phase=rnd()*6}
mdl:PivotTo(CF(stray.pos))
mdl.Parent=strayDir
Rot.addPrompt(mdl,"Catch","Catch","Stray "..ent.name.." (free)",.5).Triggered:Connect(function(who)
local at=table.find(strays,stray)
if not at then
return
end
if not Base.giveCarried(who,ent,nil,1) then
return Base.tell(who,"error","Hands full!","Carry your brainrot home first")
end
table.remove(strays,at)
mdl:Destroy()
Base.tell(who,"bought","Caught a stray "..ent.name.."!","Free brainrot. Carry it home!",ent.col)
task.delay(12,Conveyor.spawnStray)
end)
table.insert(strays,stray)
end
local function moveStrays(dt)
local now=os.clock()
for _,stray in strays do
local offset=stray.target-stray.pos
if now<stray.pause then
continue
elseif offset.Magnitude<1 then
stray.pause=now+rnd(1,3)
stray.target=plazaPoint(stray.side)
else
stray.pos+=offset.Unit*math.min(5*dt,offset.Magnitude)
local hop=math.abs(math.sin(now*7+stray.phase))*.9
stray.mdl.PrimaryPart.CFrame=CFrame.lookAt(stray.pos,stray.pos+offset.Unit)*CF(0,.5+hop,0)
end
end
end
function Conveyor.start(world)
beltDir,strayDir=world.dir.Conveyor,world.dir.Strays
for x=X0+14,X1-10,SPEED*DROP_EVERY do
Conveyor.rollRarityAndMutationThenDropOnMovingBelt(x)
end
for _=1,STRAY_COUNT do
Conveyor.spawnStray()
end
Run.Heartbeat:Connect(function(dt)
moveConveyor(dt)
moveStrays(dt)
end)
task.spawn(function()
while task.wait(DROP_EVERY) do
Conveyor.rollRarityAndMutationThenDropOnMovingBelt()
end
end)
end
local world=BazaarWorld.build3DPlazaMovingConveyorAnd8Bases()
Base.init(world)
Conveyor.start(world)
Thieves.start(world)
