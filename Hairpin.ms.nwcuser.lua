local user = nwcdraw.user

local function draw_Hairpin()
	local function parseCoords(obj, def)
		local _ = user:userProp(obj) or def
		return tonumber(_:match("([%.%-%d]+),")), tonumber(_:match(",([%.%-%d]+)"))
	end

	local penstyle = user:userProp("Pen") or "solid"
	local thickness = 240
	nwcdraw.setPen(penstyle, thickness)
	
	local hairpintype = string.lower(user:userProp("Type")) or "cresc" -- types are cresc, decresc
	local span = math.floor(tonumber(user:userProp("Span")) or 1)
	local leftoffset = tonumber(user:userProp("LeftOffset")) or -0.5
	local rightoffset_x, rightoffset_y = parseCoords("RightOffset", "0.25,0")
	local gap = tonumber(user:userProp("Gap")) or 2.5
	
	user:find("next","noteOrRest")
	if not user then return end
	local x1 = user:xyAnchor()
	
	while span > 1 do
		user:find("next","noteOrRest")
		span = span - 1
	end

	local x2 = rightoffset_x + user:xyRight()
	
	local leftgap, rightgap = 0, 0
	if hairpintype == "cresc" then rightgap = gap / 2 else leftgap = gap / 2 end
	nwcdraw.line(x1+leftoffset, -leftgap, x2, rightoffset_y - rightgap)
	nwcdraw.line(x1+leftoffset, leftgap, x2, rightoffset_y + rightgap)
end

local function spin_Hairpin(t,dir)
	local v = tonumber(t.Span) or 1
	v = math.max(v + dir, 1)
	t.Span = v
end

local function create_Hairpin(t)
	t.Span = 1
	t.Type = 'cresc'
	t.Pen = 'solid'
	t.LeftOffset = -0.5
	t.RightOffset = "0.25,0"
	t.Gap = 2.5
end

return {
	create = create_Hairpin,
	spin = spin_Hairpin,
	draw = draw_Hairpin
	}