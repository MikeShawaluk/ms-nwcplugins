-- Version 0.9

--[[----------------------------------------------------------------
Tremolo.ms

This object will add tremolo markings to (and optionally play) a pair of RestChords of the proper duration. The object should be placed between
the notes which comprise the tremolo. Also, the rest portion of each RestChord should be marked as hidden.

--]]----------------------------------------------------------------

local user = nwcdraw.user
local nextNote = nwc.drawpos.new()
local priorNote = nwc.drawpos.new()
local nextNotePlay = nwc.ntnidx.new()
local priorNotePlay = nwc.ntnidx.new()

local spec_Tremolo = {
	Beams = { type='int', default=3, min=1, max=4 },
	Play = { type='bool', default=true },
	Style = { type='int', default=1, min=1, max=3 },
	TripletPlayback = { type='bool', default=false }
}

local function draw_Tremolo(t)
	local beams = t.Beams
	local style = t.Style
	local yu = user:staffPos()
	local stemWeight = nwcdraw.getMicrons() / 195
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

local function play_Tremolo(t)
	if not t.Play then return end
	if not nextNotePlay:find('next', 'note') then return end
	if nextNotePlay:objType() ~= 'RestChord' then return end
	if not priorNotePlay:find('prior', 'note') then return end
	if priorNotePlay:objType() ~= 'RestChord' then return end
	local beams = t.Beams
	local ncp, ncn = priorNotePlay:noteCount(), nextNotePlay:noteCount()
	nextNotePlay:find('next')
	local sppEnd = nextNotePlay:sppOffset()
	nextNotePlay:reset()
	nextNotePlay:find('next', 'note')
	local spp = priorNotePlay:sppOffset()
	local noteDur = nwcplay.PPQ / 2^beams
	if t.TripletPlayback then noteDur = noteDur * 2/3 end
	while spp < sppEnd do
		for i=1, ncp do
			nwcplay.note(spp, noteDur, nwcplay.getNoteNumber(priorNotePlay:notePitchPos(i)))
		end
		spp = spp + noteDur
		for i=1, ncn do
			nwcplay.note(spp, noteDur, nwcplay.getNoteNumber(nextNotePlay:notePitchPos(i)))
		end
		spp = spp + noteDur
	end
end

local function spin_Tremolo(t, dir)
	t.Beams = t.Beams + dir
	t.Beams = t.Beams
end

local function create_Tremolo(t)

end

return {
	create = create_Tremolo,
	spin = spin_Tremolo,
	spec = spec_Tremolo,
	draw = draw_Tremolo,
	play = play_Tremolo
}