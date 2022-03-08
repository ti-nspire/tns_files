-----------------
-- How to play --
-----------------
-- To start or pause, press the Enter key.     
-- To reset, press the ESC key.    
-- To throw one of regular polygons into the sim-space, press the space bar.



-- 正多角形クラス pRegPoly も作っておく。
-- static な囲い（fence()）、static な連続線分（polyLine()）も作れるようにしておく。
require "physics"; require "color"

-----------------------
-- general functions --
-----------------------
function pV(x, y)  return physics.Vect(x, y) end
function sum(list) local result = ZERO for _, v in ipairs(list) do result = result + v end return result end
---------------------------------------------------
---------------------------------------------------

function on.resize()
   W, H = platform.window:width(), platform.window:height()
   X0, Y0, UNIT = W/2, H/2, math.floor(W/60)
end

platform.window:setBackgroundColor(color.navy)
TICKING = false
GRID = false
spaceDamping = nil --0.9
VLimit = nil --math.huge
ZERO = pV(0, 0)
LARGE = physics.misc.INFINITY()
dtLua = 1/(2^6)
dtChipmunk = 1/(2^6)
GRAVITY = -10
COLOR = { -- 参考: http://www.colordic.org
--[[パステルカラー--]]0xFF7F7F, 0xFF7FBF, 0xFF7FFF, 0xBF7FFF, 0x7F7FFF, 0x7FBFFF, 0x7FFFFF, 0x7FFFBF, 0x7FFF7F, 0xBFFF7F, 0xFFFF7F, 0xFFBF7F, 
--[[ビビッドカラー--]]0xFF6060, 0xFF60AF, 0xFF60FF, 0xAF60FF, 0x6060FF, 0x60AFFF, 0x60FFFF, 0x60FFAF, 0x60FF60, 0xAFFF60, 0xFFFF60, 0xFFAF60,
--[[モノトーン--]]0x5E5E5E, 0x7E7E7E, 0x9E9E9E, 0xBEBEBE, 0xDEDEDE, 0xFEFEFE, 
--[[メトロカラー--]]0x0078BA, 0x0079C2, 0x009944, 0x00A0DE, 0x00A7DB, 0x00ADA9, 0x019A66, 0x522886, 0x6CBB5A, 0x814721, 0x9B7CB6, 0x9CAEB7, 0xA9CC51, 0xB6007A, 0xBB641D, 0xD7C447, 0xE44D93, 0xE5171F, 0xE60012, 0xE85298, 0xEE7B1A, 0xF39700, 
}

-----------------
-- pBall class --
-----------------
pBall = class()
function pBall:init(mass, radius, elasticity, friction, color, group)
   self.color = color or color.black
   local inertia = physics.misc.momentForCircle(mass, 0, radius, ZERO)
   self.body = physics.Body(mass, inertia)
   if VLimit then self.body:setVLimit(VLimit) end
   self.shape = physics.CircleShape(self.body, radius, ZERO)
      :setRestitution(elasticity or 0.8)
      :setFriction(friction or 0.8)
   if group then self.shape:setGroup(group) end
end
function pBall:paint(gc)
   local pos = self.body:pos()
   local cx, cy = X0 + UNIT * pos:x(), Y0 - UNIT * pos:y()
   local radius = UNIT * self.shape:radius()
   local diameter = radius + radius
   local angle = self.body:angle()
   local x0, y0 = cx - radius, cy - radius  
   gc:setColorRGB(self.color)
   gc:fillArc(x0, y0, diameter, diameter, 0, 360)
   gc:setColorRGB(color.black)
   gc:setPen("thin")
   gc:drawArc(x0, y0, diameter, diameter, 0, 360)
   gc:drawLine(cx, cy, cx + radius * math.cos(angle), cy - radius * math.sin(angle))
end

----------------
-- pBox class --
----------------
pBox = class()
function pBox:init(mass, width, height, elasticity, friction, color, group)
   self.color = color or color.black
   local inertia = physics.misc.momentForBox(mass, width, height)
   self.body = physics.Body(mass, inertia)
   if VLimit then self.body:setVLimit(VLimit) end
   local verts = {pV(-width/2, -height/2), pV(-width/2, height/2), pV(width/2, height/2), pV(width/2, -height/2)}
   self.shape = physics.PolyShape(self.body, verts, ZERO)
      :setRestitution(elasticity or 0.8)
      :setFriction(friction or 0.8)
   if group then self.shape:setGroup(group) end
end
function pBox:paint(gc)
   local numVerts = self.shape:numVerts()
   local verts = {}
   for i = 1, numVerts + 1 do
      local j = i; if i > numVerts then j = 1 end
      local points = self.shape:points()[j]
      table.insert(verts, X0 + UNIT * points:x())
      table.insert(verts, Y0 - UNIT * points:y())
   end
   gc:setColorRGB(self.color)
   gc:fillPolygon(verts)
   gc:setPen("thin")
   gc:setColorRGB(color.black)
   gc:drawPolyLine(verts)
end

--------------------
-- pRegPoly class --
--------------------
pRegPoly = class(pBox)
function pRegPoly:init(mass, radius, numVerts, elasticity, friction, color, group)
   self.color = color or color.black
   local unitAngle = 2 * math.pi/numVerts
   local verts = {pV(radius, 0)}
   for i = 1, numVerts - 1 do
      table.insert(verts, pV(radius * math.cos(unitAngle * i), -radius * math.sin(unitAngle * i)))
   end
   local inertia = physics.misc.momentForPoly(mass, verts, ZERO)
   self.body = physics.Body(mass, inertia)
      :setAngle(math.pi/2)
   if VLimit then self.body:setVLimit(VLimit) end
   self.shape = physics.PolyShape(self.body, verts, ZERO)
      :setRestitution(elasticity or 0.8)
      :setFriction(friction or 0.8)
   if group then self.shape:setGroup(group) end
end

----------------------
-- pStaticSeg class --
----------------------
pStaticSeg = class()
function pStaticSeg:init(x1, y1, x2, y2, radius, elasticity, friction, color, group)
   self.color = color or color.black
   local avec, bvec = pV(x1, y1),  pV(x2, y2)
   self.shape = physics.SegmentShape(nil, avec, bvec, radius)
      :setRestitution(elasticity or 0.8)
      :setFriction(friction or 0.8)
   if group then self.shape:setGroup(group) end
end
function pStaticSeg:paint(gc)
   local pos1 = self.shape:a()
   local x1, y1 = X0 + UNIT * pos1:x(), Y0 - UNIT * pos1:y()
   local pos2 = self.shape:b()
   local x2, y2 = X0 + UNIT * pos2:x(), Y0 - UNIT * pos2:y()
   gc:setColorRGB(self.color)
   gc:setPen("thin")
   gc:drawLine(x1, y1, x2, y2)
end

------------------
-- pSpace class --
------------------
pSpace = class()
function pSpace:init(GRAVITY)
   self.space = physics.Space()
      :setGravity(pV(0, GRAVITY))
   if spaceDamping then self.space:setDamping(spaceDamping) end
   self.objects = {}
end
function pSpace:step(DT)
   self.space:step(DT)
end
function pSpace:addObj(obj, velx, vely, cx, cy)
   obj.body:setVel(pV(velx or 0, vely or 0))
      :setPos(pV(cx or W/2, cy or H/2))
   self.space:addBody(obj.body)
      :addShape(obj.shape)
   table.insert(self.objects, obj)
end
function pSpace:addStatic(obj, cx, cy)
   if obj.body then obj.body:setPos(pV(cx or W/2, cy or H/2)) end
   self.space:addStaticShape(obj.shape)
   table.insert(self.objects, obj)
end
function pSpace:attractBetween()
   local forceTable = {}
   for r = 1, #self.objects do
      forceTable[r] = {}
      for c = 1, #self.objects do
         if r == c then
            forceTable[r][c] = ZERO
         elseif r > c then
            forceTable[r][c] = -forceTable[c][r]
         else
            local posA = self.objects[r].body:pos()
            local posB = self.objects[c].body:pos()
            local massA = self.objects[r].body:mass()
            local massB = self.objects[c].body:mass()
            local vectAB = posB - posA
            local lengthABsq = vectAB:lengthsq()
            local normAB = vectAB:normalize()
            forceTable[r][c] = normAB:mult(massA * massB/lengthABsq)
         end
      end
      self.objects[r].body:setForce(sum(forceTable[r]))
   end
end
function pSpace:paint(gc)
   gc:setColorRGB(color.gray)
   if GRAVITY ~= 0 then gc:drawString(string.format("acceleration of gravity: %3.1f", -GRAVITY), 5, -3, "top") end
   gc:drawString(string.format("t = %5.1f", timeElapsed), W - 70, -3, "top")
   for _, v in ipairs(self.objects) do
      v:paint(gc)
   end
end

----------------
-- Grid class --
----------------
Grid = class()
function Grid:init() end
function Grid:paint(gc)
   gc:setPen("thin")
   gc:setColorRGB(0x6495ED)
   gc:drawLine(0, Y0, W, Y0)
   gc:drawLine(X0, 0, X0, H)
   gc:fillPolygon({W, Y0, W - 7, Y0 - 4, W - 3, Y0, W - 7, Y0 + 4, W, Y0})
   gc:fillPolygon({X0, 0, X0 - 4, 7, X0, 3, X0 + 4, 7, X0, 0})
   gc:setColorRGB(0xCAE1FF)
   local i1 = 1; while Y0 - UNIT * i1 > 0 do gc:drawLine(0, Y0 - UNIT * i1, W, Y0 - UNIT * i1); i1 = i1 + 1 end
   local i2 = 1; while Y0 + UNIT * i2 < H do gc:drawLine(0, Y0 + UNIT * i2, W, Y0 + UNIT * i2); i2 = i2 + 1 end   
   local i3 = 1; while X0 + UNIT * i3 < W do gc:drawLine(X0 + UNIT * i3, 0, X0 + UNIT * i3, H); i3 = i3 + 1 end   
   local i4 = 1; while X0 - UNIT * i4 > 0 do gc:drawLine(X0 - UNIT * i4, 0, X0 - UNIT * i4, H); i4 = i4 + 1 end
   gc:setColorRGB(0x6495ED)
   gc:drawString("x", W - 10, Y0 - 21)
   gc:drawString("y", X0 + 5, -6)
end

-----------
-- fence --
-----------
function fence(x1, y1, x2, y2, radius, elasticity, friction) -- スクリーン座標(左上 x, y, 右下 x, y, radius, elasticity, friction)で指定する。
   local color = color.black
   local a1, a2, a3, a4 = ((x1 - UNIT * radius) - X0)/UNIT, (Y0 - (y1 - UNIT * radius))/UNIT, (Y0 - (y2 + UNIT * radius))/UNIT, ((x2 + UNIT * radius) - X0)/UNIT -- 厚みのぶんだけ外側へずらす。
   local walls = {
      pStaticSeg(a1, a2, a1, a3, radius, elasticity, friction, color),
      pStaticSeg(a1, a3, a4, a3, radius, elasticity, friction, color),
      pStaticSeg(a4, a3, a4, a2, radius, elasticity, friction, color),
      pStaticSeg(a4, a2, a1, a2, radius, elasticity, friction, color)
   }
   for _, v in ipairs(walls) do space:addStatic(v) end
end

--------------
-- polyLine --
--------------
function polyLine(xyList, radius, elasticity, friction, color) -- ({x1, y1, x2, y2, ..., xn, yn}, radius, elasticity, friction, color)
   local lines = {}
   for i = 1, #xyList - 2, 2 do
      lines[i] = pStaticSeg(xyList[i], xyList[i+1], xyList[i+2], xyList[i+3], radius, elasticity, friction, color)
      space:addStatic(lines[i])
   end
end

------------------
-- 確かめてみる --
------------------
function reset()
   on.resize()
   timeElapsed = 0
   if GRID then grid = Grid() end
   space = pSpace(GRAVITY)
   fence(0, 0, W, H, 100, 1, 0) -- fence はスクリーン座標(左上 x, y, 右下 x, y, radius, elasticity, friction)で指定する。すり抜けないように極端に分厚くしておく。
   polyLine({-12, -3, -8, -8, 8, -8, 12, -3}, 0.3, 1, 0, color.gray) -- ({x1, y1, x2, y2, ..., xn, yn}, radius, elasticity, friction, color)
end   
function on.charIn(char)
   if char == " " then
      polygon = pRegPoly(math.random(1, 10), math.random(40, 200)/100, math.random(3, 7), 1, 0, COLOR[math.random(#COLOR)])
      space:addObj(polygon, 0, 0, 0, 10)
   end
   platform.window:invalidate()   
end
----------------------------------------------------------
----------------------------------------------------------

function on.construction() reset() end
function on.escapeKey()    reset() end
function on.paint(gc)
   if grid  then grid:paint(gc)  end
   space:paint(gc)
end
function on.timer()
   space:step(dtChipmunk)
   timeElapsed = timeElapsed + dtChipmunk
   platform.window:invalidate()
end
function on.enterKey()
   if     TICKING == false then timer.start(dtLua) TICKING = true
   elseif TICKING == true  then timer.stop()       TICKING = false
   end
end
