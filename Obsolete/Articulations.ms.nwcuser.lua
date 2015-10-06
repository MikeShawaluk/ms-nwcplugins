local user = nwcdraw.user

local artTable1 = {
	[1] = "z",
	[2] = ":",
	[4] = "C",
	[5] = "zC",
	[6] = ":C",
	[8] = "@",
	[9] = "z@",
	[10] = ":@",
	[12] = "C@",
	[16] = "A",
	[17] = "zA",
	[18] = ":A",
	[20] = "CA"	}

local artTable2 = {
	[1] = 'Stacatto',
	[2] = 'Stacattisimo',
	[4] = 'Tenuto',
	[8] = 'Marcato',
	[16] = 'Accent'	}

local function artsOnStem()
	local opts = user:objProp('Opts') or ''
	return opts:match('ArticulationsOnStem') or user:isSplitVoice()
end

local function getArt(str, flip)
	local i = 0
	for j, v in pairs(artTable2) do
		if string.find(str, v) then i = i + j end
	end
	local x = artTable1[i] or ''
	if flip then
		x = string.gsub(x, ':', ';')
		x = string.gsub(x, '@', 'B')
	end
	return x, i>=8
end

local function drawArtStemSide(my, off, sd, n, ch, so)
	if ch == '' then return end
	local x, y = user:xyStemAnchor(sd)
	local _, sy = user:xyStemTip(sd)
	sy = sy or y + sd
	local sya = my+sy
	local nxo = user:durationBase(n) == 'Whole' and .65-sd*.05 or .5
	local nx = x - sd*nxo
	local z = sd*sya > 3 and 1 - off or so and sya*sd - 3 - off or (sya+1) % 2
	for c in ch:gmatch('.') do
		nwcdraw.moveTo(nx, sy + sd*(2-z))
		nwcdraw.text(c)
		z = z - 2
	end
end

local function drawArtNoteSide(my, off, sd, nc, ch, so)
	if ch == '' then return end
	local n = sd > 0 and 1 or nc
	local ny = user:notePos(n)
	local x = user:xyStemAnchor(sd)
	local nxo = user:durationBase(n) == 'Whole' and .65-sd*.05 or .5
	local nx = x - sd*nxo
	local npp = tonumber(user:notePitchPos(n):match('([%-%d]+)'))
	local z = -npp*sd > 3 and 1 - off or so and -(my+ny)*sd - 2 - off or npp % 2
	for c in ch:gmatch('.') do
		nwcdraw.moveTo(nx, ny - sd*(3-z))
		nwcdraw.text(c)
		z = z - 2
	end
end
	
local function draw_Articulations(t)
	nwcdraw.setFontClass('StaffSymbols')
	nwcdraw.alignText('baseline', 'center')
	local my = user:staffPos()
	
	if not user:find('next','note') then return end
	
	local mof, sof = t.MainOffset, t.SplitOffset
	local nc = user:noteCount()
	local sd, sd1 = user:stemDir(1), user:stemDir(nc)
	local so = t.StayOutside
	local ch, ma
	
	if artsOnStem() then
	-- Split voice chords should always have articulations on their stems
		ch, ma = getArt(t.MainArticulation, sd > 0)
		drawArtStemSide(my, mof, sd, 1, ch, so or ma)
		if user:isSplitVoice() then
			ch, ma = getArt(t.SplitArticulation, sd > 0)
			drawArtStemSide(my, sof, sd1, nc, ch, so or ma)
		end
	else
		ch, ma = getArt(t.MainArticulation, sd < 0)
		drawArtNoteSide(my, mof, sd, nc, ch, so or ma)
	end
end

local function create_Articulations(t)
	t.StayOutside = t.StayOutside
	t.MainArticulation = t.MainArticulation
	t.SplitArticulation = t.SplitArticulation
	t.MainOffset = t.MainOffset
	t.SplitOffset = t.SplitOffset
end


local spec_Articulations = {
	StayOutside = { type='bool', default=false },
	MainArticulation = { type = 'text', default='Tenuto' },
	SplitArticulation = { type = 'text', default='Tenuto' },
	MainOffset = { type='int', default=0 },
	SplitOffset = { type='int', default=0 }
}

return {
	create = create_Articulations,
	spec = spec_Articulations,
	draw = draw_Articulations
	}