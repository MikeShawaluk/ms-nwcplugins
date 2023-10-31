-- Version 2.1

--[[----------------------------------------------------------------
This object creates a single note tremolo marking. It draws the markings, and will optionally play the note in tremolo style.

To create the tremolo, insert the object immediately before the note to receive the tremolo, and the marking 
will be drawn on the note's stem, or above/below a whole note. The note can be any chord or RestChord.
If additional space is needed to accommodate a larger number of beams, increase the note's stem length.

Please note that this object requires that Class be set to Standard for proper operation. During a score refresh, the Class property for all such objects will be reset to Standard.
@Beams
The number of beams to be drawn, between 1 and 4. The default setting is 3.

For stemmed notes, the first beam will be drawn closest to the stem tip, with successive beams added toward the notehead.
For unstemmed (whole) notes, the first beam will be drawn closest to the notehead, 
with successive beams added further from the notehead.

For playback, the number of beams determines the frequency and number of notes to be played. 

The number of beams for a tremolo can be modified by highlighting the object and pressing the + or - keys.
@Offset
This allows the distance between the notehead and tremolo beams to be adjusted. The value can be between -10.00 and 10.00. 
For stemmed notes, positive values move the beams away from the stem tip and toward the note head.
For unstemmed (whole) notes, positive values move the beams away from the note head. The default setting is 0.
@Play
Enables playback of the tremolo. The default setting is enabled (checked).

Note that the tremolo note should be muted for proper playback.
@TripletPlayback
Specifies that the playback notes should be in triplet rhythm. This will generally be used when the tremolo 
notes are dotted. The default setting is disabled (unchecked).
@Which
Specifies which split chord member (top or bottom) should receive the tremolo marking and be played. This parameter is
ignored for non-split chords and rest chords. The default setting is top.
@Variance
Specifies a dynamic variance between the two notes for each repetition. The specified value is a multiplier for the
volume of the second note. This allows more realistic playback for stringed instruments such as the mandolin.
The range of values is 50% to 200%, and the default setting is 100% (no variance).
--]]----------------------------------------------------------------

if nwcut then
	local userObjTypeName = arg[1]
	local score = nwcut.loadFile()
	local beams = nwcut.prompt('Number of Beams:', '#[0,4]', 3)
	
	local function applyTremolo(o)
		if o:IsFake() then return end
		
		if o.UserType == userObjTypeName then
			return 'delete'
		elseif o:ContainsNotes() then
			local opts = o:Provide('Opts')
			if beams > 0 then
				local o2 = nwcItem.new('|User|' .. userObjTypeName)
				o2.Opts.Pos = 0
				o2.Opts.Beams = beams
				opts.Muted = ''
				return { o2, o }
			else
				opts.Muted = nil
			end
		end
	end
	
	score:forSelection(applyTremolo)
	score:save()
	return
end
	
local userObjTypeName = ...	
local idx = nwc.ntnidx
local user = nwcdraw.user
local durations = { Eighth=1, Sixteenth=2, Thirtysecond=3, Sixtyfourth=4 }
local whichList = { 'top', 'bottom' }
local whichStemDirList = { top=1, bottom=-1}
local whichDur = { top='Dur', bottom='Dur2' }

local _nwcut = {
	['Apply'] = 'ClipText',
}

local _spec = {
	{ id='Beams', label='Number of Beams', type='int', default=3, min=1, max=4, step=1 },
	{ id='Offset', label='Vertical Offset', type='float', default=0, min=-10, max=10, step=.5 },
	{ id='Play', label='Play Notes', type='bool', default=true },
	{ id='TripletPlayback', label='Triplet Playback', type='bool', default=false },
	{ id='Which', label='Split Chord Member', type='enum', default=whichList[1], list=whichList },
	{ id='Variance', label='Variance (%)', type='int', default=100, min=50, max=200, step=5 },
}

local beamHeight, beamSpacing, beamHalfWidth, beamStemOffset, beamSlope = .6, 1.6, 0.55, 1, 0.6

local stopsItems = { Note=1, Chord=1, RestChord=1, Rest=-1, Bar=-1, RestMultiBar=-1, Boundary=-1 }

local function hasTargetNote(idx)
	while idx:find('next') do
		local d = stopsItems[idx:objType()]
		if d then return d > 0 end
--		if (idx:userType() == userObjTypeName) then return false end
	end
	return false
end

local function drawBeams(beams, x, ys, stemDir, wf, isError)
	if not nwcdraw.isDrawing() then return isError and beamHalfWidth*2 or 0 end
	for i = 0, beams-1 do
		local y = ys-(i*beamSpacing+beamStemOffset)*stemDir*wf
		nwcdraw.moveTo(x-beamHalfWidth, y)
		nwcdraw.beginPath()
		nwcdraw.line(x+beamHalfWidth, y+beamSlope)
		nwcdraw.line(x+beamHalfWidth, y+beamSlope-beamHeight)
		nwcdraw.line(x-beamHalfWidth, y-beamHeight)
		nwcdraw.closeFigure()
		nwcdraw.endPath()
	end
end

local function _draw(t)
	local _, my = nwcdraw.getMicrons()
	local stemWeight = my*0.0126
	local offset = t.Offset
	local beams = t.Beams

	if not hasTargetNote(idx) then
		return drawBeams(beams, -beamHalfWidth, 0, 1, 1, true)
	end
	if not nwcdraw.isDrawing() then return 0 end
	if not user:find(idx) then return end
	nwcdraw.setPen('solid', stemWeight)
	
	local whichVoice = t.Which == whichList[1] and user:noteCount() or 1

	local stemDir = user:stemDir(whichVoice)
	local x, ys = user:xyStemTip(stemDir)
	local xa, ya = user:xyAlignAnchor(stemDir)

	local wf = x and 1 or -1
	local j = durations[user:durationBase(whichVoice)]
	if j then
		offset = offset + (user:isBeamed(whichVoice) and j*2-.75 or j*1.5+3.75+stemDir/4)
	end	
	x = x or xa + .65
	ys = ys and ys-offset*stemDir or ya-(offset+2)*stemDir*wf
	drawBeams(beams, x, ys, stemDir, wf, false)
end

local function _audit(t)
	t.Class = 'Standard'
end

local function _play(t)
	if not t.Play then return end
	if not hasTargetNote(idx) then return end
	local whichStemDir = idx:objType() == 'RestChord' and idx:stemDir(1) or whichStemDirList[t.Which]
	local b = t.Beams + (durations[idx:durationBase(1)] or 0)
	local dur = nwcplay.PPQ / 2^b * (t.TripletPlayback and 2/3 or 1)
	local fini = idx:sppOffset() + nwcplay.calcDurLength(idx:objProp(whichDur[t.Which]))-1
	local defaultVel = nwcplay.getNoteVelocity()
	local vel = { defaultVel, math.min(127, defaultVel * t.Variance/100) }
	local i = 1
	for spp = idx:sppOffset(), fini, dur do
		for j = 1, idx:noteCount() or 0 do
			if not idx:isSplitVoice(j) or whichStemDir == idx:stemDir(j) then
				nwcplay.note(spp, dur, nwcplay.getNoteNumber(idx:notePitchPos(j)), vel[i])
			end
		end
        i = 3 - i
	end
end

local function flipDir(t)
	if not idx:find('next', 'note') then return 1 end
	local whichVoice = t.Which == whichList[1] and idx:noteCount() or 1
	return idx:stemDir(whichVoice) * (idx:durationBase(whichVoice) == 'Whole' and -1 or 1)
end

local function updateEnum(t, n, w)
	local s = _spec[n]
	local x = s.id
	t[x] = s.list[w]
end

local function updateParam(t, n, dir)
	dir = dir * (n == 2 and flipDir(t) or 1)
	local s = _spec[n]
	local x = s.id
	t[x] = t[x] + dir*s.step
	t[x] = t[x]
end

local charTable = {
	['8'] = { updateParam, 2, -1 },
	['2'] = { updateParam, 2, 1 },
	['+'] = { updateParam, 1, 1 },
	['-'] = { updateParam, 1, -1 },
	['9'] = { updateEnum, 5, 1 },
	['3'] = { updateEnum, 5, 2 },
}

local function _onChar(t, c)
	local x = string.char(c)
	local ptr = charTable[x]
	if not ptr then return false end
	ptr[1](t, ptr[2], ptr[3])
	return true
end

return {
	nwcut = _nwcut,
	spec = _spec,
	draw = _draw,
	width = _draw,
	play = _play,
	onChar = _onChar,
	audit = _audit,
}
