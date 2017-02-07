-- Version 2.0d

--[[----------------------------------------------------------------
This will draw a glissando line between two notes, with optional text above the line. If either of the notes is a chord, the bottom notehead
of that chord will be the starting or ending point of the line.
@Pen
Specifies the type for lines: solid, dot, dash or wavy. The default setting is solid.
@Text
The text to appear above the glissando line, drawn in the StaffItalic system font. The default setting is "gliss."
@Scale
The scale factor for the text above the glissando line. This is a value from 5% to 400%, and the default setting is 75%.

The text scale factor can be incremented/decremented by selecting the object and pressing the + or - keys.
@StartOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@StartOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's start point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetX
This will adjust the auto-determined horizontal (X) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@EndOffsetY
This will adjust the auto-determined vertical (Y) position of the glissando's end point. The range of values is -100.00 to 100.00. The default setting is 0.
@Weight
This will adjust the weight (thickness) of both straight and wavy line types. The range of values is 0.0 to 5.0, where 1 is the standard line weight. The default setting is 1.
@Playback
This can be used to activate different optional forms of play back. Most play back methods are best when the target (left side) note is muted. For PitchBend,
the left note never be muted, and the instrument definition should establish a 24 semitone pitch bend.
--]]----------------------------------------------------------------

local userObjTypeName = ...
local nextNote, priorNote = nwc.drawpos.new(), nwc.drawpos.new()
local nextNoteidx, priorNoteidx = nwc.ntnidx.new(), nwc.ntnidx.new()
local idx = nwc.ntnidx
local user = nwcdraw.user

local lineStyles = { 'solid', 'dot', 'dash', 'wavy' }
local squig = '~'
local showBoxes = { edit=true }

local PlaybackStyle = {'None','Chromatic','WhiteKeys', 'BlackKeys', 'PitchBend'}
local KeyIntervals = {
	None = {},
	Chromatic = {0,1,2,3,4,5,6,7,8,9,10,11},
	WhiteKeys = {0,2,4,5,7,9,11},
	BlackKeys = {1,3,6,8,10},
	PitchBend = {0},
}

local _spec = {
	{ id='Pen', label='Line Style', type='enum', default=lineStyles[1], list=lineStyles },
	{ id='Text', label='Text', type='text', default='gliss.' },
    { id='Scale', label='Text Scale (%)', type='int', min=5, max=400, step=5, default=75 },
    { id='StartOffsetX', label='Start Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='StartOffsetY', label='Start Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetX', label='End Offset X', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='EndOffsetY', label='End Offset Y', type='float', step=0.1, min=-100, max=100, default=0 },
	{ id='Weight', label='Line Weight', type='float', default=1, min=0, max=5, step=0.1 },
	{ id='Playback', label='Playback', type='enum', default=PlaybackStyle[1], list=PlaybackStyle },
}

local _spec2 = {}

for k, v in ipairs(_spec) do
	_spec2[v.id] = k
end

local function _create(t)
	t.Class = 'Span'
end

local function _audit(t)
	if t.Style then
		if (t.Style == 'Wavy') then t.Pen = 'wavy' end
		t.Style = nil
	end
	t.ap = nil
	
	local barSpan = (idx:find('span', 1) or idx:find('last')) and idx:find('prior','bar') and (idx:indexOffset() > 0)
	t.Class = barSpan and 'Span' or 'Standard'
end

local function box(x, y, ap, p)
	local m = (ap == p) and 'strokeandfill' or 'stroke'
	nwcdraw.setPen('solid', 100)
	nwcdraw.moveTo(x, y)
	nwcdraw.beginPath()
	nwcdraw.roundRect(0.2)
	nwcdraw.endPath(m)
end

local stopItems = { Note=1, Chord=1, RestChord=1, Rest=-1, Bar=-1, RestMultiBar=-1, Boundary=-1 }

local function hasPriorTargetNote(idx)
	while idx:find('prior') do
		local d = stopItems[idx:objType()]
		if d then return d > 0 end
		if (idx:userType() == userObjTypeName) then return false end
	end
	return false
end

local function drawGliss(x1, y1, x2, y2, drawText, t)
	local xyar = nwcdraw.getAspectRatio()
    local _, my = nwcdraw.getMicrons()
	local pen, text, weight = t.Pen, t.Text, t.Weight

	local angle = math.deg(math.atan2((y2-y1), (x2-x1)*xyar))
	
	if drawText and text ~= '' then
		nwcdraw.alignText('bottom', 'center')
		nwcdraw.setFontClass('StaffItalic')
		nwcdraw.setFontSize(nwcdraw.getFontSize()*t.Scale*.01)
		nwcdraw.moveTo((x1+x2)*.5, (y1+y2)*.5)
		nwcdraw.text(text, angle)
	end
	if pen ~= 'wavy' then
		if weight ~= 0 then
			nwcdraw.setPen(pen, my*.3*weight)	
			nwcdraw.line(x1, y1, x2, y2)
		end
	else
		nwcdraw.alignText('baseline', 'left')
		nwcdraw.setFontClass('StaffSymbols')
		nwcdraw.setFontSize(nwcdraw.getFontSize()*weight)
		local w = nwcdraw.calcTextSize(squig)
		local len = math.sqrt((y2-y1)^2 + ((x2-x1)*xyar)^2)
		local count = math.floor(len/w/xyar)
		nwcdraw.moveTo(x1, y1-1)
		nwcdraw.text(string.rep(squig, count), angle)
	end
end

local function _draw(t)
	local atSpanFront = not user:isAutoInsert()
	local atSpanEnd = nextNoteidx:find('span', 1)
	
	if not hasPriorTargetNote(priorNoteidx) or not atSpanEnd then
		if not atSpanFront then return 0 end
		local x, y = -4, 4
		if not nwcdraw.isDrawing() then return -x end
		drawGliss(x, 0, 0, y, true, t)
		return
	end
	if not nwcdraw.isDrawing() then return 0 end
	
	local xo, yo = .25, .5
	
	nextNote:find(nextNoteidx)
	priorNote:find(priorNoteidx)
	
	if not atSpanEnd then nextNoteidx:find('last') end
	local x1 = atSpanFront and priorNote:xyRight() + xo + t.StartOffsetX or -1.25
	local y1 = priorNoteidx:notePos(1)
	
	local x2 = (atSpanEnd and nextNote:xyAnchor() + t.EndOffsetX or 0) - xo 
	local y2 = nextNoteidx:notePos(1) or 0

    local s = y1>y2 and 1 or y1<y2 and -1 or 0
	y1 = y1 - yo*s + t.StartOffsetY
	y2 = y2 + yo*s + t.EndOffsetY

	drawGliss(x1, y1, x2, y2, atSpanFront, t)
	
	if t.ap and showBoxes[nwcdraw.getTarget()] then
		local ap = tonumber(t.ap)
		box(x1, y1, ap, 1)
		box(x2, y2, ap, 2)
	end
end

local function GlissOctaveNearestNextInterval(t, inOctaveSemiTone)
	for i, v in ipairs(t) do
		if v >= inOctaveSemiTone then return i-1 end
	end
	return 0
end
		
local function CountGlissIntervals(k, v)
	local o = math.floor(v/12)
	local i = v % 12
	
	return #k*o + GlissOctaveNearestNextInterval(k, i)
end

local function GlissNoteFromInterval(k,v)
	local opitches = #k
	local o = math.floor(v/opitches)
	local i = v % opitches
	
	return 12*o + k[i+1]
end

local function isStandAloneMutedNote(n)
	return n:isMute() and not n:isTieIn() and not n:isTieOut()
end
	
local function _play(t)
	local playbackt = t.Playback
	local playback = KeyIntervals[playbackt]
	if #playback < 1 then return end
	
	if not (hasPriorTargetNote(priorNoteidx) and nextNoteidx:find('span', 1)) then return end
	local startSPP = priorNoteidx:sppOffset()
	local dur = -startSPP
	
	local v1 = nwcplay.getNoteNumber(priorNoteidx:notePitchPos(1))
	local v2 = nwcplay.getNoteNumber(nextNoteidx:notePitchPos(1))
	if (not v1) or (not v2) or (v2 == v1) then return end

	local inc = (v1<v2) and 1 or -1

	if playbackt == 'PitchBend' then
		-- this technique requires that the part have a dedicated midi channel and a 24 semitone pitch bend range
		local deltav = math.min(math.abs(v1-v2),24)
		local pbStart,pbEnd = 0x02000,0x02000+inc*((0x01FFF*deltav)/24)
		
		-- if the initiating note stands alone (is not tied) and is muted, then the note pitch bend can
		-- be applied against the target pitch with a full note duration
		if isStandAloneMutedNote(priorNoteidx) then
			local noteDur = dur
			pbStart,pbEnd = 0x02000-inc*((0x01FFF*deltav)/24),0x02000
			
			-- allow the note pair to be connected together when both are stand alone muted
			if isStandAloneMutedNote(nextNoteidx) and nextNoteidx:find('next') then
				-- **limitation**: this always performs the target note in legato fashion, regardless of the active 
				-- performance style or articulation marks, and it assumes the target note or chord matches the
				-- priorNoteidx (if they don't match, the priorNoteidx controls what is played)
				noteDur = noteDur + math.max(nextNoteidx:sppOffset(),1) - 1
				nextNoteidx:find('prior')
			end
			
			for j = 1, priorNoteidx:noteCount() or 0 do
				local notenum = nwcplay.getNoteNumber(priorNoteidx:notePitchPos(j))+(inc*deltav)
				local notevel = nwcplay.getNoteVelocity()
				local bothsides = nextNoteidx:notePitchPos(j)
				nwcplay.note(startSPP, bothsides and noteDur or dur, notenum, notevel)
			end
		end
		
		local pbChanges = math.floor((dur/2) - 2)
		for i = 0, pbChanges do
			local pbVal = pbStart + math.floor((i*(pbEnd-pbStart))/pbChanges)
			local d1,d2 = math.floor(pbVal % 128),math.floor(pbVal/128)
			nwcplay.midi(startSPP+i*2,'pitchBend',d1,d2)
		end
		nwcplay.midi(0,'pitchBend',0,64)
	else
		local interval1, interval2 = CountGlissIntervals(playback, v1, inc), CountGlissIntervals(playback, v2, inc)
		local deltav = math.abs(interval1-interval2)
		local deltaSPP = dur/deltav
		if deltaSPP < 1 then return end
		for i = 0, deltav-1 do
			local interval = interval1+(inc*i)
			local notepitch = GlissNoteFromInterval(playback, interval)
			if ((i==0) and (notepitch~=v1)) then notepitch = v1 end
			nwcplay.note(startSPP+(deltaSPP*i), deltaSPP,notepitch)
		end
	end
end

local paramTable = {
	{ _spec2.StartOffsetX, _spec2.StartOffsetY },
	{ _spec2.EndOffsetX, _spec2.EndOffsetY },
}

local function toggleParam(t)
	local ap = tonumber(t.ap) or #paramTable
	ap = ap % #paramTable + 1
	t.ap = ap
end

local function updateParam(t, p, dir)
	local s = _spec[p]
	local x = s.id
	t[x] = t[x] + dir*s.step
	t[x] = t[x]
end
	
local function updateActiveParam(t, n, dir)
	local ap = tonumber(t.ap)
	if ap then 
		updateParam(t, paramTable[ap][n], dir)
	end
end

local function updateEnds(t, dir)
	updateParam(t, _spec2.StartOffsetY, dir)
	updateParam(t, _spec2.EndOffsetY, dir)
end

local skip = { Text=true }

local function defaultAllParams(t)
	for k, s in ipairs(_spec) do
		if not skip[s.id] then t[s.id] = t[s.default] end
	end
end

local function defaultActiveParam(t)
	local ap = tonumber(t.ap)
	if ap then
		for i = 1, 2 do
			local s = _spec[paramTable[ap][i]]
			t[s.id] = s.default
		end
	end
end

local function toggleEnum(t, p)
	local s = _spec[p]
	local q = {}
	for k, v in ipairs(s.list) do
		q[v] = k
	end
	t[s.id] = s.list[q[t[s.id]] + 1]
end

local charTable = {
	['+'] = { updateParam, _spec2.Scale, 1 },
	['-'] = { updateParam, _spec2.Scale, -1 },
	['7'] = { updateParam, _spec2.Weight, 1 },
	['1'] = { updateParam, _spec2.Weight, -1 },
	['8'] = { updateActiveParam, 2, 1 },
	['2'] = { updateActiveParam, 2, -1 },
	['6'] = { updateActiveParam, 1, 1 },
	['4'] = { updateActiveParam, 1, -1 },
	['5'] = { toggleParam },
	['9'] = { updateEnds, 1 },
	['3'] = { updateEnds, -1 },
	['0'] = { defaultActiveParam },
	['Z'] = { defaultAllParams },
	['.'] = { toggleEnum, _spec2.Pen },
}

local function _onChar(t, c)
	local ptr = charTable[string.char(c)]
	if not ptr then return false end
	ptr[1](t, ptr[2], ptr[3])
	return true
end


return {
	create = _create,
	spec = _spec,
	audit = _audit,
	onChar = _onChar,
	draw = _draw,
	width = _draw,
	span = function() return 1 end,
	play = _play,
}
