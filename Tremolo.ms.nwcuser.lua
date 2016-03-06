-- Version 1.1

--[[----------------------------------------------------------------
This plugin creates two-note tremolo markings. It draws the markings, and will optionally play the notes in tremolo style.

To create a tremolo, first create two RestChords of the desired duration. For whole, half and quarter note tremolos, the rest duration should be half 
of the note's duration. For eighth tremolos, the note duration should be quarter and the rest duration sixteenth. Also, the RestChords' "Show Rest" property should be unchecked.
Insert the tremolo object between the RestChords, and the markings will be drawn between them. 

Note that if either of the notes/chords are not RestChords, or if their stems are in opposite directions, the tremolo markings will not be drawn.
However, they will still play in tremolo style if Play Notes is checked.

For whole note tremolos, the beams can be positioned by moving the tremolo object marker vertically.
For stemmed tremolos, if additional space is needed to accommodate a larger number of beams, increase the notes' stem lengths.
@Beams
The number of beams to be drawn between the notes, between 1 and 4. The default setting is 3.

For playback, the number of beams determines the frequency and number of notes to be played.

The number of beams for a tremolo can be modified by highlighting the object and pressing the + or - keys.
@Style
Specifies one of three styles for half-note tremolos; it is ignored for other tremolo durations. The range of values is 1 to 3, and the default setting is 1.
@Play
Enables playback of the tremolo. The default setting is enabled (checked).

Note that the tremolo RestChords should be muted for proper playback.
@TripletPlayback
Specifies that the playback notes should be in triplet rhythm. This will generally be used when the tremolo notes are dotted. The default setting is disabled (unchecked).
@Variance
Specifies a dynamic variance between the first and second chord. The specified value is a multiplier for the
volume of the second note. This allows more realistic playback. The range of values is 50% to 200%, and the default setting is 100% (no variance).
--]]----------------------------------------------------------------

local user = nwcdraw.user
local nextNote = nwc.drawpos.new()
local priorNote = nwc.drawpos.new()

local spec_Tremolo = {
	{ id='Beams', label='Number of Beams', type='int', default=3, min=1, max=4 },
	{ id='Style', label='Half Note Beam Style', type='int', default=1, min=1, max=3 },
	{ id='Play', label='Play Notes', type='bool', default=true },
	{ id='TripletPlayback', label='Triplet Playback', type='bool', default=false },
	{ id='Variance', label='Variance (%)', type='int', default=100, min=50, max=200, step=5 },
}

local function draw_Tremolo(t)
	local _, my = nwcdraw.getMicrons()
	local stemWeight = my*0.0126
	local beams = t.Beams
	local style = t.Style
	local yu = user:staffPos()
	local beamHeight, beamSpacing, beamOffset = .8, 1.8, .6
	nwcdraw.setPen('solid', stemWeight)	
	if not nextNote:find('next','note') then return end
	if nextNote:objType() ~= 'RestChord' then return end
	local stemDir = nextNote:stemDir(1)
	local x2s, y2s = nextNote:xyStemTip(stemDir)
	local x2 = nextNote:xyAnchor()
	local dur = nextNote:durationBase()
	x2s = x2s or x2
	y2s = y2s and y2s + 0.04*stemDir or nextNote:notePos(1)+yu
	if not priorNote:find('prior','note') then return end
	if priorNote:objType() ~= 'RestChord' then return end
	if stemDir ~= priorNote:stemDir(1) then return end
	local x1s, y1s = priorNote:xyStemTip(stemDir)
	local x1 = priorNote:xyTimeslot()
	y1s = y1s and y1s+0.04*stemDir or priorNote:notePos(1)+yu
	x1s = x1s or x1+1.3
	local slope=(y2s-y1s)/(x2s-x1s)

	local function drawBeam(x, y)
		local xs, ys, bs = x*slope, y*stemDir, beamHeight*stemDir
		nwcdraw.moveTo(x1s+x, y1s+xs-ys)
		nwcdraw.beginPath()
		nwcdraw.line(x2s-x, y2s-xs-ys)
		nwcdraw.line(x2s-x, y2s-xs-ys-bs)
		nwcdraw.line(x1s+x, y1s+xs-ys-bs)
		nwcdraw.closeFigure()
		nwcdraw.endPath()
	end

	local offset1, offset2 = 0, 0
	if dur == 'Eighth' or dur == 'Half' then
		offset1 = beamOffset
		offset2 = beamOffset
	elseif dur == 'Sixteenth' then
		offset2 = beamOffset
	elseif dur == 'Quarter' then
		if style == 1 then
			offset2 = beamOffset
		elseif style == 2 then
			offset1 = beamOffset
			offset2 = beamOffset
		end
	end
	drawBeam(offset1, 0)
	for i = 1, beams-1 do
		drawBeam(offset2, i*beamSpacing)
	end
end

local _play = { nwc.ntnidx.new(), nwc.ntnidx.new() }
local function play_Tremolo(t)
	if not t.Play then return end
	local dur = nwcplay.PPQ / 2^t.Beams * (t.TripletPlayback and 2/3 or 1)
	_play[2]:find('next', 'note')
	_play[2]:find('next')
	local fini = _play[2]:sppOffset() - 1
	_play[1]:find('prior', 'note')
	_play[2]:find('prior')
	local defaultVel = nwcplay.getNoteVelocity()
	local vel = { defaultVel, math.min(127, defaultVel * t.Variance/100) }
	local i = 1
	for spp = _play[1]:sppOffset(), fini, dur do
		for j = 1, _play[i]:noteCount() or 0 do 
			nwcplay.note(spp, dur, nwcplay.getNoteNumber(_play[i]:notePitchPos(j)), vel[i])
		end
		i = 3 - i
	end
end

local function spin_Tremolo(t, dir)
	t.Beams = t.Beams + dir
	t.Beams = t.Beams
end

return {
	spec = spec_Tremolo,
    spin = spin_Tremolo,
	draw = draw_Tremolo,
	play = play_Tremolo
}