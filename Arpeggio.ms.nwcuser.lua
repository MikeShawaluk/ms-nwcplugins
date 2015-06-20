-- Version 0.3

--[[----------------------------------------------------------------
Arpeggio.ms

Draws an arpeggio next to a chord. Plays it too, if the chord is muted
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

local obj_spec = {
	Offset = { type='float', default=0 },
	MarkerExtend = { type='bool', default=false },
	Side = { type='enum', default='left', list={'left', 'right'} },
	Dir = { type='enum', default='up', list={'up', 'down'} }
}

local function draw_Arpeggio(t)
	if not user:find('next', 'note') then return end
	local noteCount = user:noteCount()
	if noteCount == 0 then return end

	local offset = t.Offset
	local leftOnSide = t.Side == 'left'
	local markerExtend = t.MarkerExtend	
	local ybottom, ytop = user:notePos(1), user:notePos(noteCount)
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
end

local function play_Arpeggio(t)
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

	if duration < 1 then return end
	if k then
		local arpeggioShift = duration >= nwcplay.PPQ and nwcplay.PPQ / 8 or 0
		local thisShift = 0
		for i, v in ipairs(k) do
			nwcplay.note(thisShift, duration-thisShift, v)
			thisShift = thisShift + arpeggioShift
		end
	end
	
end

local function create_Arpeggio(t)
	t.Offset = t.Offset
	t.MarkerExtend = t.MarkerExtend
	t.Side = t.Side
	t.Dir = t.Dir
end

return {
	spec = obj_spec,
	create = create_Arpeggio,
	draw = draw_Arpeggio,
	play = play_Arpeggio
	}