local function getF(objects, number)
	for i = 1, #objects do
		for j = 1, #objects[i].v do
			if objects[i].f[j].number == number then
				return objects[i].f[j]
			end
		end
	end
	return nil
end

local function parse(input)
	local v_c = 1
	local vt_c = 1
	local vn_c = 1
	local f_c = 1
	local doShadeSmooth = false
	local currentMaterial = ""
	
	if not(fs.exists(input)) then
		error("Cannot find file: " .. file)
	end
	
	local file =  {
		mtllib = {},
		name = fs.getName(input),
		path = input,
		objects = {}
	}
	
	local function split(str, sep)
		sep = sep or "%S+"
		local line = {}
		for sb in str:gmatch("([^"..sep.."]+)") do
			table.insert(line, sb)
		end
		return line
	end
	
	local function parseFace(face)
		local out = {}
		local faces = split(face, " ")
		out.s = doShadeSmooth
		out.mat = currentMaterial
		for i = 1, #faces do
			local a = split(faces[i], "/")
			if #a == 1 and tonumber(a[1]) < 0 then
				table.insert(out,getF(file.objects, f_c + a[1]))
			elseif #a == 2 then
				table.insert(out, {
					number = f_c,
					mtl = currentMaterial,
					v = tonumber(a[1]),
					vn = tonumber(a[2])
				})
				f_c = f_c + 1
			elseif #a == 3 then
					mtl = currentMaterial,
				table.insert(out, {
					number = f_c,
					v = tonumber(a[1]),
					vt = tonumber(a[2]),
					vn = tonumber(a[3])
				})
				f_c = f_c + 1
			end
		end
		return out
	end
	
	local function createObject(name)
		return {
			o = name,
			v = {},
			vt = {},
			vn = {},
			f = {},
			s = false
		}
	end
	
	local function latest()
		return file.objects[#file.objects]
	end
	
	local function malformed(details)
		error("Malformed file (" .. details .. ")")
	end
	local f = fs.open(input,"r")
	local line
	while true do
		line = f.readLine()
		if line == nil then
			break
		end
		line = line:match("^%s*(.-)%s*$") 
		if line:sub(1,1) ~= "#" then
			if line:lower():find("mtllib") == 1 then
				table.insert(file.mtllib, {
					path = split(line, " ")[2],
					cc = fs.exists(split(line, " ")[2])
				})
			elseif line:lower():find("usemtl") == 1 then
				currentMaterial = split(line, " ")[2] or ""
			elseif line:sub(1,1) == "o" then
				doShadeSmooth = false
				currentMaterial = ""
				table.insert(file.objects, createObject(line:sub(3)))
			elseif line:sub(1,2) == "v " then
				if latest() ~= nil then
					local pt = {
						number = v_c,
						x = tonumber(split(line:sub(3), " ")[1]),
						y = tonumber(split(line:sub(3), " ")[2]),
						z = tonumber(split(line:sub(3), " ")[3])
					}
					v_c = v_c + 1
					table.insert(latest().v,pt)
				else
					malformed("No object associated with vertex")
				end
			elseif line:sub(1,2) == "vt" then
				if latest() ~= nil then
					local pt = {
						number = vt_c,
						x = tonumber(split(line:sub(4), " ")[1]),
						y = tonumber(split(line:sub(4), " ")[2])
					}
					vt_c = vt_c + 1
					table.insert(latest().vt,pt)
				else
					malformed("No object associated with texture coordinate")
				end
			elseif line:sub(1,2) == "vn" then
				if latest() ~= nil then
					local pt = {
						number = vn_c,
						x = tonumber(split(line:sub(4), " ")[1]),
						y = tonumber(split(line:sub(4), " ")[2]),
						z = tonumber(split(line:sub(4), " ")[3])
					}
					vn_c = vn_c + 1
					table.insert(latest().vn,pt)
				else
					malformed("No object associated with vertex normal")
				end
			elseif line:sub(1,2) == "f " then
				if latest() ~= nil then
					table.insert(latest().f,parseFace(line:sub(3)))
				else
					malformed("No object associated with face")
				end
			elseif line:sub(1,1) == "s" then
				if latest() ~= nil then
					doShadeSmooth = (line:sub(3):lower() == "on")
				else
					malformed("No object associated with shading method")
				end
			end
		end
	end
	f.close()
	return file
end

local function getV(objects, number)
	for i = 1, #objects do
		for j = 1, #objects[i].v do
			if objects[i].v[j].number == number then
				return objects[i].v[j]
			end
		end
	end
	return nil
end

local function getVT(objects, number)
	for i = 1, #objects do
		for j = 1, #objects[i].vt do
			if objects[i].vt[j].number == number then
				return objects[i].vt[j]
			end
		end
	end
	return nil
end

local function getVT(objects, number)
	for i = 1, #objects do
		for j = 1, #objects[i].vn do
			if objects[i].vn[j].number == number then
				return objects[i].vn[j]
			end
		end
	end
	return nil
end

local function build(file)
	local output = {}
	local currentObject, face
	if type(file) ~= "table" then
		error("Could not read file object")
	end
	local objects = file.objects
	if type(objects) ~= "table" then
		error("Could not read object data")
	end
	for on = 1, #objects do
		currentObject = objects[on]
		if currentObject == nil or type(currentObject.f) ~= "table" then
			error("Could not get face data")
		end
		for fn = 1, #currentObject.f do
			face = currentObject.f[fn]
			if type(face) ~= "table" then
				error("Invalid face format")
			end
			local fdat = {}
			for fdn = 1, #face do
				vert = getV(objects, face[fdn].v)
				table.insert(fdat, {
					x = vert.x,
					y = vert.y,
					z = vert.z,
				})
			end
			table.insert(output, fdat)
		end
	end
	return output
end

return {
	parse = parse,
	build = build,
	getV = getV,
	getVT = getVT,
	getVN = getVN,
	getF = getF
}
