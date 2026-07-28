-- Version 0.1

--[[----------------------------------------------------------------
Synamatic.ms

This object plugin automatically draws synalepha slurs beneath lyric syllables that contain
underscore characters. These marks are used when two adjacent syllables end and begin with a 
vowel sound, and are sung as a single syllable.

Only a single Synamatic object is required. Simply add it to the start of any staff
with lyrics, and the rest is automatic.

You can turn off Synamatic at any point in a staff by adding a new Synamatic object,
then assigning its Visibility to Never.

@Overlap
The amount of overlap of the synalepha slur on the preceding syllable segments. It can be
varied between 0 and 100% of the width of a typical character. The default value is 50%.
@Strength
The strength or steepness of the syinalepha slur. It can be varied between 20 and 100%.
The default value is 50%.
--]]----------------------------------------------------------------

-- our object type is passed into the script as a first paramater, which we can access using the vararg expression ...
local userObjTypeName = ...
local userObjSigName = nwc.toolbox.genSigName(userObjTypeName)

------------------------------------------------------

local function iterateMethod(o, f, i) return function() i=(i or 0) + 1 return o[f](o, i) end end

------------------------------------------------------

local function findLyricPos(o,dir)
	dir = dir or "next"
	while o:find(dir, "noteOrRest") do
		if o:isLyricPos() then return true end
	end

	return false
end

local function list_iter(t)
	local i = 0
	local n = #t
	return function ()
		i = i + 1
		if i <= n then return t[i] end
	end
end

------------------------------------------------------

-- we never apply Synamatic operations past another Synamatic instance
local nextSynamatic = nwc.drawpos.new()

------------------------------------------------------

local function _create(t)
	t.Class = 'StaffSig'
end

local function _draw(t)
	local w = nwc.toolbox.drawStaffSigLabel(userObjSigName)
	if not nwcdraw.isDrawing() then return w end
	local _, my = nwcdraw.getMicrons()
	local solidPenWidth = my * 0.12
	local bw = 0.2
	nwcdraw.setPen('solid', solidPenWidth)
	local overlap = t.Overlap / 150
	local strength = t.Strength / 50
	local user = nwcdraw.user
	local drawpos = nwc.drawpos
	
	-- Can be disabled by turning off its visibility
	if user:isHidden() then return end

	-- we need at least one note to work with
	if not drawpos:find("next", "note") then return end

	nwcdraw.setFontClass('StaffLyric')
	local w_ref, h_ref, desc_ref =  nwcdraw.calcTextSize(" ")

	-- we never apply Synamatic operations past another Synamatic instance, so we need to check for one
	if not nextSynamatic:find("next", "user",userObjTypeName) then nextSynamatic:find("last") end

	drawpos:reset()
	while findLyricPos(drawpos) and drawpos:indexOffset() < nextSynamatic:indexOffset() do
		local lyricRow = 0
		for lt, sep in iterateMethod(drawpos, 'lyricSyllable') do
			lyricRow = lyricRow+1
			local t = {}
			local u1, u2 = 0, 0
			while true do
				u1, u2 = string.find(lt, '%s+', u2 + 1)
				if u1 == nil then break end
				table.insert(t, { u1, u2 })
			end
			if lt ~= " " and #t > 0 then
				for ltb in list_iter(t) do
					local lt1 = string.sub(lt, 1, ltb[1]-1)
					local lt2 = string.sub(lt, 1, ltb[2])
					local w1 = nwcdraw.calcTextSize(lt)
					local o1 = nwcdraw.calcTextSize(lt1)
					local o2 = nwcdraw.calcTextSize(lt2)
					local xlyr, ylyr, align = drawpos:xyLyric(lyricRow)
					if align == "Center" then xlyr = xlyr - w1 / 2 end
					local x1 = xlyr + o1 - overlap
					local x2 = xlyr + o2 + overlap
					ylyr = ylyr - (h_ref/2) + desc_ref - 0.5
					nwcdraw.moveTo(x1, ylyr)
					local xa = (x1 + x2) / 2
					local ya = ylyr - strength
					nwcdraw.beginPath()
					nwcdraw.bezier(xa, ya+bw, x2, ylyr)
					nwcdraw.bezier(xa, ya-bw, x1, ylyr)
					nwcdraw.endPath()
				end
			end
		end
	end
end

local function _spin(t, dir)
	t.Overlap = t.Overlap + dir * 10
	t.Overlap = t.Overlap
end

local _spec = {
	{ id = 'Overlap', label = '&Overlap (%)', type = 'int', default = 50, min = 0, max = 100, step = 10 },
	{ id = 'Strength', label = '&Strength (%)', type = 'int', default = 50, min = 20, max = 100, step = 10 }
}

return {
	spec = _spec,
	create = _create,
	width = _draw,
	draw = _draw,
	spin = _spin
}
