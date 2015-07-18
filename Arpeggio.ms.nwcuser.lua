-- Version 0.91

--[[----------------------------------------------------------------
Arpeggio.ms

Draws an arpeggio next to a chord. Optionally plays the notes if the chord is muted and Play parameter is set

--]]----------------------------------------------------------------

local user = nwcdraw.user
local searchObj = nwc.ntnidx.new()

local function drawSquig(x, y)
	local xo, yo = .2, -.2
	local x1, y1 = x + .5, y - .65
	local x2, y2 = x - .5, y - 1.3
	local x3, y3 = x , y - 2
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.bezier(x1, y1, x2, y2, x3, y3)
	nwcdraw.line(x3 + xo, y3 + yo)
	nwcdraw.bezier(x2 + xo, y2 + yo, x1 + xo, y1 + yo, x + xo, y + yo)
	nwcdraw.closeFigure()
	nwcdraw.endPath()
end

local function drawArrow(x, y, dir)
	local a, b, c = .3, .3*dir, 1.5*dir
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.line(x-a, y-b)
	nwcdraw.line(x, y+c)
	nwcdraw.line(x+a, y-b)
	nwcdraw.closeFigure()
	nwcdraw.endPath()
end

local spec_Arpeggio = {
	Offset = { type='float', default=0, min=-5, max=5, step=.1 },
	MarkerExtend = { type='bool', default=false },
	Side = { type='enum', default='left', list={'left', 'right'} },
	Dir = { type='enum', default='up', list={'up', 'down'} },
	Anticipated = { type='bool', default=false },
	Speed = { type='int', default=32, min=1, max=128 },
	Play = { type='bool', default=true },
	ForceArrow = { type='bool', default=false }
}

local function draw_Arpeggio(t)
	if not user:find('next', 'note') then return end
	local noteCount = user:noteCount()
	if noteCount == 0 then return end
	local offset = t.Offset
	local leftOnSide = t.Side == 'left'
	local markerExtend = t.MarkerExtend	
	local ybottom, ytop = user:notePos(1)+.5, user:notePos(noteCount)-.5
	if markerExtend then
		ytop = math.max(ytop, 0)
		ybottom = math.min(ybottom, 0)
	end
	nwcdraw.setPen('solid', 95)	
	local count = math.floor((ytop - ybottom) / 2) + 2
	local x = leftOnSide and offset - .75 or user:xyRight() + offset + .55
	local y = ytop + 2
	for i = 1, count do
		drawSquig(x, y)
		y = y - 2
	end
	if t.Dir == 'down' then
		drawArrow(x, ytop-count*2+1.85, -1)
	else
		if t.ForceArrow then
			drawArrow(x+.2, ytop+1.85, 1)
		end
	end
end

local function play_Arpeggio(t)
	if not t.Play then return end
	searchObj:find('next', 'duration')
	local noteCount = searchObj:noteCount()
	if noteCount == 0 then return end
	local k = {}
	local first, last, inc = 1, noteCount, 1
	if t.Dir == 'down' then
		first, last, inc = last, first, -1
	end
	for i=first, last, inc do
		if searchObj:isMute(i) then
			table.insert(k, nwcplay.getNoteNumber(searchObj:notePitchPos(i)))
		end
	end
	searchObj:find('next')
	local duration = searchObj:sppOffset()
	searchObj:find('first')
	if duration < 1 then return end
	local noteCount = #k
	if k then
		local arpeggioShift = nwcplay.PPQ / t.Speed
		local startOffset = t.Anticipated and math.max(-arpeggioShift * (noteCount-1), searchObj:sppOffset()) or 0
		for i, v in ipairs(k) do
			local thisShift = math.min(duration-arpeggioShift, arpeggioShift * (i-1)) + startOffset
			nwcplay.note(thisShift, duration-thisShift, v)
		end
	end
end

local function create_Arpeggio(t)
	t.Offset = t.Offset
	t.MarkerExtend = t.MarkerExtend
	t.Side = t.Side
	t.Dir = t.Dir
	t.Anticipated = t.Anticipated
	t.Speed = t.Speed
	t.Play = t.Play
	t.ForceArrow = t.ForceArrow
end

return {
	spec = spec_Arpeggio,
	create = create_Arpeggio,
	draw = draw_Arpeggio,
	play = play_Arpeggio
}