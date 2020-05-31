local obj = require('obj')

--Math
local function round(n)
    return n < 0 and math.ceil(n - 0.5) or math.floor(n + 0.5)
end

local function getDist(x1,y1,z1,x2,y2,z2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

--Display
local function color2blit(color)
    return ("0123456789abcdef"):sub(math.log(color,2)+1, math.log(color,2)+1)
end

local function createCanvas(x, y, w, h)
	if x == nil then 
		x = 1
		y = 1
		w, h = term.getSize()
	end
	
	local canvas = {
		x = x,
		y = y,
		w = w,
		h = h,
		termObj = term.current(),
		tBuffer1 = {},
		objects = {},
		display = {},
		Xc = 0,
		Yc = -10,
		Zc = -10
	}
	
	paintutils.drawFilledBox(x,y,x+w,y+h,canvas.termObj.getBackgroundColor())
	
	for i = 1, h do
		table.insert(canvas.tBuffer1, (color2blit(canvas.termObj.getBackgroundColor())):rep(w))
		table.insert(canvas.display, (color2blit(canvas.termObj.getBackgroundColor())):rep(w))
	end
	
	local function isOccupied(buffer, x, y)
		if color2blit(canvas.termObj.getBackgroundColor()) == buffer[y]:sub(x,x) then
			return false
		elseif buffer[y]:sub(x,x) == " " then
			return false
		else
			return true
		end
	end

	local function set(tBuffer, x, y, color)
		x = round(x)
		y = round(y)
		if color == nil then
		
		end
		if type(color) == "number" then
			color = color2blit(color)
		end
		if x < 1 then
			return
		end
	
		if tBuffer[y] == nil then
			return
		end
    
		if isOccupied(tBuffer, x, y) then
			return
		end
    
		if x == 1 then
			tBuffer[y] = color .. tBuffer[y]:sub(2)
		elseif x == canvas.w then
			tBuffer[y] = tBuffer[y]:sub(1, tBuffer[y]:len() - 1) .. color
		else
			tBuffer[y] = tBuffer[y]:sub(1,x-1) .. color .. tBuffer[y]:sub(x+1)
		end
	end

	local function createLine(_x, _y, _x2, _y2, _color)
		local line = {
			type = "line",
			x = _x,
			y = _y,
			x2 = _x2,
			y2 = _y2,
			z = 0,
			color = _color or 0
		}
		table.insert(canvas.objects,line)
	end
	
	local function drawPoint(x, y, color)
		set(canvas.tBuffer1,x,y,color)
	end

	local function drawLine(x, y, x2, y2, color)
		if x == nil or x2 == nil or y == nil or y2 == nil then
			return
		end
		color = color or 0
		local org = {x,y,x2,y2}
		local w = x2 - x
		local h = y2 - y
		local dx1 = 0
		local dy1 = 0
		local dx2 = 0
		local dy2 = 0
		if w < 0 then dx1 = -1 elseif w > 0 then dx1 = 1 end
		if h < 0 then dy1 = -1 elseif h > 0 then dy1 = 1 end
		if w < 0 then dx2 = -1 elseif w > 0 then dx2 = 1 end
		local longest = math.abs(w)
		local shortest = math.abs(h)
		if not(longest > shortest) then
			longest = math.abs(h)
			shortest = math.abs(w)
			if h < 0 then dy2 = -1 elseif h > 0 then dy2 = 1 end
			dx2 = 0
		end
		local numerator = bit32.rshift(longest, 1)
		local pixels = {}
		for i = 0, longest do
			table.insert(pixels, {x,y,color})
			numerator = numerator + shortest
			if not(numerator < longest) then
				numerator = numerator - longest
				x = x + dx1
				y = y + dy1
			else
				x = x + dx2
				y = y + dy2
			end
		end
    
		for i = 1, #pixels do
			set(canvas.tBuffer1,pixels[i][1],pixels[i][2],pixels[i][3])
		end
	end
	
	local function createTriangle(_x1,_y1,_z1,_x2,_y2,_z2,_x3,_y3,_z3,_color)
		local tri = {
			type = "triangle",
			x1 = _x1,
			y1 = _y1,
			z1 = _z1,
			x2 = _x2,
			y2 = _y2,
			z2 = _z2,
			x3 = _x3,
			y3 = _y3,
			z3 = _z3,
			z = math.max(_z1,_z2,_z3),
			color = _color or 0
		}
		table.insert(canvas.objects, tri)
	end

	--3D handling
	local function getPoint(oX, oY, oZ)
		local X = oX + canvas.Xc
		local Y = oY + canvas.Yc
		local Z = oZ + canvas.Zc
		local sw = canvas.w
		local sh = canvas.h
		if canvas.termObj.getGraphicsMode then
			if canvas.termObj.getGraphicsMode() then
				if sw == 51 and sh == 19 then
					sw = 305
					sh = 170
				else
					sw = 1000
					sh = 500
				end
			end
		end
		
		local persX = X / Z
		local persY = Y / Z

		local ndcX = (persX + 1) / 2
		local ndcY = (persY + 1) / 2

		if ndcY > sh then
			return {
				x = nil,
				y = nil
			}
		end
		
		if Z >= 0 then
			return {
				x = nil,
				y = nil
			}
		end

		local rasX = ndcX * sw
		local rasY = ndcY * sh
		return {
			x = rasX,
			y = rasY
		}
	end

	local function createBox(x, y, z, l, w, h, color)
		local model = {}
		model.type = "box"
		model.x = x
		model.y = y
		model.z = z * -1
		model.l = l
		model.w = w
		model.h = h
		model.color = color or colors.white
		table.insert(canvas.objects, model)
	end
	
	local function loadObj(built, color)
		if type(built) ~= "table" then
			error("Invalid build format. Did you use objlib build?")
		end
		table.insert(canvas.objects, {
			type = "object",
			color = color or 0,
			verticies = built
		})
	end
	
	local function drawObj(obj)
		for a = 1, #obj.verticies do
			--faces
			for b = 1, #obj.verticies[a] do
				--face verts
				local p1, p2
				p1 = getPoint(obj.verticies[a][b].x, obj.verticies[a][b].y, obj.verticies[a][b].z)
				if obj.verticies[a][b+1] == nil then
					p2 = getPoint(obj.verticies[a][1].x, obj.verticies[a][1].y, obj.verticies[a][1].z)
				else
					p2 = getPoint(obj.verticies[a][b+1].x, obj.verticies[a][b+1].y, obj.verticies[a][b+1].z)
				end
				drawLine(p1.x,p1.y,p2.x,p2.y, obj.color)
			end
		end
	end
	
	local function createOpenPoly(...)
		local polygon = {
			type = "opolygon",
			verticies = {}
		}
		local args = {...}
		local color = 0
		local start = 1
		if type(args[1]) == "number" then
			color = args[1]
			start = 2
		end
		for i = start, #args do
			if type(args[i]) ~= "table" then
				error("Invalid point format, Use {x, y, z} for each point")
			else
				table.insert(polygon.verticies, {
					x = args[i][1],
					y = args[i][2],
					z = args[i][3]
				})
			end
		end
		polygon.color = color
		table.insert(canvas.objects,polygon)
	end

	
	local function createPoly(...)
		local polygon = {
			type = "polygon",
			verticies = {}
		}
		local args = {...}
		local color = 0
		local start = 1
		if type(args[1]) == "number" then
			color = args[1]
			start = 2
		end
		for i = start, #args do
			if type(args[i]) ~= "table" then
				error("Invalid point format, Use {x, y, z} for each point")
			else
				table.insert(polygon.verticies, {
					x = args[i][1],
					y = args[i][2],
					z = args[i][3]
				})
			end
		end
		polygon.color = color
		table.insert(canvas.objects,polygon)
	end
	
	local function drawPoly(poly)
		--[[
			Format:
			{
				type "polygon"
				verticies {
					{
					x,
					y,
					z
					},
					...
				}
			}
		]]
		local points = {}
		if poly.verticies == nil then
			error("Malformed poly object, cannot draw")
		end
		for i = 1, #poly.verticies do
			pt = poly.verticies[i]
			table.insert(points, getPoint(pt.x, pt.y, pt.z))
		end
		for i = 1, #points do
			if i < #points then
				drawLine(points[i].x, points[i].y, points[i+1].x, points[i+1].y, poly.color)
			else
				drawLine(points[i].x, points[i].y, points[1].x, points[1].y, poly.color)
			end
		end
	end
	
	local function drawOpenPoly(poly)
		local points = {}
		if poly.verticies == nil then
			error("Malformed poly object, cannot draw")
		end
		for i = 1, #poly.verticies do
			pt = poly.verticies[i]
			table.insert(points, getPoint(pt.x, pt.y, pt.z))
		end
		for i = 1, #points do
			if i < #points then
				drawLine(points[i].x, points[i].y, points[i+1].x, points[i+1].y, poly.color)
			end
		end
	end
	
	local function drawTriangle(tri)
		local p1 = getPoint(tri.x1,tri.y1,tri.z1)
		local p2 = getPoint(tri.x2,tri.y2,tri.z2)
		local p3 = getPoint(tri.x3,tri.y3,tri.z3)
		drawLine(p1.x,p1.y,p2.x,p2.y,tri.color)
		drawLine(p2.x,p2.y,p3.x,p3.y,tri.color)
		drawLine(p3.x,p3.y,p1.x,p1.y,tri.color)
	end

	local function drawBox(cm)
		local point1 = getPoint(cm.x, cm.y, cm.z)
		local point2 = getPoint(cm.x + cm.l, cm.y, cm.z)
		local point3 = getPoint(cm.x, cm.y + cm.w, cm.z)
		local point4 = getPoint(cm.x + cm.l, cm.y + cm.w, cm.z)
		local point5 = getPoint(cm.x, cm.y, cm.z + cm.h)
		local point6 = getPoint(cm.x + cm.l, cm.y, cm.z + cm.h)
		local point7 = getPoint(cm.x, cm.y + cm.w, cm.z + cm.h)
		local point8 = getPoint(cm.x + cm.l, cm.y + cm.w, cm.z + cm.h)
		drawLine(point1.x, point1.y, point2.x, point2.y, cm.color)
		drawLine(point1.x, point1.y, point3.x, point3.y, cm.color)
		drawLine(point1.x, point1.y, point5.x, point5.y, cm.color)
		drawLine(point2.x, point2.y, point4.x, point4.y, cm.color)
		drawLine(point2.x, point2.y, point6.x, point6.y, cm.color)
		drawLine(point3.x, point3.y, point4.x, point4.y, cm.color)
		drawLine(point3.x, point3.y, point7.x, point7.y, cm.color)
		drawLine(point4.x, point4.y, point8.x, point8.y, cm.color)
		drawLine(point5.x, point5.y, point6.x, point6.y, cm.color)
		drawLine(point5.x, point5.y, point7.x, point7.y, cm.color)
		drawLine(point6.x, point6.y, point8.x, point8.y, cm.color)
		drawLine(point7.x, point7.y, point8.x, point8.y, cm.color)
	end
	
	local function createInternalCanvas(x, y, z, w, h)
		local ic
		if x == nil then
			ic = createCanvas(canvas.x, canvas.y, canvas.w, canvas. h)
		else
			ic = createCanvas(canvas.x + x - 1, canvas.y + y - 1, w, h)
		end
		local obj = {
			type = "canvas",
			x = x,
			y = y,
			z = z,
			w = w,
			h = h,
			object = ic
		}
		table.insert(canvas.objects, obj)
		return ic
	end
	
	local function drawInternalCanvas(parent, canv)
		local sx = 1
		local sy = 1
		canv.object.bdraw(true)
		for yp = canv.y, canv.h do
			for xp = canv.x, canv.w do
				if parent.tBuffer1 ~= nil then
					set(parent.tBuffer1, xp, yp, (canv.object.tBuffer1[sy]:sub(sx,sx) or ' '))
				else
					set(parent.object.tBuffer1, xp, yp, (canv.object.tBuffer1[sy]:sub(sx,sx) or ' '))
				end
				sx = sx + 1
			end
			sx = 1
			sy = sy + 1
		end
	end
	
	--Engine
	local function moveCamera(dx, dy, dz)
		canvas.Xc = canvas.Xc + dx
		canvas.Yc = canvas.Yc - dy
		canvas.Zc = canvas.Zc + dz
	end

	local function oget(otype)
		local obs = {}
		for i = 1, #canvas.objects do
			if otype == canvas.objects[i].type then
				table.insert(obs, i)
			end
		end
		return obs
	end

	local function oclear(otype)
		if otype == nil then
			canvas.objects = {}
			return
		end
		for i = 1, #canvas.objects do
			if canvas.objects[i].type == otype then
				table.remove(canvas.objects, otype)
			end
		end
	end

	local function bflush()
		for i = 1, #canvas.objects do
			if canvas.objects[i].type == "canvas" then
				--Uncommenting this will make the other canvases render seperately
				--canvas.objects[i].object.bflush()
			end
		end
		for i = 1, #canvas.tBuffer1 do
			if canvas.tBuffer1[i] ~= canvas.display[i] then
				for cxp = 1, canvas.w do
					if canvas.display[i]:sub(cxp,cxp) ~= canvas.tBuffer1[i]:sub(cxp,cxp) then
						canvas.termObj.setCursorPos(canvas.x + cxp - 1,canvas.y+i-1)
						canvas.display[i] = canvas.display[i]:sub(1,cxp-1) .. canvas.tBuffer1[i]:sub(cxp,cxp) .. canvas.display[i]:sub(cxp+1)
						canvas.termObj.blit(canvas.display[i]:sub(cxp,cxp),canvas.display[i]:sub(cxp,cxp),canvas.display[i]:sub(cxp,cxp))
					end
				end
				canvas.display[i] = canvas.tBuffer1[i]
				--canvas.termObj.setCursorPos(x,y+i-1)
				--canvas.termObj.blit(canvas.display[i], canvas.display[i], canvas.display[i]);
			end
		end
	end

	local function bclear(color)
		color = color2blit(color or colors.black)
		for i = 1, h do
			canvas.tBuffer1[i] = (color):rep(w)
		end
	end

	local function bdraw(clear, child)
		if clear then
			canvas.bclear(canvas.termObj.getBackgroundColor())
		end
		--for i = 1, #canvas.objects do
		--	if canvas.objects[i].type == "canvas" then
		--		canvas.objects[i].object.bdraw()
		--	end
		--end
		if #canvas.objects >= 2 then
			table.sort(canvas.objects, function(a, b)
				if a.z == nil or b.z == nil then
					return true
				end
				return a.z > b.z
			end)
		end
		for i = 1, #canvas.objects do
			if canvas.objects[i].type == "box" then
				drawBox(canvas.objects[i])
			elseif canvas.objects[i].type == "line" then
				drawLine(canvas.objects[i].x,canvas.objects[i].y,canvas.objects[i].x2,canvas.objects[i].y2,canvas.objects[i].color)
			elseif canvas.objects[i].type == "triangle" then
				drawTriangle(canvas.objects[i])
			elseif canvas.objects[i].type == "polygon" then
				drawPoly(canvas.objects[i])
			elseif canvas.objects[i].type == "opolygon" then
				drawOpenPoly(canvas.objects[i])
			elseif canvas.objects[i].type == "object" then
				drawObj(canvas.objects[i])
			elseif canvas.objects[i].type == "canvas" then
				drawInternalCanvas(canvas, canvas.objects[i])
			end
		end
	end

	local function screenshot(clear)
		if not(fs.isDir("/sauce")) then
			fs.makeDir("/sauce")
		end
		local save = fs.open("/sauce/screenshot_" .. os.date("%Y%m%d%H%M%S") .. ".nfp", "w")
		if clear then
			local row = ""
			for i = 1, #canvas.display do
				save.write(canvas.display[i]:gsub(color2blit(canvas.termObj.getBackgroundColor()), " ") .. "\n")
			end
		else
			for i = 1, #canvas.display do
				save.write(canvas.display[i] .. "\n")
			end
		end
		save.close()
	end
	
	local function setTerminal(to)
		if type(to) == "table" then
			if to.blit and to.getBackgroundColor and to.setBackgroundColor and to.setCursorPos and to.getCursorPos and to.setTextColor and to.getSize and to.getTextColor then
				canvas.termObj = to
			end
		end
	end
	
	local function moveTo(x, y)
		paintutils.drawFilledBox(x,y,x+canvas.w,y+canvas.h,canvas.termObj.getBackgroundColor())
		canvas.x = x
		canvas.y = y
		canvas.bflush(true)
	end
	
	local function resize(w, h)
		paintutils.drawFilledBox(x,y,x+w,y+h,canvas.termObj.getBackgroundColor())
		canvas.w = w
		canvas.h = h
		canvas.bflush(true)
	end
	
	local function UIBasic(...)
		local values = {...}
		local out = ""
		for i = 1, #values do
			out = out .. values[i]
			if i < #values then out = out .. " " end
		end
		local t = canvas.termObj.getTextColor()
		local b = canvas.termObj.getBackgroundColor()
		canvas.termObj.setTextColor(colors.black)
		canvas.termObj.setBackgroundColor(colors.lightGray)
		canvas.termObj.setCursorPos(canvas.x,canvas.y)
		canvas.termObj.write((" "):rep(canvas.w))
		canvas.termObj.setCursorPos(canvas.x,canvas.y)
		canvas.termObj.write("[Sauce Engine] " .. out)
		canvas.termObj.setCursorPos(canvas.x,canvas.y+1)
		canvas.termObj.setTextColor(t)
		canvas.termObj.setBackgroundColor(b)
		canvas.termObj.setCursorPos(canvas.x,canvas.y)
	end
	canvas.createLine = createLine
	canvas.createBox = createBox
	canvas.createInternalCanvas = createInternalCanvas
	canvas.createTriangle = createTriangle
	canvas.createPoly = createPoly
	canvas.createOpenPoly = createOpenPoly
	canvas.loadObj = loadObj
	canvas.screenshot = screenshot
	canvas.moveCamera = moveCamera
	canvas.bdraw = bdraw
	canvas.bclear = bclear
	canvas.bflush = bflush
	canvas.oget = oget
	canvas.oclear = oclear
	canvas.UIBasic = UIBasic
	canvas.setTerminal = setTerminal
	canvas.moveTo = moveTo
	canvas.resize = resize
	return canvas
end

local function demo(canv)
	local canv = canv or createCanvas(5,5,102,38)
	local inside = canv.createInternalCanvas(1,3,1,30,5)
	inside.createLine(1,2,30,2,colors.red)
	inside.createLine(1,3,30,3,colors.lightBlue)
	canv.createBox(5,5,20,8,8,8,colors.red)
	canv.createBox(5,5,10,8,8,8,colors.orange)
	canv.createBox(15,5,10,8,8,8,colors.yellow)
	canv.createBox(-5,5,10,8,8,8,colors.yellow)
	while true do
		canv.bdraw(true)
		canv.bflush()
		canv.UIBasic(canv.Xc, canv.Yc, canv.Zc)
		inside.UIBasic("UI Demo")
		local event, a, b, c = os.pullEvent()
		if event == "key" then
			if a == keys.delete then
				break
			elseif a == keys.a then
				canv.moveCamera(-1,0,0)
			elseif a == keys.d then
				canv.moveCamera(1,0,0)
			elseif a == keys.w then
				canv.moveCamera(0,0,1)
			elseif a == keys.s then
				canv.moveCamera(0,0,-1)
			elseif a == keys.space then
				canv.moveCamera(0,1,0)
			elseif a == keys.leftShift then
				canv.moveCamera(0,-1,0)
			elseif a == keys.p then
				canv.screenshot()
			end
		end
	end
end

return {
	createCanvas = createCanvas,
	color2blit = color2blit,
	demo = demo,
	objlib = obj
}
