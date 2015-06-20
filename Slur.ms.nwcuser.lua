-- Version 0.1

--[[----------------------------------------------------------------
Slur.ms
Draws solid, dashed or dotted slurs with user specified offset and strength
--]]----------------------------------------------------------------

local user = nwcdraw.user
local startNote = nwc.drawpos.new()
local endNote = nwc.drawpos.new()

local function noteStuff(item)
	local opts = item:objProp('Opts') or ''
	local stem, slur
	local slurNote = 1
	if item:isSplitVoice() and item:objType() ~= 'RestChord' then
		slur = opts:match('Slur=(%a+)') or 'Upward'
		stem = slur == 'Upward' and 'Up' or 'Down'
		if slur == 'Upward' then slurNote = item:noteCount() end
	else
		stem = item:stemDir(slurNote)==1 and 'Up' or 'Down'
		slur = opts:match('Slur=(%a+)') or stem == 'Up' and 'Downward' or 'Upward'
	end
	local baseNote = item:durationBase(slurNote)
	local dotted = item:isDotted(slurNote)
	local arcPitch, noteheadOffset = 3.75, .5
	if baseNote == 'Whole' and dotted then
		arcPitch, noteheadOffset = 7.75, .65
	elseif baseNote == 'Whole' then
		arcPitch, noteheadOffset = 5.75, .65
	elseif baseNote == 'Half' then
		arcPitch = 5.75
	end
	return stem, slur, arcPitch, noteheadOffset, baseNote
end

local spec_Slur = {
	Span = { type='int', default=2, min=2 },
	Pen = { type='enum', default='solid', list=nwc.txt.DrawPenStyle },
	Dir = { type='enum', default='Default', list=nwc.txt.TieDir },
	Strength = { type='float', default=1 },
	StartOffsetX = { type='float', default=0 },
	StartOffsetY = { type='float', default=0 },
	EndOffsetX = { type='float', default=0 },
	EndOffsetY = { type='float', default=0 },
}

local function draw_Slur(t)
	local span = t.Span
	local pen = t.Pen
	local dir = t.Dir
	local strength = t.Strength

	local startOffsetX, startOffsetY = t.StartOffsetX, t.StartOffsetY
	local endOffsetX, endOffsetY = t.EndOffsetX, t.EndOffsetY
	
	startNote:find('next', 'noteOrRest')
	if not startNote then return end
	
	local found
	for i = 1, span do
		found = endNote:find('next', 'noteOrRest')
	end
	if not found then return end
	
	local startStem, slurDir, ya, xo1, startNotehead = noteStuff(startNote)
	local endStem, _, _, xo2, endNotehead = noteStuff(endNote)
	ya = ya * strength
	
	if dir ~= 'Default' then slurDir = dir end
	
	local startNoteYBottom, startNoteYTop = startNote:notePos(1) or 0, startNote:notePos(startNote:noteCount()) or 0
	local endNoteYBottom, endNoteYTop = endNote:notePos(1) or 0, endNote:notePos(endNote:noteCount()) or 0	
	local x1 = startNote:xyTimeslot()
	local x2 = endNote:xyTimeslot()

	x1 = x1 + startOffsetX + xo1 + ((slurDir == 'Upward' and startStem == 'Up' and startNotehead ~= 'Whole') and .75 or 0)
	x2 = x2 + endOffsetX + xo2 - ((slurDir == 'Downward' and endStem == 'Down' and endNotehead ~= 'Whole') and .75 or 0)
	local y1 = (slurDir == 'Upward') and startNoteYTop + startOffsetY + 2 or startNoteYBottom - startOffsetY - 2
	local y2 = (slurDir == 'Upward') and endNoteYTop + endOffsetY + 2 or endNoteYBottom - endOffsetY - 2
	local xa = (x1 + x2) / 2
	ya = (y1 + y2) / 2 + ((slurDir == 'Upward') and ya or -ya)

	nwcdraw.moveTo(x1, y1)
	if t.Pen == 'solid' then
		nwcdraw.setPen(t.Pen, 95)
		nwcdraw.beginPath()
		nwcdraw.bezier(xa, ya+.3, x2, y2)
		nwcdraw.bezier(xa, ya-.3, x1, y1)
		nwcdraw.endPath('strokeandfill')
	else
		nwcdraw.setPen(t.Pen, 300)
		nwcdraw.bezier(xa, ya, x2, y2)
	end
end

local function spin_Slur(t, d)
	t.Span = t.Span + d
end

local function create_Slur(t)
	t.Span = t.Span
	t.Pen = t.Pen
	t.Dir = t.Dir
	t.Strength = t.Strength
	t.StartOffsetX = t.StartOffsetX
	t.StartOffsetY = t.StartOffsetY
	t.EndOffsetX = t.EndOffsetX
	t.EndOffsetY = t.EndOffsetY
end

return {
	spec = spec_Slur,
	create = create_Slur,
	spin = spin_Slur,
	draw = draw_Slur
}
