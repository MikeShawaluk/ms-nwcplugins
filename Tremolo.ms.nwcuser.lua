-- Version 2.0c

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

if nwcut then
	local userObjTypeName = arg[1]
	local score = nwcut.loadFile()
	local beams = nwcut.prompt('Number of Beams:', '#[1,4]', 3)
	local firstNote = true
	local noteDurBase = { 'Whole', 'Half', '4th', '8th' }
	local noteDurBaseRev = {}

	for i,s in ipairs(noteDurBase) do
		noteDurBaseRev[s] = i
	end

	local function parseDur(durTable)
		local dur, dot
		for v in pairs(durTable) do
			dot = dot or (v == 'Dotted' or v == 'DblDotted') and v
			dur = dur or noteDurBaseRev[v] and v
		end
		return dur, dot
	end
	
	local function applyTremolo(o)
		if o:IsFake() then return end
		local opts, stemDir, dot, duration		
		if o:ContainsNotes() and not o:Is('RestChord') and not o.Opts.Dur2 then -- don't convert rest chords or split voice chords
			local o1 = nwcItem.new('|RestChord')
			opts = o:Provide('Opts')
			stemDir = (opts.Stem or 'Up') == 'Up' and 'Down' or 'Up'
			duration, dot = parseDur(o.Opts.Dur)
			if duration then
				local newDur = noteDurBase[noteDurBaseRev[duration]+1] or '16th'
				o1.Opts.Dur2 = o.Opts.Dur
				o1.Opts.Dur2[duration] = nil
				if duration == '8th' then duration = '4th' end
				o1.Opts.Dur2[duration] = ''
				o1:Provide('Dur', newDur)
				if dot then o1.Opts.Dur[dot] = '' end
				o1.Opts.Dur.Slur = o1.Opts.Dur2.Slur
				o1:Provide('Opts', opts)
				o1.Opts.Opts.Stem = stemDir
				o1.Opts.Opts.HideRest = ''
				o1.Opts.Opts.Muted = ''
				o1:Provide('Pos2', o.Opts.Pos)
				firstNote = not firstNote
				if not firstNote then
					local o2 = nwcItem.new('|User|' .. userObjTypeName)
					o2.Opts.Pos = 0
					o2.Opts.Beams = beams
					return { o1, o2 }
				else
					return { o1 }
				end
			end
		end
	end
	
	score:forSelection(applyTremolo)
	score:save()
	return
end

local user = nwcdraw.user
local nextNote = nwc.drawpos.new()
local priorNote = nwc.drawpos.new()

local _nwcut = {
	['Apply'] = 'ClipText',
}

local _spec = {
	{ id='Beams', label='Number of Beams', type='int', default=3, min=1, max=4 },
	{ id='Style', label='Half Note Beam Style', type='int', default=1, min=1, max=3 },
	{ id='Play', label='Play Notes', type='bool', default=true },
	{ id='TripletPlayback', label='Triplet Playback', type='bool', default=false },
	{ id='Variance', label='Variance (%)', type='int', default=100, min=50, max=200, step=5 },
}

local function _draw(t)
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
		nwcdraw.moveTo(x2s-x, y2s-xs-ys)
		nwcdraw.beginPath()
		nwcdraw.lineBy(0, -bs, x1s-x2s+2*x, y1s-y2s+2*xs, 0, bs)
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

local play = { nwc.ntnidx.new(), nwc.ntnidx.new() }
local function _play(t)
	if not t.Play then return end
	local dur = nwcplay.PPQ / 2^t.Beams * (t.TripletPlayback and 2/3 or 1)
	play[2]:find('next', 'note')
	play[2]:find('next')
	local fini = play[2]:sppOffset() - 1
	play[1]:find('prior', 'note')
	play[2]:find('prior')
	local defaultVel = nwcplay.getNoteVelocity()
	local vel = { defaultVel, math.min(127, defaultVel * t.Variance/100) }
	local i = 1
	for spp = play[1]:sppOffset(), fini, dur do
		for j = 1, play[i]:noteCount() or 0 do 
			nwcplay.note(spp, dur, nwcplay.getNoteNumber(play[i]:notePitchPos(j)), vel[i])
		end
		i = 3 - i
	end
end

local function _spin(t, dir)
	t.Beams = t.Beams + dir
	t.Beams = t.Beams
end

return {
	nwcut = _nwcut,
	spec = _spec,
	spin = _spin,
	draw = _draw,
	play = _play,
}
