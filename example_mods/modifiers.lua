local arrow_size = 112
moddata = {
	any = {
		magnitude = 0,
		offset = 0,
		level = 0
	},
	log = {
		magnitude = 0,
		offset = 1,
		base = 1
	}
}
function GetXPos(col, yoff, xoff)
	return getPos(col, yoff, xoff).x
end
function GetYPos(col, yoff, xoff)
	return getPos(col, yoff, xoff).y
end
function GetZPos(col, yoff, xoff)
	return getPos(col, yoff, xoff).z
end
function GetScaleX(col, yoff)
	return getScale(col, yoff).x - 1
end
function GetScaleY(col, yoff)
	return getScale(col, yoff).y - 1
end
function GetScaleZ(col, yoff)
	return getScale(col, yoff).z - 1
end
function getPos(col, yoff, xoff)
	local pos = {x = 0, y = 0, z = 0}
  if moddata.any.magnitude ~= 0 then
    pos.x = pos.x + math.pow((yoff + 2 * moddata.any.offset) / arrow_size, moddata.any.level) * 2 * moddata.any.magnitude;
  end
	if moddata.log.magnitude ~= 0 then
		pos.x = pos.x + math.log(math.abs((yoff + 2 * moddata.log.offset) / arrow_size), moddata.log.base) * arrow_size * moddata.log.magnitude
	end
	return pos
end
function getScale(col, yoff)
	local scale = {x = 1, y = 1, z = 1}
	return scale
end
function initDefines()
	for name, mods in pairs(moddata) do
		for subname, value in pairs(mods) do
			local rs = subname
			if rs == 'magnitude' then
				rs = ''
			end
			definemod{name..rs,function(a)
				moddata[name][subname] = a
			end}
		end
	end
end
