-- Version 0.96

--[[----------------------------------------------------------------
This object creates a single note tremolo marking. It draws the markings, and will optionally play the note in tremolo style.

To create the tremolo, insert the object immediately before the note to receive the tremolo, and the marking 
will be drawn on the note's stem, or above/below a whole note. The note can be any chord or RestChord.
If additional space is needed to accommodate a larger number of beams, increase the note's stem length.
@Beams
The number of beams to be drawn, between 1 and 4. The default setting is 3.

For playback, the number of beams determines the frequency and number of notes to be played. 

The number of beams for a tremolo can be modified by highlighting the object and pressing the + or - keys.
@Offset
This allows the distance between the notehead and tremolo beams to be adjusted. The value can be between -5.00 and 5.00. 
Positive values move the beams toward the note head, negative values away from the note head. The default setting is 0.
@Play
Enables playback of the tremolo. The default setting is enabled (checked).

Note that the tremolo note should be muted for proper playback.
@TripletPlayback
Specifies that the playback notes should be in triplet rhythm. This will generally be used when the tremolo 
notes are dotted. The default setting is disabled (unchecked).
--]]----------------------------------------------------------------

local user = nwcdraw.user
local durations = { Eighth=1, Sixteenth=2, Thirtysecond=3, Sixtyfourth=4 }

local function draw_TremoloSingle(t)
	local _, my = nwcdraw.getMicrons()
	local stemWeight = my*0.0126
	local offset = t.Offset
	local beams = t.Beams
	local yu = user:staffPos()
	local beamHeight, beamSpacing, beamHalfWidth, beamStemOffset, beamSlope = .6, 1.6, 0.55, 1, 0.6
	nwcdraw.setPen('solid', stemWeight)
	if not user:find('next', 'note') then return end
	local stemDir = user:stemDir(1)
	local x, ys = user:xyStemTip(stemDir)
	local xa, ya = user:xyAlignAnchor(stemDir)
	local d = user:durationBase(1)
	local j = durations[d]
	if j then
		offset = offset + (user:isBeamed(1) and j*2-.75 or j*1.5+3.75+stemDir/4)
	end	
	x = x or xa + .65
	ys = ys and ys-offset*stemDir or ya-(offset+2)*stemDir
	for i = 0, beams-1 do
		local y = ys-(i*beamSpacing+beamStemOffset)*stemDir
		nwcdraw.moveTo(x-beamHalfWidth, y)
		nwcdraw.beginPath()
		nwcdraw.line(x+beamHalfWidth, y+beamSlope)
		nwcdraw.line(x+beamHalfWidth, y+beamSlope-beamHeight)
		nwcdraw.line(x-beamHalfWidth, y-beamHeight)
		nwcdraw.closeFigure()
		nwcdraw.endPath()
	end
end

local function spin_TremoloSingle(t,dir)
	t.Beams = t.Beams + dir
	t.Beams = t.Beams
end

local spec_TremoloSingle = {
	{ id='Beams', label='Number of Beams', type='int', default=3, min=1, max=4 },
	{ id='Offset', label='Vertical Offset', type='float', default=0, min=-5, max=5, step=.1 },
	{ id='Play', label='Play Notes', type='bool', default=true },
	{ id='TripletPlayback', label='Triplet Playback', type='bool', default=false }
}

local _play = nwc.ntnidx.new()
local function play_TremoloSingle(t)
	if not t.Play then return end
	_play:find('next', 'note')
	local b = t.Beams + (durations[_play:durationBase(1)] or 0)
	local dur = nwcplay.PPQ / 2^b * (t.TripletPlayback and 2/3 or 1)	
	_play:find('next')
	local fini = _play:sppOffset() - 1
	_play:find('prior')
	for spp = _play:sppOffset(), fini, dur do
		for j = 1, _play:noteCount() or 0 do
			nwcplay.note(spp, dur, nwcplay.getNoteNumber(_play:notePitchPos(j)))
		end
	end
end

return {
	spec = spec_TremoloSingle,
    spin = spin_TremoloSingle,
	draw = draw_TremoloSingle,
	play = play_TremoloSingle
}