local user = nwcdraw.user
local sideOptions = { 'top', 'bottom', 'both'}

local function artsOnStem()
	local opts = user:objProp('Opts') or ''
	return opts:match('ArticulationsOnStem') or user:isSplitVoice()
end

local function drawArtStemSide(my, sd, n, t, ch)
	local x, y = user:xyStemAnchor(sd)
	local _, sy = user:xyStemTip(sd)
	sy = sy or y + sd
	local sya = my+sy
	local nxo = user:durationBase(n) == 'Whole' and .65-sd*.05 or .5
	local nx = x - sd*nxo
	local z = sd*sya > 3 and 1 or (t.StayOutside == 'true') and sya*sd - 3 or (sya+1) % 2
	nwcdraw.moveTo(nx, sy + sd*(2-z))
	nwcdraw.text(ch)
end

local function drawArtNoteSide(my, sd, nc, t, ch)
	local n = sd > 0 and 1 or nc
	local ny = user:notePos(n)
	local x = user:xyStemAnchor(sd)
	local nxo = user:durationBase(n) == 'Whole' and .65-sd*.05 or .5
	local nx = x - sd*nxo
	local npp = tonumber(user:notePitchPos(n):match('([%-%d]+)'))
	local z = -npp*sd > 3 and 1 or (t.StayOutside == 'true') and -(my+ny)*sd - 2 or npp % 2
	nwcdraw.moveTo(nx, ny - sd*(3-z))
	nwcdraw.text(ch)
end
	
local function draw_Tenuto(t)
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.alignText('baseline', 'center')
	local my = user:staffPos()
	
	if not user:find('next','note') then return end
	
	local nc = user:noteCount()
	local sd, sd1 = user:stemDir(1), user:stemDir(nc)
	
	if artsOnStem() then
	-- Split voice chords should always have articulations on their stems
		if t.Side ~= 'top' then -- bottom or both
			drawArtStemSide(my, sd, 1, t, 'C')
		end
		if user:isSplitVoice() and t.Side ~= 'bottom' then -- top or both
			drawArtStemSide(my, sd1, nc, t, 'C')
		end
	else
		drawArtNoteSide(my, sd, nc, t, 'C')
	end
end

local spec_Tenuto = {
	{ id='StayOutside', label='Keep outside of staff', type='bool', default=false },
	{ id='Side', label='Side', type='enum', default=sideOptions[3], list=sideOptions },
}

local function spin_Tenuto(t,dir)
	local v = t.Side
	local j
	for i,s in pairs(sideOptions) do
		if s == v then
			j = i
			break
		end
	end
	
	j = j and math.min(math.max(j + dir,1),#sideOptions) or #sideOptions
	t.Side = sideOptions[j]
end

return {
	spec = spec_Tenuto,
	create = create_Tenuto,
	spin = spin_Tenuto,
	draw = draw_Tenuto
	}